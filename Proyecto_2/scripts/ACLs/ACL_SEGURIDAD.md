# ACL: `SEC_OUT` — Seguridad

> **ISP 3 — MoonLink** · Departamento **Seguridad** (`172.16.32.64/26`)
> Equipo: `CF-R3` · Interfaz: **`g0/1`** · Sentido: **`out`** ⚠️ *(la única ACL del proyecto aplicada en `out`)*

## Reglas que aplica

| Regla del enunciado | Resultado |
| :--- | :--- |
| Seguridad → Cualquier depto (ICMP, TCP/80, TCP/443) | ✅ Seguridad inicia, Exitoso |
| Cualquier depto → Seguridad | 🚫 Bloqueado |

## Configuración corregida

```text
enable
configure terminal
no ip access-list extended SEC_OUT
ip access-list extended SEC_OUT
 permit udp any any eq bootpc
 permit udp any any eq bootps
 permit udp host 192.168.48.50 eq domain any
 permit tcp any any established
 permit icmp any any echo-reply
 deny ip any any
 exit
interface g0/1
 ip access-group SEC_OUT out
 exit
exit
write memory
```

## Línea por línea

| Línea | Qué hace |
| :--- | :--- |
| `bootpc` / `bootps` | Permite que el **DHCP Offer/Ack** llegue a los hosts de Seguridad |
| `udp host 192.168.48.50 eq domain any` | Respuestas DNS del servidor (puerto origen 53). ⚠️ **IP corregida** |
| `tcp any any established` | Retorno de las sesiones HTTP/HTTPS que **Seguridad inicia** |
| `icmp any any echo-reply` | Respuestas a los ping que **Seguridad inicia** |
| `deny ip any any` | Bloquea todo lo que intente **entrar** a Seguridad (incluye `icmp echo`) |

## Por qué esta ACL va en sentido `out` y no `in`

Un ACL extendido **no mantiene estado**. Si se aplicara un ACL `in` sobre la interfaz LAN de Seguridad
para bloquear la entrada, se bloquearían también **las respuestas** a las conexiones que Seguridad sí
tiene permitido iniciar, rompiendo la regla *"Seguridad → cualquiera: Exitoso"*.

Con `SEC_OUT` en sentido **`out`** (tráfico que **sale del router hacia** los hosts de Seguridad):

- Un `icmp echo` (ping) enviado por otro departamento hacia Seguridad → no coincide con ninguna línea
  → cae en `deny ip any any` → **bloqueado** ✅ *(regla: nadie entra a Seguridad)*
- Un `icmp echo-reply` (respuesta al ping que Seguridad inició) → coincide con la línea 50 → **pasa** ✅
- El tráfico **originado por** Seguridad no se filtra aquí (sale por la interfaz en sentido `in`, que
  no tiene ACL) → Seguridad puede hablar con quien quiera ✅

El bloqueo de "cualquier departamento → Seguridad" **no** se implementa en las ACLs de los otros
departamentos (no tienen permiso hacia `172.16.32.64/26`, así que además hay filtrado en el origen,
lo que constituye defensa en profundidad).

## Verificación

```text
show ip access-lists SEC_OUT
show ip interface g0/1        ! debe decir: ip access-group SEC_OUT out
```

Prueba funcional:

```text
! Desde una PC de Soporte hacia una de Seguridad
ping 172.16.32.66        -> Debe FALLAR

! Desde una PC de Seguridad hacia una de Soporte
ping 172.16.32.2         -> Debe FUNCIONAR
```
