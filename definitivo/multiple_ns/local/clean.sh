#!/usr/bin/env bash

sudo ip netns delete c1-host
sudo ip netns delete c2-host
sudo ip netns delete c3-host
sudo ip netns delete c1-gw1
sudo ip netns delete c1-gw2
sudo ip netns delete c2-gw1
sudo ip netns delete c2-gw2
sudo ip netns delete c3-gw1
sudo ip netns delete c3-gw2
sudo ip netns delete c1-pod
sudo ip netns delete c2-pod
sudo ip netns delete c3-pod

