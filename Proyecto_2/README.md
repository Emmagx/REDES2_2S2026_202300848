# Manual Técnico — Proyecto 2: Integración de Operadores Nacionales

**Curso:** Redes de Computadoras 2 · Segundo Semestre 2026
**Estudiante:** Carné 202300848
**Enunciado:** `975_Proyecto_2_2S2026.pdf` (versión oficial)
**Entrega:** 23/10/2026 · **Calificación:** 24/10/2026

---

## 1. Introducción

El presente documento detalla la implementación técnica del Proyecto 2 del curso Redes de
Computadoras 2, el cual interconecta tres Proveedores de Servicio de Internet (ISP):

| ISP | AS | Topología | Enrutamiento interno | Servicio asignado |
| :--- | :--- | :--- | :--- | :--- |
| **FibraNet GT** | 100 | Árbol | OSPF área 0 | **DNS + HTTP/HTTPS** |
| **AndinaCom** | 200 | Jerárquica | OSPF área 0 | **DHCP a toda la topología** |
| **MoonLink** | 300 | Hub-and-spoke | EIGRP AS 10 | **Red inalámbrica (Wi-Fi)** |

El diseño asegura escalabilidad, redundancia y enrutamiento dinámico eficiente entre distintos
dominios administrativos utilizando OSPF, EIGRP y BGP. Se aplican políticas estrictas de control de
tráfico mediante ACLs extendidas para asegurar el cumplimiento de las reglas de negocio establecidas.

> **Nota de nomenclatura:** el enunciado original (`[RC2]`) nombraba a los ISPs *Telecom Uno*, *Redes
> Nacionales* y *Conexiones Futuras / Link Global*. El enunciado oficial los renombra a
> **FibraNet GT**, **AndinaCom** y **MoonLink**. Los *hostnames* de los dispositivos conservan los
> prefijos `T1` / `RN` / `CF` por continuidad con el archivo `.pkt`; la equivalencia está documentada
> en [`scripts/README.md`](scripts/README.md).

---

## 2. Direccionamiento y Subneteo (VLSM)

Basado en el carné **202300848**:

| Red asignada | Cálculo | Resultado |
| :--- | :--- | :--- |
| `172.16.1X.0/24` (X = último dígito = 8) | FibraNet GT | `172.16.18.0/24` |
| `172.16.2X.0/24` (X = último dígito = 8) | AndinaCom | `172.16.28.0/24` |
| `172.16.3X.0/24` (X = primer dígito = 2) | MoonLink | `172.16.32.0/24` |
| `192.168.XX.0/16` (XX = últimos 2 dígitos = 48) | Interconexión de routers / switches L3 | `192.168.48.0/16` |

### 2.1 Justificación de los cálculos

**1. Enlaces punto a punto (interconexión de routers y switches de capa 3)**

El enunciado asigna la red `192.168.XX.0/16` para *"conectar los routers o switches de capa 3"* y la
rúbrica 2.4 premia el *"subneteo eficiente de la red 192.168.X.0/16"*. Como cada enlace directo solo
requiere 2 direcciones útiles, se subneteó con máscara **`/30`**:

- Fórmula de hosts: `2² − 2 = 2` IPs útiles → cero desperdicio de direcciones.

**2. Redes LAN departamentales**

| ISP | Requisito del enunciado oficial | Máscara elegida | Hosts útiles | ¿Cumple? |
| :--- | :--- | :--- | :--- | :--- |
| **FibraNet GT** | *"debe soportar hasta **75 hosts**"* | **`/25`** | `2⁷ − 2 =` **126** | ✅ |
| **AndinaCom** | *"queda a discreción del estudiante"* | `/26` | `2⁶ − 2 =` 62 | ✅ |
| **MoonLink** | *"deben soportar hasta **45 hosts**"* | `/26` | `2⁶ − 2 =` 62 | ✅ |

> ⚠️ **Decisión de diseño clave (FibraNet GT):** el enunciado *original* dejaba el tamaño de las
> subredes a discreción, por lo que el diseño inicial usaba `/26` (62 hosts). El enunciado **oficial
> exige soportar hasta 75 hosts**, y 62 < 75, por lo que **FibraNet GT se rediseñó a `/25`**
> (126 hosts útiles). Como las dos `/25` consumen la totalidad de `172.16.18.0/24`, los enlaces punto
> a punto y el segmento de servidores de este ISP se movieron al bloque `192.168.48.0/16`, que es
> precisamente el que el enunciado destina a la conexión entre routers.

### 2.2 Tabla de direccionamiento — Redes LAN departamentales

| ISP | Departamento | Dirección de red | Máscara | Rango utilizable | Broadcast | Gateway |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **FibraNet GT** | Administración | `172.16.18.0` | `/25` (`255.255.255.128`) | `.1` – `.126` | `.127` | `172.16.18.1` (T1R4) |
| **FibraNet GT** | Atención al Cliente | `172.16.18.128` | `/25` (`255.255.255.128`) | `.129` – `.254` | `.255` | `172.16.18.129` (T1R5) |
| **AndinaCom** | Ventas | `172.16.28.0` | `/26` (`255.255.255.192`) | `.1` – `.62` | `.63` | `172.16.28.1` (**HSRP**) |
| **AndinaCom** | Facturación | `172.16.28.64` | `/26` (`255.255.255.192`) | `.65` – `.126` | `.127` | `172.16.28.65` (**HSRP**) |
| **MoonLink** | Soporte | `172.16.32.0` | `/26` (`255.255.255.192`) | `.1` – `.62` | `.63` | `172.16.32.1` (CF-R2) |
| **MoonLink** | Seguridad | `172.16.32.64` | `/26` (`255.255.255.192`) | `.65` – `.126` | `.127` | `172.16.32.65` (CF-R3) |

### 2.3 Tabla de direccionamiento — Interconexión inter-ISP (`192.168.48.0/16`)

| Enlace (fibra óptica) | Red | Máscara | Extremo A | Extremo B |
| :--- | :--- | :--- | :--- | :--- |
| FibraNet GT ↔ AndinaCom | `192.168.48.0` | `/30` | `.1` (SW-BGP-FG) | `.2` (SW-BGP-AC) |
| AndinaCom ↔ MoonLink | `192.168.48.4` | `/30` | `.5` (SW-BGP-AC) | `.6` (SW-BGP-ML) |
| MoonLink ↔ FibraNet GT | `192.168.48.8` | `/30` | `.9` (SW-BGP-FG) | `.10` (SW-BGP-ML) |

### 2.4 Tabla de direccionamiento — Enlaces internos y servidores

**FibraNet GT**

| Enlace | Red | Máscara | Extremo A | Extremo B |
| :--- | :--- | :--- | :--- | :--- |
| SW-BGP-FG ↔ T1R1 | `192.168.48.32` | `/30` | `.33` (SW-BGP-FG) | `.34` (T1R1) |
| T1R1 ↔ T1R2 | `192.168.48.16` | `/30` | `.17` (T1R1) | `.18` (T1R2) |
| T1R1 ↔ T1R3 | `192.168.48.20` | `/30` | `.21` (T1R1) | `.22` (T1R3) |
| T1R2 ↔ T1R4 | `192.168.48.24` | `/30` | `.25` (T1R2) | `.26` (T1R4) |
| T1R3 ↔ T1R5 | `192.168.48.28` | `/30` | `.29` (T1R3) | `.30` (T1R5) |
| T1R5 ↔ Servidor DNS/HTTP/HTTPS | `192.168.48.48` | `/30` | `.49` (T1R5) | `.50` (Servidor) |

**AndinaCom**

| Enlace | Red | Máscara | Extremo A | Extremo B |
| :--- | :--- | :--- | :--- | :--- |
| SW-BGP-AC ↔ RN-R1 | `172.16.28.252` | `/30` | `.253` | `.254` |
| RN-R1 ↔ RN-R2 | `172.16.28.132` | `/30` | `.133` | `.134` |
| RN-R1 ↔ RN-R5 | `172.16.28.136` | `/30` | `.137` | `.138` |
| RN-R5 ↔ Servidor DHCP | `172.16.28.128` | `/30` | `.129` | `.130` |
| RN-R2 ↔ RN-R3 | `172.16.28.140` | `/30` | `.141` | `.142` |
| RN-R2 ↔ RN-R4 | `172.16.28.144` | `/30` | `.145` | `.146` |

**MoonLink**

| Enlace | Red | Máscara | Extremo A | Extremo B |
| :--- | :--- | :--- | :--- | :--- |
| SW-BGP-ML ↔ CF-R1 | `172.16.32.252` | `/30` | `.253` | `.254` |
| Red WAN multipunto (SW-WAN) | `172.16.32.128` | `/27` | CF-R1 `.129`, CF-R2 `.130`, CF-R3 `.131`, CF-R4 `.132`, CF-R5 `.133` | – |
| Loopback CF-R4 | `172.16.32.201` | `/32` | – | – |
| Loopback CF-R5 | `172.16.32.202` | `/32` | – | – |

### 2.5 Pools DHCP (servidor central en AndinaCom)

Servidor DHCP: `172.16.28.130` (AndinaCom, `RN-R5 g0/1`). Los routers de acceso de los tres ISPs
tienen `ip helper-address 172.16.28.130` en su interfaz LAN, lo que permite dar direccionamiento
cruzando dominios de enrutamiento.

| Pool | Red | Máscara | Gateway | DNS |
| :--- | :--- | :--- | :--- | :--- |
| `POOL-ADMIN-FG` | `172.16.18.0` | `255.255.255.128` | `172.16.18.1` | `192.168.48.50` |
| `POOL-ATC-FG` | `172.16.18.128` | `255.255.255.128` | `172.16.18.129` | `192.168.48.50` |
| `POOL-VENTAS-AC` | `172.16.28.0` | `255.255.255.192` | `172.16.28.1` (VIP HSRP) | `192.168.48.50` |
| `POOL-FACTURACION-AC` | `172.16.28.64` | `255.255.255.192` | `172.16.28.65` (VIP HSRP) | `192.168.48.50` |
| `POOL-SOPORTE-ML` | `172.16.32.0` | `255.255.255.192` | `172.16.32.1` | `192.168.48.50` |
| `POOL-SEGURIDAD-ML` | `172.16.32.64` | `255.255.255.192` | `172.16.32.65` | `192.168.48.50` |

Direcciones excluidas de los pools: `.1` y `.129` de FibraNet GT, `.1` y `.65` de AndinaCom y
MoonLink (gateways y VIPs de HSRP), y `172.16.28.130` (el propio servidor DHCP).

> **Todos los dispositivos finales obtienen su dirección por DHCP** (requisito eliminatorio de la
> rúbrica 8.1). Los únicos elementos con IP estática son los dos servidores de infraestructura.

---

## 3. Topologías y tecnologías implementadas

![Topología completa](images/image.png)

### 3.1 FibraNet GT (ISP 1 — AS 100)

- **Topología:** Árbol.
- **Enrutamiento:** OSPF área 0.
- **Servicios:** Aloja el servidor **DNS, HTTP y HTTPS** (`192.168.48.50`). Proporciona resolución
  de nombres para el dominio `www.proyecto2_202300848.com` a toda la topología.
- **Alta disponibilidad:** EtherChannel con **LACP** (`mode active` / `mode passive`) en los pares de
  switches de cada departamento.
- **Requisito de subneteo:** dos subredes **`/25`** de 126 hosts cada una (≥ 75 requeridos).
- **Scripts:** [`scripts/FibraNet_GT/`](scripts/FibraNet_GT/)

![FibraNet GT](images/image1.png)

### 3.2 AndinaCom (ISP 2 — AS 200)

- **Topología:** Modelo jerárquico (núcleo, distribución y acceso).
- **Enrutamiento:** OSPF área 0.
- **Servicios:** Aloja el **servidor DHCP central** (`172.16.28.130`), que asigna direcciones IP a
  toda la infraestructura nacional mediante `ip helper-address` en las interfaces LAN de todos los
  routers de acceso de los tres ISPs.
- **Alta disponibilidad — redundancia de capa 3 obligatoria:** **HSRP** con dos grupos
  (grupo 10 para Ventas, grupo 20 para Facturación), `priority 110` + `preempt` en RN-R3 (activo).
  Se agregó `ip ospf cost 50` en los enlaces cruzados para forzar enrutamiento simétrico.
- **Scripts:** [`scripts/AndinaCom/`](scripts/AndinaCom/)

![AndinaCom](images/image2.png)

### 3.3 MoonLink (ISP 3 — AS 300)

- **Topología:** Hub-and-spoke.
- **Enrutamiento:** EIGRP (AS 10) con `no auto-summary` obligatorio.
- **Servicios:** Red inalámbrica mediante router **WRT300N** configurado con seguridad WPA2 y
  conectado por sus puertos **LAN** (modo bridge/access point) para permitir el paso transparente de
  las solicitudes DHCP hacia la infraestructura cableada.
- **Requisito de subneteo:** dos subredes **`/26`** de 62 hosts (≥ 45 requeridos).
- **Scripts:** [`scripts/MoonLink/`](scripts/MoonLink/)

![MoonLink](images/image3.png)

---

## 4. Enrutamiento interdominio (BGP)

La interconexión de los tres ISPs se logró con **eBGP** en los switches multicapa de borde
(3650-24PS), conectados en la topología triangular de fibra óptica indicada por el enunciado.
Cada ISP usa su propio Sistema Autónomo y se redistribuyen los protocolos internos (OSPF/EIGRP)
hacia BGP y viceversa.

| Router de borde | AS | Vecinos eBGP |
| :--- | :--- | :--- |
| `SW-BGP-FG` | 100 | `192.168.48.2` (AS 200), `192.168.48.10` (AS 300) |
| `SW-BGP-AC` | 200 | `192.168.48.1` (AS 100), `192.168.48.6` (AS 300) |
| `SW-BGP-ML` | 300 | `192.168.48.5` (AS 200), `192.168.48.9` (AS 100) |

**Configuración base BGP (ejemplo MoonLink):**

```text
router bgp 300
 bgp log-neighbor-changes
 neighbor 192.168.48.5 remote-as 200
 neighbor 192.168.48.9 remote-as 100
 redistribute eigrp 10
 exit
```

Scripts completos: [`scripts/BGP/`](scripts/BGP/)

![BGP](images/image4.png)

---

## 5. Listas de Control de Acceso (ACLs)

Para cumplir con las reglas de comunicación del enunciado se implementaron **ACLs extendidas
aplicadas en sentido `in` sobre la interfaz LAN de cada departamento** (filtrado en el origen),
garantizando el paso de los servicios críticos (DHCP, DNS, HTTP y HTTPS) y del plano de control
(OSPF, EIGRP y HSRP) antes del `deny ip any any` implícito.

| ACL | Departamento | Equipo | Interfaz | Sentido |
| :--- | :--- | :--- | :--- | :--- |
| `ATC_IN` | Atención al Cliente | T1R5 | `g0/1` | in |
| `VENTAS_IN` | Ventas | RN-R3 y RN-R4 | `g0/1` | in |
| `FAC_IN` | Facturación | RN-R3 y RN-R4 | `g0/2` | in |
| `SEC_OUT` | Seguridad | CF-R3 | `g0/1` | **out** |
| *(ninguna)* | Administración | T1R4 | — | — |
| *(ninguna)* | Soporte | CF-R2 | — | — |

> **Administración y Soporte no llevan ACL por diseño:** su regla es "hablar y escuchar a todos", así
> que las restricciones se aplican en el **origen** de los departamentos que sí las necesitan. La
> restricción "nadie entra a Seguridad" se resuelve en el destino con `SEC_OUT` (sentido `out`), que
> solo permite tráfico de retorno.

- 📄 **Justificación completa de interfaz y sentido (requisito 4.2):** [`scripts/ACLs/README.md`](scripts/ACLs/README.md)
- 📄 **Configuración de cada ACL:** [`scripts/ACLs/`](scripts/ACLs/)
- 📄 **Matriz de pruebas (24 pruebas ICMP + servicios):** [`scripts/ACLs/MATRIZ_PRUEBAS.md`](scripts/ACLs/MATRIZ_PRUEBAS.md)

### Evidencia de verificación (ping / PDU)

#### Seguridad — origen de las pruebas
![Pruebas desde Seguridad](images/image5.png)
![Pruebas desde Seguridad (continuación)](images/image51.png)

#### Soporte
![Pruebas desde Soporte](images/image6.png)
![Pruebas desde Soporte (continuación)](images/image61.png)

#### Ventas
![Pruebas desde Ventas](images/image7.png)

#### Administración
![Pruebas desde Administración](images/image8.png)

#### Facturación
![Pruebas desde Facturación](images/image9.png)

#### Atención al Cliente
![Pruebas desde Atención al Cliente](images/image10.png)

---

## 6. Análisis de tráfico con Wireshark (sección 4.5 del enunciado)

Esta sección cubre el requisito **4.5** y la rúbrica **1.3 (14 puntos)**, además del requisito
eliminatorio de la rúbrica 8.1 (el archivo `.pcapng` debe existir y abrir correctamente).

| Elemento | Ubicación |
| :--- | :--- |
| Archivo de captura | [`Wireshark/captura_wireshark_202300848.pcapng`](Wireshark/) |
| Script generador de tráfico | [`Wireshark/generar_trafico.sh`](Wireshark/generar_trafico.sh) |
| Procedimiento y análisis capa por capa | [`Wireshark/ANALISIS_WIRESHARK.md`](Wireshark/ANALISIS_WIRESHARK.md) |

**Entorno de captura:** máquina virtual (VirtualBox / VMware) con Ubuntu Desktop o Kali Linux,
configurada en modo **NAT o red interna** para garantizar que el tráfico capturado provenga
únicamente de la VM y no del equipo anfitrión.

**Los cuatro escenarios capturados:**

| # | Escenario | Tráfico generado | Elementos identificados |
| :-: | :--- | :--- | :--- |
| 1 | Three-way handshake TCP | `curl http://example.com` / `telnet` | Flags `SYN`, `SYN-ACK`, `ACK` y números de secuencia |
| 2 | Resolución DNS | `nslookup` / `dig` contra `8.8.8.8` o `1.1.1.1` | Tipo de registro, TTL y puerto UDP 53 |
| 3 | HTTP vs HTTPS | Petición HTTP y petición HTTPS al mismo sitio | Handshake TLS y por qué el contenido va cifrado |
| 4 | ICMP | `ping` a una dirección externa | Pares `Echo Request` / `Echo Reply` |

📄 **El análisis capa por capa de los cuatro protocolos está desarrollado en
[`Wireshark/ANALISIS_WIRESHARK.md`](Wireshark/ANALISIS_WIRESHARK.md).**

---

## 7. Resolución de Problemas (Troubleshooting)

Durante el desarrollo del proyecto y las fases de prueba de conectividad se presentaron diversos
desafíos técnicos de alto nivel que fueron diagnosticados y resueltos exitosamente, demostrando el
dominio de las tecnologías empleadas.

### 7.1 Bucles de Enrutamiento por EIGRP Auto-Summary

- **Problema:** El switch multicapa de la interconexión BGP no podía hacer ping al router de Soporte
  (`CF-R2`), a pesar de que los equipos intermedios sí tenían conectividad.
- **Causa Raíz:** Se detectó que EIGRP estaba realizando una sumarización automática (`auto-summary`)
  en las fronteras de red con clase, anunciando la ruta global `172.16.0.0/16` en lugar de las
  subredes específicas `/26`. Esto causaba un choque de subredes con las otras redes ISP propagadas
  por BGP, ocasionando que los paquetes se enviaran al ISP equivocado.
- **Solución:** Se deshabilitó el resumen automático globalmente aplicando el comando
  `no auto-summary` en todos los procesos `router eigrp 10`. Esto forzó la propagación de prefijos
  específicos (Longest Prefix Match), habilitando el enrutamiento exitoso de extremo a extremo y
  restaurando las respuestas del servidor DHCP.

### 7.2 Bloqueo de DHCP por NAT Involuntario (Router Inalámbrico WRT300N)

- **Problema:** Los equipos de Soporte y la laptop no recibían direccionamiento IP del servidor DHCP
  centralizado, generando IPs `169.254.x.x` (APIPA).
- **Causa Raíz:** Se descubrió que el router inalámbrico WRT300N estaba conectado al switch principal
  a través del puerto `Internet` (WAN). Esto activaba la función de NAT nativa del dispositivo,
  bloqueando y descartando los paquetes de difusión `DHCP Discover`.
- **Solución:** Se migró el cable físico del puerto `Internet` hacia el puerto `Ethernet 1` del router
  WRT300N. Esta acción convirtió el equipo en un Bridge/Access Point transparente en capa 2,
  permitiendo que las solicitudes DHCP fluyeran libremente hacia el router `CF-R2` y su respectivo
  `ip helper-address`.

### 7.3 Conflictos por IPs Duplicadas (Inestabilidad en Adyacencias EIGRP)

- **Problema:** El protocolo EIGRP en la topología Hub and Spoke colapsaba constantemente, mostrando
  mensajes de consola `%DUAL-5-NBRCHANGE... retry limit exceeded`.
- **Causa Raíz:** Una auditoría de configuración reveló que dos routers (`CF-R2` y `CF-R3`) tenían la
  misma dirección IP asignada en su interfaz WAN, provocando tormentas de paquetes y negación del
  servicio de enrutamiento.
- **Solución:** Se corrigió el archivo de script de inicialización y se reconfiguraron las interfaces
  con las IPs correctas (`.130` y `.131`), estabilizando las adyacencias EIGRP en cuestión de segundos.

### 7.4 Intercambio de Cables e Interfaces Físicas Invertidas

- **Problema:** Fallo total de comunicación entre el router central (`CF-R1`) y el router de Soporte
  (`CF-R2`).
- **Causa Raíz:** Se identificó mediante inspección visual y análisis de la tabla de enrutamiento que
  las conexiones físicas de `CF-R2` estaban invertidas: la interfaz configurada para la red LAN estaba
  conectada al puerto hacia la WAN y viceversa.
- **Solución:** Se eliminaron los cables y se procedió a realizar un cableado estructurado correcto,
  respetando la estandarización (`Gig0/0` para WAN, `Gig0/1` para LAN), restableciendo la
  comunicación de Capa 3 inmediatamente.

### 7.5 Inestabilidad de Conexiones por Balanceo de Carga OSPF en Entorno HSRP

- **Problema:** Los pings desde Ventas hacia Soporte mostraban intermitencia severa (flapping),
  alternando entre paquetes exitosos y perdidos.
- **Causa Raíz:** Al contar con redundancia física obligatoria (cables cruzados) para soportar HSRP,
  OSPF interpretó ambas rutas hacia la LAN como de igual costo. Esto generó un balanceo de carga
  asimétrico en el retorno de los paquetes. La mitad del tráfico regresaba por el router Standby, el
  cual descartaba los paquetes debido a políticas locales o falta de estado.
- **Solución:** Se implementó enrutamiento simétrico manipulando la métrica de OSPF. Se aplicó
  `ip ospf cost 50` en las interfaces de respaldo cruzadas, forzando a OSPF a utilizar siempre el
  router Activo HSRP para el tráfico de retorno, solucionando la intermitencia de inmediato.

### 7.6 Caída de Redundancia y Enrutamiento por Listas de Control de Acceso (Split-Brain)

- **Problema:** Tras aplicar las ACLs estrictas, la red presentó colapsos, y ambos routers HSRP
  (`RN-R3` y `RN-R4`) se declararon en estado "Active".
- **Causa Raíz:** La sentencia implícita `deny ip any any` al final de las ACLs bloqueó los paquetes
  multicast internos necesarios para la adyacencia de los protocolos de control, específicamente los
  "Hello" de OSPF (protocolo 89) y de HSRP (UDP 1985/2029).
- **Solución:** Se incluyeron sentencias explícitas `permit ospf any any` y
  `permit udp any any eq 1985` **al inicio** de las ACLs extendidas (bloque común documentado en
  [`scripts/ACLs/README.md`](scripts/ACLs/README.md)), restableciendo la comunicación de los planos de
  control sin comprometer el plano de datos.

### 7.7 Ambigüedad de Reglas Administrativas (Conflictos de Tráfico)

- **Problema:** Los departamentos con reglas de salida estrictas (como Ventas y Facturación) no podían
  alcanzar a Soporte ni a Administración, a pesar de que estos últimos tenían la regla de
  "entrada desde todos".
- **Causa Raíz:** Un choque clásico de lógicas de firewall. Una regla estricta de salida en un origen
  bloquea el paquete antes de que pueda ser evaluado por la regla permisiva del destino. Además,
  ligeros desajustes en el tamaño de las subredes (VLSM) impedían el "match" exacto de la IP.
- **Solución:** Se interpretó a Soporte y Administración como **"excepciones globales"**. Se añadieron
  reglas de permiso explícitas hacia sus subredes usando origen `any` en las ACLs de los departamentos
  restrictivos, blindando la configuración contra problemas de subredes asimétricas.

### 7.8 Conflicto entre las reglas "Soporte ↔ todos" y "Nadie entra a Seguridad"

- **Problema:** La tabla de reglas del enunciado es contradictoria para el par Soporte ↔ Seguridad:
  Soporte debe poder comunicarse con *todos* los departamentos en ambos sentidos, pero ningún
  departamento debe tener tráfico de entrada a Seguridad.
- **Causa Raíz:** Ambas reglas no pueden cumplirse simultáneamente; no había un criterio explícito de
  precedencia.
- **Solución:** Se dio **prioridad a la regla más restrictiva** (la de Seguridad), criterio estándar de
  firewall, coherente además con el orden en que el enunciado lista las reglas y con la naturaleza
  aislada del departamento de Seguridad. La justificación quedó documentada en
  [`scripts/ACLs/ACL_SOPORTE.md`](scripts/ACLs/ACL_SOPORTE.md).

---

## 8. Entregables

| Entregable | Ubicación | Estado |
| :--- | :--- | :--- |
| Enlace al repositorio | UEDI (antes de la fecha límite) | ⬜ |
| Archivo de simulación | `Proyecto2_202300848.pkt` | ✅ |
| Manual técnico | Este `README.md` | ✅ |
| Captura de tráfico | `Wireshark/captura_wireshark_202300848.pcapng` | ⬜ |
| Presentación ejecutiva | `Proyecto2_Presentacion_202300848.pdf` | ✅ |

## 9. Documentos de apoyo del repositorio

| Documento | Contenido |
| :--- | :--- |
| [`scripts/README.md`](scripts/README.md) | Índice de scripts, mapa de renombrado de ISPs y tabla comparativa de tecnologías |
| [`scripts/ACLs/README.md`](scripts/ACLs/README.md) | Justificación de cada ACL (interfaz y sentido in/out) |
| [`scripts/ACLs/MATRIZ_PRUEBAS.md`](scripts/ACLs/MATRIZ_PRUEBAS.md) | 24 pruebas ICMP + pruebas de servicios y de redundancia |
| [`Wireshark/ANALISIS_WIRESHARK.md`](Wireshark/ANALISIS_WIRESHARK.md) | Análisis capa por capa de los 4 escenarios capturados |
| [`guia_presentacion.md`](guia_presentacion.md) | Guion de la exposición y respuestas a preguntas del evaluador |
| [`COMPARACION_RC2_vs_OFICIAL_975.md`](COMPARACION_RC2_vs_OFICIAL_975.md) | Comparación de los dos enunciados (documento de trabajo interno) |
| [`PACKET_TRACER_CAMBIOS.md`](PACKET_TRACER_CAMBIOS.md) | Paso a paso para aplicar los cambios en el archivo `.pkt` |
