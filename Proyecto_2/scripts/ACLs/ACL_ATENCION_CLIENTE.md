# ACL — Atención al Cliente

> **ISP 1 — FibraNet GT** · Departamento **Atención al Cliente**
> Equipo: `T1R5` · Interfaz: **`g0/1`** (LAN `172.16.18.128/25`) · Sentido: **`in`**

## Reglas que aplica este ACL

| Regla del enunciado (4.2) | Resultado |
| :--- | :--- |
| Atención al Cliente ↔ Ventas (ICMP, TCP/80) | ✅ Bidireccional, Exitoso |
| Atención al Cliente → Facturación | 🚫 Bloqueado |
| Cualquier depto → Seguridad | 🚫 Bloqueado |

## Configuración

```text
ip access-list extended ACL_ATC_IN

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

 ! --- Regla: ATC -> Facturacion BLOQUEADO ---
 deny   ip 172.16.18.128 0.0.0.127 172.16.28.64 0.0.0.63

 ! --- Regla: ningun departamento INICIA hacia Seguridad ---
 permit icmp 172.16.18.128 0.0.0.127 172.16.32.64 0.0.0.63 echo-reply
 permit tcp  172.16.18.128 0.0.0.127 eq 80  172.16.32.64 0.0.0.63
 permit tcp  172.16.18.128 0.0.0.127 eq 443 172.16.32.64 0.0.0.63
 deny   ip   172.16.18.128 0.0.0.127 172.16.32.64 0.0.0.63

 ! --- Regla: ATC <-> Ventas (solo ICMP y TCP/80) ---
 permit icmp 172.16.18.128 0.0.0.127 172.16.28.0 0.0.0.63
 permit tcp  172.16.18.128 0.0.0.127 172.16.28.0 0.0.0.63 eq 80
 permit icmp 172.16.28.0 0.0.0.63 172.16.18.128 0.0.0.127
 permit tcp  172.16.28.0 0.0.0.63 172.16.18.128 0.0.0.127 eq 80

 ! --- Excepciones "VIP": Soporte y Administracion hablan con todos ---
 permit icmp 172.16.18.128 0.0.0.127 172.16.32.0 0.0.0.63
 permit tcp  172.16.18.128 0.0.0.127 172.16.32.0 0.0.0.63 eq 80
 permit tcp  172.16.18.128 0.0.0.127 172.16.32.0 0.0.0.63 eq 443
 permit icmp 172.16.32.0 0.0.0.63 172.16.18.128 0.0.0.127
 permit tcp  172.16.32.0 0.0.0.63 172.16.18.128 0.0.0.127 eq 80
 permit tcp  172.16.32.0 0.0.0.63 172.16.18.128 0.0.0.127 eq 443
 permit icmp 172.16.18.128 0.0.0.127 172.16.18.0 0.0.0.127
 permit tcp  172.16.18.128 0.0.0.127 172.16.18.0 0.0.0.127 eq 80
 permit tcp  172.16.18.128 0.0.0.127 172.16.18.0 0.0.0.127 eq 443
 permit icmp 172.16.18.0 0.0.0.127 172.16.18.128 0.0.0.127
 permit tcp  172.16.18.0 0.0.0.127 172.16.18.128 0.0.0.127 eq 80
 permit tcp  172.16.18.0 0.0.0.127 172.16.18.128 0.0.0.127 eq 443

 ! --- Deny implicito: deny ip any any ---
 exit
```

## Aplicación en la interfaz

```text
interface g0/1
 ip access-group ACL_ATC_IN in
 exit
```

## Justificación del sentido `in`

Igual que Administración: se filtra en el **origen** sobre la interfaz LAN. El `deny` explícito
hacia Facturación debe evaluarse **antes** de cualquier `permit` amplio, por eso aparece arriba
en la lista (las ACL se evalúan de arriba hacia abajo y se detienen en la primera coincidencia).

## Verificación

```text
show ip access-lists ACL_ATC_IN
show ip interface g0/1 | include access group
```
