#!/usr/bin/env bash

#!/usr/bin/env bash

export DISPLAY=":1.0"

sudo killall -9 gnome-terminal-server

sudo gnome-terminal --hide-menubar --geometry 960x540+0+0 --title "pod" -e "sudo ip netns exec pod tcpdump -t -n -l -i any -e -vvv icmp"
sudo gnome-terminal --hide-menubar --geometry 960x540+960+0 --title "host" -e "tcpdump -t -n -l -i any -e -vvv icmp"
sudo gnome-terminal --hide-menubar --geometry 960x540+0+540 --title "gateway" -e "sudo ip netns exec gw tcpdump -t -n -l -i any -e -vvv icmp"

#sudo gnome-terminal --hide-menubar --geometry 960x540+0+0 --title "pod" -e "tcpdump -t -n -l -i any not ip6 -e "
#sudo gnome-terminal --hide-menubar --geometry 960x540+960+0 --title "host" -e "tcpdump -t -n -l -i any not ip6 -e "
#sudo gnome-terminal --hide-menubar --geometry 960x540+0+540 --title "gateway 1" -e "sudo ip netns exec gw1 tcpdump -t -n -l -i any not ip6 -e "
#sudo gnome-terminal --hide-menubar --geometry 960x540+960+540 --title "gateway 2" -e "sudo ip netns exec gw2 tcpdump -t -n -l -i any not ip6 -e "
