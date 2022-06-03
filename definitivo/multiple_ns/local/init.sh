#!/usr/bin/env bash
shopt -s expand_aliases
source ./aliases.sh

#Define pods ips
C1_PODIP="20.0.0.1"
C1_PODIP_GW="20.0.0.2"
C1_PODCIDR="20.1.0.0/16"

C2_PODIP="20.0.0.1"
C2_PODIP_GW="20.0.0.2"
C2_PODCIDR="20.0.0.0/16"

C3_PODIP="20.0.0.1"
C3_PODIP_GW="20.0.0.2"
C3_PODCIDR="20.0.0.0/16"

GW1_NATCIDR_POOL="30.1.0.0/16"
GW2_NATCIDR_POOL="30.2.0.0/16"

LL_HOST="169.254.1.1"
LL_GW="169.254.1.2"

LL_WG1="169.254.2.1"
LL_WG2="169.254.2.2"

#Create network namespaces
sudo ip netns add c1-pod
sudo ip netns add c2-pod
sudo ip netns add c3-pod
sudo ip netns add c1-host
sudo ip netns add c2-host
sudo ip netns add c3-host
sudo ip netns add c1-gw1
sudo ip netns add c1-gw2
sudo ip netns add c2-gw1
sudo ip netns add c2-gw2
sudo ip netns add c3-gw1
sudo ip netns add c3-gw2

#Create and assign virtual ethernets

sudo ip link add c1-h1-eth type veth peer name c1-gw1-eth
sudo ip link add c1-h2-eth type veth peer name c1-gw2-eth
sudo ip link add c2-h1-eth type veth peer name c2-gw1-eth
sudo ip link add c2-h2-eth type veth peer name c2-gw2-eth
sudo ip link add c3-h1-eth type veth peer name c3-gw1-eth
sudo ip link add c3-h2-eth type veth peer name c3-gw2-eth
sudo ip link add c1-p-pod type veth peer name c1-h-pod
sudo ip link add c2-p-pod type veth peer name c2-h-pod
sudo ip link add c3-p-pod type veth peer name c3-h-pod


sudo ip link set c1-h1-eth netns c1-host
sudo ip link set c1-h2-eth netns c1-host
sudo ip link set c2-h1-eth netns c2-host
sudo ip link set c2-h2-eth netns c2-host
sudo ip link set c3-h1-eth netns c3-host
sudo ip link set c3-h2-eth netns c3-host
sudo ip link set c1-gw1-eth netns c1-gw1
sudo ip link set c1-gw2-eth netns c1-gw2
sudo ip link set c2-gw1-eth netns c2-gw1
sudo ip link set c2-gw2-eth netns c2-gw2
sudo ip link set c3-gw1-eth netns c3-gw1
sudo ip link set c3-gw2-eth netns c3-gw2
sudo ip link set c1-p-pod netns c1-pod
sudo ip link set c2-p-pod netns c2-pod
sudo ip link set c3-p-pod netns c3-pod
sudo ip link set c1-h-pod netns c1-host
sudo ip link set c2-h-pod netns c2-host
sudo ip link set c3-h-pod netns c3-host


c1-host ip addr add "${LL_HOST}/30" dev c1-h1-eth
c1-host ip addr add "${LL_HOST}/30" dev c1-h2-eth
c1-gw1 ip addr add "${LL_GW}/30" dev c1-gw1-eth
c1-gw2 ip addr add "${LL_GW}/30" dev c1-gw2-eth
c2-host ip addr add "${LL_HOST}/30" dev c2-h1-eth
c2-host ip addr add "${LL_HOST}/30" dev c2-h2-eth
c2-gw1 ip addr add "${LL_GW}/30" dev c2-gw1-eth
c2-gw2 ip addr add "${LL_GW}/30" dev c2-gw2-eth
c3-host ip addr add "${LL_HOST}/30" dev c3-h1-eth
c3-host ip addr add "${LL_HOST}/30" dev c3-h2-eth
c3-gw1 ip addr add "${LL_GW}/30" dev c3-gw1-eth
c3-gw2 ip addr add "${LL_GW}/30" dev c3-gw2-eth
c1-pod ip addr add "${C1_PODIP}/16" dev c1-p-pod
c2-pod ip addr add "${C2_PODIP}/16" dev c2-p-pod
c3-pod ip addr add "${C3_PODIP}/16" dev c3-p-pod
c1-host ip addr add "${C1_PODIP_GW}/16" dev c1-h-pod
c2-host ip addr add "${C2_PODIP_GW}/16" dev c2-h-pod
c3-host ip addr add "${C3_PODIP_GW}/16" dev c3-h-pod

c1-host ip link set c1-h1-eth up
c1-host ip link set c1-h2-eth up
c2-host ip link set c2-h1-eth up
c2-host ip link set c2-h2-eth up
c3-host ip link set c3-h1-eth up
c3-host ip link set c3-h2-eth up
c1-gw1 ip link set c1-gw1-eth up
c1-gw2 ip link set c1-gw2-eth up
c2-gw1 ip link set c2-gw1-eth up
c2-gw2 ip link set c2-gw2-eth up
c3-gw1 ip link set c3-gw1-eth up
c3-gw2 ip link set c3-gw2-eth up
c1-pod ip link set c1-p-pod up
c2-pod ip link set c2-p-pod up
c3-pod ip link set c3-p-pod up
c1-host ip link set c1-h-pod up
c2-host ip link set c2-h-pod up
c3-host ip link set c3-h-pod up


#Create and assign interfaces to enstablish VPN

sudo ip link add c1-gw1-tmp type veth peer c2-gw1-tmp
sudo ip link add c1-gw2-tmp type veth peer c3-gw2-tmp
sudo ip link add c2-gw2-tmp type veth peer c3-gw1-tmp

sudo ip link set c1-gw1-tmp netns c1-gw1
sudo ip link set c1-gw2-tmp netns c1-gw2
sudo ip link set c2-gw1-tmp netns c2-gw1
sudo ip link set c2-gw2-tmp netns c2-gw2
sudo ip link set c3-gw1-tmp netns c3-gw1
sudo ip link set c3-gw2-tmp netns c3-gw2

c1-gw1 ip addr add 50.0.0.1/30 dev c1-gw1-tmp
c1-gw2 ip addr add 50.0.0.1/30 dev c1-gw2-tmp
c2-gw1 ip addr add 50.0.0.2/30 dev c2-gw1-tmp
c2-gw2 ip addr add 50.0.0.1/30 dev c2-gw2-tmp
c3-gw1 ip addr add 50.0.0.2/30 dev c3-gw1-tmp
c3-gw2 ip addr add 50.0.0.2/30 dev c3-gw2-tmp

c1-gw1 ip link set c1-gw1-tmp up
c1-gw2 ip link set c1-gw2-tmp up
c2-gw1 ip link set c2-gw1-tmp up
c2-gw2 ip link set c2-gw2-tmp up
c3-gw1 ip link set c3-gw1-tmp up
c3-gw2 ip link set c3-gw2-tmp up

#Create and assigns VPN interfaces

c1-gw1 wg genkey > private_c1-gw1
c1-gw2 wg genkey > private_c1-gw2
c2-gw1 wg genkey > private_c2-gw1
c2-gw2 wg genkey > private_c2-gw2
c3-gw1 wg genkey > private_c3-gw1
c3-gw2 wg genkey > private_c3-gw2

c1-gw1 ip link add c1-gw1-wg type wireguard
c1-gw2 ip link add c1-gw2-wg type wireguard
c2-gw1 ip link add c2-gw1-wg type wireguard
c2-gw2 ip link add c2-gw2-wg type wireguard
c3-gw1 ip link add c3-gw1-wg type wireguard
c3-gw2 ip link add c3-gw2-wg type wireguard

c1-gw1 ip addr add ${LL_WG1}/30 dev c1-gw1-wg
c1-gw2 ip addr add ${LL_WG1}/30 dev c1-gw2-wg
c2-gw1 ip addr add ${LL_WG2}/30 dev c2-gw1-wg
c2-gw2 ip addr add ${LL_WG1}/30 dev c2-gw2-wg
c3-gw1 ip addr add ${LL_WG2}/30 dev c3-gw1-wg
c3-gw2 ip addr add ${LL_WG2}/30 dev c3-gw2-wg

c1-gw1 wg set c1-gw1-wg private-key ./private_c1-gw1
c1-gw2 wg set c1-gw2-wg private-key ./private_c1-gw2
c2-gw1 wg set c2-gw1-wg private-key ./private_c2-gw1
c2-gw2 wg set c2-gw2-wg private-key ./private_c2-gw2
c3-gw1 wg set c3-gw1-wg private-key ./private_c3-gw1
c3-gw2 wg set c3-gw2-wg private-key ./private_c3-gw2

c1-gw1 ip link set c1-gw1-wg up
c1-gw2 ip link set c1-gw2-wg up
c2-gw1 ip link set c2-gw1-wg up
c2-gw2 ip link set c2-gw2-wg up
c3-gw1 ip link set c3-gw1-wg up
c3-gw2 ip link set c3-gw2-wg up

c1-gw1 cat ./private_c2-gw1 | wg pubkey > public_c2-gw1
c1-gw2 cat ./private_c3-gw2 | wg pubkey > public_c3-gw2
c2-gw1 cat ./private_c1-gw1 | wg pubkey > public_c1-gw1
c2-gw2 cat ./private_c3-gw1 | wg pubkey > public_c3-gw1
c3-gw1 cat ./private_c2-gw2 | wg pubkey > public_c2-gw2
c3-gw2 cat ./private_c1-gw2 | wg pubkey > public_c1-gw2

c1-gw1 wg show c1-gw1-wg listen-port > port_c1-gw1
c1-gw2 wg show c1-gw2-wg listen-port > port_c1-gw2
c2-gw1 wg show c2-gw1-wg listen-port > port_c2-gw1
c2-gw2 wg show c2-gw2-wg listen-port > port_c2-gw2
c3-gw1 wg show c3-gw1-wg listen-port > port_c3-gw1
c3-gw2 wg show c3-gw2-wg listen-port > port_c3-gw2

c1-gw1 wg set c1-gw1-wg peer $(cat public_c2-gw1) allowed-ips 0.0.0.0/0 endpoint 50.0.0.2:$(cat port_c2-gw1)
c1-gw2 wg set c1-gw2-wg peer $(cat public_c3-gw2) allowed-ips 0.0.0.0/0 endpoint 50.0.0.2:$(cat port_c3-gw2)
c2-gw1 wg set c2-gw1-wg peer $(cat public_c1-gw1) allowed-ips 0.0.0.0/0 endpoint 50.0.0.1:$(cat port_c1-gw1)
c2-gw2 wg set c2-gw2-wg peer $(cat public_c3-gw1) allowed-ips 0.0.0.0/0 endpoint 50.0.0.2:$(cat port_c3-gw1)
c3-gw1 wg set c3-gw1-wg peer $(cat public_c2-gw2) allowed-ips 0.0.0.0/0 endpoint 50.0.0.1:$(cat port_c2-gw2)
c3-gw2 wg set c3-gw2-wg peer $(cat public_c1-gw2) allowed-ips 0.0.0.0/0 endpoint 50.0.0.1:$(cat port_c1-gw2)

# Setup Pod routing


c1-pod ip route add default via "${C1_PODIP_GW}" dev c1-p-pod
c2-pod ip route add default via "${C2_PODIP_GW}" dev c2-p-pod
c3-pod ip route add default via "${C3_PODIP_GW}" dev c3-p-pod

# Setup Host routing

c1-host ip route add "${GW1_NATCIDR_POOL}" via "${LL_GW}" dev c1-h1-eth
c1-host ip route add "${GW2_NATCIDR_POOL}" via "${LL_GW}" dev c1-h2-eth
c2-host ip route add "${GW1_NATCIDR_POOL}" via "${LL_GW}" dev c2-h1-eth
c2-host ip route add "${GW2_NATCIDR_POOL}" via "${LL_GW}" dev c2-h2-eth
c3-host ip route add "${GW1_NATCIDR_POOL}" via "${LL_GW}" dev c3-h1-eth
c3-host ip route add "${GW2_NATCIDR_POOL}" via "${LL_GW}" dev c3-h2-eth

# Setup liqo-gateway routing

#echo 200 liqo-out >> /etc/iproute2/rt_tables
#echo 201 liqo-in >> /etc/iproute2/rt_tables

c1-gw1 ip rule add iif c1-gw1-wg lookup liqo-in
c1-gw1 ip rule add iif c1-gw1-eth lookup liqo-out
c1-gw1 ip route add default via ${LL_WG2} table liqo-out
c1-gw1 ip route add default via "${LL_HOST}" table liqo-in

c1-gw2 ip rule add iif c1-gw2-wg lookup liqo-in
c1-gw2 ip rule add iif c1-gw2-eth lookup liqo-out
c1-gw2 ip route add default via ${LL_WG2} table liqo-out
c1-gw2 ip route add default via ${LL_HOST} table liqo-in

c2-gw1 ip rule add iif c2-gw1-wg lookup liqo-in
c2-gw1 ip rule add iif c2-gw1-eth lookup liqo-out
c2-gw1 ip route add default via ${LL_WG1} table liqo-out
c2-gw1 ip route add default via "${LL_HOST}" table liqo-in

c2-gw2 ip rule add iif c2-gw2-wg lookup liqo-in
c2-gw2 ip rule add iif c2-gw2-eth lookup liqo-out
c2-gw2 ip route add default via ${LL_WG2} table liqo-out
c2-gw2 ip route add default via ${LL_HOST} table liqo-in

c3-gw1 ip rule add iif c3-gw1-wg lookup liqo-in
c3-gw1 ip rule add iif c3-gw1-eth lookup liqo-out
c3-gw1 ip route add default via ${LL_WG1} table liqo-out
c3-gw1 ip route add default via "${LL_HOST}" table liqo-in

c3-gw2 ip rule add iif c3-gw2-wg lookup liqo-in
c3-gw2 ip rule add iif c3-gw2-eth lookup liqo-out
c3-gw2 ip route add default via ${LL_WG1} table liqo-out
c3-gw2 ip route add default via ${LL_HOST} table liqo-in

c1-host iptables -A FORWARD -i any -j ACCEPT
c1-host iptables -A FORWARD -o any -j ACCEPT
c2-host iptables -A FORWARD -i any -j ACCEPT
c2-host iptables -A FORWARD -o any -j ACCEPT
c3-host iptables -A FORWARD -i any -j ACCEPT
c3-host iptables -A FORWARD -o any -j ACCEPT
c1-gw1 iptables -A FORWARD -i any -j ACCEPT
c1-gw1 iptables -A FORWARD -o any -j ACCEPT
c1-gw2 iptables -A FORWARD -i any -j ACCEPT
c1-gw2 iptables -A FORWARD -o any -j ACCEPT
c2-gw1 iptables -A FORWARD -i any -j ACCEPT
c2-gw1 iptables -A FORWARD -o any -j ACCEPT
c2-gw2 iptables -A FORWARD -i any -j ACCEPT
c2-gw2 iptables -A FORWARD -o any -j ACCEPT
c3-gw1 iptables -A FORWARD -i any -j ACCEPT
c3-gw1 iptables -A FORWARD -o any -j ACCEPT
c3-gw2 iptables -A FORWARD -i any -j ACCEPT
c3-gw2 iptables -A FORWARD -o any -j ACCEPT


# Setup liqo-gateway natting

c1-gw1 iptables -t nat -A PREROUTING -d "${GW1_NATCIDR_POOL}" -j NETMAP --to "${C2_PODCIDR}"
c1-gw2 iptables -t nat -A PREROUTING -d "${GW2_NATCIDR_POOL}" -j NETMAP --to "${C3_PODCIDR}"
c2-gw1 iptables -t nat -A PREROUTING -d "${GW1_NATCIDR_POOL}" -j NETMAP --to "${C1_PODCIDR}"
c2-gw2 iptables -t nat -A PREROUTING -d "${GW2_NATCIDR_POOL}" -j NETMAP --to "${C3_PODCIDR}"
c3-gw1 iptables -t nat -A PREROUTING -d "${GW1_NATCIDR_POOL}" -j NETMAP --to "${C2_PODCIDR}"
c3-gw2 iptables -t nat -A PREROUTING -d "${GW2_NATCIDR_POOL}" -j NETMAP --to "${C1_PODCIDR}"

c1-gw1 iptables -t nat -A POSTROUTING -o c1-gw1-eth -j NETMAP --to "${GW1_NATCIDR_POOL}"
c1-gw2 iptables -t nat -A POSTROUTING -o c1-gw2-eth -j NETMAP --to "${GW2_NATCIDR_POOL}"
c2-gw1 iptables -t nat -A POSTROUTING -o c2-gw1-eth -j NETMAP --to "${GW1_NATCIDR_POOL}"
c2-gw2 iptables -t nat -A POSTROUTING -o c2-gw2-eth -j NETMAP --to "${GW2_NATCIDR_POOL}"
c3-gw1 iptables -t nat -A POSTROUTING -o c3-gw1-eth -j NETMAP --to "${GW1_NATCIDR_POOL}"
c3-gw2 iptables -t nat -A POSTROUTING -o c3-gw2-eth -j NETMAP --to "${GW2_NATCIDR_POOL}"

umask 002


