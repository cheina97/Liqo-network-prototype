#!/usr/bin/env bash

#echo GW1 PEERING INFO
#GW1_PUBKEY="$(cat public_gw1)"
#echo "PUBKEY: ${GW1_PUBKEY}"
#GW1_PORT="$(cat port_gw1)"
#echo "PORT: ${GW1_PORT}"
#echo
#
#echo GW2 PEERING INFO
#GW2_PUBKEY="$(cat public_gw2)"
#echo "PUBKEY: ${GW2_PUBKEY}"
#GW2_PORT="$(cat port_gw2)"
#echo "PORT: ${GW2_PORT}"
#echo
#
#ENDPOINT="$(ip addr show dev enp1s0|grep "inet "|tr -s " "| cut -d " " -f 3|cut -d "/" -f 1)"
#echo "EXPOSED ENDPOINT: ${ENDPOINT}"
#echo

echo "PEERING COMMANDS"
echo "GW1: wg set INTERFACE peer ${GW1_PUBKEY} allowed-ips 0.0.0.0/0 endpoint ${ENDPOINT}:${GW1_PORT}"
echo "GW2: wg set INTERFACE peer ${GW2_PUBKEY} allowed-ips 0.0.0.0/0 endpoint ${ENDPOINT}:${GW2_PORT}"



