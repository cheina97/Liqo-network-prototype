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
sudo ip netns add gw

#Create and assign virtual ethernets

sudo ip link add h-eth type veth peer name gw-eth
sudo ip link add p-pod type veth peer name h-pod


sudo ip link set gw-eth netns gw
sudo ip link set p-pod netns pod


sudo ip addr add "${LL_HOST}/30" dev h-eth
gw ip addr add "${LL_GW}/30" dev gw-eth
pod ip addr add "${MY_PODIP}/16" dev p-pod
sudo ip addr add "${MY_PODIP_GW}/16" dev h-pod

sudo ip link set h-eth up
gw ip link set gw-eth up
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

sudo ip link set gw1-wg netns gw
sudo ip link set gw2-wg netns gw

gw ip addr add "${LL_WG1_LOCAL}"/30 dev gw1-wg
gw ip addr add "${LL_WG2_LOCAL}"/30 dev gw2-wg

gw ip link set gw1-wg up
gw ip link set gw2-wg up

gw wg show gw1-wg listen-port > port_gw1
gw wg show gw2-wg listen-port > port_gw2

# gw1 wg set gw1-wg peer $(cat public_c2-gw1) allowed-ips 0.0.0.0/0 endpoint 50.0.0.2:$(cat port_c2-gw1)
# FACCIO A MANO gw2 wg set gw2-wg peer $(cat public_c3-gw2) allowed-ips 0.0.0.0/0 endpoint 50.0.0.2:$(cat port_c3-gw2)

# Setup Pod routing


pod ip route add default via "${MY_PODIP_GW}" dev p-pod

# Setup Host routing

sudo ip route add "${GW1_NATCIDR_POOL}" via "${LL_GW}" dev h-eth
sudo ip route add "${GW2_NATCIDR_POOL}" via "${LL_GW}" dev h-eth

# Setup liqo-gateway routing

#echo 200 liqo-out >> /etc/iproute2/rt_tables
#echo 201 liqo-in >> /etc/iproute2/rt_tables

gw iptables -A PREROUTING -i gw-eth -d "${GW1_NATCIDR_POOL}" -t mangle -j MARK --set-mark 21
gw iptables -A PREROUTING -i gw-eth -d "${GW2_NATCIDR_POOL}" -t mangle -j MARK --set-mark 22 

gw ip rule add iif gw-eth fwmark 21 lookup liqo-out-1
gw ip route add default via "${LL_WG1_REMOTE}" dev gw1-wg table liqo-out-1

gw ip rule add iif gw-eth fwmark 22 lookup liqo-out-2
gw ip route add default via "${LL_WG2_REMOTE}" dev gw2-wg table liqo-out-2

gw ip route add default via "${LL_HOST}" dev gw-eth

sudo iptables -A FORWARD -i any -j ACCEPT
sudo iptables -A FORWARD -o any -j ACCEPT
gw iptables -A FORWARD -i any -j ACCEPT
gw iptables -A FORWARD -o any -j ACCEPT

# Setup liqo-gateway natting

gw iptables -t nat -A PREROUTING -i gw-eth -d "${GW1_NATCIDR_POOL}" -j NETMAP --to "${GW1_PODCIDR}"
gw iptables -t nat -A PREROUTING -i gw-eth -d "${GW2_NATCIDR_POOL}" -j NETMAP --to "${GW2_PODCIDR}"

gw iptables -A PREROUTING -i gw1-wg -t mangle -j MARK --set-mark 31
gw iptables -A PREROUTING -i gw2-wg -t mangle -j MARK --set-mark 32

gw iptables -t nat -A POSTROUTING --match mark --mark 31 -j NETMAP --to "${GW1_NATCIDR_POOL}"
gw iptables -t nat -A POSTROUTING --match mark --mark 32 -j NETMAP --to "${GW2_NATCIDR_POOL}"

echo
./info.sh


