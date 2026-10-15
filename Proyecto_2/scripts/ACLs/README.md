# Listas de Control de Acceso (ACLs) — documentación real

> Requisito del enunciado oficial **4.2**: *"El estudiante deberá entregar en el manual técnico la
> justificación de **en qué interfaz y en qué dirección (in/out)** aplicó cada ACL."*
>
> Requisito de la rúbrica **2.5 (8 pts)**: *"ACLs extendidas correctamente aplicadas según la tabla de
> reglas, **verificadas con ping y acceso a servicios** entre todos los pares de departamentos."*

Este directorio documenta **las ACLs que existen realmente en `Proyecto2_202300848.pkt`**
(verificadas con `show ip access-lists`).

---

## 1. Inventario: qué ACL tiene cada equipo

| # | Departamento | ISP | Equipo(s) | ACL | Interfaz | Sentido |
| :-: | :--- | :--- | :--- | :--- | :--- | :--- |
| 1 | Administración | FibraNet GT | `T1R4` | **ninguna** | — | — |
| 2 | Atención al Cliente | FibraNet GT | `T1R5` | `ATC_IN` | `g0/1` | **in** |
| 3 | Ventas | AndinaCom | `RN-R3` y `RN-R4` | `VENTAS_IN` | `g0/1` | **in** |
| 4 | Facturación | AndinaCom | `RN-R3` y `RN-R4` | `FAC_IN` | `g0/2` | **in** |
| 5 | Soporte | MoonLink | `CF-R2` | **ninguna** | — | — |
| 6 | Seguridad | MoonLink | `CF-R3` | `SEC_OUT` | `g0/1` | **out** |

### ¿Por qué Administración y Soporte no tienen ACL?

Sus reglas del enunciado son *"habla y escucha a todos los departamentos"* (bidireccional). Al no
tener restricciones de origen, se dejan sus interfaces **sin ACL** y las restricciones se aplican en
el **origen** de los departamentos que sí las necesitan. Esto evita gastar CPU del router evaluando
listas largas de `permit` que no restringen nada.

### ¿Por qué se filtra en `in` y en el origen?

1. **Eficiencia:** el paquete se descarta antes de entrar al dominio de enrutamiento, sin cruzar la WAN.
2. **Precisión:** el origen del tráfico es inequívoco (está en esa LAN).
3. **Escalabilidad:** al agregar un departamento solo se toca su propia ACL.
4. **Redundancia (HSRP):** en Ventas y Facturación la misma ACL está **replicada en `RN-R3` y
   `RN-R4`** porque el gateway activo puede cambiar tras un failover y la política debe sobrevivir.

### El caso especial de Seguridad (`SEC_OUT`, sentido `out`)

`SEC_OUT` es la única ACL aplicada en sentido **`out`**. Es una **ACL de retorno**: permite
únicamente las respuestas (DNS proveniente del servidor, TCP `established` e ICMP `echo-reply`) y
deniega todo lo demás que intente **entrar** a Seguridad. Así se cumple la regla
*"ningún departamento entra a Seguridad"* sin romper la regla *"Seguridad → cualquiera: exitoso"*
(un ACL `in` habría bloqueado también las respuestas a las conexiones que Seguridad inicia).

---

## 2. Bloque común: plano de control y servicios

Todas las ACLs de departamento incluyen, **antes del `deny ip any any`**, permisos para el plano de
control y para los servicios centrales. Sin ellos la red colapsa (ver el "split-brain" del
troubleshooting §7.6 del README):

| Sentencia | Motivo |
| :--- | :--- |
| `permit ospf any any` | Hello/adyacencias OSPF (protocolo IP 89) |
| `permit udp any any eq 1985` / `eq 2029` | HSRP (grupos 10 y 20 de AndinaCom) |
| `permit udp any any eq bootpc` / `bootps` | DHCP (`ip helper-address` al servidor central) |
| `permit ip any 192.168.48.48 0.0.0.3` | **Servidor DNS/HTTP/HTTPS completo** (`192.168.48.50`): DNS, HTTP, HTTPS **e ICMP** |
| `permit tcp any any established` | Tráfico de retorno de sesiones TCP iniciadas desde fuera |
| `permit icmp any any echo-reply` | Respuestas a los ping que el departamento inicia |

> ⚠️ **Corrección aplicada el 14/10/2026:** originalmente estas ACLs apuntaban a `172.16.18.130`,
> que era la IP del servidor **antes** de moverlo a `192.168.48.50` al re-subnetear FibraNet GT a
> `/25`. Como consecuencia, DNS y HTTP quedaban bloqueados en cuatro departamentos. También se
> agregó el permiso de **HTTPS (443)**, que no existía en ninguna ACL.

---

## 3. Reglas del enunciado y cómo se cumplen

| Origen | Destino | Protocolo permitido | Resultado esperado | Implementado en |
| :--- | :--- | :--- | :--- | :--- |
| Seguridad | Cualquier depto | ICMP, TCP/80, TCP/443 | ✅ Exitoso | `SEC_OUT` permite solo el retorno; el origen no se filtra |
| Cualquier depto | Seguridad | — | 🚫 Bloqueado | `SEC_OUT` (out en `CF-R3 g0/1`) |
| Soporte | Cualquier depto | ICMP, TCP/80, TCP/443 | ✅ Exitoso (salvo Seguridad) | sin ACL + `SEC_OUT` bloquea el ingreso |
| Administración | Cualquier depto | ICMP, TCP/80, TCP/443 | ✅ Exitoso (salvo Seguridad) | sin ACL + `SEC_OUT` bloquea el ingreso |
| Atención al Cliente ↔ Ventas | — | ICMP, TCP/80 | ✅ Exitoso | `ATC_IN` + `VENTAS_IN` |
| Atención al Cliente | Facturación | — | 🚫 Bloqueado | `ATC_IN` no permite `172.16.28.64/26` |
| Facturación | Ventas | ICMP, TCP/80 | ✅ Exitoso | `VENTAS_IN` + `FAC_IN` |
| Facturación | Atención al Cliente | — | 🚫 Bloqueado | `FAC_IN` no permite `172.16.18.128/25` |
| Ventas | Facturación y Atención al Cliente | ICMP, TCP/80 | ✅ Exitoso | `VENTAS_IN` |

### Nota sobre la verificación con TCP/80 y TCP/443

El único servidor web de la topología es el de FibraNet GT (`192.168.48.50`). La verificación de las
reglas *entre* departamentos se hace con **ping (ICMP)**, y el **servicio HTTP/HTTPS** se verifica
abriendo `http://www.proyecto2_202300848.com` y `https://www.proyecto2_202300848.com` desde una PC de
**cada** departamento. Las ACLs incluyen los permisos hacia el servidor precisamente para no romper
el requisito eliminatorio *"el servidor web y DNS funcionan desde cualquier dispositivo"*.

---

## 4. Archivos

| ACL | Archivo |
| :--- | :--- |
| `ATC_IN` | [ACL_ATENCION_CLIENTE.md](ACL_ATENCION_CLIENTE.md) |
| `VENTAS_IN` | [ACL_VENTAS.md](ACL_VENTAS.md) |
| `FAC_IN` | [ACL_FACTURACION.md](ACL_FACTURACION.md) |
| `SEC_OUT` | [ACL_SEGURIDAD.md](ACL_SEGURIDAD.md) |
| Administración (sin ACL) | [ACL_ADMINISTRACION.md](ACL_ADMINISTRACION.md) |
| Soporte (sin ACL) | [ACL_SOPORTE.md](ACL_SOPORTE.md) |
| Matriz de pruebas | [MATRIZ_PRUEBAS.md](MATRIZ_PRUEBAS.md) |

## 5. Cómo verificar (comandos)

```text
! Contenido de la ACL y contadores de coincidencias
show ip access-lists
show ip access-lists ATC_IN

! En que interfaz y sentido esta aplicada (buscar "Inbound/Outbound access list")
show ip interface g0/1

! Redundancia de gateway
show standby brief
```

> **Notas sobre Packet Tracer:**
> - `show ip interface g0/1` **sí** funciona y muestra `Inbound access list ATC_IN`.
> - En cambio `show run interface g0/1` **no existe** en PT (`% Invalid input`). Usa
>   `show ip interface <interfaz>` o `show running-config` completo.
> - `show ip interface g0/1 | include access group` devuelve vacío porque PT escribe
>   `Inbound access list ...` (no "access group").
