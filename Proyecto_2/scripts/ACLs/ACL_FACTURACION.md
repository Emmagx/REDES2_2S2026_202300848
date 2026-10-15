# ACL: `FAC_IN` — Facturación

> **ISP 2 — AndinaCom** · Departamento **Facturación** (`172.16.28.64/26`, VIP HSRP `172.16.28.65`)
> Equipos: `RN-R3` **y** `RN-R4` · Interfaz: **`g0/2`** · Sentido: **`in`**

## Reglas que aplica

| Regla del enunciado | Resultado |
| :--- | :--- |
| Facturación ↔ Ventas (ICMP, TCP/80) | ✅ Exitoso |
| Facturación → Atención al Cliente | 🚫 Bloqueado |
| Cualquier depto → Seguridad | 🚫 Bloqueado |

## Configuración corregida

```text
enable
configure terminal
no ip access-list extended FAC_IN
ip access-list extended FAC_IN
 permit ospf any any
 permit udp any any eq 1985
 permit udp any any eq 2029
 permit udp any any eq bootpc
 permit udp any any eq bootps
 permit ip any 192.168.48.48 0.0.0.3
 permit tcp any any established
 permit icmp any any echo-reply
 permit ip any 172.16.28.0 0.0.0.63
 permit ip any 172.16.32.0 0.0.0.63
 permit ip any 172.16.18.0 0.0.0.127
 deny ip any any
 exit
interface g0/2
 ip access-group FAC_IN in
 exit
exit
write memory
```

## Línea por línea

| Línea | Qué hace |
| :--- | :--- |
| `ospf` + `1985` + `2029` | Plano de control OSPF y HSRP |
| `bootpc` / `bootps` | DHCP relayado al servidor central |
| `ip any 192.168.48.48 0.0.0.3` | **Servidor DNS/HTTP/HTTPS** completo: DNS, HTTP, HTTPS **e ICMP** |
| `tcp any any established` + `icmp echo-reply` | Retorno de sesiones iniciadas desde fuera |
| `ip any 172.16.28.0 0.0.0.63` | Facturación ↔ **Ventas** |
| `ip any 172.16.32.0 0.0.0.63` | Facturación ↔ **Soporte** |
| `ip any 172.16.18.0 0.0.0.127` | Facturación ↔ **Administración** (wildcard corregido) |
| `deny ip any any` | **Atención al Cliente y Seguridad quedan bloqueados** ⚠️ |

> ⚠️ **No agregues `permit ip any 172.16.18.128 0.0.0.127` (ATC) ni `172.16.32.64/26` (Seguridad)
> a esta ACL.** La tabla del enunciado exige que **Facturación → Atención al Cliente esté bloqueado**;
> agregar ese permiso rompería la regla y costaría puntos en la rúbrica 2.5.

## Aplicación en los DOS routers HSRP

```text
! RN-R3 y RN-R4
interface g0/2
 ip access-group FAC_IN in
 exit
```

La ACL se replica en ambos routers para que la política sobreviva a la conmutación de HSRP: el
*gateway* activo puede cambiar tras un fallo y, si la ACL estuviera en un solo equipo, la red quedaría
sin filtrado.

## Verificación

```text
show ip access-lists FAC_IN
show standby brief
```
