# Scripts de configuración — CLI

Todas las configuraciones de routers y switches multicapa se aplicaron **desde la línea de comandos**
(requisito eliminatorio de la rúbrica oficial 8.1). Estos archivos documentan el equivalente CLI de
cada dispositivo del archivo `Proyecto2_202300848.pkt`.

## Mapa de renombrado de ISPs (enunciado oficial 975)

| Enunciado RC2 (anterior) | Enunciado oficial | Carpeta | Prefijo de hostname |
| :--- | :--- | :--- | :--- |
| Telecom Uno | **FibraNet GT** | [`FibraNet_GT/`](FibraNet_GT/) | `T1` (T1R1…T1R5) |
| Redes Nacionales | **AndinaCom** | [`AndinaCom/`](AndinaCom/) | `RN` (RN-R1…RN-R5) |
| Conexiones Futuras / Link Global | **MoonLink** | [`MoonLink/`](MoonLink/) | `CF` (CF-R1…CF-R5) |

> Los prefijos `T1`/`RN`/`CF` se conservan porque son los **hostnames reales de los dispositivos del
> archivo `.pkt`**. Renombrarlos es opcional (implica reconfigurar 30 equipos en Packet Tracer); si se
> hace, hay que actualizar también estos scripts y las capturas del README.

## Estructura

| Carpeta | Contenido |
| :--- | :--- |
| [`FibraNet_GT/`](FibraNet_GT/) | 5 routers (`T1R1`…`T1R5`) + 4 switches de acceso con EtherChannel (LACP) |
| [`AndinaCom/`](AndinaCom/) | 5 routers (`RN-R1`…`RN-R5`, con HSRP en RN-R3/RN-R4) + 4 switches con LACP |
| [`MoonLink/`](MoonLink/) | 5 routers (`CF-R1`…`CF-R5`) + 4 switches con LACP |
| [`BGP/`](BGP/) | Los 3 switches multicapa de borde (AS 100 / 200 / 300) |
| [`ACLs/`](ACLs/) | Las 6 ACLs extendidas + justificación de interfaz/sentido + matriz de pruebas |

## Resumen de tecnologías por ISP

| | FibraNet GT (ISP 1) | AndinaCom (ISP 2) | MoonLink (ISP 3) |
| :--- | :--- | :--- | :--- |
| AS | 100 | 200 | 300 |
| Topología | Árbol | Jerárquica (core/distribución/acceso) | Hub-and-spoke |
| Enrutamiento interno | OSPF (área 0) | OSPF (área 0) | EIGRP AS 10 |
| Red LAN | `172.16.18.0/24` → 2 × `/25` | `172.16.28.0/24` → 2 × `/26` | `172.16.32.0/24` → 2 × `/26` |
| Hosts útiles por depto | **126** (requisito ≥ 75) | 62 | **62** (requisito ≥ 45) |
| Redundancia L3 | — | **HSRP** grupos 10 y 20 | — |
| Agregación de enlaces | 2 × LACP (2 puertos c/u) | 2 × LACP (2 puertos c/u) | 2 × LACP (2 puertos c/u) |
| Servicio asignado | **DNS + HTTP/HTTPS** | **DHCP central** | **Red inalámbrica (WRT300N)** |
| Routers / hosts | 5 / 5 | 5 / 5 | 5 / 5 (+ laptop Wi-Fi) |

## Servidores (direccionamiento estático, no son dispositivos finales)

| Servidor | IP | Ubicación | Servicios |
| :--- | :--- | :--- | :--- |
| SERVER DNS/HTTP/HTTPS | `192.168.48.50` (gw `192.168.48.49`) | FibraNet GT, `T1R5 g0/2` | DNS (`www.proyecto2_202300848.com`), HTTP y HTTPS |
| SERVER-DHCP | `172.16.28.130` | AndinaCom, `RN-R5 g0/1` | DHCP con 6 pools (uno por departamento) |

> Los **dispositivos finales** (PCs y laptop) obtienen su dirección **exclusivamente por DHCP**,
> requisito eliminatorio de la rúbrica 8.1.
