# Script: CF-R2

> **ISP 3 — MoonLink** · AS 300 · EIGRP AS 10 · Router de **Soporte** (subred `/26` = 62 hosts ≥ 45 requeridos).
> Soporte habla con todos los departamentos (ICMP, HTTP y HTTPS) **excepto con Seguridad**,
> porque la regla "ningún departamento entra a Seguridad" tiene prioridad.

```text
enable
configure terminal
hostname CF-R2
interface g0/0
 description Link to SW-WAN
 ip address 172.16.32.130 255.255.255.224
 no shutdown
 exit
interface g0/1
 description LAN Soporte
 ip address 172.16.32.1 255.255.255.192
 ip helper-address 172.16.28.130
 no shutdown
 exit
router eigrp 10
 no auto-summary
 network 172.16.32.128 0.0.0.31
 network 172.16.32.0 0.0.0.63
 exit
```

## ACL aplicada en este router

```text
! ACL_SOPORTE_IN -> aplicada en g0/1 in (ver scripts/ACLs/ACL_SOPORTE.md)
interface g0/1
 ip access-group ACL_SOPORTE_IN in
 exit
```
