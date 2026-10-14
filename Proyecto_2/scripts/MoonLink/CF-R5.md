# Script: CF-R5

> **ISP 3 — MoonLink** · AS 300 · EIGRP AS 10 · Router 5 (cumple el mínimo de 5 routers).
> La topología hub-and-spoke se apoya en los routers inalámbricos (WRT300N) en modo
> bridge/AP para dar servicio Wi-Fi a Soporte.

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
 no auto-summary
 network 172.16.32.128 0.0.0.31
 network 172.16.32.202 0.0.0.0
 exit
```
