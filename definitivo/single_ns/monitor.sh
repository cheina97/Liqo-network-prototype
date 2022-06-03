#!/usr/bin/env bash

sudo killall -9 gnome-terminal-server

sudo gnome-terminal --hide-menubar --geometry 960x540+1920+0 --title "cluster 1 - host" -e "sudo ip netns exec c1-host tcpdump -t -n -l -i any -e -vvv not ip6"
sudo gnome-terminal --hide-menubar --geometry 960x540+2880+0 --title "cluster 2 - host" -e "sudo ip netns exec c2-host tcpdump -t -n -l -i any -e -vvv not ip6"
sudo gnome-terminal --hide-menubar --geometry 960x540+200+200 --title "cluster 3 - host" -e "sudo ip netns exec c3-host tcpdump -t -n -l -i any -e -vvv not ip6 "
sudo gnome-terminal --hide-menubar --geometry 960x540+1920+600 --title "cluster 1 - gateway" -e "sudo ip netns exec c1-gw tcpdump -t -n -l -i any -e -vvv not ip6 "
sudo gnome-terminal --hide-menubar --geometry 960x540+2880+600 --title "cluster 2 - gateway" -e "sudo ip netns exec c2-gw tcpdump -t -n -l -i any -e -vvv not ip6 "
sudo gnome-terminal --hide-menubar --geometry 960x540+200+200 --title "cluster 3 - gateway" -e "sudo ip netns exec c3-gw tcpdump -t -n -l -i any -e -vvv not ip6 "

#sudo gnome-terminal --hide-menubar --geometry 640x360+1920+0 --title "cluster 1 - host" -e "sudo ip netns exec c1-host tcpdump -t -n -l -i any arp -e "
#sudo gnome-terminal --hide-menubar --geometry 640x360+2560+0 --title "cluster 1 - gateway" -e "sudo ip netns exec c1-gw tcpdump -t -n -l -i any arp -e "
#sudo gnome-terminal --hide-menubar --geometry 640x360+1920+360 --title "cluster 2 - host" -e "sudo ip netns exec c2-host tcpdump -t -n -l -i any arp -e "
#sudo gnome-terminal --hide-menubar --geometry 640x360+2560+360 --title "cluster 2 - gateway" -e "sudo ip netns exec c2-gw tcpdump -t -n -l -i any arp -e "
#sudo gnome-terminal --hide-menubar --geometry 640x360+1920+720 --title "cluster 3 - host" -e "sudo ip netns exec c3-host tcpdump -t -n -l -i any arp -e "
#sudo gnome-terminal --hide-menubar --geometry 640x360+2560+720 --title "cluster 3 - gateway" -e "sudo ip netns exec c3-gw tcpdump -t -n -l -i any arp -e "