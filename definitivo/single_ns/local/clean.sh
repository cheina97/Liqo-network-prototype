#!/usr/bin/env bash

sudo ip netns delete c1-host
sudo ip netns delete c2-host
sudo ip netns delete c3-host
sudo ip netns delete c1-gw
sudo ip netns delete c2-gw
sudo ip netns delete c3-gw
sudo ip netns delete c1-pod
sudo ip netns delete c2-pod
sudo ip netns delete c3-pod

