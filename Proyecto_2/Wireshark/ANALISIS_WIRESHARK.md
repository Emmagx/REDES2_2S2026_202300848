# Análisis de tráfico con Wireshark — Sección 4.5

**Estudiante:** Carné 202300848
**Curso:** Redes de Computadoras 2 · Proyecto 2

**Archivo de captura:** `captura_wireshark_202300848.pcapng` (en esta misma carpeta — se genera
ejecutando [`generar_trafico.sh`](generar_trafico.sh) dentro de la máquina virtual; ver
[`README.md`](README.md))
**Herramienta:** Wireshark (captura generada con `dumpcap` / `tshark` dentro de una máquina virtual)
**Entorno:** máquina virtual con Ubuntu Desktop / Kali Linux en modo **NAT o red interna**, para
garantizar que el tráfico capturado provenga **únicamente de la VM** y no del equipo anfitrión.

---

## 0. Resumen del análisis

El enunciado exige documentar **el análisis capa por capa de al menos tres protocolos distintos**.
Esta captura contiene **cuatro escenarios** y se analizan **cinco protocolos**: TCP, DNS, HTTP, TLS y
ICMP (más el direccionamiento Ethernet/IP que los transporta).

| # | Escenario | Protocolo principal | Puerto / tipo | Paquetes encontrados |
| :-: | :--- | :--- | :--- | :---: |
| 1 | Three-way handshake TCP | TCP | 80 / 443 | _completar_ |
| 2 | Resolución DNS | DNS | UDP 53 | _completar_ |
| 3a | Petición HTTP | HTTP sobre TCP | TCP 80 | _completar_ |
| 3b | Petición HTTPS | TLS sobre TCP | TCP 443 | _completar_ |
| 4 | ICMP | ICMP | tipo 8 / tipo 0 | _completar_ |

**Filtros de visualización utilizados:**

```text
tcp.flags.syn == 1 && tcp.flags.ack == 0     ! SYN
tcp.flags.syn == 1 && tcp.flags.ack == 1     ! SYN-ACK
dns                                          ! consultas y respuestas DNS
http.request                                 ! petición HTTP en texto plano
tls.handshake                                ! handshake TLS
icmp                                         ! Echo Request / Echo Reply
```

---

## 1. Escenario 1 — Three-way handshake TCP

**Tráfico generado:** `curl -v http://example.com` (conexión TCP al puerto 80).

### 1.1 Concepto

El *three-way handshake* es el procedimiento con el que TCP establece una conexión confiable antes de
enviar datos. Se llama de tres vías porque requiere tres mensajes:

```text
   Cliente                                              Servidor
      |  --------------- SYN  (seq = X) ------------------->  |   (1) "Quiero conectar"
      |                                                        |
      |  <-------- SYN-ACK (seq = Y, ack = X+1) -------------- |   (2) "Acepto, yo también quiero"
      |                                                        |
      |  --------------- ACK  (seq = X+1, ack = Y+1) --------> |   (3) "Confirmado, empecemos"
```

**Formación de la conexión:** el cliente elige un **ISN** (*Initial Sequence Number*) aleatorio `X` y
lo envía en el `SYN`. El servidor responde con su propio `SYN` con ISN `Y` y **reconoce** el del
cliente con `ack = X + 1`. Finalmente el cliente reconoce el del servidor con `ack = Y + 1`. A partir
de ahí los números de secuencia avanzan según la cantidad de bytes de datos transmitidos.

### 1.2 Evidencia en la captura (completar con los valores reales)

| # | Origen | Destino | Flags | Seq | Ack | Len | Observación |
| :-: | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 1 | _IP PC_ | _IP servidor_ | `SYN` | _X_ | 0 | 0 | Inicio de conexión. Flags `0x002` |
| 2 | _IP servidor_ | _IP PC_ | `SYN, ACK` | _Y_ | _X+1_ | 0 | Aceptación. Flags `0x012` |
| 3 | _IP PC_ | _IP servidor_ | `ACK` | _X+1_ | _Y+1_ | 0 | Confirmación. Flags `0x010` |

### 1.3 Análisis capa por capa del paquete `SYN`

| Capa | Campo | Valor observado | Explicación |
| :--- | :--- | :--- | :--- |
| **1-2 Física/Enlace** | `Ethernet II` · Src / Dst MAC | _MAC de la VM_ → _MAC del gateway_ | El destino en la trama Ethernet **no** es la MAC del servidor remoto, sino la de la puerta de enlace (capa 2 solo tiene alcance local). |
| **2 Enlace** | Type | `0x0800` (IPv4) | Indica que la carga útil es un paquete IPv4. |
| **3 Red** | Version / IHL | `4` / `20 bytes` | Sin opciones: cabecera IP mínima. |
| **3 Red** | Src / Dst IP | _IP privada de la VM_ → _IP pública de example.com_ | El router aplica **NAT** en modo NAT de VirtualBox: la IP origen se traduce a la del host. |
| **3 Red** | Protocol | `6` (TCP) | Multiplexación hacia la capa de transporte. |
| **3 Red** | TTL | _valor_ | Se decrementa en cada salto; el valor inicial revela cuántos saltos recorrió. |
| **4 Transporte** | Src Port | _puerto efímero (p. ej. 51234)_ | Puerto aleatorio elegido por el sistema operativo cliente. |
| **4 Transporte** | Dst Port | `80` | Puerto *well-known* de HTTP. |
| **4 Transporte** | Flags | `SYN = 1`, resto en 0 | Solicitud de sincronización. |
| **4 Transporte** | Sequence Number | _X_ | ISN del cliente (relativo en Wireshark). |
| **4 Transporte** | Window Size | _valor_ | Control de flujo: cuántos bytes puede recibir sin confirmar. |
| **4 Transporte** | Options | MSS, SACK Permitted, Window Scale | Negociación de parámetros TCP. |

> **Verificación del handshake completo:** en Wireshark, *Statistics → Flow Graph* (o clic derecho en
> un paquete → *Follow → TCP Stream*) muestra la secuencia `SYN → SYN-ACK → ACK` y luego la petición
> `GET / HTTP/1.1` y la respuesta `200 OK`. El `SYN` debe tener `Len = 0`.

---

## 2. Escenario 2 — Resolución DNS

**Tráfico generado:** `dig @8.8.8.8 example.com A`, `dig @8.8.8.8 example.com MX` y
`dig @1.1.1.1 www.wikipedia.org AAAA` (o `nslookup` con las mismas consultas).

### 2.1 Concepto

DNS traduce nombres de dominio a direcciones IP. Para ello envía una **consulta** (Query) y recibe
una **respuesta** (Response) normalmente sobre **UDP puerto 53** (usa TCP 53 cuando la respuesta
excede 512 bytes o en transferencias de zona). Cada registro tiene un **TTL** (*Time To Live*) que
indica cuántos segundos puede conservarse en caché antes de volver a preguntar.

Tipos de registro relevantes:

| Tipo | Significado | Ejemplo |
| :--- | :--- | :--- |
| **A** | Dirección IPv4 | `example.com → 93.184.216.34` |
| **AAAA** | Dirección IPv6 | `example.com → 2606:2800:...` |
| **MX** | Servidor de correo | `example.com → 0 .` |
| **CNAME** | Alias | `www.x.com → x.com` |
| **NS** | Servidor de nombres autoritativo | `example.com → a.iana-servers.net` |

### 2.2 Evidencia en la captura (completar con los valores reales)

| # | Origen | Destino | Puerto | Longitud | Consulta / Respuesta | Contenido |
| :-: | :--- | :--- | :--- | :--- | :--- | :--- |
| 1 | _IP VM_ | `8.8.8.8` | `53` | _n_ | **Standard query** | `A example.com` |
| 2 | `8.8.8.8` | _IP VM_ | `53` | _n_ | **Standard query response** | `A 93.184.216.34`, TTL = _valor_ |
| 3 | _IP VM_ | `8.8.8.8` | `53` | _n_ | **Standard query** | `MX example.com` |
| 4 | `8.8.8.8` | _IP VM_ | `53` | _n_ | **Standard query response** | `MX 0 .`, TTL = _valor_ |
| 5 | _IP VM_ | `1.1.1.1` | `53` | _n_ | **Standard query** | `AAAA www.wikipedia.org` |

**Datos a reportar:**

| Parámetro preguntado por el enunciado | Valor observado |
| :--- | :--- |
| Tipo de registro consultado | `A` (y `MX`, `AAAA`) |
| TTL de la respuesta | _completar_ |
| Puerto y protocolo de transporte | **UDP 53** (y TCP 53 si la respuesta excede 512 bytes) |
| Servidor DNS consultado | `8.8.8.8` (Google) y `1.1.1.1` (Cloudflare) |
| Longitud típica de la consulta | ~ 70-80 bytes |
| Flag `Recursion desired` | `1` (el cliente pide resolución recursiva) |

### 2.3 Análisis capa por capa de la consulta DNS

| Capa | Campo | Valor observado | Explicación |
| :--- | :--- | :--- | :--- |
| **2 Enlace** | Src / Dst MAC | _VM_ → _gateway_ | El paquete sale hacia la puerta de enlace de la VM. |
| **3 Red** | Protocol | `17` (UDP) | DNS usa UDP por ser una consulta corta y sin necesidad de conexión. |
| **3 Red** | Src / Dst IP | _IP VM_ → `8.8.8.8` | Destino externo (servidor público de Google). |
| **4 Transporte** | Src Port | _efímero (p. ej. 44123)_ | Puerto de origen aleatorio. |
| **4 Transporte** | Dst Port | `53` | Puerto estándar del servicio DNS. |
| **4 Transporte** | Length | _valor_ | 8 bytes de cabecera UDP + datos. |
| **7 Aplicación** | Transaction ID | _valor_ | Identificador que empareja consulta con respuesta. |
| **7 Aplicación** | Flags | `0x0100` (query) / `0x8180` (response) | Consulta estándar y respuesta con *recursion available*. |
| **7 Aplicación** | Queries / Answers | `example.com: type A, class IN` | Nombre, tipo y clase del registro. |

> **Relación con el proyecto:** en la topología de Packet Tracer este mismo mecanismo se usa cuando
> una PC escribe `www.proyecto2_202300848.com`; el servidor DNS de FibraNet GT (`192.168.48.50`)
> responde con la consulta tipo **A** hacia toda la red.

---

## 3. Escenario 3 — Petición HTTP vs HTTPS

**Tráfico generado:** `curl http://example.com` (HTTP) y `curl https://example.com` (HTTPS).

### 3.1 Comparación directa

| Característica | HTTP | HTTPS |
| :--- | :--- | :--- |
| Puerto de destino | **80** | **443** |
| Protocolo de aplicación | HTTP | HTTP **sobre TLS** |
| Confidencialidad | ❌ Texto plano, legible en Wireshark | ✅ Cifrado (TLS) |
| Visibilidad del contenido | Se ve `GET / HTTP/1.1`, las cabeceras y el HTML | Solo se ve `Application Data` binario |
| Integridad / autenticidad | ❌ Sin verificación del servidor | ✅ Certificado X.509 + firmas |
| Overhead | Menor (sin handshake criptográfico) | Mayor (handshake TLS + cifrado) |
| Puertos capturados | `80` | `443` |
| Filtro de Wireshark | `http` / `http.request` | `tls` / `tls.handshake` |

### 3.2 Por qué el contenido de HTTPS aparece cifrado

HTTPS = HTTP + **TLS**. El cifrado es **simétrico** (AES, ChaCha20) porque es rápido, pero las claves
simétricas se negocian de forma **asimétrica** (ECDHE + RSA/ECDSA) mediante el *handshake* TLS, que
además autentica al servidor con su certificado. Wireshark no puede descifrar el contenido porque:

1. La clave de sesión se deriva de un **secreto compartido** calculado con intercambio de claves
   Diffie-Hellman efímero (ECDHE), que **no viaja por la red**.
2. Solo el cliente y el servidor conocen los secretos; una captura pasiva no basta para derivarlos.
   *(Para descifrarlo habría que exportar la clave de sesión, p. ej. `SSLKEYLOGFILE`, o poseer la
   clave privada del servidor si se usara RSA sin PFS — ningún caso aplicable a una captura pasiva.)*
3. Renegociar TLS 1.3 añade *forward secrecy*: aunque se comprometiera la clave privada del servidor
   en el futuro, las sesiones pasadas seguirían siendo indescifrables.

En la práctica, en Wireshark se observa la secuencia:

```text
   TCP SYN → SYN-ACK → ACK                          (conexión TCP al puerto 443)
   Client Hello        (TLS 1.3, SNI = ejemplo.com, cipher suites ofrecidas)
   Server Hello        (cipher suite elegida) + Change Cipher Spec
   Certificate, Server Key Exchange, Server Hello Done
   Client Key Exchange, Change Cipher Spec, Finished
   Application Data  ← a partir de aquí TODO el contenido HTTP va cifrado
```

### 3.3 Evidencia en la captura (completar con los valores reales)

| # | Escenario | Puerto | Protocolo | Qué se observa en Wireshark |
| :-: | :--- | :--- | :--- | :--- |
| 1 | HTTP | `80` | HTTP | `GET / HTTP/1.1` + cabeceras en texto plano |
| 2 | HTTP | `80` | HTTP | `HTTP/1.1 200 OK` y el cuerpo HTML legible |
| 3 | HTTPS | `443` | TCP | `SYN` / `SYN-ACK` / `ACK` al puerto 443 |
| 4 | HTTPS | `443` | TLS 1.3 | `Client Hello` con **Server Name Indication** = _dominio_ |
| 5 | HTTPS | `443` | TLS 1.3 | `Server Hello`, `Certificate`, `Finished` |
| 6 | HTTPS | `443` | TLS 1.3 | `Application Data` → **contenido cifrado** |

**Datos a reportar:**

| Parámetro | Valor observado |
| :--- | :--- |
| Versión de TLS negociada | _TLS 1.3 / 1.2_ |
| Cipher suite elegida | _p. ej. TLS_AES_128_GCM_SHA256_ |
| ¿Se ve el HTML en la captura HTTPS? | **No** — aparece como `Application Data` |
| ¿Se ve el HTML en la captura HTTP? | **Sí**, en texto plano |
| SNI (nombre del servidor) | _sí es visible_, el cifrado no oculta el SNI en TLS 1.2/1.3 sin ECH |

---

## 4. Escenario 4 — ICMP

**Tráfico generado:** `ping -c 4 8.8.8.8` y `ping -c 4 1.1.1.1`.

### 4.1 Concepto

`ping` utiliza el protocolo **ICMP** (encapsulado directamente en IP, sin TCP ni UDP) para verificar
alcanzabilidad y medir el RTT (*Round Trip Time*). Envía un mensaje **Echo Request (tipo 8)** y espera
un **Echo Reply (tipo 0)** del mismo tamaño.

### 4.2 Evidencia en la captura (completar con los valores reales)

| # | Origen | Destino | Tipo ICMP | Código | Identificador | Seq | Tamaño | TTL |
| :-: | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 1 | _IP VM_ | `8.8.8.8` | `8` (Echo Request) | 0 | _valor_ | 1 | 64 bytes | _valor_ |
| 2 | `8.8.8.8` | _IP VM_ | `0` (Echo Reply) | 0 | _valor_ | 1 | 64 bytes | _valor_ |
| 3 | _IP VM_ | `8.8.8.8` | `8` (Echo Request) | 0 | _valor_ | 2 | 64 bytes | _valor_ |
| 4 | `8.8.8.8` | _IP VM_ | `0` (Echo Reply) | 0 | _valor_ | 2 | 64 bytes | _valor_ |

**Datos a reportar:**

| Parámetro | Valor observado |
| :--- | :--- |
| Paquetes enviados / recibidos | 4 / 4 (0% de pérdida) |
| RTT mínimo / promedio / máximo | _completar_ ms |
| TTL del Echo Reply | _completar_ |
| Tamaño de la carga útil | 56 bytes (64 bytes con la cabecera ICMP) |
| Identificador ICMP del `ping` | _valor_ (mismo en todos los paquetes de la sesión) |

### 4.3 Análisis capa por capa del Echo Request

| Capa | Campo | Valor observado | Explicación |
| :--- | :--- | :--- | :--- |
| **2 Enlace** | Dst MAC | _gateway_ | Destino local (fuera de la subred → va al router). |
| **3 Red** | Protocol | `1` (ICMP) | ICMP viaja directamente sobre IP, no sobre TCP/UDP. |
| **3 Red** | Src / Dst IP | _IP VM_ → `8.8.8.8` | Traducidas por el NAT de la máquina virtual. |
| **3 Red** | TTL | _valor inicial_ | El valor decrece en cada salto; el TTL recibido = inicial − nº de saltos. |
| **3 Red** | Identification / Flags | _valor_ / `DF` | Fragmentación y control de MTU. |
| **4 ICMP** | Type = `8` | Echo Request | Solicitud de eco. |
| **4 ICMP** | Code = `0` | – | Código estándar. |
| **4 ICMP** | Checksum | _valor_ | Verifica la integridad de la cabecera ICMP. |
| **4 ICMP** | Identifier / Sequence | _valor_ / `1..4` | Empareja solicitudes y respuestas del mismo proceso `ping`. |
| **4 ICMP** | Data | 56 bytes de relleno | Patrón incremental; suele incluir la marca de tiempo para medir el RTT. |

> **Relación con el proyecto:** el ping es la herramienta con la que se validan las **ACLs** de la
> topología (ver [`../scripts/ACLs/MATRIZ_PRUEBAS.md`](../scripts/ACLs/MATRIZ_PRUEBAS.md)). Un
> `Echo Request` bloqueado por una ACL se manifiesta en Packet Tracer como `Request timed out`,
> exactamente igual que en esta captura cuando un destino no responde.

---

## 5. Conclusión del análisis

La captura demuestra de forma práctica, y a nivel de paquete, los conceptos del proyecto:

1. **TCP** establece conexiones con un handshake de tres vías y usa números de secuencia para
   garantizar la entrega ordenada — el mismo mecanismo que transporta BGP (TCP 179) entre los tres ISPs.
2. **DNS** resuelve nombres con consultas UDP/53 y respuestas con TTL — el servicio que en la
   topología provee FibraNet GT a toda la red.
3. **HTTP y HTTPS** comparten el modelo petición/respuesta, pero HTTPS añade una capa TLS que aporta
   confidencialidad, integridad y autenticidad; el precio es un handshake adicional y un mayor uso de CPU.
4. **ICMP** opera sobre IP y es la herramienta básica de diagnóstico — la evidencia usada para validar
   las ACLs y la conectividad extremo a extremo en Packet Tracer.

El análisis se realizó **capa por capa** distinguiendo el direccionamiento de enlace (MAC local del
gateway) del direccionamiento de red (IP extremo a extremo, traducida por NAT), el direccionamiento de
transporte (puertos) y la carga útil de aplicación.
