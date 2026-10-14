# Script: RN-R2

> **ISP 2 — AndinaCom** · AS 200 · OSPF área 0 · Capa de **distribución** del modelo jerárquico.

```text
enable
configure terminal
hostname RN-R2
interface g0/0
 description Link to RN-R1
 ip address 172.16.28.134 255.255.255.252
 no shutdown
 exit
interface g0/1
 description Link to RN-R3
 ip address 172.16.28.141 255.255.255.252
 no shutdown
 exit
interface g0/2
 description Link to RN-R4
 ip address 172.16.28.145 255.255.255.252
 no shutdown
 exit
router ospf 1
 network 172.16.28.132 0.0.0.3 area 0
 network 172.16.28.140 0.0.0.3 area 0
 network 172.16.28.144 0.0.0.3 area 0
 exit
```
