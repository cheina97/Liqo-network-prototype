#!/usr/bin/env bash

sudo ip link delete h-eth
sudo ip link delete h-pod

sudo ip netns delete gw
sudo ip netns delete pod
