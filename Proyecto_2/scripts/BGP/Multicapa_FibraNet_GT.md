# Script: SW-BGP-FG (switch multicapa de borde)

> **ISP 1 — FibraNet GT** · AS **100** · OSPF área 0 + eBGP.
> Interconexión entre ISPs sobre fibra óptica (topología triangular del enunciado).

```text
enable
configure terminal
hostname SW-BGP-FG
ip routing

! Puerto hacia el switch multicapa de AndinaCom (AS 200)
interface gig1/1/1
 no switchport
 ip address 192.168.48.1 255.255.255.252
 no shutdown
 exit

! Puerto hacia el switch multicapa de MoonLink (AS 300)
interface gig1/1/2
 no switchport
 ip address 192.168.48.9 255.255.255.252
 no shutdown
 exit

! Puerto hacia el router interno T1R1
! Se movio al bloque 192.168.48.0/16 para liberar 172.16.18.0/24 a las dos /25 de departamento
interface gig1/0/1
 no switchport
 ip address 192.168.48.34 255.255.255.252
 no shutdown
 exit

! OSPF para conocer las rutas internas de FibraNet GT
! + redistribucion de BGP hacia OSPF: SIN ESTO los routers internos (T1R2..T1R5)
!   no conocen las redes de AndinaCom ni MoonLink, y el servidor DHCP no puede
!   responder a las giaddr de los departamentos.
router ospf 1
 redistribute bgp 100 subnets
 network 192.168.48.32 0.0.0.3 area 0
 exit

! BGP
router bgp 100
 bgp router-id 1.1.1.1
 neighbor 192.168.48.2 remote-as 200
 neighbor 192.168.48.10 remote-as 300
 redistribute ospf 1 subnets
 exit
```

> **Opcional (alcance extra del enunciado):** `neighbor 192.168.48.2 password <clave>` y
> `neighbor 192.168.48.10 password <clave>` para autenticar las sesiones eBGP.
