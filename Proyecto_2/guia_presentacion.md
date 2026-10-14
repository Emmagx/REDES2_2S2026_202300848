# Guía de Presentación y Calificación — Proyecto 2

**Enunciado oficial:** `975_Proyecto_2_2S2026.pdf`
**ISPs:** FibraNet GT (ISP 1) · AndinaCom (ISP 2) · MoonLink (ISP 3)
**Exposición:** mínimo 5, máximo 10 minutos (rúbrica 1.1, 10 pts)
**Evaluación oral de conocimiento:** rúbrica 2.6, 5 pts
**Análisis en modo simulación:** rúbrica 1.4, 5 pts

Esta guía está diseñada para que conduzcas tu evaluación o presentación de forma segura, estructurada
y demostrando un dominio absoluto del proyecto.

---

## 1. Preparación antes de iniciar

- **Modo Realtime:** Asegúrate de que Packet Tracer esté en la pestaña `Realtime` (abajo a la derecha).
- **Convergencia:** Haz clic en el botón `Fast Forward Time (>>)` unas 10 veces rápidas. Esto asegura
  que STP, OSPF, EIGRP y BGP ya hayan calculado sus rutas y HSRP ya sepa quién es el router Activo.
- **Prueba en frío:** Manda un ping rápido desde cada departamento clave antes de compartir pantalla
  para asegurar que las memorias ARP de las PCs estén frescas.
- **Verifica el requisito eliminatorio:** que exista
  `Wireshark/captura_wireshark_202300848.pcapng` y que **abra** en Wireshark.
- **Ten a mano esta consola:**

```text
show standby brief
show ip bgp summary
show etherchannel summary
show ip access-lists
```

---

## 2. Orden sugerido de exposición

### Fase 1: Visión general y direccionamiento (2 minutos)

- Muestra la topología general.
- Explica que interconectaste 3 ISPs usando **BGP** como protocolo exterior (AS 100, 200 y 300).
- Menciona que **FibraNet GT** y **AndinaCom** usan **OSPF**, mientras que **MoonLink** usa
  **EIGRP**, demostrando la redistribución de protocolos en los switches multicapa de borde.
- Explica el subneteo con VLSM:
  - **FibraNet GT:** `172.16.18.0/24` → 2 × **`/25`** (126 hosts) porque el enunciado exige soportar
    **hasta 75 hosts**. *Frase clave:* "El enunciado original dejaba el tamaño a discreción y usábamos
    `/26`; el oficial exige 75 hosts, y 62 no alcanza, así que rediseñamos a `/25` y movimos los
    enlaces punto a punto al bloque `192.168.48.0/16` que el propio enunciado asigna para conectar
    routers, dejando el `/24` completo disponible para los dos departamentos."
  - **AndinaCom:** 2 × `/26` (a discreción).
  - **MoonLink:** 2 × `/26` (62 ≥ 45 requeridos).
  - **Interconexión:** `192.168.48.0/16` subneteada en `/30` (2 IPs útiles, cero desperdicio).

### Fase 2: Servicios principales (DHCP, DNS y Web) (3 minutos)

- **DHCP:** Muestra cómo el `SERVER-DHCP` (`172.16.28.130`, en AndinaCom) reparte IPs a PCs de los
  **tres** ISPs. Ve a la PC de Ventas o Facturación (que están en otro dominio de enrutamiento),
  pásala a Static y luego a DHCP para que vean que obtiene su IP.
  - *Frase clave:* "Utilizamos `ip helper-address` para centralizar el servicio DHCP cruzando
    dominios de enrutamiento y lo redistribuimos por BGP."
- **DNS y Web:** Abre el navegador en cualquier PC y entra a `http://www.proyecto2_202300848.com`
  **y** a `https://www.proyecto2_202300848.com`.
  - *Frase clave:* "El servidor en FibraNet GT resuelve el dominio y sirve la página por HTTP y
    HTTPS a toda la red, demostrando ruteo de extremo a extremo."

### Fase 3: Redundancia avanzada (la joya de la corona) (3 minutos)

- Muéstrales los cables cruzados en **AndinaCom**.
- Explica que implementaste **HSRP** (grupo 10 para Ventas, grupo 20 para Facturación) con
  `priority 110` + `preempt` en RN-R3.
- *Demostración práctica:*
  1. Abre una consola haciendo `ping continuo (-t)` a un servidor.
  2. Elimina o apaga el enlace principal del router Activo.
  3. Muestra cómo el ping falla 1 o 2 veces y luego se recupera solo.
- *Frase clave:* "Tuvimos que ajustar los costos de OSPF (`ip ospf cost 50`) en las interfaces
  cruzadas para forzar enrutamiento simétrico y evitar la inestabilidad que causa el balanceo de carga
  en escenarios HSRP."

### Fase 4: Seguridad y ACLs (4 minutos)

- Saca tu **Matriz de Pruebas** ([`scripts/ACLs/MATRIZ_PRUEBAS.md`](scripts/ACLs/MATRIZ_PRUEBAS.md)).
- Ejecuta las pruebas clave usando el sobrecito del simulador (PDU) o el Command Prompt:
  1. **Bloqueo a Seguridad:** Ping desde Soporte ➔ Seguridad (`Failed`). "Nadie entra a seguridad."
  2. **Libertad de los jefes:** Ping desde Soporte ➔ Ventas (`Successful`) y Admin ➔ Facturación
     (`Successful`).
  3. **Bloqueo restrictivo:** Ping desde ATC ➔ Facturación (`Failed`), seguido de ATC ➔ Ventas
     (`Successful`).
- *Frase clave:* "Las políticas se implementaron **filtrando en el origen**: cada ACL extendida va
  aplicada `in` sobre la interfaz LAN del departamento, para descartar el tráfico antes de que cruce
  la WAN. Hubo que agregar un bloque común que permite OSPF, EIGRP, HSRP, DHCP y DNS antes del
  `deny` implícito, y reglas de retorno (`echo-reply`) para que el tráfico que Seguridad inicia
  pueda volver."

### Fase 5: Wireshark (2 minutos)

- Muestra el archivo `Wireshark/captura_wireshark_202300848.pcapng` abierto en Wireshark.
- Filtra por `tcp.flags.syn == 1` para el three-way handshake, `dns` para la resolución, `tls` para el
  handshake de HTTPS y `icmp` para el ping.
- *Frase clave:* "La captura se generó dentro de una máquina virtual en modo NAT para garantizar que
  el tráfico provenga únicamente de la VM, tal como exige el enunciado."

---

## 3. Análisis en modo simulación (rúbrica 1.4 — 5 pts)

El evaluador elegirá **un paquete** y debes explicarlo **capa por capa**. Practica este guion:
`Simulation` (abajo a la derecha) → `Show All/Hide All` → clic en el sobre para ver el detalle por capa.

| Protocolo | Cómo generarlo | Qué explicar capa por capa |
| :--- | :--- | :--- |
| **DHCP (DORA)** | Cambiar una PC de Static a DHCP en modo Simulación | L2: Ethernet broadcast `FF:FF:FF:FF:FF:FF` · L3: `0.0.0.0` → `255.255.255.255` · L4: UDP **67/68** · Los 4 mensajes: **Discover, Offer, Request, Ack** · El `Relay Agent IP` = interfaz del router que tiene el `ip helper-address` |
| **DNS** | Web Browser → `www.proyecto2_202300848.com` | L4: UDP **53** · Consulta tipo **A** → respuesta con la IP `192.168.48.50` · Luego inicia TCP/80 (o TLS 443) |
| **HTTP/HTTPS** | Petición web | HTTP: TCP **80**, texto plano visible (`GET / HTTP/1.1`) · HTTPS: TCP **443**, TLS Client Hello → Server Hello → certificado, contenido cifrado (Application Data) |
| **OSPF** | Ver un Hello de OSPF | L3: protocolo IP **89**, destino multicast `224.0.0.5`/`224.0.0.6` · Estado de vecindad `FULL` · Área 0 |
| **EIGRP** | Ver un Hello de EIGRP | L3: protocolo IP **88**, destino `224.0.0.10` · AS 10 y `no auto-summary` |
| **BGP** | Ver un UPDATE/OPEN entre los switches de borde | L4: TCP **179** · `OPEN` (AS 100/200/300) y `UPDATE` con los prefijos redistribuidos de OSPF/EIGRP |

**Tip:** el evaluador suele pedir "el paquete del ping que acabas de hacer" — ten listo el PDU
en Simulation y muestra el **Echo Request (ICMP tipo 8)** y el **Echo Reply (ICMP tipo 0)**, con las
MAC de origen/destino cambiando en cada salto (eso demuestra que entiendes el reenvío capa 2 vs capa 3).

---

## 4. Respuestas a preguntas trampa

> **Ingeniero:** ¿Por qué FibraNet GT usa `/25` y no `/26` como los otros?
> **Tú:** Porque el enunciado oficial exige que sus subredes soporten **hasta 75 hosts**. Un `/26` da
> 62 direcciones útiles y no alcanza. Con `/25` obtenemos 126. Como las dos `/25` llenan el
> `172.16.18.0/24`, los enlaces punto a punto y el segmento del servidor los movimos al
> `192.168.48.0/16`, que es el bloque que el enunciado asigna justamente para conectar routers y
> switches de capa 3.

> **Ingeniero:** ¿En qué interfaz y en qué sentido aplicaste las ACLs y por qué?
> **Tú:** Todas en sentido **`in` sobre la interfaz LAN del router de acceso del departamento**:
> filtrado **en el origen**. Así el paquete se descarta antes de entrar al dominio de enrutamiento y
> antes de consumir WAN. En Ventas y Facturación la misma ACL está **replicada en RN-R3 y RN-R4**
> porque el gateway activo de HSRP puede cambiar tras un failover y la política debe sobrevivir.

> **Ingeniero:** ¿Por qué no bloqueaste el tráfico entrante a Seguridad con un ACL `out` en su LAN?
> **Tú:** Porque las ACLs extendidas no mantienen estado. Si bloqueara la entrada a Seguridad,
> también bloquearía **las respuestas** a las conexiones que Seguridad sí inicia, y la regla dice que
> Seguridad → cualquiera debe ser exitoso. La solución es filtrar en cada origen, con una excepción
> previa que permite solo el retorno (`echo-reply` y TCP con puerto origen 80/443).

> **Ingeniero:** Soporte debe hablar con todos, pero nadie entra a Seguridad. ¿Cómo resolviste la
> contradicción?
> **Tú:** Di prioridad a la regla más restrictiva, que es la de Seguridad. Es el criterio estándar de
> firewall y coincide con el orden en que el enunciado lista las reglas. Quedó documentado en
> `ACL_SOPORTE.md`. En la matriz de pruebas, `PC1-SOPORTE → PC1-SEGURIDAD = Failed`.

> **Ingeniero:** ¿Por qué Soporte y Administración no tienen ACLs "restrictivas"?
> **Tú:** Sus reglas dictan que deben hablar y escuchar a todos, así que sus ACLs son de tipo
> *permit-list*: permiten explícitamente ICMP/HTTP/HTTPS hacia y desde cualquier departamento (salvo
> Seguridad) y cierran con el `deny` implícito. Las restricciones fuertes las pusimos en el **origen**
> de los departamentos restringidos.

> **Ingeniero:** ¿Por qué las ACLs permiten OSPF, EIGRP, DHCP y DNS?
> **Tú:** Porque son el **plano de control** y los servicios centrales compartidos. Sin
> `permit ospf any any` y `permit udp any any eq 1985`, el `deny ip any any` implícito rompe las
> adyacencias de OSPF y HSRP — nos pasó y lo documentamos como "split-brain" en el troubleshooting
> (§7.6). Sin el permiso de DHCP (UDP 67/68) los hosts quedarían en APIPA, que es requisito
> eliminatorio.

> **Ingeniero:** ¿Cómo aseguraste que los Access Points no arruinaran el DHCP?
> **Tú:** Identificamos que el puerto 'Internet' de los routers inalámbricos aplica NAT y descarta los
> paquetes Broadcast de DHCP. Al conectarlos por sus puertos LAN (Ethernet), los convertimos en
> Access Points puros que pasan el tráfico en Capa 2 hacia el `ip helper-address`.

> **Ingeniero:** ¿Cómo resolvieron el problema de inestabilidad de ruteo asimétrico?
> **Tú:** Al tener dos routers OSPF conectados al mismo switch por HSRP, OSPF dividía el tráfico a
> partes iguales hacia ambos. Al penalizar el cable de respaldo con `ip ospf cost 50`, obligamos al
> router principal a usar la ruta primaria de forma simétrica, dejando el segundo cable estrictamente
> para failover del HSRP.

> **Ingeniero:** ¿Por qué EIGRP necesitó `no auto-summary`?
> **Tú:** Porque EIGRP resumía en la frontera de red con clase y anunciaba `172.16.0.0/16`, que
> chocaba con las subredes de los otros ISPs propagadas por BGP y enviaba paquetes al ISP equivocado.
> Deshabilitarlo forzó el anuncio de prefijos específicos y el longest prefix match correcto.

> **Ingeniero:** ¿La captura de Wireshark la hiciste en tu máquina?
> **Tú:** No, la generé **dentro de una máquina virtual** en modo NAT/red interna, para garantizar que
> el tráfico capturado provenga únicamente de la VM y no del equipo anfitrión, tal como exige la
> sección 4.5. Contiene los cuatro escenarios: three-way handshake TCP, resolución DNS, HTTP vs HTTPS
> e ICMP.

---

## 5. Recordatorio de la presentación ejecutiva (rúbrica 1.1 — 10 pts)

El enunciado exige que la presentación incluya **cinco** elementos. Verifica que tu PDF los tenga:

- [ ] Arquitectura seleccionada
- [ ] Descripción de las topologías (fibra óptica, árbol, jerárquica, hub-and-spoke)
- [ ] **Dispositivos utilizados** (modelos: 3650-24PS, 2911, 2960-24TT, WRT300N, Server-PT)
- [ ] **Lista de precios estimados** (comparativa con equipos físicos reales: Cisco ISR, Catalyst)
- [ ] Tecnologías y protocolos implementados (BGP, OSPF, EIGRP, HSRP, LACP, DHCP, DNS, HTTP/HTTPS, ACLs)

**Además:** la presentación debe estar renombrada a **FibraNet GT**, **AndinaCom** y **MoonLink**.

---

## 6. Tips finales

- Si un ping falla la primera vez, recuérdale al ingeniero que "es el ARP resolviendo la dirección MAC"
  y dale doble clic al botón `Fire` en la lista de PDU de abajo a la derecha. Casi siempre el segundo
  intento da verde.
- Si te preguntan algo de Wireshark y no recuerdas un dato, abre el `.pcapng` y usa el filtro
  correspondiente: la evidencia está en el archivo, no en tu memoria.
- Mantén la calma. Tú configuraste y reparaste los problemas más difíciles (split-brain de HSRP, NAT
  en routers AP, auto-summary en EIGRP, costos OSPF, rediseño de subneteo a `/25`). Conoces esta red
  mejor que nadie. ¡Mucho éxito en tu presentación!
