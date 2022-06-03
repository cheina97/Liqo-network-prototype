#!/usr/bin/env bash

#sudo echo "200 liqo-in" >>/etc/iproute2/rt_tables
#sudo echo "201 liqo-out" >>/etc/iproute2/rt_tables

sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1
sudo sysctl -w net.ipv6.conf.default.disable_ipv6=1
sudo sysctl -w net.ipv6.conf.lo.disable_ipv6=1
sudo sysctl -w net.ipv4.ip_forward=1
sudo sysctl -w net.ipv4.conf.all.forwarding=1
sudo sysctl -w net.ipv4.conf.all.accept_redirects=0
sudo sysctl -p