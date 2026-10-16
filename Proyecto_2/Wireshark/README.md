# Wireshark — Sección 4.5 del Proyecto 2

Esta carpeta contiene el **entregable eliminatorio** de la rúbrica 8.1:

> `captura_wireshark_202300848.pcapng` — *"El archivo debe poder abrirse correctamente en cualquier
> instalación de Wireshark y contener los paquetes de los cuatro escenarios solicitados."*

y el documento de análisis **capa por capa de al menos tres protocolos distintos** que exige la
rúbrica 1.2 (manual técnico) y 1.3 (14 puntos).

| Archivo | Estado | Descripción |
| :--- | :--- | :--- |
| `captura_wireshark_202300848.pcapng` | **generado y verificado** | Captura con los 4 escenarios — 238 paquetes, 25,86 s, 166 kB |
| [`ANALISIS_WIRESHARK.md`](ANALISIS_WIRESHARK.md) | **completo** | Análisis capa por capa de los 4 escenarios, con los valores reales extraídos de la captura |
| [`images/`](images/) | listo | 8 capturas de pantalla (entorno VirtualBox + los 4 escenarios en Wireshark) |
| [`INSTRUCTIVO_VIRTUALBOX.md`](INSTRUCTIVO_VIRTUALBOX.md) | listo | **Guía completa paso a paso**: instalar VirtualBox, crear la VM, instalar el invitado, capturar y sacar el archivo al repositorio |
| [`generar_trafico.sh`](generar_trafico.sh) | listo | Script que genera el tráfico y captura con `dumpcap` |

### Entorno real de la captura

| Dato | Valor |
| :--- | :--- |
| Hipervisor | **Oracle VirtualBox** sobre Windows |
| Sistema invitado | **Kali Linux 2026.1** |
| Modo de red | **NAT** (`Intel PRO/1000 MT Desktop (NAT)`) |
| IP de la VM | `10.0.4.15` |
| Fecha | 15/10/2026 · 13:50:42 → 13:51:08 |

### Capturas de pantalla incluidas

| Archivo | Contenido |
| :--- | :--- |
| [`01_virtualbox_vm_kali_red_nat.png`](images/01_virtualbox_vm_kali_red_nat.png) | VirtualBox con la VM y el **adaptador en modo NAT** (evidencia del requisito 4.5) |
| [`02_vm_kali_ejecucion_script.png`](images/02_vm_kali_ejecucion_script.png) | El script ejecutándose **dentro** de la VM + carpeta compartida |
| [`03_escenario1_tcp_handshake.png`](images/03_escenario1_tcp_handshake.png) | Filtro `tcp.flags.syn == 1` |
| [`04_escenario2_dns.png`](images/04_escenario2_dns.png) | Filtro `dns` |
| [`05_escenario3_http_texto_plano.png`](images/05_escenario3_http_texto_plano.png) | Filtro `http.request` |
| [`06_escenario3_https_tls.png`](images/06_escenario3_https_tls.png) | Filtro `tls.handshake` |
| [`07_escenario4_icmp.png`](images/07_escenario4_icmp.png) | Filtro `icmp` |
| [`08_resumen_cuatro_escenarios.png`](images/08_resumen_cuatro_escenarios.png) | Los cuatro escenarios en una sola vista |

> **Si tuvieras que repetir la captura, empieza por [`INSTRUCTIVO_VIRTUALBOX.md`](INSTRUCTIVO_VIRTUALBOX.md).**
> El procedimiento resumido de las secciones 2 a 7 de este documento es equivalente, pero el
> instructivo incluye la instalación del hipervisor, la configuración de red y las soluciones a los
> problemas más comunes (Hyper-V en Windows, permisos de `dumpcap`, HTTP bloqueado, etc.).

---

## 1. Requisito clave: la captura debe salir de una MÁQUINA VIRTUAL

El enunciado (4.5) y la rúbrica 1.3 son explícitos:

> *"El estudiante deberá montar una máquina virtual utilizando software como VirtualBox o VMware
> Workstation Player… La máquina virtual debe configurarse en modo NAT o Red interna para garantizar
> que el tráfico capturado provenga **únicamente de la VM** y no de la máquina anfitriona."*
>
> Nivel "Necesita mejorar" de la rúbrica 1.3: *"…**no fue generada en máquina virtual** o no se
> documenta el análisis."*

### Estado del equipo anfitrión

| Herramienta | Estado verificado |
| :--- | :--- |
| Wireshark / tshark / dumpcap | instalados en el anfitrión |
| VirtualBox | **no instalado** |
| VMware Workstation Player | no instalado |
| QEMU | instalado (`qemu-system-x86_64`) |

---

## 2. Procedimiento completo (paso a paso)

### Paso 1 — Instalar VirtualBox en el anfitrión

```bash
# Debian/Ubuntu
sudo apt update && sudo apt install -y virtualbox virtualbox-ext-pack

# Arch
sudo pacman -S virtualbox virtualbox-host-modules-arch
```

### Paso 2 — Crear la VM

1. Descarga una ISO de **Ubuntu Desktop** o **Kali Linux** (Kali trae Wireshark preinstalado, es la
   opción más rápida).
2. Crea la VM con al menos **2 GB de RAM** y **20 GB de disco**.
3. **Configuración de red (crítico):** *Configuración → Red → Adaptador 1 → Conectado a:*
   **`NAT`** (recomendado) o **`Red interna`**.
   - Con `NAT`, todo el tráfico de la VM sale a Internet a través del anfitrión pero la captura solo
     ve tráfico originado por la VM.
   - **No uses "Adaptador puente"**, porque capturarías el tráfico de toda la red física.
4. Instala el sistema operativo.

### Paso 3 — Preparar la VM

Dentro de la VM:

```bash
sudo apt update
sudo apt install -y tshark curl dnsutils iputils-ping
# Al instalar tshark, responde "Yes" cuando pregunte si los usuarios no root
# pueden capturar paquetes (grupo wireshark).
```

Verifica la captura:

```bash
sudo dumpcap -D          # lista las interfaces disponibles
```

### Paso 4 — Copiar y ejecutar el script

Copia `generar_trafico.sh` dentro de la VM (por ejemplo con un *shared folder*, `scp` o copiando y
pegando el contenido) y ejecútalo:

```bash
chmod +x generar_trafico.sh
sudo ./generar_trafico.sh
```

El script hace exactamente lo siguiente, con la captura corriendo en segundo plano:

| Escenario | Tráfico que genera |
| :--- | :--- |
| 1. Three-way handshake TCP | `curl -v http://example.com` y `curl http://www.gstatic.com/generate_204` |
| 2. Resolución DNS | `dig @8.8.8.8 example.com A`, `dig @8.8.8.8 example.com MX`, `dig @1.1.1.1 www.wikipedia.org AAAA` |
| 3. HTTP vs HTTPS | `curl http://example.com` y `curl https://example.com` (+ `https://www.wikipedia.org`) |
| 4. ICMP | `ping -c 4 8.8.8.8` y `ping -c 4 1.1.1.1` |

Al terminar, el script **verifica solo** que la captura contenga SYN, SYN-ACK, DNS, HTTP, TLS e ICMP,
y te imprime el conteo de cada uno. Si falta HTTP o TLS, te avisa.

### Paso 5 — Sacar el archivo de la VM y ponerlo en el repositorio

Copia `captura_wireshark_202300848.pcapng` a esta carpeta:

```text
Proyecto_2/Wireshark/captura_wireshark_202300848.pcapng
```

Comprueba que el nombre sea **exacto** (es lo que revisa el auxiliar en la rúbrica 8.1).

### Paso 6 — Verificar que abre correctamente

```bash
# Abrir en la interfaz gráfica
wireshark captura_wireshark_202300848.pcapng

# O verificar por consola que el archivo no está corrupto
capinfos captura_wireshark_202300848.pcapng
tshark -r captura_wireshark_202300848.pcapng -q -z io,phs
```

Debe ser un `.pcapng` válido y contener los cuatro escenarios.

### Paso 7 — Completar el análisis

Abre [`ANALISIS_WIRESHARK.md`](ANALISIS_WIRESHARK.md) y rellena las tablas marcadas con
*"completar con los valores reales"* (IPs, números de secuencia, TTL, cipher suite, RTT, etc.).
La explicación conceptual de cada protocolo ya está redactada: solo faltan tus valores.

---

## 3. Filtros de Wireshark para la demostración en la calificación

```text
tcp.flags.syn == 1 && tcp.flags.ack == 0     ! paquete SYN del escenario 1
tcp.flags.syn == 1 && tcp.flags.ack == 1     ! paquete SYN-ACK del escenario 1
dns                                          ! escenario 2 (consultas y respuestas)
http.request                                 ! escenario 3 — HTTP en texto plano
tls.handshake                                ! escenario 3 — handshake TLS de HTTPS
icmp                                         ! escenario 4 — Echo Request / Echo Reply
```

También útiles: *Statistics → Protocol Hierarchy* (resumen de protocolos) y
*Statistics → Flow Graph* (ver el handshake completo).

---

## 4. Alternativa si no puedes instalar VirtualBox

El enunciado dice *"software como VirtualBox o VMware Workstation Player"* — la palabra *como* admite
otros hipervisores. Si no puedes instalar VirtualBox, puedes usar **QEMU/KVM**, que ya está en el
equipo:

```bash
# Ejemplo con una ISO de Ubuntu/Kali (ajusta rutas y tamaños)
qemu-img create -f qcow2 proyecto2.qcow2 20G
qemu-system-x86_64 -enable-kvm -m 2048 -smp 2 \
  -cdrom kali-linux.iso -boot d \
  -netdev user,id=n0 -device e1000,netdev=n0 \
  proyecto2.qcow2
```

La opción `-netdev user` equivale al modo **NAT**: el tráfico capturado dentro del invitado proviene
únicamente de la VM, que es exactamente lo que pide el enunciado.

> **Documenta en el manual qué hipervisor usaste y en qué modo de red.** El auxiliar lo revisa
> (rúbrica 1.3: *"capturados desde máquina virtual"*).

---

## 5. Lista de verificación final

- [ ] La captura se generó **dentro de una máquina virtual** en modo NAT o red interna.
- [ ] El archivo se llama **exactamente** `captura_wireshark_202300848.pcapng`.
- [ ] Está ubicado en `Proyecto_2/Wireshark/`.
- [ ] Abre correctamente en Wireshark (probado con `capinfos`).
- [ ] Contiene el **escenario 1**: SYN, SYN-ACK y ACK.
- [ ] Contiene el **escenario 2**: consulta y respuesta DNS contra 8.8.8.8 o 1.1.1.1.
- [ ] Contiene el **escenario 3**: una petición HTTP y una HTTPS con handshake TLS.
- [ ] Contiene el **escenario 4**: Echo Request y Echo Reply.
- [ ] [`ANALISIS_WIRESHARK.md`](ANALISIS_WIRESHARK.md) tiene los valores reales completados.
- [ ] El README principal menciona y enlaza esta carpeta.
