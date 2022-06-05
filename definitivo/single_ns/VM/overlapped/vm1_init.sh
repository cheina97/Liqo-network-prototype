#!/usr/bin/env bash

MY_PODIP="20.0.0.1"
MY_PODIP_GW="20.0.0.254"
GW1_PODCIDR="20.0.0.0/16"
GW2_PODCIDR="20.0.0.0/16"
GW1_NATCIDR_POOL="30.1.0.0/16"
GW2_NATCIDR_POOL="30.2.0.0/16"
LL_WG1_LOCAL="169.254.2.1"
LL_WG2_LOCAL="169.254.2.2"
LL_WG1_REMOTE="169.254.2.2"
LL_WG2_REMOTE="169.254.2.1"

./init.sh $MY_PODIP $MY_PODIP_GW $GW1_PODCIDR $GW2_PODCIDR $GW1_NATCIDR_POOL $GW2_NATCIDR_POOL $LL_WG1_LOCAL $LL_WG2_LOCAL $LL_WG1_REMOTE $LL_WG2_REMOTE
