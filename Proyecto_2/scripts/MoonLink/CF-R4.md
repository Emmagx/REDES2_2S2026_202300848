# Script: CF-R4

> **ISP 3 — MoonLink** · AS 300 · EIGRP AS 10 · Router spoke de la red WAN multipunto.

```text
enable
configure terminal
hostname CF-R4
interface g0/0
 description Link to SW-WAN
 ip address 172.16.32.132 255.255.255.224
 no shutdown
 exit
interface loopback 0
 ip address 172.16.32.201 255.255.255.255
router eigrp 10
 no auto-summary
 network 172.16.32.128 0.0.0.31
 network 172.16.32.201 0.0.0.0
 exit
```
