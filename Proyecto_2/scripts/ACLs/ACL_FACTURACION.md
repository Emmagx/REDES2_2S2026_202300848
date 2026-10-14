# ACL — Facturación

> **ISP 2 — AndinaCom** · Departamento **Facturación** (`172.16.28.64/26`, VIP HSRP `172.16.28.65`)
> Equipos: `RN-R3` y `RN-R4` · Interfaz: **`g0/2`** · Sentido: **`in`** (en **ambos** routers)

## Reglas que aplica este ACL

| Regla del enunciado (4.2) | Resultado |
| :--- | :--- |
| Facturación ↔ Ventas (ICMP, TCP/80) | ✅ Bidireccional, Exitoso |
| Facturación → Atención al Cliente | 🚫 Bloqueado |
| Cualquier depto → Seguridad | 🚫 Bloqueado |

## Configuración

```text
ip access-list extended ACL_FACTURACION_IN

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

 ! --- Regla: Facturacion -> Atencion al Cliente BLOQUEADO ---
 deny   ip 172.16.28.64 0.0.0.63 172.16.18.128 0.0.0.127

 ! --- Regla: ningun departamento INICIA hacia Seguridad ---
 permit icmp 172.16.28.64 0.0.0.63 172.16.32.64 0.0.0.63 echo-reply
 permit tcp  172.16.28.64 0.0.0.63 eq 80  172.16.32.64 0.0.0.63
 permit tcp  172.16.28.64 0.0.0.63 eq 443 172.16.32.64 0.0.0.63
 deny   ip   172.16.28.64 0.0.0.63 172.16.32.64 0.0.0.63

 ! --- Regla: Facturacion <-> Ventas (ICMP, TCP/80) ---
 permit icmp 172.16.28.64 0.0.0.63 172.16.28.0 0.0.0.63
 permit tcp  172.16.28.64 0.0.0.63 172.16.28.0 0.0.0.63 eq 80
 permit icmp 172.16.28.0 0.0.0.63 172.16.28.64 0.0.0.63
 permit tcp  172.16.28.0 0.0.0.63 172.16.28.64 0.0.0.63 eq 80

 ! --- Excepciones "VIP": Soporte y Administracion hablan con todos ---
 permit icmp 172.16.28.64 0.0.0.63 172.16.32.0 0.0.0.63
 permit tcp  172.16.28.64 0.0.0.63 172.16.32.0 0.0.0.63 eq 80
 permit tcp  172.16.28.64 0.0.0.63 172.16.32.0 0.0.0.63 eq 443
 permit icmp 172.16.32.0 0.0.0.63 172.16.28.64 0.0.0.63
 permit tcp  172.16.32.0 0.0.0.63 172.16.28.64 0.0.0.63 eq 80
 permit tcp  172.16.32.0 0.0.0.63 172.16.28.64 0.0.0.63 eq 443
 permit icmp 172.16.28.64 0.0.0.63 172.16.18.0 0.0.0.127
 permit tcp  172.16.28.64 0.0.0.63 172.16.18.0 0.0.0.127 eq 80
 permit tcp  172.16.28.64 0.0.0.63 172.16.18.0 0.0.0.127 eq 443
 permit icmp 172.16.18.0 0.0.0.127 172.16.28.64 0.0.0.63
 permit tcp  172.16.18.0 0.0.0.127 172.16.28.64 0.0.0.63 eq 80
 permit tcp  172.16.18.0 0.0.0.127 172.16.28.64 0.0.0.63 eq 443

 ! --- Deny implicito: deny ip any any ---
 exit
```

## Aplicación en la interfaz (en los DOS routers HSRP)

```text
! RN-R3 y RN-R4
interface g0/2
 ip access-group ACL_FACTURACION_IN in
 exit
```

## Justificación del sentido `in`

Mismo razonamiento que `ACL_VENTAS_IN`: filtrado **en el origen** sobre la interfaz LAN y
**replicado en ambos routers HSRP** para que la política sobreviva a la conmutación de gateway.
El `deny` hacia Atención al Cliente se coloca en las primeras posiciones porque las ACL son
secuenciales (primera coincidencia gana).

## Verificación

```text
show ip access-lists ACL_FACTURACION_IN
show standby brief
```
