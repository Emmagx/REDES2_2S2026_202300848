# Script: CF-R5

```text
enable
configure terminal
hostname CF-R5
interface g0/0
 description Link to SW-WAN
 ip address 172.16.32.133 255.255.255.224
 no shutdown
 exit
interface loopback 0
 ip address 172.16.32.202 255.255.255.255
router eigrp 10
 network 172.16.32.128 0.0.0.31
 network 172.16.32.202 0.0.0.0
 exit
```
