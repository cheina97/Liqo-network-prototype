#!/usr/bin/env bash

sudo ip link delete h1-eth
sudo ip link delete h2-eth
sudo ip link delete h-pod

sudo ip netns delete gw1
sudo ip netns delete gw2
sudo ip netns delete pod
