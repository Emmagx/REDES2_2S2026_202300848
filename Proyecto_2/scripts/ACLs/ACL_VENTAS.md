# ACL — Ventas

> **ISP 2 — AndinaCom** · Departamento **Ventas** (`172.16.28.0/26`, VIP HSRP `172.16.28.1`)
> Equipos: `RN-R3` y `RN-R4` · Interfaz: **`g0/1`** · Sentido: **`in`** (en **ambos** routers)

## Reglas que aplica este ACL

| Regla del enunciado (4.2) | Resultado |
| :--- | :--- |
| Ventas → Facturación y Atención al Cliente (ICMP, TCP/80) | ✅ Bidireccional, Exitoso |
| Cualquier depto → Seguridad | 🚫 Bloqueado |

## Configuración

```text
ip access-list extended ACL_VENTAS_IN

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
 permit icmp 172.16.28.0 0.0.0.63 172.16.32.64 0.0.0.63 echo-reply
 permit tcp  172.16.28.0 0.0.0.63 eq 80  172.16.32.64 0.0.0.63
 permit tcp  172.16.28.0 0.0.0.63 eq 443 172.16.32.64 0.0.0.63
 deny   ip   172.16.28.0 0.0.0.63 172.16.32.64 0.0.0.63

 ! --- Regla: Ventas <-> Facturacion (ICMP, TCP/80) ---
 permit icmp 172.16.28.0 0.0.0.63 172.16.28.64 0.0.0.63
 permit tcp  172.16.28.0 0.0.0.63 172.16.28.64 0.0.0.63 eq 80
 permit icmp 172.16.28.64 0.0.0.63 172.16.28.0 0.0.0.63
 permit tcp  172.16.28.64 0.0.0.63 172.16.28.0 0.0.0.63 eq 80

 ! --- Regla: Ventas <-> Atencion al Cliente (ICMP, TCP/80) ---
 permit icmp 172.16.28.0 0.0.0.63 172.16.18.128 0.0.0.127
 permit tcp  172.16.28.0 0.0.0.63 172.16.18.128 0.0.0.127 eq 80
 permit icmp 172.16.18.128 0.0.0.127 172.16.28.0 0.0.0.63
 permit tcp  172.16.18.128 0.0.0.127 172.16.28.0 0.0.0.63 eq 80

 ! --- Excepciones "VIP": Soporte y Administracion hablan con todos ---
 permit icmp 172.16.28.0 0.0.0.63 172.16.32.0 0.0.0.63
 permit tcp  172.16.28.0 0.0.0.63 172.16.32.0 0.0.0.63 eq 80
 permit tcp  172.16.28.0 0.0.0.63 172.16.32.0 0.0.0.63 eq 443
 permit icmp 172.16.32.0 0.0.0.63 172.16.28.0 0.0.0.63
 permit tcp  172.16.32.0 0.0.0.63 172.16.28.0 0.0.0.63 eq 80
 permit tcp  172.16.32.0 0.0.0.63 172.16.28.0 0.0.0.63 eq 443
 permit icmp 172.16.28.0 0.0.0.63 172.16.18.0 0.0.0.127
 permit tcp  172.16.28.0 0.0.0.63 172.16.18.0 0.0.0.127 eq 80
 permit tcp  172.16.28.0 0.0.0.63 172.16.18.0 0.0.0.127 eq 443
 permit icmp 172.16.18.0 0.0.0.127 172.16.28.0 0.0.0.63
 permit tcp  172.16.18.0 0.0.0.127 172.16.28.0 0.0.0.63 eq 80
 permit tcp  172.16.18.0 0.0.0.127 172.16.28.0 0.0.0.63 eq 443

 ! --- Deny implicito: deny ip any any ---
 exit
```

## Aplicación en la interfaz (en los DOS routers HSRP)

```text
! RN-R3
interface g0/1
 ip access-group ACL_VENTAS_IN in
 exit

! RN-R4
interface g0/1
 ip access-group ACL_VENTAS_IN in
 exit
```

## Justificación del sentido `in` y de duplicar el ACL

La ACL se aplica **`in` en la interfaz LAN de los dos routers HSRP**. Al existir dos routers activos
en el mismo dominio de difusión, el tráfico de un host puede salir por RN-R3 o por RN-R4 según cuál
sea el *gateway* activo en ese momento (o tras un failover). Si la ACL se aplicara en un solo router,
al conmutar HSRP la política de seguridad desaparecería. Por eso la ACL debe estar replicada con el
mismo nombre en ambos equipos.

## Verificación

```text
show ip access-lists ACL_VENTAS_IN
show standby brief
```
