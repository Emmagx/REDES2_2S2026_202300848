# ACL — Seguridad

> **ISP 3 — MoonLink** · Departamento **Seguridad** (`172.16.32.64/26`)
> Equipo: `CF-R3` · Interfaz: **`g0/1`** · Sentido: **`in`**

## Reglas que aplica este ACL

| Regla del enunciado (4.2) | Resultado |
| :--- | :--- |
| Seguridad → Cualquier depto (ICMP, TCP/80, TCP/443) | ✅ Seguridad inicia, Exitoso |
| Cualquier depto → Seguridad | 🚫 Bloqueado |

## Configuración

```text
ip access-list extended ACL_SEGURIDAD_IN

 ! --- Plano de control y servicios compartidos: NO filtrar ---
 permit ospf any any
 permit eigrp any any
 permit udp any any eq 1985
 permit udp any any eq 67
 permit udp any any eq 68
 permit udp any any eq 53
 permit tcp any any eq 53

 ! --- Regla: Seguridad INICIA hacia cualquier departamento (ICMP, HTTP, HTTPS) ---
 permit icmp 172.16.32.64 0.0.0.63 any
 permit tcp  172.16.32.64 0.0.0.63 any eq 80
 permit tcp  172.16.32.64 0.0.0.63 any eq 443

 ! --- El trafico entrante NO se permite aqui: lo bloquean las ACLs de cada origen ---
 ! (ver MATRIZ_PRUEBAS.md). Este ACL solo acota lo que Seguridad puede iniciar.
 exit
```

## Aplicación en la interfaz

```text
interface g0/1
 ip access-group ACL_SEGURIDAD_IN in
 exit
```

## Justificación del sentido `in`

Este ACL **no** intenta bloquear el tráfico entrante a Seguridad: un ACL `in` sobre la interfaz LAN
solo inspecciona los paquetes que **salen de** los hosts de Seguridad. El bloqueo de "cualquier
departamento → Seguridad" se implementa de forma distribuida, en la ACL **de cada departamento de
origen** (filtrado en origen). Así se evita el problema clásico de ACLs sin estado, donde bloquear
el tráfico entrante en el destino también bloquearía las **respuestas** a las conexiones que
Seguridad sí inicia.

> **Nota de diseño (defensa en profundidad):** este ACL acota a Seguridad a los protocolos que el
> enunciado le autoriza (ICMP, HTTP, HTTPS, DNS y DHCP). Si se quisiera ser aún más estricto, se
> podría aplicar adicionalmente un ACL `out` sobre la misma interfaz LAN que deniegue únicamente
> `icmp ... echo` proveniente de los demás departamentos.

## Verificación

```text
show ip access-lists ACL_SEGURIDAD_IN
show ip interface g0/1 | include access group
```
