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

## ACL

**Sin ACL (decisión de diseño).** La regla de Soporte es *"habla y escucha a todos los departamentos"*,
así que su interfaz LAN se deja libre. La restricción "nadie entra a Seguridad" (que también aplica a
Soporte) se resuelve en el destino con `SEC_OUT` en `CF-R3`. Ver
[`../ACLs/ACL_SOPORTE.md`](../ACLs/ACL_SOPORTE.md).
