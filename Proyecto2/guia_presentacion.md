# Guía de Presentación - Proyecto 2

Esta guía está diseñada para que conduzcas tu evaluación o presentación de forma segura, estructurada y demostrando un dominio absoluto del proyecto.

## 1. Preparación Antes de Iniciar
- **Modo Realtime:** Asegúrate de que Packet Tracer esté en la pestaña `Realtime` (abajo a la derecha).
- **Convergencia:** Haz clic en el botón `Fast Forward Time (>>)` unas 10 veces rápidas. Esto asegura que STP, OSPF, EIGRP y BGP ya hayan calculado sus rutas y HSRP ya sepa quién es el router Activo.
- **Prueba en Frío:** Manda un ping rápido desde cada departamento clave antes de compartir pantalla para asegurar que las memorias ARP de las PCs estén frescas.

## 2. Orden Sugerido de Exposición

### Fase 1: Visión General y Direccionamiento (2 Minutos)
- Muestra la topología general.
- Explica brevemente que interconectaste 3 ISPs usando **BGP** como protocolo exterior.
- Menciona que Redes Nacionales y Telecom Uno usan **OSPF**, mientras que Conexiones Futuras usa **EIGRP**, demostrando la redistribución de protocolos.
- Haz énfasis en cómo usaste VLSM y subneteo (subredes `/26` o las que apliquen según el último dígito de tu carné).

### Fase 2: Servicios Principales (DHCP, DNS y Web) (3 Minutos)
- **DHCP:** Muestra cómo `Server-Admin` reparte IPs. Ve a la PC de Ventas o Facturación (que están en otro ISP), pásala a Static y luego a DHCP para que vean que obtiene su IP.
    - *Frase clave:* "Utilizamos `ip helper-address` para centralizar el servicio DHCP cruzando dominios de enrutamiento."
- **DNS y Web:** Abre el navegador en cualquier PC y entra a `www.proyecto2_202300848.com`.
    - *Frase clave:* "El servidor en Telecom Uno resuelve el dominio y sirve la página a toda la red, demostrando ruteo de extremo a extremo."

### Fase 3: Redundancia Avanzada (La Joya de la Corona) (3 Minutos)
- Muéstrales los cables cruzados en **Redes Nacionales**.
- Explica que implementaste **HSRP** para redundancia de puerta de enlace.
- *Demostración Práctica:*
    1. Abre una consola haciendo `ping continuo (-t)` a un servidor.
    2. Elimina o apaga el enlace principal del Router Activo.
    3. Muestra cómo el ping falla 1 o 2 veces y luego se recupera solo.
- *Frase clave:* "Tuvimos que ajustar los costos de OSPF (`ip ospf cost 50`) en las interfaces cruzadas para forzar enrutamiento simétrico y evitar la inestabilidad que causa el balanceo de carga en escenarios HSRP." (El ingeniero amará esta frase).

### Fase 4: Seguridad y Listas de Control de Acceso (ACLs) (4 Minutos)
- Saca tu **Matriz de Pruebas** (el checklist).
- Ejecuta las pruebas clave usando el sobrecito del simulador (PDU) o el Command Prompt:
    1. **Bloqueo a Seguridad:** Ping desde Soporte ➔ Seguridad (`Failed`). "Nadie entra a seguridad."
    2. **Libertad de los Jefes:** Ping desde Soporte ➔ Ventas (`Successful`) y Admin ➔ Facturación (`Successful`).
    3. **Bloqueo Restrictivo:** Ping desde ATC ➔ Facturación (`Failed`), seguido de ATC ➔ Ventas (`Successful`).
- *Frase clave:* "Las políticas de seguridad se implementaron de forma estricta. Hubo que agregar excepciones para el tráfico de control (HSRP y OSPF) y reglas globales hacia Soporte y Administración para respetar la jerarquía."

## 3. Respuestas a Preguntas Trampa del Ingeniero

> **Ingeniero:** ¿Por qué Soporte y Administración no tienen ACLs configuradas?
> **Tú:** Porque sus reglas dictan que deben hablar y escuchar a todos. Al dejar sus interfaces libres, la red fluye naturalmente. Si hubiéramos puesto un `permit ip any any`, estaríamos gastando procesamiento de CPU del router innecesariamente. Las restricciones las pusimos en el "origen" (en los departamentos restringidos).

> **Ingeniero:** ¿Cómo aseguraste que los Access Points no arruinaran el DHCP?
> **Tú:** Identificamos que el puerto 'Internet' de los routers inalámbricos aplica NAT y descarta los paquetes Broadcast de DHCP. Al conectarlos por sus puertos LAN (Ethernet), los convertimos en Access Points puros que pasan el tráfico en Capa 2 hacia el `ip helper-address`.

> **Ingeniero:** ¿Cómo resolvieron el problema de inestabilidad de ruteo asimétrico?
> **Tú:** Al tener dos routers OSPF conectados al mismo switch por HSRP, OSPF dividía el tráfico a partes iguales hacia ambos. Al penalizar el cable de respaldo con `ip ospf cost 50`, obligamos al router principal a usar la ruta primaria de forma simétrica, dejando el segundo cable estrictamente para Failover del HSRP.

## 4. Tips Finales
- Si un ping falla la primera vez, recuérdale al ingeniero que "es el ARP resolviendo la dirección MAC" y dale doble clic al botón `Fire` en la lista de PDU de abajo a la derecha. Casi siempre el segundo intento da verde.
- Mantén la calma. Tú configuraste y reparaste los problemas más difíciles (Split-brain de HSRP, NAT en routers AP, Auto-Summary en EIGRP, Costos OSPF). Conoces esta red mejor que nadie. ¡Mucho éxito en tu presentación!
