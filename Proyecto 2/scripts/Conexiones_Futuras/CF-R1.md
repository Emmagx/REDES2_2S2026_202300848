# Script: CF-R1

```text
enable
configure terminal
hostname CF-R1
interface g0/0
 description Link to BGP Multilayer Switch
 ip address 172.16.32.254 255.255.255.252
 no shutdown
 exit
interface g0/1
 description Link to SW-WAN (Multipoint)
 ip address 172.16.32.129 255.255.255.224
 no shutdown
 exit
router eigrp 10
 network 172.16.32.128 0.0.0.31
 network 172.16.32.252 0.0.0.3
 exit
```
