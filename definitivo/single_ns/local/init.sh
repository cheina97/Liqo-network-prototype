#!/usr/bin/env bash
shopt -s expand_aliases
source ./aliases.sh

#Define pods ips
C1_PODIP="20.1.0.1"
C1_PODIP_GW="20.1.0.2"
C1_PODCIDR="20.1.0.0/16"

C2_PODIP="20.2.0.1"
C2_PODIP_GW="20.2.0.2"
C2_PODCIDR="20.2.0.0/16"

C3_PODIP="20.3.0.1"
C3_PODIP_GW="20.3.0.2"
C3_PODCIDR="20.3.0.0/16"

GW1_NATCIDR_POOL="30.1.0.0/16"
GW2_NATCIDR_POOL="30.2.0.0/16"

LL_HOST="169.254.1.1"
LL_GW="169.254.1.2"

LL_C1WG1="169.254.2.1"
LL_C2WG1="169.254.2.2"
LL_C2WG2="169.254.2.5"
LL_C3WG1="169.254.2.6"
LL_C1WG2="169.254.2.9"
LL_C3WG2="169.254.2.10"

#Create network namespaces
sudo ip netns add c1-pod
sudo ip netns add c2-pod
sudo ip netns add c3-pod
sudo ip netns add c1-host
sudo ip netns add c2-host
sudo ip netns add c3-host
sudo ip netns add c1-gw
sudo ip netns add c2-gw
sudo ip netns add c3-gw

#Create and assign virtual ethernets

sudo ip link add c1-h-eth type veth peer name c1-gw-eth
sudo ip link add c2-h-eth type veth peer name c2-gw-eth
sudo ip link add c3-h-eth type veth peer name c3-gw-eth
sudo ip link add c1-p-pod type veth peer name c1-h-pod
sudo ip link add c2-p-pod type veth peer name c2-h-pod
sudo ip link add c3-p-pod type veth peer name c3-h-pod


sudo ip link set c1-h-eth netns c1-host
sudo ip link set c2-h-eth netns c2-host
sudo ip link set c3-h-eth netns c3-host
sudo ip link set c1-gw-eth netns c1-gw
sudo ip link set c2-gw-eth netns c2-gw
sudo ip link set c3-gw-eth netns c3-gw
sudo ip link set c1-p-pod netns c1-pod
sudo ip link set c2-p-pod netns c2-pod
sudo ip link set c3-p-pod netns c3-pod
sudo ip link set c1-h-pod netns c1-host
sudo ip link set c2-h-pod netns c2-host
sudo ip link set c3-h-pod netns c3-host


c1-host ip addr add "${LL_HOST}/30" dev c1-h-eth
c1-gw ip addr add "${LL_GW}/30" dev c1-gw-eth
c2-host ip addr add "${LL_HOST}/30" dev c2-h-eth
c2-gw ip addr add "${LL_GW}/30" dev c2-gw-eth
c3-host ip addr add "${LL_HOST}/30" dev c3-h-eth
c3-gw ip addr add "${LL_GW}/30" dev c3-gw-eth
c1-pod ip addr add "${C1_PODIP}/16" dev c1-p-pod
c2-pod ip addr add "${C2_PODIP}/16" dev c2-p-pod
c3-pod ip addr add "${C3_PODIP}/16" dev c3-p-pod
c1-host ip addr add "${C1_PODIP_GW}/16" dev c1-h-pod
c2-host ip addr add "${C2_PODIP_GW}/16" dev c2-h-pod
c3-host ip addr add "${C3_PODIP_GW}/16" dev c3-h-pod

c1-host ip link set c1-h-eth up
c2-host ip link set c2-h-eth up
c3-host ip link set c3-h-eth up
c1-gw ip link set c1-gw-eth up
c2-gw ip link set c2-gw-eth up
c3-gw ip link set c3-gw-eth up
c1-pod ip link set c1-p-pod up
c2-pod ip link set c2-p-pod up
c3-pod ip link set c3-p-pod up
c1-host ip link set c1-h-pod up
c2-host ip link set c2-h-pod up
c3-host ip link set c3-h-pod up

#Create and assign interfaces to enstablish VPN

sudo ip link add c1-gw1-tmp type veth peer c2-gw1-tmp
#sudo ip link add c1-gw2-tmp type veth peer c3-gw2-tmp
#sudo ip link add c2-gw2-tmp type veth peer c3-gw1-tmp

sudo ip link set c1-gw1-tmp netns c1-gw
#sudo ip link set c1-gw2-tmp netns c1-gw
sudo ip link set c2-gw1-tmp netns c2-gw
#sudo ip link set c2-gw2-tmp netns c2-gw
#sudo ip link set c3-gw1-tmp netns c3-gw
#sudo ip link set c3-gw2-tmp netns c3-gw

c1-gw ip addr add 50.0.0.1/30 dev c1-gw1-tmp
#c1-gw ip addr add 50.0.0.5/30 dev c1-gw2-tmp
c2-gw ip addr add 50.0.0.2/30 dev c2-gw1-tmp
#c2-gw ip addr add 50.0.0.9/30 dev c2-gw2-tmp
#c3-gw ip addr add 50.0.0.10/30 dev c3-gw1-tmp
#c3-gw ip addr add 50.0.0.6/30 dev c3-gw2-tmp

c1-gw ip link set c1-gw1-tmp up
#c1-gw ip link set c1-gw2-tmp up
c2-gw ip link set c2-gw1-tmp up
#c2-gw ip link set c2-gw2-tmp up
#c3-gw ip link set c3-gw1-tmp up
#c3-gw ip link set c3-gw2-tmp up

#Create and assigns VPN interfaces

c1-gw wg genkey > private_c1-gw1
#c1-gw wg genkey > private_c1-gw2
c2-gw wg genkey > private_c2-gw1
#c2-gw wg genkey > private_c2-gw2
#c3-gw wg genkey > private_c3-gw1
#c3-gw wg genkey > private_c3-gw2

c1-gw ip link add c1-gw1-wg type wireguard
#c1-gw ip link add c1-gw2-wg type wireguard
c2-gw ip link add c2-gw1-wg type wireguard
#c2-gw ip link add c2-gw2-wg type wireguard
#c3-gw ip link add c3-gw1-wg type wireguard
#c3-gw ip link add c3-gw2-wg type wireguard

c1-gw ip addr add ${LL_C1WG1}/30 dev c1-gw1-wg
#c1-gw ip addr add ${LL_C1WG2}/30 dev c1-gw2-wg
c2-gw ip addr add ${LL_C2WG1}/30 dev c2-gw1-wg
#c2-gw ip addr add ${LL_C2WG2}/30 dev c2-gw2-wg
#c3-gw ip addr add ${LL_C3WG1}/30 dev c3-gw1-wg
#c3-gw ip addr add ${LL_C3WG2}/30 dev c3-gw2-wg

c1-gw wg set c1-gw1-wg private-key ./private_c1-gw1
#c1-gw wg set c1-gw2-wg private-key ./private_c1-gw2
c2-gw wg set c2-gw1-wg private-key ./private_c2-gw1
#c2-gw wg set c2-gw2-wg private-key ./private_c2-gw2
#c3-gw wg set c3-gw1-wg private-key ./private_c3-gw1
#c3-gw wg set c3-gw2-wg private-key ./private_c3-gw2

c1-gw ip link set c1-gw1-wg up
#c1-gw ip link set c1-gw2-wg up
c2-gw ip link set c2-gw1-wg up
#c2-gw ip link set c2-gw2-wg up
#c3-gw ip link set c3-gw1-wg up
#c3-gw ip link set c3-gw2-wg up

c1-gw cat ./private_c2-gw1 | wg pubkey > public_c2-gw1
#c1-gw cat ./private_c3-gw2 | wg pubkey > public_c3-gw2
c2-gw cat ./private_c1-gw1 | wg pubkey > public_c1-gw1
#c2-gw cat ./private_c3-gw1 | wg pubkey > public_c3-gw1
#c3-gw cat ./private_c2-gw2 | wg pubkey > public_c2-gw2
#c3-gw cat ./private_c1-gw2 | wg pubkey > public_c1-gw2

c1-gw wg show c1-gw1-wg listen-port > port_c1-gw1
#c1-gw wg show c1-gw2-wg listen-port > port_c1-gw2
c2-gw wg show c2-gw1-wg listen-port > port_c2-gw1
#c2-gw wg show c2-gw2-wg listen-port > port_c2-gw2
#c3-gw wg show c3-gw1-wg listen-port > port_c3-gw1
#c3-gw wg show c3-gw2-wg listen-port > port_c3-gw2

c1-gw wg set c1-gw1-wg peer $(cat public_c2-gw1) allowed-ips 0.0.0.0/0 endpoint 50.0.0.2:$(cat port_c2-gw1)
#c1-gw wg set c1-gw2-wg peer $(cat public_c3-gw2) allowed-ips 0.0.0.0/0 endpoint 50.0.0.6:$(cat port_c3-gw2)
c2-gw wg set c2-gw1-wg peer $(cat public_c1-gw1) allowed-ips 0.0.0.0/0 endpoint 50.0.0.1:$(cat port_c1-gw1)
#c2-gw wg set c2-gw2-wg peer $(cat public_c3-gw1) allowed-ips 0.0.0.0/0 endpoint 50.0.0.10:$(cat port_c3-gw1)
#c3-gw wg set c3-gw1-wg peer $(cat public_c2-gw2) allowed-ips 0.0.0.0/0 endpoint 50.0.0.9:$(cat port_c2-gw2)
#c3-gw wg set c3-gw2-wg peer $(cat public_c1-gw2) allowed-ips 0.0.0.0/0 endpoint 50.0.0.5:$(cat port_c1-gw2)

# Setup Pod routing

c1-pod ip route add default via "${C1_PODIP_GW}" dev c1-p-pod
c2-pod ip route add default via "${C2_PODIP_GW}" dev c2-p-pod
#c3-pod ip route add default via "${C3_PODIP_GW}" dev c3-p-pod

# Setup Host routing

c1-host ip route add "${GW1_NATCIDR_POOL}" via "${LL_GW}" dev c1-h-eth
#c1-host ip route add "${GW2_NATCIDR_POOL}" via "${LL_GW}" dev c1-h-eth
c2-host ip route add "${GW1_NATCIDR_POOL}" via "${LL_GW}" dev c2-h-eth
#c2-host ip route add "${GW2_NATCIDR_POOL}" via "${LL_GW}" dev c2-h-eth
#c3-host ip route add "${GW1_NATCIDR_POOL}" via "${LL_GW}" dev c3-h-eth
#c3-host ip route add "${GW2_NATCIDR_POOL}" via "${LL_GW}" dev c3-h-eth

# Setup liqo-gateway routing

#echo 200 liqo-out >> /etc/iproute2/rt_tables
#echo 201 liqo-in >> /etc/iproute2/rt_tables

c1-gw ip rule add fwmark 21 lookup liqo-out-1
c1-gw ip route add default via ${LL_C2WG1} dev c1-gw1-wg table liqo-out-1
#c1-gw ip rule add iif c1-gw1-wg lookup liqo-in-1
#c1-gw ip route add default via ${LL_HOST} dev c1-gw-eth table liqo-in-1

#c1-gw ip rule add iif c1-gw-eth fwmark 22 lookup liqo-out-2
#c1-gw ip route add default via ${LL_C3WG2} dev c1-gw2-wg table liqo-out-2
#c1-gw ip rule add iif c1-gw2-wg lookup liqo-in-2
#c1-gw ip route add default via ${LL_HOST} dev c1-gw-eth table liqo-in-2

c2-gw ip rule add iif c2-gw-eth fwmark 21 lookup liqo-out-1
c2-gw ip route add default via ${LL_C1WG1} dev c2-gw1-wg table liqo-out-1
c2-gw ip rule add iif c2-gw1-wg lookup liqo-in-1
c2-gw ip route add default via ${LL_HOST} dev c2-gw-eth table liqo-in-1

#c2-gw ip rule add iif c2-gw-eth fwmark 22 lookup liqo-out-2
#c2-gw ip route add default via ${LL_C3WG1} dev c2-gw2-wg table liqo-out-2
#c2-gw ip rule add iif c2-gw2-wg lookup liqo-in-2
#c2-gw ip route add default via ${LL_HOST} dev c2-gw-eth table liqo-in-2

#c3-gw ip rule add iif c3-gw-eth fwmark 21 lookup liqo-out-1
#c3-gw ip route add default via ${LL_C2WG2} dev c3-gw1-wg table liqo-out-1
#c3-gw ip rule add iif c3-gw1-wg lookup liqo-in-1
#c3-gw ip route add default via ${LL_HOST} dev c3-gw-eth table liqo-in-1

#c3-gw ip rule add iif c3-gw-eth fwmark 22 lookup liqo-out-2
#c3-gw ip route add default via ${LL_C1WG2} dev c3-gw2-wg table liqo-out-2
#c3-gw ip rule add iif c3-gw2-wg lookup liqo-in-2
#c3-gw ip route add default via ${LL_HOST} dev c3-gw-eth table liqo-in-2

c1-host iptables -A FORWARD -i any -j ACCEPT
c1-host iptables -A FORWARD -o any -j ACCEPT
c2-host iptables -A FORWARD -i any -j ACCEPT
c2-host iptables -A FORWARD -o any -j ACCEPT
c3-host iptables -A FORWARD -i any -j ACCEPT
c3-host iptables -A FORWARD -o any -j ACCEPT
c1-gw iptables -A FORWARD -i any -j ACCEPT
c1-gw iptables -A FORWARD -o any -j ACCEPT
c2-gw iptables -A FORWARD -i any -j ACCEPT
c2-gw iptables -A FORWARD -o any -j ACCEPT
c3-gw iptables -A FORWARD -i any -j ACCEPT
c3-gw iptables -A FORWARD -o any -j ACCEPT

# Setup liqo-gateway natting

c1-gw iptables -t mangle -A PREROUTING -d "${GW1_NATCIDR_POOL}" -j MARK --set-mark 21
#c1-gw iptables -t mangle -A PREROUTING -d "${GW2_NATCIDR_POOL}" -j MARK --set-mark 22
c2-gw iptables -t mangle -A PREROUTING -d "${GW1_NATCIDR_POOL}" -j MARK --set-mark 21
#c2-gw iptables -t mangle -A PREROUTING -d "${GW2_NATCIDR_POOL}" -j MARK --set-mark 22
#c3-gw iptables -t mangle -A PREROUTING -d "${GW1_NATCIDR_POOL}" -j MARK --set-mark 21
#c3-gw iptables -t mangle -A PREROUTING -d "${GW2_NATCIDR_POOL}" -j MARK --set-mark 22

#TODO agggiungo interfacce in uscita
c1-gw iptables -t nat -A PREROUTING -d "${GW1_NATCIDR_POOL}" -j NETMAP --to "${C2_PODCIDR}"
#c1-gw iptables -t nat -A PREROUTING -d "${GW2_NATCIDR_POOL}" -j NETMAP --to "${C3_PODCIDR}"
c2-gw iptables -t nat -A PREROUTING -d "${GW1_NATCIDR_POOL}" -j NETMAP --to "${C1_PODCIDR}"
#c2-gw iptables -t nat -A PREROUTING -d "${GW2_NATCIDR_POOL}" -j NETMAP --to "${C3_PODCIDR}"
#c3-gw iptables -t nat -A PREROUTING -d "${GW1_NATCIDR_POOL}" -j NETMAP --to "${C2_PODCIDR}"
#c3-gw iptables -t nat -A PREROUTING -d "${GW2_NATCIDR_POOL}" -j NETMAP --to "${C1_PODCIDR}"

#TODO agggiungo interfacce in ingresso
c1-gw iptables -t nat -A POSTROUTING -o c1-gw1-eth -j NETMAP --to "${GW1_NATCIDR_POOL}"
#c1-gw iptables -t nat -A POSTROUTING -o c1-gw2-eth -j NETMAP --to "${GW2_NATCIDR_POOL}"
c2-gw iptables -t nat -A POSTROUTING -o c2-gw1-eth -j NETMAP --to "${GW1_NATCIDR_POOL}"
#c2-gw iptables -t nat -A POSTROUTING -o c2-gw2-eth -j NETMAP --to "${GW2_NATCIDR_POOL}"
#c3-gw iptables -t nat -A POSTROUTING -o c3-gw1-eth -j NETMAP --to "${GW1_NATCIDR_POOL}"
#c3-gw iptables -t nat -A POSTROUTING -o c3-gw2-eth -j NETMAP --to "${GW2_NATCIDR_POOL}"

umask 002


