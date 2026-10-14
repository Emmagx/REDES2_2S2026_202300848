# ACL — Soporte

> **ISP 3 — MoonLink** · Departamento **Soporte** (`172.16.32.0/26`)
> Equipo: `CF-R2` · Interfaz: **`g0/1`** · Sentido: **`in`**

## Reglas que aplica este ACL

| Regla del enunciado (4.2) | Resultado |
| :--- | :--- |
| Soporte → Cualquier depto (ICMP, TCP/80, TCP/443) | ✅ Bidireccional, Exitoso |
| Cualquier depto → Seguridad | 🚫 Bloqueado (**excepción que gana sobre la regla anterior**) |

> ⚠️ **Conflicto de reglas y su resolución:** la tabla del enunciado dice que *Soporte habla con todos*
> en ambos sentidos, pero también que *ningún departamento tiene tráfico de entrada a Seguridad*.
> Ambas no pueden cumplirse a la vez para el par Soporte↔Seguridad. Se resuelve dando **prioridad a la
> regla de Seguridad** (el enunciado la lista primero y es la más restrictiva, criterio estándar de
> firewall: la regla más específica/restrictiva gana). Es exactamente lo que valida la matriz de
> pruebas del proyecto: `PC1-SOPORTE → PC1-SEGURIDAD = Failed`.
> **Esta justificación debe explicarse en la evaluación oral.**

## Configuración

```text
ip access-list extended ACL_SOPORTE_IN

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
 permit icmp 172.16.32.0 0.0.0.63 172.16.32.64 0.0.0.63 echo-reply
 permit tcp  172.16.32.0 0.0.0.63 eq 80  172.16.32.64 0.0.0.63
 permit tcp  172.16.32.0 0.0.0.63 eq 443 172.16.32.64 0.0.0.63
 deny   ip   172.16.32.0 0.0.0.63 172.16.32.64 0.0.0.63

 ! --- Regla: Soporte <-> cualquier departamento (ICMP, HTTP, HTTPS) ---
 permit icmp 172.16.32.0 0.0.0.63 any
 permit tcp  172.16.32.0 0.0.0.63 any eq 80
 permit tcp  172.16.32.0 0.0.0.63 any eq 443
 permit icmp any 172.16.32.0 0.0.0.63
 permit tcp  any 172.16.32.0 0.0.0.63 eq 80
 permit tcp  any 172.16.32.0 0.0.0.63 eq 443

 ! --- Deny implicito: deny ip any any ---
 exit
```

## Aplicación en la interfaz

```text
interface g0/1
 ip access-group ACL_SOPORTE_IN in
 exit
```

## Justificación del sentido `in`

Se filtra en el **origen** (interfaz LAN de Soporte, sentido `in`). El `deny` hacia Seguridad va
antes de los `permit` amplios porque, de lo contrario, `permit icmp 172.16.32.0 0.0.0.63 any`
capturaría primero el ping hacia Seguridad y lo dejaría pasar.

## Verificación

```text
show ip access-lists ACL_SOPORTE_IN
show ip interface g0/1 | include access group
```
