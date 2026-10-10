# Script: CF-R3

```text
enable
configure terminal
hostname CF-R3
interface g0/0
 description Link to SW-WAN
 ip address 172.16.32.131 255.255.255.224
 no shutdown
 exit
interface g0/1
 description LAN Seguridad
 ip address 172.16.32.65 255.255.255.192
 ip helper-address 172.16.28.130
 no shutdown
 exit
router eigrp 10
 network 172.16.32.128 0.0.0.31
 network 172.16.32.64 0.0.0.63
 exit
```
