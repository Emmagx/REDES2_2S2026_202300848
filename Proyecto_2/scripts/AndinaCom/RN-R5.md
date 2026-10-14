# Script: RN-R5

> **ISP 2 — AndinaCom** · AS 200 · OSPF área 0 · Router de **servicios**: concentra el
> servidor DHCP central (`172.16.28.130`) que da direccionamiento a los tres ISPs.

```text
enable
configure terminal
hostname RN-R5
interface g0/0
 description Link to RN-R1
 ip address 172.16.28.138 255.255.255.252
 no shutdown
 exit
interface g0/1
 description Link to Server DHCP
 ip address 172.16.28.129 255.255.255.252
 no shutdown
 exit
router ospf 1
 network 172.16.28.136 0.0.0.3 area 0
 network 172.16.28.128 0.0.0.3 area 0
 exit
```
