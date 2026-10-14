# Matriz de pruebas de las reglas de comunicación

> Evidencia exigida por la rúbrica oficial **2.5**: verificar las ACLs *"con ping (ICMP) y con acceso
> al servicio HTTP/HTTPS según corresponda"*.
>
> Ejecutar cada prueba **dos veces** (la primera puede fallar por resolución ARP) y capturar
> pantalla del resultado. Se recomienda la herramienta **Add Simple PDU** de Packet Tracer para
> dejar la tabla de resultados visible, más una captura del `Command Prompt` para el ping.

## 1. Pruebas ICMP departamento → departamento (ping)

Leyenda: ✅ Exitoso · 🚫 Bloqueado

| # | Origen | Destino | Esperado | Motivo (regla del enunciado) |
| :-: | :--- | :--- | :---: | :--- |
| 1 | Seguridad | Administración | ✅ | Seguridad inicia hacia cualquier depto |
| 2 | Seguridad | Atención al Cliente | ✅ | Seguridad inicia hacia cualquier depto |
| 3 | Seguridad | Ventas | ✅ | Seguridad inicia hacia cualquier depto |
| 4 | Seguridad | Facturación | ✅ | Seguridad inicia hacia cualquier depto |
| 5 | Seguridad | Soporte | ✅ | Seguridad inicia hacia cualquier depto |
| 6 | Soporte | Administración | ✅ | Soporte ↔ todos |
| 7 | Soporte | Atención al Cliente | ✅ | Soporte ↔ todos |
| 8 | Soporte | Ventas | ✅ | Soporte ↔ todos |
| 9 | Soporte | Facturación | ✅ | Soporte ↔ todos |
| 10 | Soporte | Seguridad | 🚫 | **Nadie entra a Seguridad** (regla que gana) |
| 11 | Administración | Ventas | ✅ | Administración ↔ todos |
| 12 | Administración | Facturación | ✅ | Administración ↔ todos |
| 13 | Administración | Soporte | ✅ | Administración ↔ todos |
| 14 | Administración | Atención al Cliente | ✅ | Administración ↔ todos |
| 15 | Administración | Seguridad | 🚫 | Nadie entra a Seguridad |
| 16 | Atención al Cliente | Ventas | ✅ | ATC ↔ Ventas |
| 17 | Ventas | Atención al Cliente | ✅ | ATC ↔ Ventas |
| 18 | Atención al Cliente | Facturación | 🚫 | ATC ↛ Facturación |
| 19 | Facturación | Atención al Cliente | 🚫 | Facturación ↛ ATC |
| 20 | Facturación | Ventas | ✅ | Facturación ↔ Ventas |
| 21 | Ventas | Facturación | ✅ | Ventas ↔ Facturación |
| 22 | Ventas | Seguridad | 🚫 | Nadie entra a Seguridad |
| 23 | Facturación | Seguridad | 🚫 | Nadie entra a Seguridad |
| 24 | Atención al Cliente | Seguridad | 🚫 | Nadie entra a Seguridad |

**Total: 24 pruebas ICMP** (18 exitosas y 6 bloqueadas).

## 2. Pruebas de servicios (HTTP / HTTPS / DNS / DHCP)

| # | Prueba | Desde | Comando / acción | Esperado |
| :-: | :--- | :--- | :--- | :--- |
| 25 | DNS | Una PC de cada departamento | `nslookup www.proyecto2_202300848.com` | Resuelve a `192.168.48.50` |
| 26 | HTTP | Web Browser de una PC de cada depto | `http://www.proyecto2_202300848.com` | Carga la página estática |
| 27 | HTTPS | Web Browser de una PC de cada depto | `https://www.proyecto2_202300848.com` | Carga la página cifrada |
| 28 | DHCP | Cada PC (IP Configuration → DHCP) | – | Recibe IP, máscara, gateway y DNS del pool correcto |
| 29 | DHCP en Ventas/Facturación | PC-Ventas1 / PC-Facturación1 | – | Gateway entregado = **VIP de HSRP** (`.1` / `.65`) |
| 30 | DHCP en Soporte/Seguridad | Todas las PCs y la laptop Wi-Fi | – | Direccionamiento correcto cruzando dominios de enrutamiento |

> **Por qué HTTP/HTTPS se prueba contra el servidor y no entre departamentos:**
> el único servidor web de la topología es el de FibraNet GT (`192.168.48.50`). Ningún departamento
> aloja un servidor HTTP, así que la verificación de las reglas *entre* departamentos se realiza con
> **ICMP** (los `deny`/`permit` de TCP/80 rigen la lógica del firewall y quedan documentados en
> `scripts/ACLs/`), y el acceso al servicio HTTP/HTTPS se verifica abriendo el dominio del proyecto
> desde una PC de cada departamento.

## 3. Pruebas de redundancia y alta disponibilidad

| # | Prueba | Procedimiento | Esperado |
| :-: | :--- | :--- | :--- |
| 31 | HSRP Ventas | `ping -t` continuo desde PC-Ventas1 al servidor y **desconectar** la interfaz del router activo | Falla ≤ 2 paquetes y se recupera automáticamente |
| 32 | HSRP Facturación | Idem desde PC-Facturación1 | Falla ≤ 2 paquetes y se recupera |
| 33 | Rol HSRP | `show standby brief` en RN-R3 y RN-R4 | Uno **Active**, otro **Standby** (nunca dos Active) |
| 34 | LACP FibraNet GT | `show etherchannel summary` en T1S1/T1S2 y T1S3/T1S4 | Grupo **SU** (in use) con 2 puertos |
| 35 | LACP AndinaCom | `show etherchannel summary` en SW1/SW2 y SW3/SW4 | Grupo **SU** con 2 puertos |
| 36 | LACP MoonLink | `show etherchannel summary` en SW1/SW2-SOPORTE y SW3/SW4-SEGURIDAD | Grupo **SU** con 2 puertos |
| 37 | BGP | `show ip bgp summary` en los 3 switches multicapa | 2 vecinos en estado **Established** (o números distintos de 0) |
| 38 | OSPF | `show ip ospf neighbor` en FibraNet GT y AndinaCom | Todos los vecinos en **FULL** |
| 39 | EIGRP | `show ip eigrp neighbors` en MoonLink | Todos los vecinos en **UP** |
| 40 | Ruta inter-ISP | `traceroute` desde una PC de Soporte a una PC de Administración | Pasa por CF-R1 → SW-BGP-ML → SW-BGP-FG → T1R1 … |

## 4. Guion para la evaluación oral (rúbrica 2.6, 5 pts)

Preguntas previsibles del evaluador y su respuesta ya justificada en este repositorio:

| Pregunta | Dónde está la respuesta |
| :--- | :--- |
| ¿En qué interfaz y sentido aplicaste cada ACL y por qué? | Este directorio, §1 del `README.md` de ACLs |
| ¿Por qué Soporte no puede llegar a Seguridad si "habla con todos"? | `ACL_SOPORTE.md` (conflicto de reglas y su resolución) |
| ¿Por qué la ACL de Ventas está en dos routers? | `ACL_VENTAS.md` (supervivencia al failover de HSRP) |
| ¿Por qué no bloqueaste el tráfico entrante en Seguridad? | §1 del `README.md` de ACLs (ACLs sin estado y respuestas) |
| ¿Por qué las ACLs permiten OSPF/EIGRP/DHCP/DNS? | §2 del `README.md` de ACLs (plano de control y servicios) |
| ¿Por qué ISP 1 usa `/25` y no `/26` como antes? | README principal §2.1 (75 hosts requeridos → 126 útiles) |
| ¿Por qué los enlaces punto a punto están en `192.168.48.0/16`? | README principal §2.1 (las dos `/25` consumen el `/24`; el enunciado asigna ese bloque para routers) |
