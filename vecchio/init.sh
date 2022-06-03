#!/usr/bin/env bash

shopt -s expand_aliases
source ./aliases.sh

sudo ip netns add pod1
sudo ip netns add pod2
sudo ip netns add gw1
sudo ip netns add gw2

sudo ip link add pod1-eth type veth peer name gw1-eth
sudo ip link add pod2-eth type veth peer name gw2-eth
sudo ip link add wg1-eth type veth peer name wg2-eth

sudo ip link set pod1-eth netns pod1
sudo ip link set pod2-eth netns pod2
sudo ip link set gw1-eth netns gw1
sudo ip link set gw2-eth netns gw2
sudo ip link set wg1-eth netns gw1
sudo ip link set wg2-eth netns gw2
#Connect pod1 and gw1


pod1 ip addr add 40.0.0.1/24 dev pod1-eth
pod1 ip link set pod1-eth up

gw1 ip addr add 40.0.0.2/24 dev gw1-eth
gw1 ip link set gw1-eth up

#Connect pod2 and gw2

pod2 ip addr add 40.0.0.1/24 dev pod2-eth
pod2 ip link set pod2-eth up

gw2 ip addr add 40.0.0.2/24 dev gw2-eth
gw2 ip link set gw2-eth up

#Connect gw1 and gw2 (VPN)
gw1 wg genkey > private1
gw2 wg genkey > private2

gw1 ip link add wg-1to2 type wireguard
gw2 ip link add wg-2to1 type wireguard

gw1 ip addr add 10.0.0.1/24 dev wg-1to2
gw2 ip addr add 10.0.0.2/24 dev wg-2to1

gw1 wg set wg-1to2 private-key ./private1
gw2 wg set wg-2to1 private-key ./private2

gw1 ip link set wg-1to2 up
gw2 ip link set wg-2to1 up

gw1 cat private1 | wg pubkey > public1
gw2 cat private2 | wg pubkey > public2

gw1 wg show wg-1to2 listen-port > port1
gw2 wg show wg-2to1 listen-port > port2

gw1 ip addr add 50.0.0.1/24 dev wg1-eth
gw1 ip link set wg1-eth up

gw2 ip addr add 50.0.0.2/24 dev wg2-eth
gw2 ip link set wg2-eth up

gw1 wg set wg-1to2 peer $(cat public2) allowed-ips 0.0.0.0/0 endpoint 50.0.0.2:$(cat port2)
gw2 wg set wg-2to1 peer $(cat public1) allowed-ips 0.0.0.0/0 endpoint 50.0.0.1:$(cat port1)

#Setup routes
pod1 ip route add 0.0.0.0/0 via 40.0.0.2
pod2 ip route add 0.0.0.0/0 via 40.0.0.2
gw1 ip route add 0.0.0.0/0 via 10.0.0.2

#echo 200 liqo-out >> /etc/iproute2/rt_tables
#echo 201 liqo-in >> /etc/iproute2/rt_tables

#gw1 ip rule add iif wg-1to2 lookup liqo-in
#gw1 ip rule add iif gw1-eth lookup liqo-out
#gw1 ip route add default via 10.0.0.2 table liqo-out
#gw1 ip route add default via 40.0.0.2 table liqo-in

#gw2 ip rule add iif wg-2to1 lookup liqo-in 
#gw2 ip rule add iif gw2-eth lookup liqo-out
#gw2 ip route add default via 10.0.0.1 table liqo-out
#gw2 ip route add default via 40.0.0.2 table liqo-in

##gw1 ip rule add iif wg-1to2 lookup liqo-in
##gw1 ip rule add iif gw1-eth fwmark 22 lookup liqo-out
##gw1 ip rule add iif wg-1to2 fwmark 23 lookup liqo-in
##gw1 ip route add default via 10.0.0.2 table liqo-out
##gw1 ip route add default via 40.0.0.2 table liqo-in

##gw2 ip rule add iif wg-2to1 lookup liqo-in 
##gw2 ip rule add iif gw2-eth fwmark 22 lookup liqo-out
##gw2 ip rule add iif gw2-eth fwmark 23 lookup liqo-out
##gw2 ip route add default via 10.0.0.1 table liqo-out
##gw2 ip route add default via 40.0.0.2 table liqo-in

gw1 iptables -A FORWARD -i any -j ACCEPT
gw1 iptables -A FORWARD -o any -j ACCEPT
gw2 iptables -A FORWARD -i any -j ACCEPT
gw2 iptables -A FORWARD -o any -j ACCEPT

##gw1 iptables -t mangle -A PREROUTING -d 30.0.0.1 -j MARK --set-mark 22
##gw2 iptables -t mangle -A PREROUTING -d 30.0.0.1 -j MARK --set-mark 22
##gw2 iptables -t mangle -A PREROUTING -d 60.0.0.1 -j MARK --set-mark 23
##gw1 iptables -t mangle -A PREROUTING -d 60.0.0.1 -j MARK --set-mark 23

#setup natting
gw1 iptables -t nat -A PREROUTING -d 30.0.0.1 -j DNAT --to-destination 40.0.0.1
gw2 iptables -t nat -A POSTROUTING -o gw2-eth -j SNAT --to-source 60.0.0.1
gw2 iptables -t nat -A PREROUTING -d 30.0.0.1 -j DNAT --to-destination 40.0.0.1
gw1 iptables -t nat -A POSTROUTING -o gw1-eth -j SNAT --to-source 60.0.0.1

