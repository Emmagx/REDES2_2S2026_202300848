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

Abre cada pool (*Services → DHCP*) y corrige la máscara, el DNS **y el Start IP**:

| Pool | Default Gateway | Start IP | Máscara | Max User | DNS |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `Pool Admin (FG)` | `172.16.18.1` | `172.16.18.2` | `255.255.255.128` | 75 | `192.168.48.50` |
| `Pool AC (FG)` | `172.16.18.129` | `172.16.18.130` | `255.255.255.128` | 62 | `192.168.48.50` |
| `Pool Ventas (RN)` | `172.16.28.1` | **`172.16.28.4`** | `255.255.255.192` | 58 | `192.168.48.50` |
| `Pool Factura (RN)` | `172.16.28.65` | **`172.16.28.68`** | `255.255.255.192` | 56 | `192.168.48.50` |
| `Pool Soporte (CF)` | `172.16.32.1` | `172.16.32.2` | `255.255.255.192` | 62 | `192.168.48.50` |
| `Pool Seguridad (CF)` | `172.16.32.65` | `172.16.32.66` | `255.255.255.192` | 62 | `192.168.48.50` |

> ⚠️ **Corrección importante en Ventas y Facturación:** el *Start IP* original (`.2` y `.66`) es
> **exactamente la dirección de la interfaz `g0/1` y `g0/2` de RN-R3** (la pareja HSRP usa `.2`/`.3`
> y `.66`/`.67`). El servidor DHCP entregaría una IP que ya está en uso por un router y provocaría un
> conflicto de direcciones. Debe arrancar en `.4` y `.68` respectivamente.

> ⚠️ **Sobre `serverPool`:** su rango (`172.16.28.128/30`) contiene la IP del propio servidor DHCP
> (`.130`) y la interfaz de RN-R5 (`.129`). Deja el `serverPool` como está si el proyecto ya
> funcionaba con él, pero **no lo uses para ningún departamento**.

**Muy importante:** en el servidor DNS (*Services → DNS*), la entrada
`www.proyecto2_202300848.com` debe apuntar a la **nueva** IP `192.168.48.50`.
Si estaba apuntando a `172.16.18.130`, la resolución dejará de funcionar.

### B.4 Renovar DHCP en los hosts

En **cada** PC y en la laptop: *Desktop → IP Configuration* → pasar a `Static` y volver a `DHCP`
(o apagar/encender el equipo). Verifica que reciban la IP con la máscara correcta.

### B.5 Si el DHCP responde `Request Failed`

`Request Failed` significa que el cliente envió el `DHCP Discover` pero **nunca le llegó un `Offer`
válido**. El paquete recorre 4 eslabones; si cualquiera falla, se ve exactamente ese error.

```text
[PC] --1--> [router de acceso] --2--> [router del servidor DHCP] --3--> [SERVER-DHCP]
                                                                            |
[PC] <------4---------------------------------------------------------------+
```

**Prueba discriminante (hazla primero):** pide DHCP desde una PC de **Ventas o Facturación**
(AndinaCom, el **mismo ISP** donde vive el servidor).

| Resultado | Interpretación | Ir a |
| :--- | :--- | :--- |
| Ventas **funciona**, FibraNet GT/MoonLink **fallan** | El servidor y los pools están bien → es un problema de **rutas entre ISPs** | Paso 2 y 3 |
| Ventas **también falla** | El problema está en el **servidor, los pools o el relay de AndinaCom** | Paso 1 y 4 |

---

#### Paso 1 — ¿Existe el `ip helper-address` en el router de acceso?

En `T1R4`, `T1R5`, `RN-R3`, `RN-R4`, `CF-R2` y `CF-R3`:

```text
show ip interface g0/1
show ip interface g0/2
```

Debe aparecer `ip helper-address 172.16.28.130`. Si falta, es la causa:

```text
enable
configure terminal
interface g0/1
 ip helper-address 172.16.28.130
 exit
exit
write memory
```

Para `RN-R4` y `CF-R3` verifica también su interfaz LAN (`g0/1` y `g0/2` según el caso).

#### Paso 2 — ¿El router de acceso tiene ruta al servidor DHCP?

```text
show ip route 172.16.28.130
show ip ospf interface brief          ! la interfaz LAN (g0/1) debe aparecer AQUÍ
```

Si la interfaz LAN **no aparece** en `show ip ospf interface brief`, el problema es que el comando
`no network ...` eliminó la red vieja y el `network ...` nuevo no quedó bien escrito: sin él, OSPF no
anuncia la subred `/25`, el resto de la topología nunca la aprende y el `DHCP Offer` no puede volver.
Revisa y corrige en el router:

```text
show run | section router ospf
```

Debe contener, por ejemplo en `T1R4`:

```text
router ospf 1
 network 192.168.48.24 0.0.0.3 area 0
 network 172.16.18.0 0.0.0.127 area 0
```

Y en `T1R5`:

```text
router ospf 1
 network 192.168.48.28 0.0.0.3 area 0
 network 192.168.48.48 0.0.0.3 area 0
 network 172.16.18.128 0.0.0.127 area 0
```

##### ⚠️ Trampa de orden: `% Subnet not in table` en la propia LAN

Si en `show ip route 172.16.18.128` (ejecutado **en T1R5**) sale `% Subnet not in table`, eso es
anómalo: esa red debería aparecer como **directly connected** porque es la LAN de Atención al Cliente.
Significa que la interfaz `g0/1` **no tiene la IP nueva**.

**Causa más común: solapamiento de direcciones.** El nuevo `172.16.18.129/25` de `g0/1` se solapa con
el **viejo** `172.16.18.129/30` que tenía `g0/2` (el enlace al servidor). IOS/Packet Tracer rechaza la
asignación con un mensaje del tipo:

```text
% 172.16.18.128 overlaps with GigabitEthernet0/2
```

**El orden importa: primero hay que liberar `g0/2`, y solo después asignar `g0/1`.**

```text
enable
configure terminal

! 1) PRIMERO libera 172.16.18.129 del enlace del servidor
interface g0/2
 ip address 192.168.48.49 255.255.255.252
 exit

! 2) AHORA si asigna la LAN /25 de Atencion al Cliente
interface g0/1
 ip address 172.16.18.129 255.255.255.128
 ip helper-address 172.16.28.130
 no shutdown
 exit

! 3) Confirma que g0/0 ya esta en el bloque nuevo
interface g0/0
 ip address 192.168.48.30 255.255.255.252
 no shutdown
 exit

router ospf 1
 network 192.168.48.28 0.0.0.3 area 0
 network 192.168.48.48 0.0.0.3 area 0
 network 172.16.18.128 0.0.0.127 area 0
 exit
exit
write memory
```

**Verificación (las tres deben pasar):**

```text
show ip interface brief            ! g0/1 = 172.16.18.129, up/up
show ip route 172.16.18.128        ! "directly connected, GigabitEthernet0/1"
show ip ospf interface brief       ! g0/1 presente en area 0
```

> **Por qué el DHCP falla solo en ese departamento:** mientras `g0/1` conserve la IP vieja
> (`172.16.18.65`), el `giaddr` que T1R5 manda al servidor es el viejo. Ningún pool coincide con esa
> `giaddr` (o coincide con el pool equivocado), así que el `Offer` vuelve con una dirección de la
> subred de Administración y el cliente lo rechaza → **`Request Failed`**. Administración funciona
> porque `T1R4` sí quedó bien renumerado.

Si `show ip route 172.16.28.130` responde `% Network not in table`, el paquete relayado nunca sale del
router. La redistribución entre el protocolo interno y BGP está incompleta. En el **switch multicapa
del ISP afectado**:

```text
! FibraNet GT (AS 100)
enable
configure terminal
router ospf 1
 redistribute bgp 100 subnets
 exit
exit
write memory
```

```text
! AndinaCom (AS 200)
router ospf 1
 redistribute bgp 200 subnets
 exit
```

```text
! MoonLink (AS 300) — EIGRP exige métrica explícita
router eigrp 10
 redistribute bgp 300 metric 10000 100 255 1 1500
 exit
```

> El parámetro **`subnets`** es obligatorio al redistribuir OSPF. Sin él, Cisco IOS solo redistribuye
> redes **con clase** (`172.16.0.0/16`) y las subredes `/25` y `/26` **no se anuncian**, con lo que el
> servidor DHCP no puede responder a las LAN de los departamentos.

#### Paso 3 — ¿El servidor DHCP tiene ruta de vuelta a las nuevas `/25`? ⭐ *causa más probable*

El `DHCP Offer` se envía a la **`giaddr`** (la IP de la interfaz LAN del router que relayó, por
ejemplo `172.16.18.1`). El servidor DHCP **necesita una ruta hacia esa subred**. Como el
direccionamiento de FibraNet GT acaba de cambiar de `/26` a `/25`, esta es la verificación clave:

En **`RN-R5`** (el router del servidor DHCP):

```text
show ip route 172.16.18.0
show ip route 172.16.18.128
```

Deben aparecer como `172.16.18.0/25` y `172.16.18.128/25`. Si no aparecen (o aparecen como `/26`,
que son las rutas viejas), aplica el Paso 2 en **`SW-BGP-AC`**.

Adicionalmente, en **`SW-BGP-FG`** debe existir la redistribución en el sentido contrario para que
FibraNet GT conozca la red del servidor:

```text
router ospf 1
 redistribute bgp 100 subnets
 exit
```

Y en cada router de borde, la redistribución del protocolo interno hacia BGP **con `subnets`**:

```text
router bgp 100
 redistribute ospf 1 subnets
 exit
```

#### Paso 4 — ¿Una ACL vieja está bloqueando UDP 67/68?

Las ACLs del proyecto original siguen aplicadas y fueron escritas para las subredes `/26` viejas.
Para aislar el problema, quítala temporalmente de la interfaz LAN (usa el nombre real que te devuelva
`show ip access-lists`: `ATC_IN`, `VENTAS_IN`, `FAC_IN` o `SEC_OUT`):

```text
enable
configure terminal
interface g0/1
 no ip access-group ATC_IN in
 exit
exit
```

Pide DHCP de nuevo. **Si ahora funciona, la ACL es la culpable**: le falta el permiso genérico de
DHCP o tiene wildcards viejos. Vuelve a aplicarla ya corregida (paso E) y asegúrate de que incluya,
antes del `deny ip any any`:

```text
permit udp any any eq 67
permit udp any any eq 68
```

> El `Discover` se envía desde `0.0.0.0` hacia `255.255.255.255`. Cualquier regla de ACL que
> especifique la IP del cliente o del servidor en lugar de `any any` **no hace match** y el paquete
> cae en el `deny` implícito.

#### Paso 5 — Convergencia y renovación en el cliente

1. Botón **Fast Forward Time (>>)** unas 10 veces.
2. En la PC: *Desktop → IP Configuration* → `Static` → `DHCP`.
3. Si sigue fallando, apaga y enciende la PC (en PT a veces hay que forzar el reenvío).
4. Manda un `ping` desde el router de acceso hacia la PC una vez que tenga IP.

#### Cómo pedir ayuda con datos concretos

Ejecuta y reporta estos tres resultados: es el 90% del diagnóstico.

```text
! En el router de acceso del departamento que falla
show ip route 172.16.28.130
show ip interface g0/1

! En RN-R5
show ip route 172.16.18.0
show ip route 172.16.18.128
```

---

### B.6 Si el ping al servidor falla desde TODOS los departamentos

**La pista decisiva:** Administración (`T1R4`) y Soporte (`CF-R2`) **no tienen ninguna ACL**. Si el
ping al servidor falla también desde ellos, entonces **el problema no son las ACLs**: el paquete no
llega al servidor o el servidor no puede responder.

El servidor cuelga de **`T1R5 g0/2`** (`192.168.48.48/30`). Cualquier fallo en ese punto afecta a
**todos** los departamentos por igual.

#### Paso 1 — ¿Hay un ACL aplicado en la interfaz equivocada de T1R5? ⭐

Este es el error más probable al reaplicar una ACL: aplicarla en `g0/0` o `g0/2` en lugar de `g0/1`.
Si `ATC_IN` queda en `g0/0` de T1R5, **todo** el tráfico que va hacia el servidor desde cualquier ISP
cae en su `deny ip any any`.

```text
show ip interface g0/0
show ip interface g0/1
show ip interface g0/2
```

Lo correcto en `T1R5` es:

| Interfaz | Debe tener |
| :--- | :--- |
| `g0/0` | **sin** `ip access-group` |
| `g0/1` | `ip access-group ATC_IN in` |
| `g0/2` | **sin** `ip access-group` |

Si hay un ACL en `g0/0` o `g0/2`, quítalo:

```text
interface g0/0
 no ip access-group ATC_IN in
 no ip access-group ATC_IN out
 exit
```

#### Paso 2 — ¿Está bien numerado el enlace del servidor?

```text
show ip interface brief
```

En `T1R5`: `g0/2` debe decir **`192.168.48.49`** con estado **`up up`**.
En el servidor (`Desktop → IP Configuration`): `192.168.48.50`, máscara `255.255.255.252`,
gateway `192.168.48.49`.

Y en `T1R5`:

```text
show ip route 192.168.48.48
```

Debe decir `directly connected, GigabitEthernet0/2` (`192.168.48.48/30`). Si no aparece, la interfaz
no tiene la IP nueva (o está caída).

#### Paso 3 — ¿Tienen los hosts direccionamiento?

Si el PDU muestra **`Time 0.000`**, el paquete se descartó de inmediato: normalmente significa que el
**origen no tiene IP ni gateway**. En la PC de Administración:

```text
ipconfig /all
ping 172.16.18.1        ! su gateway: debe responder
ping 192.168.48.50      ! el servidor
```

Si `ipconfig` muestra `169.254.x.x`, la PC perdió el DHCP y el problema es el paso B.4/B.5, no el
servidor. Recupera con `Static` → `DHCP`.

#### Paso 4 — Prueba desde el propio router del servidor

```text
! En T1R5
ping 192.168.48.50
```

- **Responde** → el servidor está bien y el problema está más arriba (ruteo hacia él o ACLs mal
  aplicadas).
- **No responde** → el problema es el enlace/la configuración del servidor (Paso 2).

#### Resumen de la lógica de diagnóstico

| Síntoma | Conclusión |
| :--- | :--- |
| Falla solo en departamentos **con** ACL | Es la ACL de ese departamento |
| Falla en **todos**, incluso Admin y Soporte (sin ACL) | El problema es el **camino al servidor** (`T1R5 g0/2`) o una **ACL mal aplicada** en una interfaz troncal |
| Falla solo el **HTTP/HTTPS** pero el ping funciona | Es la ACL (falta `permit ip any 192.168.48.48 0.0.0.3`) |
| Falla solo la **resolución del dominio** (carga por IP pero no por nombre) | Es **DNS**: la PC tiene un DNS viejo → renovar el arrendamiento |

---

### B.7 Verificación del direccionamiento de FibraNet GT (tabla de chequeo)

Si un router del **núcleo** de FibraNet GT se queda sin renumerar, se rompe el árbol de OSPF y los
síntomas son engañosos: *"alcanzo el router de borde pero no los routers internos"*.

Ejecuta **`show ip interface brief`** en cada equipo y compara con esta tabla:

| Equipo | Interfaz | IP esperada | Para qué sirve |
| :--- | :--- | :--- | :--- |
| **T1R1** | `g0/0` | `192.168.48.34/30` | Enlace al switch de borde `SW-BGP-FG` |
| **T1R1** | `g0/1` | `192.168.48.17/30` | Enlace a `T1R2` |
| **T1R1** | `g0/2` | `192.168.48.21/30` | Enlace a `T1R3` |
| **T1R2** | `g0/0` | `192.168.48.25/30` | Enlace a `T1R4` |
| **T1R2** | `g0/1` | `192.168.48.18/30` | Enlace a `T1R1` |
| **T1R3** | `g0/0` | `192.168.48.29/30` | Enlace a `T1R5` |
| **T1R3** | `g0/2` | `192.168.48.22/30` | Enlace a `T1R1` |
| **T1R4** | `g0/0` | `192.168.48.26/30` | Enlace a `T1R2` |
| **T1R4** | `g0/1` | `172.16.18.1/25` | LAN Administración |
| **T1R5** | `g0/0` | `192.168.48.30/30` | Enlace a `T1R3` |
| **T1R5** | `g0/1` | `172.16.18.129/25` | LAN Atención al Cliente |
| **T1R5** | `g0/2` | `192.168.48.49/30` | Servidor DNS/HTTP/HTTPS |
| **SW-BGP-FG** | `g1/1/1` | `192.168.48.1/30` | Enlace a AndinaCom |
| **SW-BGP-FG** | `g1/1/2` | `192.168.48.9/30` | Enlace a MoonLink |
| **SW-BGP-FG** | `g1/0/1` | `192.168.48.33/30` | Enlace a `T1R1` |

Y el OSPF de cada router de FibraNet GT:

| Equipo | Statements `network` esperados |
| :--- | :--- |
| `T1R1` | `192.168.48.16 0.0.0.3` · `192.168.48.20 0.0.0.3` · `192.168.48.32 0.0.0.3` |
| `T1R2` | `192.168.48.16 0.0.0.3` · `192.168.48.24 0.0.0.3` |
| `T1R3` | `192.168.48.20 0.0.0.3` · `192.168.48.28 0.0.0.3` |
| `T1R4` | `192.168.48.24 0.0.0.3` · `172.16.18.0 0.0.0.127` |
| `T1R5` | `192.168.48.28 0.0.0.3` · `192.168.48.48 0.0.0.3` · `172.16.18.128 0.0.0.127` |
| `SW-BGP-FG` | `192.168.48.32 0.0.0.3` |

**Síntoma típico de un router del núcleo sin renumerar:**

| Prueba | Resultado |
| :--- | :--- |
| Desde `RN-R3`: `ping` al switch de borde y a **T1R1** | ✅ Funciona (van por el bloque `192.168.48.0/16`) |
| Desde `RN-R3`: `ping` a **T1R3** y **T1R4** | 🚫 Falla (T1R1 no tiene ruta hacia ellos) |
| Desde un PC de ATC: carga la página del servidor | ✅ Funciona (no necesita pasar por T1R1) |
| Desde Admin / Soporte / Ventas / Facturación: ping al servidor | 🚫 Falla (su ruta **sí** atraviesa T1R1) |

Ese es exactamente el patrón que delata a **T1R1** sin renumerar.

**Corrección de T1R1:**

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

**Verificación después de corregir:**

```text
! En T1R1
show ip ospf neighbor          ! deben aparecer T1R2 y T1R3 (y SW-BGP-FG)
show ip route 172.16.28.0      ! ruta hacia AndinaCom (aprendida por BGP→OSPF)

! En RN-R3
ping 192.168.48.29             ! T1R3
ping 192.168.48.26             ! T1R4

! En la PC de Administracion
ping 192.168.48.50             ! el servidor
```

---

### B.8 OSPF: vecino ausente o "flapping"

Dos síntomas distintos que se ven en `show ip ospf neighbor` y en la consola:

#### 1. Un vecino que **no aparece** en la lista

Casi siempre significa que el enlace no está en OSPF. Causas, en orden de probabilidad:

1. **IP mal numerada en uno de los dos extremos** (lo más común después de renumerar: se actualiza un
   router y se olvida el otro).
2. **Falta el `network` de OSPF** que cubre esa interfaz.
3. La interfaz está en `shutdown` o el cable está desconectado.
4. La interfaz quedó como `passive-interface`.

Diagnóstico:

```text
show ip interface brief          ! IP y estado up/up de ambos extremos
show ip ospf interface brief     ! en que area y en que interfaces corre OSPF
show ip ospf interface g0/2      ! detalle: area, timers, tipo de red
```

#### 2. Un vecino que **flapea** (`FULL → DOWN → LOADING → FULL` cada 40 s)

| Mensaje | Significado |
| :--- | :--- |
| `Neighbor Down: Dead timer expired` | Dejaron de llegar los *Hello* durante 40 s (4 × 10 s) |
| `Neighbor Down: Interface down or detached` | La interfaz (local o del vecino) se cayó |
| `from LOADING to FULL, Loading Done` | El vecino se volvió a establecer |

Causas típicas:

1. **Estado OSPF obsoleto tras cambiar direcciones IP** — es el caso más frecuente en Packet Tracer
   después de renumerar. Se arregla reiniciando el proceso:
   ```text
   enable
   clear ip ospf process
   ! responder "yes"
   ```
   Hacerlo en **ambos** extremos del enlace.
2. **Router-ID duplicado** en el dominio OSPF.
3. **IP duplicada** en el enlace.
4. Inestabilidad física (cable/interfaz).

##### Cuando la configuración está bien y aun así no hay vecinos

Si ya verificaste **las tres cosas** y todas están correctas:

| Verificación | Comando | Resultado esperado |
| :--- | :--- | :--- |
| IP correcta y `up/up` en ambos extremos | `show ip interface brief` | `192.168.48.21` y `192.168.48.22`, `up up` |
| OSPF corriendo en la interfaz | `show ip ospf interface brief` | la interfaz aparece en `Area 0` |
| `network` que cubre la interfaz | `show run \| section router ospf` | `network 192.168.48.20 0.0.0.3 area 0` |
| Cable en el puerto correcto | `show cdp neighbors` | el vecino correcto en la interfaz correcta |
| Sin ACL filtrando | `show ip interface g0/2` | `Inbound access list is not set` |

…entonces **no es un problema de configuración: es estado atascado de Packet Tracer**. Al cambiar
direcciones IP con el protocolo corriendo, PT a veces no reconstruye las adyacencias.

**Remedio, en este orden (de menos a más invasivo):**

```text
! 1) Bajar y volver a subir las interfaces del enlace (fuerza a PT a rehacer el L2)
configure terminal
interface g0/2
 shutdown
 exit
! esperar unos segundos
interface g0/2
 no shutdown
 exit
exit
```

```text
! 2) Reiniciar el proceso OSPF en los dos extremos
clear ip ospf process        ! responder "yes"
```

```text
! 3) Rehacer el cable: selecciona el rayo de borrar, elimina el enlace
!    T1R1 g0/2 <-> T1R3 g0/2 y vuelve a tenderlo (cable directo de cobre)
```

```text
! 4) Ultimo recurso: reiniciar el router desde la pestana Physical
!    (boton de encendido del equipo). Limpia todo el estado OSPF.
```

> **Señal de alarma:** si `show cdp neighbors` muestra el vecino en **un solo lado** (T1R3 ve a T1R1,
> pero T1R1 no ve a T1R3), el enlace quedó en un estado **asimétrico**: no es configuración, es el
> cable o la interfaz. Aplica el paso 3.

> **Buena práctica que además evita el punto 2:** fijar un **router-id explícito y único** en cada
> router. Al renumerar, el router-id auto-electo se queda con la IP **vieja** (por ejemplo `T1R4`
> conserva `172.16.18.142`), lo que confunde al leer `show ip route` y puede provocar colisiones.
>
> ```text
> ! En cada router, con un ID distinto y estable
> router ospf 1
>  router-id 1.1.1.1        ! T1R1 -> 1.1.1.1, T1R2 -> 1.1.1.2, T1R3 -> 1.1.1.3,
>  exit                     ! T1R4 -> 1.1.1.4, T1R5 -> 1.1.1.5, SW-BGP-FG -> 1.1.1.100
> clear ip ospf process      ! responder "yes" para que tome el nuevo router-id
> ```

#### 3. Cómo leer un `Destination host unreachable` en un ping

```text
C:\>ping 192.168.48.50
Reply from 172.16.18.1: Destination host unreachable.
```

Ese mensaje **no** lo genera el servidor: lo genera **el gateway del PC** (`172.16.18.1` = `T1R4`)
cuando **no tiene ruta** hacia `192.168.48.50`. Es una prueba directa de que:

- El problema es de **enrutamiento**, no de ACL ni del servidor.
- El PC y su gateway funcionan (el gateway responde).
- `T1R4` no conoce `192.168.48.48/30`, es decir, **el árbol de OSPF está cortado en algún punto
  intermedio de FibraNet GT**.

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

## E. ACLs — inventario real y correcciones

### E.1 Inventario: qué ACL existe hoy en cada equipo

Obtenido de `show ip access-lists` en el `.pkt` (14/10/2026):

| Router | ACL(s) configuradas | Departamento dueño | Interfaz / sentido | Estado |
| :--- | :--- | :--- | :--- | :--- |
| `T1R4` | **ninguna** | Administración | — | ✅ intencional (regla "habla con todos") |
| `T1R5` | `ATC_IN` | Atención al Cliente | `g0/1` **in** | ⚠️ requiere corrección |
| `RN-R3` | `VENTAS_IN` (`g0/1` in) · `FAC_IN` (`g0/2` in) | Ventas y Facturación | ver ACL | ⚠️ requiere corrección |
| `RN-R4` | `VENTAS_IN` (`g0/1` in) · `FAC_IN` (`g0/2` in) | Ventas y Facturación | ver ACL | ⚠️ requiere corrección |
| `CF-R2` | **ninguna** | Soporte | — | ✅ intencional (regla "habla con todos") |
| `CF-R3` | `SEC_OUT` | Seguridad | `g0/1` **out** (protege la entrada a Seguridad) | ⚠️ requiere corrección |

> **Nota sobre los comandos de verificación en Packet Tracer:**
> - `show ip interface g0/1` **sí** funciona y muestra la línea `Inbound access list ATC_IN`.
> - `show run interface g0/1` **no existe** en PT (devuelve `% Invalid input`).
> - `show ip interface g0/1 | include access group` devuelve vacío, porque PT escribe
>   `Inbound access list ...` (no "access group").
>
> ```text
> show ip interface g0/1
> show ip interface g0/2
> ```

### E.2 El problema: las ACLs siguen apuntando al servidor VIEJO

En **cuatro** ACLs el permiso de DNS y HTTP apunta a `172.16.18.130`, que era la IP del servidor
**antes** de moverlo a `192.168.48.50`. Como esas ACLs terminan en `deny ip any any`, el resultado es:

- **DNS** (`UDP 53`) hacia `192.168.48.50` → 🚫 bloqueado
- **HTTP** (`TCP 80`) hacia `192.168.48.50` → 🚫 bloqueado
- **HTTPS** (`TCP 443`) → 🚫 bloqueado (ni siquiera existía el permiso)
- **ICMP hacia el servidor** → 🚫 bloqueado (solo se permitía `echo-reply`, es decir, la respuesta a
  los ping que el departamento inicia, no el ping hacia el servidor)

Ese es exactamente el síntoma: *"tengo ping a todos lados pero no me carga la página"*.

Las líneas culpables son:

| ACL | Líneas | Contenido actual |
| :--- | :--- | :--- |
| `ATC_IN` (T1R5) | 40, 50 | `permit udp any host 172.16.18.130 eq domain` · `permit tcp any host 172.16.18.130 eq www` |
| `VENTAS_IN` (RN-R3/R4) | 60, 70 | idem |
| `FAC_IN` (RN-R3/R4) | 60, 70 | idem |
| `SEC_OUT` (CF-R3) | 30 | `permit udp host 172.16.18.130 eq domain any` |

### E.3 Tres correcciones adicionales que hay que hacer en el mismo paso

1. **Permiso hacia el servidor (recurso compartido).** Ninguna ACL permitía llegar al servidor. Hay
   que agregar **una sola línea** que autorice el segmento completo del servidor
   (`192.168.48.48/30`, donde vive `192.168.48.50`):

   ```text
   permit ip any 192.168.48.48 0.0.0.3
   ```

   Esta línea cubre **DNS (UDP 53), HTTP (TCP 80), HTTPS (TCP 443) e ICMP**, es decir, también permite
   que los departamentos hagan **ping al servidor** — necesario para las demostraciones y para las
   capturas del manual. Sustituye a los tres permisos `host 192.168.48.50` que se habían propuesto.
2. **`VENTAS_IN` quedó roto para Atención al Cliente.** Su línea 110 dice
   `permit ip any 172.16.18.64 0.0.0.63`, que era la subred **vieja** de ATC. Con el rediseño a `/25`,
   Atención al Cliente se movió a `172.16.18.128/25`, así que **Ventas ↔ ATC ya no se permite**.
   Debe pasar a `172.16.18.128 0.0.0.127`.
3. **Wildcards de Administración desactualizados.** `permit ip any 172.16.18.0 0.0.0.63` solo cubre
   la primera mitad del `/25`; debe ser `0.0.0.127`.

### E.4 Configuración corregida (lista para pegar)

**`T1R5` — Atención al Cliente**

```text
enable
configure terminal
no ip access-list extended ATC_IN
ip access-list extended ATC_IN
 permit ospf any any
 permit udp any any eq bootpc
 permit udp any any eq bootps
 permit ip any 192.168.48.48 0.0.0.3
 permit tcp any any established
 permit icmp any any echo-reply
 permit ip any 172.16.28.0 0.0.0.63
 permit ip any 172.16.32.0 0.0.0.63
 permit ip any 172.16.18.0 0.0.0.127
 deny ip any any
 exit
interface g0/1
 ip access-group ATC_IN in
 exit
exit
write memory
```

**`RN-R3` y `RN-R4` — Ventas**

```text
enable
configure terminal
no ip access-list extended VENTAS_IN
ip access-list extended VENTAS_IN
 permit ospf any any
 permit udp any any eq 1985
 permit udp any any eq 2029
 permit udp any any eq bootpc
 permit udp any any eq bootps
 permit ip any 192.168.48.48 0.0.0.3
 permit tcp any any established
 permit icmp any any echo-reply
 permit ip any 172.16.28.64 0.0.0.63
 permit ip any 172.16.18.128 0.0.0.127
 permit ip any 172.16.32.0 0.0.0.63
 permit ip any 172.16.18.0 0.0.0.127
 deny ip any any
 exit
interface g0/1
 ip access-group VENTAS_IN in
 exit
exit
write memory
```

**`RN-R3` y `RN-R4` — Facturación**

```text
enable
configure terminal
no ip access-list extended FAC_IN
ip access-list extended FAC_IN
 permit ospf any any
 permit udp any any eq 1985
 permit udp any any eq 2029
 permit udp any any eq bootpc
 permit udp any any eq bootps
 permit ip any 192.168.48.48 0.0.0.3
 permit tcp any any established
 permit icmp any any echo-reply
 permit ip any 172.16.28.0 0.0.0.63
 permit ip any 172.16.32.0 0.0.0.63
 permit ip any 172.16.18.0 0.0.0.127
 deny ip any any
 exit
interface g0/2
 ip access-group FAC_IN in
 exit
exit
write memory
```

> ⚠️ **`FAC_IN` NO debe llevar el permiso hacia `172.16.18.128/25` (ATC)**, porque la regla del
> enunciado dice que Facturación → Atención al Cliente está **bloqueado**. Tampoco debe permitir
> `172.16.32.64/26` (Seguridad).

**`CF-R3` — Seguridad**

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

> `SEC_OUT` es una ACL de **retorno**: permite únicamente las respuestas (DNS desde el servidor, TCP
> establecido, `echo-reply`). Va aplicada en sentido **`out`** sobre la interfaz LAN de Seguridad, que
> es lo que bloquea "cualquier depto → Seguridad" sin romper "Seguridad → cualquiera".

### E.5 Verificación

```text
show ip access-lists
show ip interface g0/1
```

Debe desaparecer `172.16.18.130` de todas las ACLs y aparecer `192.168.48.50`.

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
