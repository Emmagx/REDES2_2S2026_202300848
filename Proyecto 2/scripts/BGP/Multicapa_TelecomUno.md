# Script: Multicapa_TelecomUno

```text
enable
configure terminal
hostname SW-BGP-T1
ip routing

! Puerto hacia Multicapa Redes Nacionales
interface gig1/1/1
 no switchport
 ip address 192.168.48.1 255.255.255.252
 no shutdown
 exit

! Puerto hacia Multicapa Link Global (Conexiones Futuras)
interface gig1/1/2
 no switchport
 ip address 192.168.48.9 255.255.255.252
 no shutdown
 exit

! Puerto hacia tu router interno T1R1
interface gig1/0/1
 no switchport
 ip address 172.16.18.253 255.255.255.252
 no shutdown
 exit

! OSPF para conocer las rutas internas de Telecom Uno
router ospf 1
 network 172.16.18.252 0.0.0.3 area 0
 exit

! BGP
router bgp 100
 bgp router-id 1.1.1.1
 neighbor 192.168.48.2 remote-as 200
 neighbor 192.168.48.10 remote-as 300
 redistribute ospf 1
 exit
```
