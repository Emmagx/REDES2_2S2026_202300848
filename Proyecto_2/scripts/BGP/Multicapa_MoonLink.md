# Script: SW-BGP-ML (switch multicapa de borde)

> **ISP 3 — MoonLink** · AS **300** · EIGRP AS 10 + eBGP.
> Interconexión entre ISPs sobre fibra óptica (topología triangular del enunciado).

```text
enable
configure terminal
hostname SW-BGP-ML
ip routing

! Puerto hacia el switch multicapa de AndinaCom (AS 200)
interface gig1/1/1
 no switchport
 ip address 192.168.48.6 255.255.255.252
 no shutdown
 exit

! Puerto hacia el switch multicapa de FibraNet GT (AS 100)
interface gig1/1/2
 no switchport
 ip address 192.168.48.10 255.255.255.252
 no shutdown
 exit

! Puerto hacia el router interno CF-R1
interface gig1/0/1
 no switchport
 ip address 172.16.32.253 255.255.255.252
 no shutdown
 exit

! EIGRP para conocer las rutas internas de MoonLink
! no auto-summary es OBLIGATORIO: sin el, EIGRP anuncia 172.16.0.0/16
! y choca con las redes de los otros ISPs propagadas por BGP.
router eigrp 10
 no auto-summary
 network 172.16.32.252 0.0.0.3
 exit

! BGP
router bgp 300
 bgp router-id 3.3.3.3
 neighbor 192.168.48.5 remote-as 200
 neighbor 192.168.48.9 remote-as 100
 redistribute eigrp 10
 exit
```

> **Opcional (alcance extra del enunciado):** `neighbor 192.168.48.5 password <clave>` y
> `neighbor 192.168.48.9 password <clave>` para autenticar las sesiones eBGP.
