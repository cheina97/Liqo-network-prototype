#!/usr/bin/env bash

shopt -s expand_aliases
source ./aliases.sh

#Define pods ips
C1_PODIP="20.0.10.1"
C2_PODIP="21.0.20.1"
C3_PODIP="22.0.30.1"

c1-gw1 wg
c1-gw2 wg
c2-gw1 wg
c2-gw2 wg
c3-gw1 wg
c3-gw2 wg
echo

#c1-gw1 ping -c 1 10.0.0.2|tail -n 3| head -n 2
#echo
#c1-gw2 ping -c 1 10.0.0.2|tail -n 3| head -n 2
#echo
#c2-gw1 ping -c 1 10.0.0.1|tail -n 3| head -n 2
#echo
#c2-gw2 ping -c 1 10.0.0.2|tail -n 3| head -n 2
#echo
#c3-gw1 ping -c 1 10.0.0.1|tail -n 3| head -n 2
#echo
#c3-gw2 ping -c 1 10.0.0.1|tail -n 3| head -n 2
#echo
#
c1-host ping -c 1 30.1.0.1|tail -n 3| head -n 2
echo
c1-host ping -c 1 30.2.0.1|tail -n 3| head -n 2
echo
c2-host ping -c 1 30.2.0.1|tail -n 3| head -n 2
echo
c2-host ping -c 1 30.1.0.1|tail -n 3| head -n 2
echo
c3-host ping -c 1 30.2.0.1|tail -n 3| head -n 2
echo
c3-host ping -c 1 30.1.0.1|tail -n 3| head -n 2
echo

c1-host hping3 --spoof "${C1_PODIP}" --icmp -c 1 30.1.0.1
echo
c1-host hping3 --spoof "${C1_PODIP}" --icmp -c 1 30.2.0.1
echo
c2-host hping3 --spoof "${C2_PODIP}" --icmp -c 1 30.1.0.1
echo
c2-host hping3 --spoof "${C2_PODIP}" --icmp -c 1 30.2.0.1
echo
c3-host hping3 --spoof "${C3_PODIP}" --icmp -c 1 30.1.0.1
echo
c3-host hping3 --spoof "${C3_PODIP}" --icmp -c 1 30.2.0.1


echo "c1-host arp table"
c1-host arp
echo
echo "c2-host arp table"
c2-host arp
echo
echo "c3-host arp table"
c3-host arp
echo
echo "c1-gw1 arp table"
c1-gw1 arp
echo
echo "c1-gw2 arp table"
c1-gw2 arp
echo
echo "c2-gw1 arp table"
c2-gw1 arp
echo
echo "c2-gw2 arp table"
c2-gw2 arp
echo
echo "c3-gw1 arp table"
c3-gw1 arp
echo
echo "c3-gw2 arp table"
c3-gw2 arp
echo
