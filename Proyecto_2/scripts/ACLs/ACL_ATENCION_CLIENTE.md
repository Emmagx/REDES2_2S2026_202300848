# ACL: `ATC_IN` — Atención al Cliente

> **ISP 1 — FibraNet GT** · Departamento **Atención al Cliente** (`172.16.18.128/25`)
> Equipo: `T1R5` · Interfaz: **`g0/1`** · Sentido: **`in`**

## Reglas que aplica

| Regla del enunciado | Resultado |
| :--- | :--- |
| Atención al Cliente ↔ Ventas (ICMP, TCP/80) | ✅ Exitoso |
| Atención al Cliente → Facturación | 🚫 Bloqueado |
| Cualquier depto → Seguridad | 🚫 Bloqueado |

## Configuración corregida

```text
enable
configure terminal
no ip access-list extended ATC_IN
ip access-list extended ATC_IN
 permit ospf any any
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
interface g0/1
 ip access-group ATC_IN in
 exit
exit
write memory
```

## Línea por línea

| Línea | Qué hace |
| :--- | :--- |
| `permit ospf any any` | Mantiene las adyacencias OSPF (protocolo 89) |
| `bootpc` / `bootps` | Permite el DHCP relayado hacia `172.16.28.130` |
| `ip any 192.168.48.48 0.0.0.3` | **Servidor DNS/HTTP/HTTPS** completo: DNS, HTTP, HTTPS **e ICMP** (permite el ping al servidor) |
| `tcp any any established` | Retorno de sesiones iniciadas desde fuera |
| `icmp any any echo-reply` | Respuestas a los ping que ATC inicia |
| `ip any 172.16.28.0 0.0.0.63` | ATC ↔ **Ventas** |
| `ip any 172.16.32.0 0.0.0.63` | ATC ↔ **Soporte** (excepción "habla con todos") |
| `ip any 172.16.18.0 0.0.0.127` | ATC ↔ **Administración** (wildcard corregido de `0.0.0.63` a `0.0.0.127`) |
| `deny ip any any` | Explícito; **Facturación (`172.16.28.64/26`) y Seguridad (`172.16.32.64/26`) quedan bloqueados** |

## Justificación del sentido `in`

Se filtra **en el origen** sobre la interfaz LAN: el paquete se descarta antes de entrar al dominio de
enrutamiento y antes de consumir ancho de banda WAN.

## Verificación

```text
show ip access-lists ATC_IN
show ip interface g0/1
```
