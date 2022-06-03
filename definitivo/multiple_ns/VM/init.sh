#!/usr/bin/env bash
shopt -s expand_aliases
if [ -f aliases.sh ]; then
    # shellcheck source=aliases.sh
    source aliases.sh
fi


if [ $# -ne 10 ]; then
    echo "Usage: $0 <pod_ip> <pod_ipgw> <gw1_podcidr> <gw2_podcidr> <gw1_natpool> <gw2_natpool> <gw1_wgip_local> <gw2_wgip_local> <gw1_wgip_remote> <gw2_wgip_remote>"
    exit 1
fi



#Define pods ips
MY_PODIP=$1
MY_PODIP_GW=$2

GW1_PODCIDR=$3

GW2_PODCIDR=$4

GW1_NATCIDR_POOL=$5
GW2_NATCIDR_POOL=$6

LL_HOST="169.254.1.1"
LL_GW="169.254.1.2"

LL_WG1_LOCAL=$7
LL_WG2_LOCAL=$8

LL_WG1_REMOTE=$9
LL_WG2_REMOTE=${10}

echo "PODIP: $MY_PODIP"
echo "PODIP_GW: $MY_PODIP_GW"
echo "GW1_PODCIDR: $GW1_PODCIDR"
echo "GW2_PODCIDR: $GW2_PODCIDR"
echo "GW1_NATCIDR_POOL: $GW1_NATCIDR_POOL"
echo "GW2_NATCIDR_POOL: $GW2_NATCIDR_POOL"
echo "LL_WG1_LOCAL: $LL_WG1_LOCAL"
echo "LL_WG2_LOCAL: $LL_WG2_LOCAL"
echo "LL_WG1_REMOTE: $LL_WG1_REMOTE"
echo "LL_WG2_REMOTE: $LL_WG2_REMOTE"

#Create network namespaces
sudo ip netns add pod
sudo ip netns add gw1
sudo ip netns add gw2

#Create and assign virtual ethernets

sudo ip link add h1-eth type veth peer name gw1-eth
sudo ip link add h2-eth type veth peer name gw2-eth
sudo ip link add p-pod type veth peer name h-pod


sudo ip link set gw1-eth netns gw1
sudo ip link set gw2-eth netns gw2
sudo ip link set p-pod netns pod


sudo ip addr add "${LL_HOST}/30" dev h1-eth
sudo ip addr add "${LL_HOST}/30" dev h2-eth
gw1 ip addr add "${LL_GW}/30" dev gw1-eth
gw2 ip addr add "${LL_GW}/30" dev gw2-eth
pod ip addr add "${MY_PODIP}/16" dev p-pod
sudo ip addr add "${MY_PODIP_GW}/16" dev h-pod

sudo ip link set h1-eth up
sudo ip link set h2-eth up
gw1 ip link set gw1-eth up
gw2 ip link set gw2-eth up
pod ip link set p-pod up
sudo ip link set h-pod up

#Create and assigns VPN interfaces

wg genkey > private_gw1
wg genkey > private_gw2

sudo ip link add gw1-wg type wireguard
sudo ip link add gw2-wg type wireguard

sudo wg set gw1-wg private-key ./private_gw1
sudo wg set gw2-wg private-key ./private_gw2

sudo cat ./private_gw1 | wg pubkey > public_gw1
sudo cat ./private_gw2 | wg pubkey > public_gw2

sudo ip link set gw1-wg netns gw1
sudo ip link set gw2-wg netns gw2

gw1 ip addr add "${LL_WG1_LOCAL}"/30 dev gw1-wg
gw2 ip addr add "${LL_WG2_LOCAL}"/30 dev gw2-wg

gw1 ip link set gw1-wg up
gw2 ip link set gw2-wg up

gw1 wg show gw1-wg listen-port > port_gw1
gw2 wg show gw2-wg listen-port > port_gw2

# gw1 wg set gw1-wg peer $(cat public_c2-gw1) allowed-ips 0.0.0.0/0 endpoint 50.0.0.2:$(cat port_c2-gw1)
# FACCIO A MANO gw2 wg set gw2-wg peer $(cat public_c3-gw2) allowed-ips 0.0.0.0/0 endpoint 50.0.0.2:$(cat port_c3-gw2)

# Setup Pod routing


pod ip route add default via "${MY_PODIP_GW}" dev p-pod

# Setup Host routing

sudo ip route add "${GW1_NATCIDR_POOL}" via "${LL_GW}" dev h1-eth
sudo ip route add "${GW2_NATCIDR_POOL}" via "${LL_GW}" dev h2-eth

# Setup liqo-gateway routing

#echo 200 liqo-out >> /etc/iproute2/rt_tables
#echo 201 liqo-in >> /etc/iproute2/rt_tables

gw1 ip rule add iif gw1-wg lookup liqo-in
gw1 ip rule add iif gw1-eth lookup liqo-out
gw1 ip route add default via "${LL_WG1_REMOTE}" table liqo-out
gw1 ip route add default via "${LL_HOST}" table liqo-in

gw2 ip rule add iif gw2-wg lookup liqo-in
gw2 ip rule add iif gw2-eth lookup liqo-out
gw2 ip route add default via "${LL_WG2_REMOTE}" table liqo-out
gw2 ip route add default via ${LL_HOST} table liqo-in

sudo iptables -A FORWARD -i any -j ACCEPT
sudo iptables -A FORWARD -o any -j ACCEPT
gw1 iptables -A FORWARD -i any -j ACCEPT
gw1 iptables -A FORWARD -o any -j ACCEPT
gw2 iptables -A FORWARD -i any -j ACCEPT
gw2 iptables -A FORWARD -o any -j ACCEPT

# Setup liqo-gateway natting

gw1 iptables -t nat -A PREROUTING -d "${GW1_NATCIDR_POOL}" -j NETMAP --to "${GW1_PODCIDR}"
gw2 iptables -t nat -A PREROUTING -d "${GW2_NATCIDR_POOL}" -j NETMAP --to "${GW2_PODCIDR}"

gw1 iptables -t nat -A POSTROUTING -o gw1-eth -j NETMAP --to "${GW1_NATCIDR_POOL}"
gw2 iptables -t nat -A POSTROUTING -o gw2-eth -j NETMAP --to "${GW2_NATCIDR_POOL}"

echo
./info.sh


