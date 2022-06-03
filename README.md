# Liqo-network-prototype

In questo file vado a riassumere le 2 principali soluzioni ideate con relativi vantaggi e svantaggi.In entrambi gli esempi viene considerato solo il caso in ci il traffico debba andare da un cluster 1 a un cluster 2 (da destra a sinistra) in cui vi sia overlapping delle pod CIDR. 
**Entrambe le soluzioni sono state testate utilizzando 2 network namespace per simulare i pod e altrri 2 per simulare i gateway.** 
**Entrambe le soluzioni presentano problemi nell’implementazione (spiegati di sotto) che non sono ancora riuscito a risolvere.**

## DNAT su cluster1 e SNAT su cluster2

![](/home/cheina/Documents/liqo/network/netns/img/dnatOnGateway1AndSnatOnGateway2.png)

Cosa deve sapere il cluster1 del cluster 2:

- Deve conoscere la pod CIDR originale del cluster 2 per convertire l’indirizzo destinazione rimappato in un indirizzo destinazione valido nel cluster 2

Cosa deve sapere il cluster 2 del cluster 1:

- Nulla

### Problemi nell’implementazione

Iptables permette di fare DNAT solo in prerouting. 
Di seguito elenco le operazioni fatte sul pacchetto in modo da rendere più chiaro il problema:

1. Viene generato da POD1 un pacchetto con destinazione 30.0.0.1 e inoltrato a GATEWAY1
2. GATEWAY1 riceve il pacchetto e applica la regola di DNAT, la destinazione del pacchetto diventa 40.0.0.1
3. Viene fatta la scelta di routing per decidere su dove inoltrare il pacchetto che avendo indirizzo destinazione 40.0.0.1 tornerà indietro

### Possibile soluzione

Se riuscissi a fare DNAT dopo la scelta di routing risolverei il problema. Attualmente non ho idea di come risolvere il problema se non con un programma in ebpf (soluzione che mi è stata consigliata da terzi) che faccia il natting di cui ho bisogno.

## DNAT e SNAT su cluster2

![](/home/cheina/Documents/liqo/network/netns/img/dnatOnGateway1AndSnatOnGateway2.png)

Cosa deve sapere il cluster 1 del cluster 2:

- Nulla, basta inoltrare tutto il traffico per il cluster 2 sulla VPN

Cosa deve sapere il cluster 2 del cluster 1:

- Deve conoscere come il cluster 1 ha rimappato la pod CIDR del cluster 2 per poter settare le regole di DNAT



### Problemi nell’implementazione

Pod1 riesce ad inviare i pacchetti a pod2, il problema è la risposta. 

Quando Pod2 invia il pacchetto di risposta passerà per prima cosa attraverso il DNAT che darà come ip destinazione al pacchetto 40.0.0.1, solo in seguito avverrà la scelta di routing e di conseguenza il pacchetto verrà reinviato all’interfaccia **gw2-eth**.

![](/home/cheina/Documents/liqo/network/netns/img/tcpdump1.png)

![](/home/cheina/Documents/liqo/network/netns/img/tcpdump2.png)

## Script

Di seguito ho inserito gli script usati per inizializzare e pulire i network namespaces usati:

```bash
#!/usr/bin/env bash
#Initialize network namespaces and the related interfaces. It also applies routes and NAT rules.

shopt -s expand_aliases
source ./aliases.sh

sudo ip netns add pod1
sudo ip netns add pod2
sudo ip netns add gw1
sudo ip netns add gw2
sudo ip link add pod1-eth type veth peer name gw1-eth
sudo ip link add pod2-eth type veth peer name gw2-eth
sudo ip link add wg1-eth type veth peer name wg2-eth

sudo ip link set pod1-eth netns pod1
sudo ip link set pod2-eth netns pod2
sudo ip link set gw1-eth netns gw1
sudo ip link set gw2-eth netns gw2
sudo ip link set wg1-eth netns gw1
sudo ip link set wg2-eth netns gw2
#Connect pod1 and gw1


pod1 ip addr add 40.0.0.1/24 dev pod1-eth
pod1 ip link set pod1-eth up

gw1 ip addr add 40.0.0.2/24 dev gw1-eth
gw1 ip link set gw1-eth up

#Connect pod2 and gw2

pod2 ip addr add 40.0.0.1/24 dev pod2-eth
pod2 ip link set pod2-eth up

gw2 ip addr add 40.0.0.2/24 dev gw2-eth
gw2 ip link set gw2-eth up

#Connect gw1 and gw2 (VPN)
gw1 wg genkey > private1
gw2 wg genkey > private2

gw1 ip link add wg-1to2 type wireguard
gw2 ip link add wg-2to1 type wireguard

gw1 ip addr add 10.0.0.1/24 dev wg-1to2
gw2 ip addr add 10.0.0.2/24 dev wg-2to1

gw1 wg set wg-1to2 private-key ./private1
gw2 wg set wg-2to1 private-key ./private2

gw1 ip link set wg-1to2 up
gw2 ip link set wg-2to1 up

gw1 cat private1 | wg pubkey > public1
gw2 cat private2 | wg pubkey > public2

gw1 wg show wg-1to2 listen-port > port1
gw2 wg show wg-2to1 listen-port > port2

gw1 ip addr add 50.0.0.1/24 dev wg1-eth
gw1 ip link set wg1-eth up

gw2 ip addr add 50.0.0.2/24 dev wg2-eth
gw2 ip link set wg2-eth up

gw1 wg set wg-1to2 peer $(cat public2) allowed-ips 0.0.0.0/0 endpoint 50.0.0.2:$(cat port2)
gw2 wg set wg-2to1 peer $(cat public1) allowed-ips 0.0.0.0/0 endpoint 50.0.0.1:$(cat port1)

#Setup routes
pod1 ip route add 0.0.0.0/0 via 40.0.0.2
pod2 ip route add 0.0.0.0/0 via 40.0.0.2
gw1 ip route add 0.0.0.0/0 via 10.0.0.2
gw1 ip route add 30.0.0.0/24 via 10.0.0.2

gw1 iptables -A FORWARD -i any -j ACCEPT
gw1 iptables -A FORWARD -o any -j ACCEPT
gw2 iptables -A FORWARD -i any -j ACCEPT
gw2 iptables -A FORWARD -o any -j ACCEPT

#setup natting
gw2 iptables -t nat -A PREROUTING -p icmp -d 30.0.0.1 -j DNAT --to-destination 40.0.0.1
gw2 iptables -t nat -A POSTROUTING -o gw2-eth -j SNAT --to-source 60.0.0.1

```

```bash
#!/usr/bin/env bash
# Cleans the environment deleting network namespaces

sudo ip netns delete pod1
sudo ip netns delete pod2
sudo ip netns delete gw1
sudo ip netns delete gw2
```
