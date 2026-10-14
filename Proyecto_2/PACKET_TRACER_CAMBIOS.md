# Cambios pendientes en `Proyecto2_202300848.pkt` (Packet Tracer)

> El archivo `.pkt` está **cifrado**, así que estos cambios se hacen **a mano en la GUI de Packet
> Tracer**. Este documento es la lista de trabajo; los valores exactos también están en el
> [`README.md`](README.md) y en [`scripts/`](scripts/).
>
> **Antes de empezar:** guarda una copia de respaldo (`Proyecto2_202300848_BACKUP.pkt`).

**Orden recomendado:** A → B → C → D → E → F → G (renombrar primero, luego re-IP, luego ACLs).

---

## A. Renombrar los ISPs

### A.1 Los 3 switches multicapa de borde (obligatorio)

Hoy su etiqueta en el mapa lógico dice los nombres viejos. Renómbralos así:

| Ubicación en el mapa | Etiqueta actual | Nueva etiqueta | Hostname CLI nuevo |
| :--- | :--- | :--- | :--- |
| ISP 1 (izquierda) | `Telecom uno` | `FibraNet GT` | `SW-BGP-FG` |
| ISP 2 (arriba) | `Redes Nacionales` | `AndinaCom` | `SW-BGP-AC` |
| ISP 3 (derecha) | `Link Global` | `MoonLink` | `SW-BGP-ML` |

**Procedimiento por cada switch:** clic en el dispositivo → pestaña **Config** → campo *Display Name*
→ escribir la nueva etiqueta. Luego en la pestaña **CLI**:

```text
enable
configure terminal
hostname SW-BGP-FG        ! SW-BGP-AC / SW-BGP-ML según corresponda
exit
write memory
```

### A.2 Etiqueta del servidor web (recomendado)

Renombra `SERVER DNS HTTP` → **`SERVER DNS HTTP HTTPS`** (el enunciado exige HTTPS).

### A.3 Hostnames internos (OPCIONAL)

Los prefijos `T1`, `RN` y `CF` son válidos y están documentados en
[`scripts/README.md`](scripts/README.md) (mapa de equivalencia). Si decides renombrarlos, hazlo en
**todos** los equipos y luego actualiza los scripts y las capturas del README:

| Actual | Alternativa sugerida |
| :--- | :--- |
| `T1R1` … `T1R5`, `T1S1-ADMIN` … | `FG-R1` … `FG-R5`, `FG-SW1-ADMIN` … |
| `RN-R1` … `RN-R5` | `AC-R1` … `AC-R5` |
| `CF-R1` … `CF-R5` | `ML-R1` … `ML-R5` |

---

## B. Re-subnetear FibraNet GT a `/25` (obligatorio — 75 hosts)

> **Motivo:** el enunciado oficial exige subredes que soporten **hasta 75 hosts**. El `/26` actual
> da 62 → **no cumple**. Las dos `/25` consumen el `/24` completo, por lo que los enlaces punto a
> punto y el servidor se mueven al bloque `192.168.48.0/16`.

### B.1 Tabla de cambios de interfaces

| Equipo | Interfaz | Dirección ACTUAL | Dirección NUEVA |
| :--- | :--- | :--- | :--- |
| **T1R1** | `g0/0` | `172.16.18.254 255.255.255.252` | `192.168.48.34 255.255.255.252` |
| **T1R1** | `g0/1` | `172.16.18.133 255.255.255.252` | `192.168.48.17 255.255.255.252` |
| **T1R1** | `g0/2` | `172.16.18.137 255.255.255.252` | `192.168.48.21 255.255.255.252` |
| **T1R2** | `g0/1` | `172.16.18.134 255.255.255.252` | `192.168.48.18 255.255.255.252` |
| **T1R2** | `g0/0` | `172.16.18.141 255.255.255.252` | `192.168.48.25 255.255.255.252` |
| **T1R3** | `g0/2` | `172.16.18.138 255.255.255.252` | `192.168.48.22 255.255.255.252` |
| **T1R3** | `g0/0` | `172.16.18.145 255.255.255.252` | `192.168.48.29 255.255.255.252` |
| **T1R4** | `g0/0` | `172.16.18.142 255.255.255.252` | `192.168.48.26 255.255.255.252` |
| **T1R4** | `g0/1` | `172.16.18.1 **255.255.255.192**` | `172.16.18.1 **255.255.255.128**` |
| **T1R5** | `g0/0` | `172.16.18.146 255.255.255.252` | `192.168.48.30 255.255.255.252` |
| **T1R5** | `g0/1` | `172.16.18.65 **255.255.255.192**` | `172.16.18.129 **255.255.255.128**` |
| **T1R5** | `g0/2` | `172.16.18.129 255.255.255.252` | `192.168.48.49 255.255.255.252` |
| **SW-BGP-FG** | `g1/0/1` | `172.16.18.253 255.255.255.252` | `192.168.48.33 255.255.255.252` |
| **SERVER DNS/HTTP/HTTPS** | NIC | `172.16.18.130` (gw `172.16.18.129`) | `192.168.48.50` (gw `192.168.48.49`, mask `255.255.255.252`) |

> ⚠️ **El `ip helper-address 172.16.28.130` NO cambia** en ninguna interfaz LAN.

### B.2 Comandos por equipo

**T1R1**
```text
enable
configure terminal
interface g0/0
 ip address 192.168.48.34 255.255.255.252
 exit
interface g0/1
 ip address 192.168.48.17 255.255.255.252
 exit
interface g0/2
 ip address 192.168.48.21 255.255.255.252
 exit
router ospf 1
 no network 172.16.18.132 0.0.0.3 area 0
 no network 172.16.18.136 0.0.0.3 area 0
 no network 172.16.18.252 0.0.0.3 area 0
 network 192.168.48.16 0.0.0.3 area 0
 network 192.168.48.20 0.0.0.3 area 0
 network 192.168.48.32 0.0.0.3 area 0
 exit
exit
write memory
```

**T1R2**
```text
enable
configure terminal
interface g0/1
 ip address 192.168.48.18 255.255.255.252
 exit
interface g0/0
 ip address 192.168.48.25 255.255.255.252
 exit
router ospf 1
 no network 172.16.18.132 0.0.0.3 area 0
 no network 172.16.18.140 0.0.0.3 area 0
 network 192.168.48.16 0.0.0.3 area 0
 network 192.168.48.24 0.0.0.3 area 0
 exit
exit
write memory
```

**T1R3**
```text
enable
configure terminal
interface g0/2
 ip address 192.168.48.22 255.255.255.252
 exit
interface g0/0
 ip address 192.168.48.29 255.255.255.252
 exit
router ospf 1
 no network 172.16.18.136 0.0.0.3 area 0
 no network 172.16.18.144 0.0.0.3 area 0
 network 192.168.48.20 0.0.0.3 area 0
 network 192.168.48.28 0.0.0.3 area 0
 exit
exit
write memory
```

**T1R4** (LAN Administración → `/25`)
```text
enable
configure terminal
interface g0/0
 ip address 192.168.48.26 255.255.255.252
 exit
interface g0/1
 ip address 172.16.18.1 255.255.255.128
 ip helper-address 172.16.28.130
 exit
router ospf 1
 no network 172.16.18.140 0.0.0.3 area 0
 no network 172.16.18.0 0.0.0.63 area 0
 network 192.168.48.24 0.0.0.3 area 0
 network 172.16.18.0 0.0.0.127 area 0
 exit
exit
write memory
```

**T1R5** (LAN Atención al Cliente → `/25` y servidor → `192.168.48.48/30`)
```text
enable
configure terminal
interface g0/0
 ip address 192.168.48.30 255.255.255.252
 exit
interface g0/1
 ip address 172.16.18.129 255.255.255.128
 ip helper-address 172.16.28.130
 exit
interface g0/2
 ip address 192.168.48.49 255.255.255.252
 exit
router ospf 1
 no network 172.16.18.144 0.0.0.3 area 0
 no network 172.16.18.64 0.0.0.63 area 0
 no network 172.16.18.128 0.0.0.3 area 0
 network 192.168.48.28 0.0.0.3 area 0
 network 192.168.48.48 0.0.0.3 area 0
 network 172.16.18.128 0.0.0.127 area 0
 exit
exit
write memory
```

**SW-BGP-FG**
```text
enable
configure terminal
interface gig1/0/1
 ip address 192.168.48.33 255.255.255.252
 exit
router ospf 1
 no network 172.16.18.252 0.0.0.3 area 0
 network 192.168.48.32 0.0.0.3 area 0
 exit
exit
write memory
```

**SERVER DNS/HTTP/HTTPS** (pestaña *Desktop → IP Configuration*)

| Campo | Valor |
| :--- | :--- |
| IP Configuration | **Static** |
| IP Address | `192.168.48.50` |
| Subnet Mask | `255.255.255.252` |
| Default Gateway | `192.168.48.49` |
| DNS Server | `192.168.48.50` |

### B.3 Pools DHCP en el servidor de AndinaCom (`172.16.28.130`)

Abre cada pool (*Services → DHCP*) y corrige la máscara y el DNS:

| Pool | Gateway | Máscara | DNS |
| :--- | :--- | :--- | :--- |
| `POOL-ADMIN-FG` | `172.16.18.1` | `255.255.255.128` | `192.168.48.50` |
| `POOL-ATC-FG` | `172.16.18.129` | `255.255.255.128` | `192.168.48.50` |
| `POOL-VENTAS-AC` | `172.16.28.1` | `255.255.255.192` | `192.168.48.50` |
| `POOL-FACTURACION-AC` | `172.16.28.65` | `255.255.255.192` | `192.168.48.50` |
| `POOL-SOPORTE-ML` | `172.16.32.1` | `255.255.255.192` | `192.168.48.50` |
| `POOL-SEGURIDAD-ML` | `172.16.32.65` | `255.255.255.192` | `192.168.48.50` |

**Muy importante:** en el servidor DNS (*Services → DNS*), la entrada
`www.proyecto2_202300848.com` debe apuntar a la **nueva** IP `192.168.48.50`.
Si estaba apuntando a `172.16.18.130`, la resolución dejará de funcionar.

### B.4 Renovar DHCP en los hosts

En **cada** PC y en la laptop: *Desktop → IP Configuration* → pasar a `Static` y volver a `DHCP`
(o apagar/encender el equipo). Verifica que reciban la IP con la máscara correcta.

---

## C. Habilitar HTTPS y verificar el dominio

1. Clic en el servidor → **Services → HTTP**.
2. Verifica que **HTTP** y **HTTPS** estén en **On**.
3. Asegúrate de que la página `index.html` contenga los datos del estudiante y la información del
   curso (el enunciado lo exige desde cualquier dispositivo).
4. Prueba desde una PC de **cada** ISP:
   - `http://www.proyecto2_202300848.com`
   - `https://www.proyecto2_202300848.com`

---

## D. `no auto-summary` en EIGRP (MoonLink)

Aplica en **CF-R1, CF-R2, CF-R3, CF-R4, CF-R5 y SW-BGP-ML**:

```text
enable
configure terminal
router eigrp 10
 no auto-summary
 exit
exit
write memory
```

Verifica que las rutas se anuncien como `/26` y `/27` y no como `172.16.0.0/16`:

```text
show ip route eigrp
show ip protocols
```

---

## E. Implementar las ACLs

Copia las ACLs desde [`scripts/ACLs/`](scripts/ACLs/) en cada equipo. Resumen de aplicación:

| Equipo | Interfaz | Sentido | ACL |
| :--- | :--- | :--- | :--- |
| `T1R4` | `g0/1` | in | `ACL_ADMIN_IN` |
| `T1R5` | `g0/1` | in | `ACL_ATC_IN` |
| `RN-R3` y `RN-R4` | `g0/1` | in | `ACL_VENTAS_IN` |
| `RN-R3` y `RN-R4` | `g0/2` | in | `ACL_FACTURACION_IN` |
| `CF-R2` | `g0/1` | in | `ACL_SOPORTE_IN` |
| `CF-R3` | `g0/1` | in | `ACL_SEGURIDAD_IN` |

> ⚠️ **Las direcciones de red cambiaron en FibraNet GT.** Si ya tenías ACLs aplicadas en `T1R4` y
> `T1R5`, sus wildcards deben actualizarse de `0.0.0.63` a **`0.0.0.127`**, y el origen de Atención
> al Cliente pasa de `172.16.18.64 0.0.0.63` a **`172.16.18.128 0.0.0.127`**.

Al terminar cada ACL, verifica:

```text
show ip access-lists
show ip interface g0/1 | include access group
```

---

## F. Verificación final en Packet Tracer

Ejecuta esta secuencia y **captura pantalla** de cada resultado (son evidencia para el manual):

```text
! En los 3 switches de borde
show ip bgp summary                 ! 2 vecinos, contadores avanzando

! FibraNet GT y AndinaCom
show ip ospf neighbor               ! todos en FULL

! MoonLink
show ip eigrp neighbors             ! todos en UP
show ip route eigrp                 ! prefijos /26 y /27, no 172.16.0.0/16

! AndinaCom
show standby brief                  ! uno Active, otro Standby

! Todos los switches de acceso
show etherchannel summary           ! grupos "SU" con 2 puertos
```

Pruebas de conectividad mínimas:

1. Ping de una PC de **cada** departamento al servidor `192.168.48.50` → ✅
2. Ping cruzado entre los tres ISPs → ✅
3. Abrir `http://` y `https://www.proyecto2_202300848.com` desde cada ISP → ✅
4. Ejecutar la matriz completa de [`scripts/ACLs/MATRIZ_PRUEBAS.md`](scripts/ACLs/MATRIZ_PRUEBAS.md)

---

## G. Volver a tomar las capturas del manual

Las imágenes en `images/` muestran las etiquetas viejas y el direccionamiento `/26`. Después de
los cambios hay que **reemplazarlas**:

| Archivo | Contenido a capturar |
| :--- | :--- |
| `images/image.png` | Topología completa (con FibraNet GT / AndinaCom / MoonLink) |
| `images/image1.png` | FibraNet GT |
| `images/image2.png` | AndinaCom |
| `images/image3.png` | MoonLink |
| `images/image4.png` | `show ip bgp summary` de los 3 switches |
| `images/image5.png` … `image10.png` | Matrices de pruebas de ACLs actualizadas |
| *(nuevas)* | `show standby brief`, `show etherchannel summary`, `show ip ospf neighbor` |
| *(nuevas)* | Navegador con `https://www.proyecto2_202300848.com` |
| *(nuevas)* | Capturas del análisis en modo simulación (DHCP DORA, DNS, BGP) |

---

## H. Confirmación final

| Cambio | ¿Hecho? |
| :--- | :--- |
| A. Renombrado de los 3 switches de borde a FibraNet GT / AndinaCom / MoonLink | ⬜ |
| A.2 Etiqueta del servidor con HTTPS | ⬜ |
| B. Re-subneteo de FibraNet GT a `/25` (12 interfaces + OSPF) | ⬜ |
| B.3 Pools DHCP con máscara `/25` y DNS `192.168.48.50` | ⬜ |
| B.3 Entrada DNS del dominio apuntando a `192.168.48.50` | ⬜ |
| B.4 Hosts renovados por DHCP | ⬜ |
| C. HTTPS habilitado y probado desde los 3 ISPs | ⬜ |
| D. `no auto-summary` en los 6 equipos de MoonLink | ⬜ |
| E. Las 6 ACLs aplicadas con la interfaz y sentido correctos | ⬜ |
| F. Verificación de BGP/OSPF/EIGRP/HSRP/LACP | ⬜ |
| G. Capturas del manual actualizadas | ⬜ |
| G. `git add` + `git commit` de todos los cambios | ⬜ |
