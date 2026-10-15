# Script: CF-R3

> **ISP 3 — MoonLink** · AS 300 · EIGRP AS 10 · Router de **Seguridad** (subred `/26`).
> Seguridad **inicia** tráfico hacia cualquier departamento (ICMP, HTTP, HTTPS);
> **ningún** departamento puede iniciar tráfico hacia Seguridad.

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
 no auto-summary
 network 172.16.32.128 0.0.0.31
 network 172.16.32.64 0.0.0.63
 exit
```

## ACL aplicada en este router

```text
! SEC_OUT -> aplicada en g0/1 OUT (es una ACL de retorno: protege la entrada a Seguridad)
! El bloqueo de "cualquier depto -> Seguridad" se resuelve AQUI, en el destino.
! Ver ../ACLs/ACL_SEGURIDAD.md
interface g0/1
 ip access-group SEC_OUT out
 exit
```
