# Listas de Control de Acceso (ACLs) — Justificación de implementación

> Requisito del enunciado oficial **4.2**: *"El estudiante deberá entregar en el manual técnico la
> justificación de **en qué interfaz y en qué dirección (in/out)** aplicó cada ACL."*
>
> Requisito de la rúbrica **2.5 (8 pts)**: *"ACLs extendidas correctamente aplicadas según la tabla de
> reglas, **verificadas con ping y acceso a servicios** entre todos los pares de departamentos."*

---

## 1. Tabla de justificación: ACL → equipo → interfaz → sentido

| # | Departamento | ISP | Equipo | Interfaz | Red de la interfaz | Sentido | Nombre del ACL |
| :- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 1 | Administración | FibraNet GT | `T1R4` | `g0/1` | `172.16.18.0/25` | **in** | `ACL_ADMIN_IN` |
| 2 | Atención al Cliente | FibraNet GT | `T1R5` | `g0/1` | `172.16.18.128/25` | **in** | `ACL_ATC_IN` |
| 3 | Ventas | AndinaCom | `RN-R3` **y** `RN-R4` | `g0/1` | `172.16.28.0/26` | **in** | `ACL_VENTAS_IN` |
| 4 | Facturación | AndinaCom | `RN-R3` **y** `RN-R4` | `g0/2` | `172.16.28.64/26` | **in** | `ACL_FACTURACION_IN` |
| 5 | Soporte | MoonLink | `CF-R2` | `g0/1` | `172.16.32.0/26` | **in** | `ACL_SOPORTE_IN` |
| 6 | Seguridad | MoonLink | `CF-R3` | `g0/1` | `172.16.32.64/26` | **in** | `ACL_SEGURIDAD_IN` |

### ¿Por qué `in` y no `out`?

Todas las ACLs se aplican en sentido **`in` sobre la interfaz LAN** del router de acceso del
departamento (filtrado **en el origen**):

1. **Eficiencia:** el paquete se descarta antes de entrar al dominio de enrutamiento, sin cruzar la
   WAN ni consumir ancho de banda troncal.
2. **Precisión:** el origen del tráfico es inequívoco (está en esa LAN), lo que evita listas largas
   de "permitir esto excepto aquello".
3. **Escalabilidad:** al agregar un departamento nuevo solo se toca su propia ACL, no las de los demás.
4. **Redundancia (HSRP):** en Ventas y Facturación la misma ACL debe estar **replicada en ambos
   routers HSRP** (`RN-R3` y `RN-R4`), porque el gateway activo puede cambiar tras un failover y la
   política de seguridad debe sobrevivir a la conmutación.

### ¿Por qué NO se aplicó un ACL `out` para bloquear la entrada a Seguridad?

Un ACL extendido no mantiene estado. Si se bloqueara *el tráfico entrante* a Seguridad con un ACL
`out` en su interfaz LAN, se bloquearían también **las respuestas** a las conexiones que Seguridad
sí tiene permitido iniciar (rompiendo la regla "Seguridad → cualquiera: Exitoso").
La solución estándar es **filtrar en el origen**: la ACL de cada departamento contiene un `deny`
hacia la subred de Seguridad, con una excepción previa que permite únicamente el tráfico de
**retorno** (`echo-reply` y TCP con puerto origen 80/443).

---

## 2. Contenido de cada ACL (resumen de reglas)

Todas las ACLs comparten un **bloque común de plano de control y servicios compartidos** que se
evalúa *antes* de cualquier `deny`, porque sin él caen los protocolos de enrutamiento y los
servicios centrales (es el "split-brain" documentado en el README §6.6):

| Sentencia | Motivo |
| :--- | :--- |
| `permit ospf any any` | Hello/adyacencias OSPF (protocolo IP 89) |
| `permit eigrp any any` | Hello/adyacencias EIGRP (protocolo IP 88) |
| `permit udp any any eq 1985` | HSRP (grupos 10 y 20 de AndinaCom) |
| `permit udp any any eq 67` | DHCP cliente → servidor (`ip helper-address`) |
| `permit udp any any eq 68` | DHCP servidor → cliente |
| `permit udp/tcp any any eq 53` | Resolución DNS (`www.proyecto2_202300848.com`) |
| `permit tcp any host 192.168.48.50 eq 80` | Servidor web del proyecto (HTTP) |
| `permit tcp any host 192.168.48.50 eq 443` | Servidor web del proyecto (HTTPS) |

Detalle completo por departamento:

| ACL | Archivo |
| :--- | :--- |
| `ACL_ADMIN_IN` | [ACL_ADMINISTRACION.md](ACL_ADMINISTRACION.md) |
| `ACL_ATC_IN` | [ACL_ATENCION_CLIENTE.md](ACL_ATENCION_CLIENTE.md) |
| `ACL_VENTAS_IN` | [ACL_VENTAS.md](ACL_VENTAS.md) |
| `ACL_FACTURACION_IN` | [ACL_FACTURACION.md](ACL_FACTURACION.md) |
| `ACL_SOPORTE_IN` | [ACL_SOPORTE.md](ACL_SOPORTE.md) |
| `ACL_SEGURIDAD_IN` | [ACL_SEGURIDAD.md](ACL_SEGURIDAD.md) |
| Matriz de pruebas | [MATRIZ_PRUEBAS.md](MATRIZ_PRUEBAS.md) |

---

## 3. Reglas de comunicación del enunciado y cómo se cumplen

| Origen | Destino | Protocolo permitido | Sentido | Resultado esperado | Implementado en |
| :--- | :--- | :--- | :--- | :--- | :--- |
| Seguridad | Cualquier depto | ICMP, TCP/80, TCP/443 | Seguridad inicia | ✅ Exitoso | `ACL_SEGURIDAD_IN` |
| Cualquier depto | Seguridad | — | Bloqueado | 🚫 Bloqueado | `deny` hacia `172.16.32.64/26` en cada ACL de origen |
| Soporte | Cualquier depto | ICMP, TCP/80, TCP/443 | Bidireccional | ✅ Exitoso (salvo Seguridad) | `ACL_SOPORTE_IN` |
| Administración | Cualquier depto | ICMP, TCP/80, TCP/443 | Bidireccional | ✅ Exitoso (salvo Seguridad) | `ACL_ADMIN_IN` |
| Atención al Cliente | Ventas | ICMP, TCP/80 | Bidireccional | ✅ Exitoso | `ACL_ATC_IN` |
| Atención al Cliente | Facturación | — | Bloqueado | 🚫 Bloqueado | `deny` en `ACL_ATC_IN` |
| Facturación | Ventas | ICMP, TCP/80 | Bidireccional | ✅ Exitoso | `ACL_FACTURACION_IN` |
| Facturación | Atención al Cliente | — | Bloqueado | 🚫 Bloqueado | `deny` en `ACL_FACTURACION_IN` |
| Ventas | Facturación y Atención al Cliente | ICMP, TCP/80 | Bidireccional | ✅ Exitoso | `ACL_VENTAS_IN` |

### Nota sobre la verificación con TCP/80 y TCP/443

El único servidor web real de la topología es el de FibraNet GT (`192.168.48.50`). Por eso la
verificación de las reglas entre departamentos se hace con **ping (ICMP)**, y la verificación del
**servicio HTTP/HTTPS** se hace abriendo `http://www.proyecto2_202300848.com` y
`https://www.proyecto2_202300848.com` desde una PC de **cada** departamento. Las ACLs incluyen las
sentencias que permiten ese acceso al servidor desde todos los departamentos, para no romper el
requisito eliminatorio *"el servidor web y DNS funcionan desde cualquier dispositivo de la topología"*.

---

## 4. Cómo verificar (comandos)

```text
! Ver la ACL y sus contadores de coincidencias
show ip access-lists
show ip access-lists ACL_VENTAS_IN

! Confirmar en qué interfaz y sentido está aplicada
show ip interface g0/1 | include access group

! Confirmar la redundancia de gateway
show standby brief
```
