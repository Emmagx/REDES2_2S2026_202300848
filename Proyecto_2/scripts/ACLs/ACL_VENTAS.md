# ACL: `VENTAS_IN` — Ventas

> **ISP 2 — AndinaCom** · Departamento **Ventas** (`172.16.28.0/26`, VIP HSRP `172.16.28.1`)
> Equipos: `RN-R3` **y** `RN-R4` · Interfaz: **`g0/1`** · Sentido: **`in`**

## Reglas que aplica

| Regla del enunciado | Resultado |
| :--- | :--- |
| Ventas → Facturación y Atención al Cliente (ICMP, TCP/80) | ✅ Exitoso |
| Cualquier depto → Seguridad | 🚫 Bloqueado |

## Configuración corregida

```text
enable
configure terminal
no ip access-list extended VENTAS_IN
ip access-list extended VENTAS_IN
 permit ospf any any
 permit udp any any eq 1985
 permit udp any any eq 2029
 permit udp any any eq bootpc
 permit udp any any eq bootps
 permit ip any 192.168.48.48 0.0.0.3
 permit tcp any any established
 permit icmp any any echo-reply
 permit ip any 172.16.28.64 0.0.0.63
 permit ip any 172.16.18.128 0.0.0.127
 permit ip any 172.16.32.0 0.0.0.63
 permit ip any 172.16.18.0 0.0.0.127
 deny ip any any
 exit
interface g0/1
 ip access-group VENTAS_IN in
 exit
exit
write memory
```

## Línea por línea

| Línea | Qué hace |
| :--- | :--- |
| `ospf` + `1985` + `2029` | Plano de control OSPF y HSRP (grupos 10 y 20) |
| `bootpc` / `bootps` | DHCP relayado al servidor central |
| `ip any 192.168.48.48 0.0.0.3` | **Servidor DNS/HTTP/HTTPS** completo: DNS, HTTP, HTTPS **e ICMP** |
| `tcp any any established` + `icmp echo-reply` | Retorno de sesiones iniciadas desde fuera |
| `ip any 172.16.28.64 0.0.0.63` | Ventas ↔ **Facturación** |
| `ip any 172.16.18.128 0.0.0.127` | Ventas ↔ **Atención al Cliente** ⚠️ **línea corregida** |
| `ip any 172.16.32.0 0.0.0.63` | Ventas ↔ **Soporte** |
| `ip any 172.16.18.0 0.0.0.127` | Ventas ↔ **Administración** (wildcard corregido) |
| `deny ip any any` | **Seguridad queda bloqueada** |

> ⚠️ **Corrección importante:** la línea original era
> `permit ip any 172.16.18.64 0.0.0.63`, que correspondía a la subred **vieja** de Atención al
> Cliente (`/26`). Con el rediseño de FibraNet GT a `/25`, ATC se movió a `172.16.18.128/25`, así que
> esa línea ya no permitía nada y **la regla "Ventas ↔ Atención al Cliente: Exitoso" quedaba rota**.
> Ahora es `172.16.18.128 0.0.0.127`.

## Aplicación en los DOS routers HSRP

```text
! RN-R3 y RN-R4
interface g0/1
 ip access-group VENTAS_IN in
 exit
```

Al existir dos routers activos en el mismo dominio de difusión, el tráfico de un host puede salir por
`RN-R3` o por `RN-R4` según cuál sea el *gateway* activo. Si la ACL estuviera solo en un router, al
conmutar HSRP **la política de seguridad desaparecería**. Por eso se replica con el mismo nombre en
ambos equipos.

## Verificación

```text
show ip access-lists VENTAS_IN
show standby brief
```
