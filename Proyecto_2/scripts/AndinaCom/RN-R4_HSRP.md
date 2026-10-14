# Script: RN-R4_HSRP

> **ISP 2 — AndinaCom** · AS 200 · OSPF área 0 · Router **standby de HSRP** (sin prioridad,
> asume el rol activo cuando RN-R3 falla).

```text
enable
configure terminal
hostname RN-R4
interface g0/0
 description Link to RN-R2
 ip address 172.16.28.146 255.255.255.252
 no shutdown
 exit
! LAN VENTAS
interface g0/1
 ip address 172.16.28.3 255.255.255.192
 ip helper-address 172.16.28.130
 standby 10 ip 172.16.28.1
 standby 10 preempt
 no shutdown
 exit
! LAN FACTURACION
interface g0/2
 ip address 172.16.28.67 255.255.255.192
 ip helper-address 172.16.28.130
 standby 20 ip 172.16.28.65
 standby 20 preempt
 no shutdown
 exit
router ospf 1
 network 172.16.28.144 0.0.0.3 area 0
 network 172.16.28.0 0.0.0.63 area 0
 network 172.16.28.64 0.0.0.63 area 0
 exit
```

## ACLs aplicadas en este router

```text
! ACL_VENTAS_IN -> aplicada en g0/1 in
! ACL_FACTURACION_IN -> aplicada en g0/2 in
! (ver scripts/ACLs/ACL_VENTAS.md y ACL_FACTURACION.md)
interface g0/1
 ip access-group ACL_VENTAS_IN in
 exit
interface g0/2
 ip access-group ACL_FACTURACION_IN in
 exit
```
