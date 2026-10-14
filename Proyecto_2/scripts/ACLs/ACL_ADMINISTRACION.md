# ACLs — Listas de Control de Acceso Extendidas

> **ISP 1 — FibraNet GT** · Departamento **Administración**
> Equipo: `T1R4` · Interfaz: **`g0/1`** (LAN Administración `172.16.18.0/25`) · Sentido: **`in`**

## Reglas que aplica este ACL

| Regla del enunciado (4.2) | Resultado |
| :--- | :--- |
| Administración → Cualquier depto (ICMP, TCP/80, TCP/443) | ✅ Bidireccional, Exitoso |
| Cualquier depto → Seguridad | 🚫 Bloqueado |

## Configuración

```text
ip access-list extended ACL_ADMIN_IN

 ! --- Plano de control y servicios compartidos: NO filtrar ---
 permit ospf any any
 permit eigrp any any
 permit udp any any eq 1985
 permit udp any any eq 67
 permit udp any any eq 68
 permit udp any any eq 53
 permit tcp any any eq 53
 permit tcp any host 192.168.48.50 eq 80
 permit tcp any host 192.168.48.50 eq 443

 ! --- Regla: ningun departamento INICIA hacia Seguridad ---
 ! Se permiten las respuestas a sesiones que Seguridad inicio.
 permit icmp 172.16.18.0 0.0.0.127 172.16.32.64 0.0.0.63 echo-reply
 permit tcp  172.16.18.0 0.0.0.127 eq 80  172.16.32.64 0.0.0.63
 permit tcp  172.16.18.0 0.0.0.127 eq 443 172.16.32.64 0.0.0.63
 deny   ip   172.16.18.0 0.0.0.127 172.16.32.64 0.0.0.63

 ! --- Regla: Administracion <-> cualquier departamento (ICMP, HTTP, HTTPS) ---
 permit icmp 172.16.18.0 0.0.0.127 any
 permit tcp  172.16.18.0 0.0.0.127 any eq 80
 permit tcp  172.16.18.0 0.0.0.127 any eq 443
 permit icmp any 172.16.18.0 0.0.0.127
 permit tcp  any 172.16.18.0 0.0.0.127 eq 80
 permit tcp  any 172.16.18.0 0.0.0.127 eq 443

 ! --- Deny implicito: deny ip any any ---
 exit
```

## Aplicación en la interfaz

```text
interface g0/1
 ip access-group ACL_ADMIN_IN in
 exit
```

## Justificación del sentido `in`

Se aplica **`in` sobre la interfaz LAN** porque el objetivo es filtrar el tráfico **en el origen**:
el paquete se descarta antes de entrar al dominio de enrutamiento y antes de consumir ancho de banda
WAN. Si se aplicara `out` en la interfaz WAN, el tráfico restringido ya habría cruzado la red troncal
y el filtro afectaría a todos los orígenes que salen por esa interfaz.

## Verificación

```text
show ip access-lists ACL_ADMIN_IN
show ip interface g0/1 | include access group
```
