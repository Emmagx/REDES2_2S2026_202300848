# Proyecto 2 - Subnetting

**Carné:** 202300848
- **Primer dígito:** 2
- **Último dígito:** 8
- **Últimos dos dígitos:** 48

---

## 1. Interconexión de ISPs (BGP)
Según el enunciado, la red base para conectar los routers principales de los ISP es `192.168.X.0/16`, donde X son los últimos 2 dígitos del carné.
*   **Red Base BGP:** `192.168.48.0/16`

Dado que la topología de interconexión es un triángulo (3 enlaces punto a punto entre los bordes de los ISP), se recomienda hacer subnetting con máscara `/30` para optimizar y asegurar las conexiones:
*   **Enlace ISP 1 a ISP 2:** `192.168.48.0/30` (IPs utilizables: .1 y .2)
*   **Enlace ISP 2 a ISP 3:** `192.168.48.4/30` (IPs utilizables: .5 y .6)
*   **Enlace ISP 3 a ISP 1:** `192.168.48.8/30` (IPs utilizables: .9 y .10)

---

## 2. ISP 1: Telecom Uno
*   **Red Base:** `172.16.1X.0/24`, donde X es el último dígito del carné.
*   **Red Asignada:** `172.16.18.0/24`
*   **Departamentos:** Administración y Atención al cliente.

**Subnetting sugerido:**
Se dividirá la red `/24` utilizando máscaras `/26` para dejar espacio a los enlaces internos punto a punto (routers) y futuras expansiones.

*   **Administración:** `172.16.18.0/26`
    *   Rango útil: `172.16.18.1` - `172.16.18.62`
    *   Broadcast: `172.16.18.63`
*   **Atención al Cliente:** `172.16.18.64/26`
    *   Rango útil: `172.16.18.65` - `172.16.18.126`
    *   Broadcast: `172.16.18.127`
*   *Reserva para enlaces internos (OSPF):* A partir de `172.16.18.128/26`, segmentado en redes `/30` (ej. 172.16.18.128/30, 172.16.18.132/30, etc.).

---

## 3. ISP 2: Redes Nacionales
*   **Red Base:** `172.16.2X.0/24`, donde X es el último dígito del carné.
*   **Red Asignada:** `172.16.28.0/24`
*   **Departamentos:** Ventas y Facturación.

**Subnetting sugerido:**
Aplicando la misma lógica (máscaras `/26` para departamentos).

*   **Ventas:** `172.16.28.0/26`
    *   Rango útil: `172.16.28.1` - `172.16.28.62`
    *   Broadcast: `172.16.28.63`
*   **Facturación:** `172.16.28.64/26`
    *   Rango útil: `172.16.28.65` - `172.16.28.126`
    *   Broadcast: `172.16.28.127`
*   *Reserva para enlaces internos (OSPF):* A partir de `172.16.28.128/26`, segmentado en redes `/30`.

---

## 4. ISP 3: Conexiones Futuras
*   **Red Base:** `172.16.3X.0/24`, donde X es el **primer** dígito del carné.
*   **Red Asignada:** `172.16.32.0/24`
*   **Departamentos:** Soporte y Seguridad.

**Subnetting sugerido:**
*   **Soporte:** `172.16.32.0/26`
    *   Rango útil: `172.16.32.1` - `172.16.32.62`
    *   Broadcast: `172.16.32.63`
*   **Seguridad:** `172.16.32.64/26`
    *   Rango útil: `172.16.32.65` - `172.16.32.126`
    *   Broadcast: `172.16.32.127`
*   *Reserva para enlaces internos (EIGRP):* A partir de `172.16.32.128/26`, segmentado en redes `/30`.
