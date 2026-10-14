# Comparación: `[RC2] Enunciado Proyecto 2.pdf` (versión que usaste) vs `975_Proyecto_2_2S2026.pdf` (versión oficial)

> Documento de trabajo. **No es entregable del proyecto**: puedes borrarlo antes de la entrega final.
> Fecha del análisis: 14/10/2026 · Entrega oficial: **23/10/2026** · Calificación: **24/10/2026** (quedan 9 días).

---

## 0. Conclusión corta (lo más importante)

Tu proyecto **sí cumple la mayor parte** de la estructura (topologías, 5 routers/5 hosts por ISP, 2 LACP por ISP, HSRP, DHCP central, DNS/HTTP, wireless, BGP).

Pero **"solo cambiar los nombres" NO es suficiente**. Hay 3 cambios que sí afectan la nota:

| # | Hallazgo | Tipo | Impacto |
| :- | :--- | :--- | :--- |
| 1 | ISP 1 debe subnetearse para soportar **hasta 75 hosts por departamento** (tú usaste `/26` = 62) → hay que re-diseñar el subneteo de FibraNet GT | 🔴 Técnico obligatorio | Rúbrica 2.1 (**12 pts**) |
| 2 | **Sección 4.5 Wireshark es nueva** (máquina virtual + 4 escenarios + `.pcapng`) | 🔴 Obligatorio | Rúbrica 1.3 (**14 pts**) y además es **requisito para optar a calificación** (si falta → 0) |
| 3 | Renombrado de ISPs (lo que ya sabías) | 🟡 Cosmético pero visible | Presentación, manual, `.pkt` |

Además hay 4 huecos que la rúbrica oficial ahora sí califica y hoy no están cubiertos:
**justificación de ACLs (interfaz + in/out)**, **lista de precios en la presentación**,
**análisis en modo simulación**, y **commits de Git pendientes**.

---

## 0.1 Estado de aplicación (14/10/2026)

| Cambio | Estado | Dónde quedó |
| :--- | :--- | :--- |
| Renombrado de ISPs en la documentación y carpetas | ✅ **hecho** | `README.md`, `guia_presentacion.md`, `scripts/**`, `notas` |
| Renombrado de los 3 switches de borde dentro del `.pkt` | ⬜ pendiente (manual en PT) | [`PACKET_TRACER_CAMBIOS.md`](PACKET_TRACER_CAMBIOS.md) §A |
| Re-subneteo de FibraNet GT a `/25` en la documentación y scripts | ✅ **hecho** | `README.md` §2, `scripts/FibraNet_GT/*`, `scripts/BGP/Multicapa_FibraNet_GT.md` |
| Re-subneteo de FibraNet GT a `/25` dentro del `.pkt` | ⬜ pendiente (manual en PT) | [`PACKET_TRACER_CAMBIOS.md`](PACKET_TRACER_CAMBIOS.md) §B |
| ACLs documentadas + justificación interfaz/sentido + matriz de pruebas | ✅ **hecho** | `scripts/ACLs/` |
| ACLs aplicadas/verificadas dentro del `.pkt` | ⬜ pendiente (manual en PT) | [`PACKET_TRACER_CAMBIOS.md`](PACKET_TRACER_CAMBIOS.md) §E |
| `no auto-summary` documentado en los 6 equipos de MoonLink | ✅ **hecho** | `scripts/MoonLink/*`, `scripts/BGP/Multicapa_MoonLink.md` |
| Guion del análisis en modo simulación | ✅ **hecho** | `guia_presentacion.md` §3 |
| Kit de Wireshark (script + plantilla de análisis + instrucciones de VM) | ✅ **hecho** | `Wireshark/` |
| Generar el `.pcapng` real dentro de la VM | ⬜ pendiente | `Wireshark/README.md` |
| Slides de dispositivos y lista de precios en la presentación | ⬜ pendiente | `guia_presentacion.md` §5 |
| Capturas del manual actualizadas y commits en Git | ⬜ pendiente | [`PACKET_TRACER_CAMBIOS.md`](PACKET_TRACER_CAMBIOS.md) §G |

> Recuerda: los cambios en el `.pkt` **no se pueden automatizar** (el archivo está cifrado); hay que
> aplicarlos a mano en la GUI de Packet Tracer siguiendo `PACKET_TRACER_CAMBIOS.md`.

---

## 1. Mapa de renombrado de ISPs

| Enunciado RC2 (lo que usaste) | Enunciado oficial 975 | Abreviatura actual en tu proyecto |
| :--- | :--- | :--- |
| Telecom Uno | **FibraNet GT** | `T1` (`T1R1`…`T1R5`, `T1S1-ADMIN`…) |
| Redes Nacionales | **AndinaCom** | `RN` (`RN-R1`…`RN-R5`) |
| Conexiones Futuras ***o*** Link Global *(el propio RC2 se contradecía: el título decía "Link Global" y las secciones "Conexiones Futuras")* | **MoonLink** | `CF` (`CF-R1`…`CF-R5`) |

**Importante:** los **departamentos NO cambian** (Administración, Atención al cliente, Ventas, Facturación, Soporte, Seguridad).
Los **números de red asignados tampoco cambian** (`172.16.1X.0/24`, `2X`, `3X` y `192.168.XX.0/16`) — ya están correctos: `172.16.18.0/24`, `172.16.28.0/24`, `172.16.32.0/24`, `192.168.48.0/16`. ✅

### Dónde hay que renombrar (`grep` ya hecho)

| Ubicación | Ocurrencias | Acción |
| :--- | :--- | :--- |
| `README.md` | 14 líneas (4, 25–31, 37–39, 44, 52, 60, 70) | Reemplazo de texto |
| `guia_presentacion.md` | 3 líneas (15, 22, 25) | Reemplazo de texto |
| `scripts/BGP/Multicapa_TelecomUno.md` | 4 (incluye comentarios y el título) | Reemplazo + renombrar archivo |
| `scripts/BGP/Multicapa_RedesNacionales.md` | 3 | Reemplazo + renombrar archivo |
| `scripts/BGP/Multicapa_ConexionesFuturas.md` | 3 | Reemplazo + renombrar archivo |
| Carpetas `scripts/Telecom_Uno/`, `scripts/Redes_Nacionales/`, `scripts/Conexiones_Futuras/` | 3 carpetas | `git mv` a `FibraNet_GT/`, `AndinaCom/`, `MoonLink/` |
| `Proyecto2_Presentacion_202300848.pdf` | Slides "Telecom Uno", "Redes Nacionales", "Conexiones Futuras" | Regenerar el PDF |
| `Proyecto2_202300848.pkt` | 🔴 Etiquetas de los 3 switch multicapa 3650-24PS: **"Telecom uno"**, **"Redes Nacionales"**, **"Link Global"** (se ven en `images/image1.png`, `image2.png`, `image3.png`) | Renombrar en la GUI de Packet Tracer (el `.pkt` está cifrado, no se puede editar con script) |
| `images/*.png` | Todas las capturas muestran las etiquetas viejas | Volver a capturar después del renombrado |

**Recomendación adicional (no obligatoria, pero sí evaluada por coherencia):** renombrar también los *hostnames* internos
(`T1R1`→`FG-R1`, `RN-R1`→`AC-R1`, `CF-R1`→`ML-R1`) y las etiquetas de PCs. Si no quieres tocar el `.pkt` más de lo necesario,
como mínimo cambia **los 3 switches de borde** y las etiquetas de los ISP en el mapa lógico; el manual puede aclarar la equivalencia.

---

## 2. 🔴 CAMBIO TÉCNICO OBLIGATORIO: subneteo de ISP 1 (FibraNet GT)

### Qué dice cada versión

| | RC2 (el que usaste) | Oficial 975 |
| :--- | :--- | :--- |
| ISP 1 (172.16.1X.0/24) | *"El tamaño de las subredes **queda a discreción** del estudiante"* | *"El tamaño de las subredes **debe soportar hasta 75 hosts**"* |
| ISP 3 (172.16.3X.0/24) | *"queda a discreción"* | *"deben soportar **hasta 45 hosts**"* |
| ISP 2 (172.16.2X.0/24) | *"queda a discreción"* | *"queda a discreción"* (sin cambio) |

### Estado actual y por qué no cumple

Hoy todo tu subneteo es `/26`:

- `172.16.18.0/26` → **62 hosts útiles** ❌ (se piden 75)
- `172.16.18.64/26` → **62 hosts útiles** ❌ (se piden 75)
- `172.16.18.128/30` → servidores
- `172.16.18.132–.252` → 5 enlaces punto a punto `/30`
- ISP 2 `/26` → ✅ (a discreción)
- ISP 3 `/26` = 62 ≥ 45 → ✅ cumple

La rúbrica oficial 2.1 (12 pts) dice textualmente *"subneteo correcto sobre 172.16.1X.0/24"* y en "Necesita mejorar" castiga
*"faltan enlaces LACP o servicios DNS/HTTPS"*. Un `/26` de 62 hosts **no soporta 75**, así que hay que re-IP-ear FibraNet GT.

### Diseño propuesto (el único que cumple con 75 hosts + deja espacio para enlaces)

Con `/25` cada departamento soporta **126 hosts útiles** (≥ 75 ✅), pero **dos `/25` consumen los 256 del `/24`**,
así que los enlaces punto a punto y el segmento de servidores deben salir del bloque `192.168.48.0/16`
—que es exactamente lo que el enunciado oficial manda usar para *"conectar los routers o switches de capa 3"*
y cuya **subneteo eficiente vale 2 pts en la rúbrica 2.4**.

**FibraNet GT (ISP 1 / AS 100)**

| Segmento | Red | Máscara | Gateway / IPs | Wildcard ACL |
| :--- | :--- | :--- | :--- | :--- |
| LAN Administración | `172.16.18.0` | `/25` (`255.255.255.128`) | T1R4 G0/1 = `.1` | `0.0.0.127` |
| LAN Atención al Cliente | `172.16.18.128` | `/25` (`255.255.255.128`) | T1R5 G0/1 = `.129` | `0.0.0.127` |
| Servidor DNS/HTTP(S) | `192.168.48.48` | `/30` | T1R5 G0/2 = `.49`, Server = `.50` | – |
| SW-BGP-T1 ↔ T1R1 | `192.168.48.32` | `/30` | `.33` / `.34` | – |
| T1R1 ↔ T1R2 | `192.168.48.16` | `/30` | `.17` / `.18` | – |
| T1R1 ↔ T1R3 | `192.168.48.20` | `/30` | `.21` / `.22` | – |
| T1R2 ↔ T1R4 | `192.168.48.24` | `/30` | `.25` / `.26` | – |
| T1R3 ↔ T1R5 | `192.168.48.28` | `/30` | `.29` / `.30` | – |

*(Los 3 enlaces BGP actuales `192.168.48.0/30`, `.4/30`, `.8/30` se mantienen igual ✅)*

**Archivos que hay que tocar en consecuencia:**

| Archivo | Cambio |
| :--- | :--- |
| `scripts/Telecom_Uno/T1R1.md` | IPs `/30` → `192.168.48.16/20/32` + statements `network` de OSPF |
| `scripts/Telecom_Uno/T1R2.md`, `T1R3.md` | idem enlaces internos |
| `scripts/Telecom_Uno/T1R4.md` | G0/1 → `172.16.18.1 255.255.255.128`; OSPF `network 172.16.18.0 0.0.0.127` |
| `scripts/Telecom_Uno/T1R5.md` | G0/1 → `172.16.18.129 255.255.255.128`; G0/2 → `192.168.48.49 255.255.255.252`; OSPF wildcards |
| `scripts/BGP/Multicapa_TelecomUno.md` | G1/0/1 → `192.168.48.33 255.255.255.252`; OSPF `network 192.168.48.32 0.0.0.3` |
| ACLs de Administración / Atención al Cliente | wildcards `0.0.0.63` → `0.0.0.127` (y origen ATC `172.16.18.128 0.0.0.127`) |
| Pools DHCP del servidor (en el `.pkt`) | máscara `255.255.255.192` → `255.255.255.128`, excluir `.1` y `.129` |
| `README.md` sección 2.1/2.2 | justificar `/25` = 126 hosts ≥ 75 y actualizar la tabla |
| `Proyecto2_Presentacion_202300848.pdf` | actualizar la mención de VLSM/`/26` |
| 📌 **El `.pkt`** | reconfigurar las interfaces, OSPF y los pools DHCP en Packet Tracer |

> **Si tienes dudas**, pregunta al auxiliar si acepta `/25` para ambos departamentos y los enlaces punto a punto
> dentro de `192.168.48.0/16`. Es la interpretación técnicamente correcta y defendible.

---

## 3. 🔴 Sección 4.5 — Análisis de tráfico con Wireshark (COMPLETAMENTE NUEVA)

### Lo que pide el enunciado oficial

Montar una **máquina virtual** (VirtualBox o VMware Workstation Player; se recomienda Ubuntu Desktop o Kali Linux),
en modo **NAT o Red interna** para garantizar que el tráfico capturado venga **solo de la VM**.

**4 escenarios a generar y capturar dentro de la VM:**

| # | Escenario | Cómo generarlo | Qué debes identificar |
| :- | :--- | :--- | :--- |
| 1 | **Three-way handshake TCP** | `curl http://example.com` o `telnet` | Flags `SYN`, `SYN-ACK`, `ACK` y números de secuencia |
| 2 | **Resolución DNS** | `nslookup` / `dig` contra `8.8.8.8` o `1.1.1.1` | Tipo de registro, TTL y puerto UDP utilizado (53) |
| 3 | **HTTP vs HTTPS** | Una petición por HTTP y otra por HTTPS | El handshake TLS en la de HTTPS y por qué el contenido va cifrado |
| 4 | **ICMP** | `ping` a una dirección externa | Pares `Echo Request` / `Echo Reply` |

**Entregable (4.5.2):** `Proyecto_2/Wireshark/captura_wireshark_202300848.pcapng`
— debe abrir correctamente en cualquier instalación de Wireshark y contener los 4 escenarios.

### Por qué es crítico y no opcional

- **Rúbrica 1.3 = 14 puntos** (la calificación más alta de la sección de habilidades; más que toda la ISP 3).
  El nivel "Satisfactorio" exige *"capturados desde máquina virtual y documenta el análisis capa por capa"*.
  El nivel "Necesita mejorar" castiga explícitamente *"no fue generada en máquina virtual"*.
- **Rúbrica 8.1 — Requisitos para optar a calificación:** *"Archivo `captura_wireshark_#carné.pcapng` presente
  en el repositorio y abrible correctamente"*. **Si falta, la nota es 0 puntos.**
- Además, el **manual técnico** (rubric 1.2, 8 pts) debe incluir *"análisis del tráfico capturado en Wireshark
  con explicación capa por capa de al menos tres protocolos distintos"*.
- El **alcance obligatorio (4.8)** insiste: *"documentar el análisis de al menos tres protocolos distintos en el manual técnico"*.

### Estado de tu máquina (verificado)

| Herramienta | Estado |
| :--- | :--- |
| Wireshark / tshark / dumpcap | ✅ instalados en el host |
| VirtualBox / VMware | ❌ **no instalados** |
| QEMU | ✅ instalado (`qemu-system-x86_64`) |

**Nota:** la captura debe generarse **desde dentro de una VM**, no desde el host. Opciones:
instalar VirtualBox (rápido, es lo que el enunciado nombra) o usar QEMU con un ISO de Ubuntu/Kali.
Se puede preparar todo con anticipación.

👉 **Te propongo:** yo puedo crear la carpeta `Proyecto_2/Wireshark/`, un script que genere los 4 tipos de tráfico
y dispare `dumpcap/tshark` para producir el `.pcapng`, más la plantilla de análisis capa por capa para el README.
Tú solo tendrías que ejecutarlo dentro de la VM (o yo lo preparo para que lo corras ahí).

---

## 4. Reglas de comunicación / ACLs — diferencias reales

Las **reglas de negocio son idénticas** entre ambas versiones ✅, pero el oficial es más específico:

| Origen | Destino | RC2 | Oficial 975 | ¿Tu proyecto? |
| :--- | :--- | :--- | :--- | :--- |
| Seguridad | Cualquier depto | "tráfico" | ICMP, **TCP/80, TCP/443** | ⚠️ verificar 443 |
| Cualquier depto | Seguridad | Bloqueado | Bloqueado | ✅ |
| Soporte | Cualquier depto | Todos | ICMP, **TCP/80, TCP/443** | ⚠️ verificar 443 |
| Administración | Cualquier depto | Todos | ICMP, **TCP/80, TCP/443** | ⚠️ verificar 443 |
| Atención al Cliente | Ventas | Ventas | ICMP, TCP/80 | ✅ |
| Atención al Cliente | Facturación | — | Bloqueado | ✅ |
| Facturación | Ventas | Ventas | ICMP, TCP/80 | ✅ |
| Facturación | Atención al Cliente | — | Bloqueado | ✅ |
| Ventas | Facturación y ATC | Ambos | ICMP, TCP/80 | ✅ |

**Novedades del oficial que hoy no tienes documentadas:**

1. **`TCP/443` explícito** para Seguridad, Soporte y Administración → revisa que esas ACLs tengan `permit tcp any any eq 443`.
2. **Verificación con acceso a HTTP/HTTPS**, no solo ping. Hoy tus capturas (`images/image5–10.png`) son
   **matrices de PDU/ping**; falta la evidencia de acceso web entre departamentos permitidos. La rúbrica 2.5 dice:
   *"verificadas con **ping y acceso a servicios** entre todos los pares de departamentos"*.
3. **Justificación obligatoria (4.2):** *"El estudiante deberá entregar en el manual técnico la justificación de
   **en qué interfaz y en qué dirección (in/out)** aplicó cada ACL."* → **no existe** en tu README hoy.
4. 🚨 **Las configuraciones de ACL no están en el repositorio.** `scripts/` tiene routers, HSRP, LACP y BGP,
   pero **ningún ACL**. La rúbrica 1.2 exige *"configuraciones aplicadas en cada dispositivo"*.
   → Hay que crear `scripts/ACLs/` con el bloque `ip access-list extended ...` y el `ip access-group ... in/out` de cada departamento.

---

## 5. Rúbrica: la ponderación cambió por completo

| Criterio | RC2 | **Oficial 975** |
| :--- | ---: | ---: |
| Presentación ejecutiva | 9 (de 100) | **10** |
| Manual técnico | (dentro de topologías) | **8** |
| **Análisis de tráfico con Wireshark** | ❌ no existía | **14** |
| **Análisis en modo simulación** | ❌ no existía | **5** |
| **Seguimiento en GitHub/GitLab** | penalización 10% | **3** |
| ISP 1 FibraNet GT | 21 | **12** |
| ISP 2 AndinaCom | 23 | **13** |
| ISP 3 MoonLink | 21 | **12** |
| Conexión inter-ISP (BGP) | 10 | **10** |
| Reglas de comunicación (ACLs) | 10 | **8** |
| Evaluación oral | 6 | **5** |

**Lo relevante:** las "habilidades" (presentación + manual + Wireshark + simulación + Git) pasan a valer **40 de 100**,
y **19 de esos 40 puntos son Wireshark/simulación**, cosas que hoy no tienes. Ese es el mayor riesgo de tu entrega.

### Nuevos "Requisitos para optar a la calificación" (8.1) — si uno falla, es 0

1. Entrega puntual en UEDI.
2. **Todos** los dispositivos finales por DHCP (sin estático).
3. Servidor web y DNS funcionando desde **cualquier** dispositivo de la topología.
4. HSRP con conmutación efectiva.
5. **`captura_wireshark_#carné.pcapng` presente y abrible.** ← nuevo y eliminatorio
6. Todas las configuraciones de routers y switches multicapa **desde CLI**. ← nuevo y eliminatorio

---

## 6. Cambios menores que también aparecen en el oficial

| Tema | RC2 | Oficial 975 | Acción |
| :--- | :--- | :--- | :--- |
| Servidor web | "buscador web" | *"utilizando **HTTP o HTTPS**"*; rúbrica 2.1: *"servicios **DNS/HTTPS** operativos"* | Habilitar HTTPS en el servidor PT y probar `https://www.proyecto2_202300848.com`. Renombrar la etiqueta `SERVER DNS HTTP` → `SERVER DNS HTTP HTTPS` |
| Carpeta del repo | "Proyecto 2" | **`Proyecto_2`** | ✅ ya la tienes así, pero **sin commitear** |
| Manual técnico | informal | "Documento (PDF o Markdown)" con contenido mínimo explícito | Ver checklist §7 |
| Presentación | "arquitectura, costos, dispositivos, tecnologías" | idem + **"descripción de topologías"** y **"lista de precios estimados"** | Añadir slides de dispositivos y precios |
| Fechas | entrega 02/05/2026 | entrega **23/10/2026**, calificación **24/10/2026** | – |
| Alcance explícito | no había | 4.8 separa **obligatorio** y **opcional** | Ver §8 |
| Herramientas | PT + GitHub + UEDI | + **Wireshark obligatorio**, PT **8.2 o superior**, Draw.io opcional | – |

---

## 7. Checklist del Manual Técnico (rúbrica 1.2 = 8 pts)

| Requisito (4.10 oficial) | Estado actual | Qué falta |
| :--- | :--- | :--- |
| Diagramas de topología por ISP | ✅ `images/image1–3.png` | Recapturar tras renombrar ISPs |
| Tablas de subneteo | ✅ README §2.1 | **Rehacer ISP 1 con `/25`** |
| Tablas de direccionamiento | ✅ README §2.2, §2.3 | Actualizar ISP 1 |
| Configuraciones aplicadas en cada dispositivo | ⚠️ `scripts/` (routers, HSRP, LACP, BGP) | **Faltan ACLs**, pools DHCP del servidor, config del WRT300N y `no auto-summary` |
| **Justificación de las ACLs (interfaz + in/out)** | ❌ | Sección nueva completa |
| Capturas de las pruebas de comunicación | ⚠️ solo ping (PDU) | Añadir pruebas de **HTTP/HTTPS** entre departamentos permitidos |
| **Análisis de la captura de Wireshark, capa por capa, ≥3 protocolos** | ❌ | Sección nueva completa (§3) |
| Formato PDF o Markdown | ✅ `README.md` | – |

---

## 8. Alcance OPCIONAL del oficial (sube nota y demuestra dominio)

Baratos de implementar y con alto retorno en la **evaluación oral (5 pts)** y el **análisis de simulación (5 pts)**:

- [ ] **Autenticación de protocolos de enrutamiento:** `OSPF MD5`, `EIGRP key-chain`, `BGP password` (≈20 min de trabajo, muy vistoso).
- [ ] **VLANs adicionales por departamento** con SVI o router-on-a-stick.
- [ ] **Análisis comparativo de costos con equipos físicos reales** (Cisco ISR, Catalyst) → alimenta la slide de precios que te falta.
- [ ] **Captura del handshake TLS completo del servidor HTTPS** en Wireshark.

---

## 9. 🟡 Estado del repositorio Git (rúbrica 1.5 = 3 pts + penalización del 10%)

Verificado con `git status`:

- Último commit: **9 de octubre** (`9c8432d docs: diapositivas`). Hoy es 14 de octubre.
- Hay un **renombrado de carpetas sin commitear**: `Proyecto 2/` y `Proyecto2/` → `Proyecto_2/`;
  `Proyecto1/` → `Proyecto_1/`. Todo eso aparece como `D` (borrado) + untracked.
- ⚠️ **Riesgo:** un `git add -A` + commit incluiría el borrado de los archivos viejos. Verifica que
  `Proyecto_1/` (con su `Proyecto1.pkt`, `Documentación/` y PDF) quede **commiteado**, porque el enunciado
  dice *"el repositorio creado para el proyecto 1"* y el auxiliar lo va a revisar.
- El enunciado pide **commits progresivos**; concentrar todo al final se penaliza.

**Acción:** commitear ya la estructura actual y luego hacer commits atómicos por avance
(renombrado → subneteo ISP1 → ACLs → Wireshark → manual → presentación).

---

## 10. Plan de trabajo sugerido (14 → 23 de octubre)

| Día | Tarea | Archivos |
| :--- | :--- | :--- |
| **14–15 oct** | Commitear estructura actual. Renombrar ISPs en `.pkt`, README, guía, scripts y carpetas. **Preguntar al auxiliar** lo del `/25`. | `.pkt`, `README.md`, `guia_presentacion.md`, `scripts/**`, `scripts/BGP/*` |
| **15–16 oct** | Re-subnetear FibraNet GT a `/25` + enlaces en `192.168.48.0/16`. Reconfigurar el `.pkt`, OSPF, pools DHCP y wildcards de ACL. Verificar ping/handshake de extremo a extremo. | `.pkt`, `scripts/Telecom_Uno/*`, `scripts/BGP/Multicapa_TelecomUno.md`, `README.md` §2 |
| **16–17 oct** | Documentar ACLs (`scripts/ACLs/`) + sección de justificación (interfaz, in/out) + probar HTTP/HTTPS entre departamentos. Habilitar HTTPS. | `scripts/ACLs/*`, `README.md` §5 |
| **17–18 oct** | Montar la VM y **generar la captura Wireshark** con los 4 escenarios. Redactar el análisis capa por capa (≥3 protocolos). | `Wireshark/captura_wireshark_202300848.pcapng`, `README.md` §7 |
| **18–19 oct** | Regenerar todas las capturas de pantalla (topologías, tablas, pruebas) y actualizar imágenes del README. | `images/*` |
| **19–20 oct** | Preparar el guion del **análisis en modo simulación** (DHCP DORA, DNS, HTTP/HTTPS, OSPF/EIGRP, BGP). Ensayar. | `guia_presentacion.md` |
| **20–21 oct** | Añadir slides de **dispositivos** y **lista de precios**; renombrar ISPs; exportar el PDF. | `Proyecto2_Presentacion_202300848.pdf` |
| **21–22 oct** | Ensayo completo de la exposición (5–10 min) + repaso de troubleshooting. Verificación final de la matriz de pruebas. | `guia_presentacion.md` |
| **23 oct** | Entrega en UEDI con el enlace del repositorio. | – |

---

## 11. Matriz de verificación final (antes de la calificación)

**Requisitos eliminatorios**
- [ ] `Proyecto_2/Wireshark/captura_wireshark_202300848.pcapng` existe y abre en Wireshark.
- [ ] Todos los hosts obtienen IP por DHCP (ninguno estático).
- [ ] `www.proyecto2_202300848.com` resuelve y carga por HTTP **y** HTTPS desde cualquier ISP.
- [ ] HSRP conmuta (apagar el router activo → el ping se recupera).
- [ ] Todas las configs de routers y switches multicapa hechas por CLI.

**Conocimientos (60 pts)**
- [ ] FibraNet GT: árbol + OSPF + 2 LACP + 5 routers/5 hosts + **subredes de 126 hosts (≥75)** + DNS/HTTPS.
- [ ] AndinaCom: jerárquica + OSPF + 2 LACP + HSRP conmutando + DHCP central en toda la topología.
- [ ] MoonLink: hub-and-spoke + EIGRP + 2 LACP + wireless operativo + subredes ≥45 hosts.
- [ ] BGP: 3 vecinos establecidos, rutas redistribuidas desde OSPF y EIGRP, `/30` eficientes.
- [ ] ACLs: los 9 pares de la tabla verificados con **ping y navegador**.
- [ ] Evaluación oral: puedes justificar `ip ospf cost 50`, `no auto-summary`, el WRT300N en modo bridge, la excepción de HSRP/OSPF en las ACLs.

**Habilidades (40 pts)**
- [ ] Presentación 5–10 min con arquitectura, topologías, **dispositivos**, **precios**, tecnologías.
- [ ] Manual técnico completo (§7 de este documento).
- [ ] `.pcapng` con los 4 escenarios + análisis capa por capa de ≥3 protocolos.
- [ ] Repositorio con commits progresivos y estructura correcta.
