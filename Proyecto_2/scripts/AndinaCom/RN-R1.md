# Script: RN-R1

> **ISP 2 — AndinaCom** · AS 200 · OSPF área 0 · Router núcleo del modelo jerárquico.
> AndinaCom es el ISP que provee **DHCP a toda la topología** (servidor en `172.16.28.130`,
> redistribuido a los otros ISPs mediante `ip helper-address` y BGP).

```text
enable
configure terminal
hostname RN-R1
interface g0/0
 description Link to BGP Multilayer Switch
 ip address 172.16.28.254 255.255.255.252
 no shutdown
 exit
interface g0/1
 description Link to RN-R2
 ip address 172.16.28.133 255.255.255.252
 no shutdown
 exit
interface g0/2
 description Link to RN-R5 (Servicios DHCP)
 ip address 172.16.28.137 255.255.255.252
 no shutdown
 exit
router ospf 1
 network 172.16.28.132 0.0.0.3 area 0
 network 172.16.28.136 0.0.0.3 area 0
 network 172.16.28.252 0.0.0.3 area 0
 exit
```
