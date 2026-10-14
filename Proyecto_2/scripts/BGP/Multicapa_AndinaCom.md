# Script: SW-BGP-AC (switch multicapa de borde)

> **ISP 2 — AndinaCom** · AS **200** · OSPF área 0 + eBGP.
> Interconexión entre ISPs sobre fibra óptica (topología triangular del enunciado).

```text
enable
configure terminal
hostname SW-BGP-AC
ip routing

! Puerto hacia el switch multicapa de FibraNet GT (AS 100)
interface gig1/1/1
 no switchport
 ip address 192.168.48.2 255.255.255.252
 no shutdown
 exit

! Puerto hacia el switch multicapa de MoonLink (AS 300)
interface gig1/1/2
 no switchport
 ip address 192.168.48.5 255.255.255.252
 no shutdown
 exit

! Puerto hacia el router interno RN-R1
interface gig1/0/1
 no switchport
 ip address 172.16.28.253 255.255.255.252
 no shutdown
 exit

! OSPF para conocer las rutas internas de AndinaCom
router ospf 1
 network 172.16.28.252 0.0.0.3 area 0
 exit

! BGP
router bgp 200
 bgp router-id 2.2.2.2
 neighbor 192.168.48.1 remote-as 100
 neighbor 192.168.48.6 remote-as 300
 redistribute ospf 1
 exit
```

> **Opcional (alcance extra del enunciado):** `neighbor 192.168.48.1 password <clave>` y
> `neighbor 192.168.48.6 password <clave>` para autenticar las sesiones eBGP.
