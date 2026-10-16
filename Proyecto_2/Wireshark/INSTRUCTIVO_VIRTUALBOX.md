# Instructivo completo: captura con Wireshark en una máquina virtual (VirtualBox)

**Proyecto 2 — Redes de Computadoras 2 — Carné 202300848**

Esta guía te lleva **de cero a la entrega** del requisito **4.5** del enunciado y de la rúbrica
**1.3 (14 puntos)**: la captura de tráfico en formato `.pcapng` generada **dentro de una máquina
virtual**, con los cuatro escenarios solicitados.

> ⚠️ **Recuerda por qué es crítico:** el archivo `captura_wireshark_202300848.pcapng` está en los
> **requisitos para optar a calificación** (rúbrica 8.1). Si falta o no abre, la nota es **0**.
> Y la rúbrica 1.3 dice explícitamente que debe estar *"capturado desde máquina virtual"*.

---

## 0. Resumen del flujo

```text
  HOST (tu sistema operativo)
  │
  ├─ 1. Instalar VirtualBox
  ├─ 2. Descargar la ISO del sistema invitado
  ├─ 3. Crear la VM  ──── Red: NAT  ◄── CRÍTICO
  ├─ 4. Instalar el sistema invitado
  ├─ 5. Instalar tshark/dumpcap y el grupo wireshark
  ├─ 6. Copiar generar_trafico.sh a la VM
  ├─ 7. Ejecutar la captura (4 escenarios)
  ├─ 8. Verificar el .pcapng dentro de la VM
  └─ 9. Sacar el archivo al repositorio:
         Proyecto_2/Wireshark/captura_wireshark_202300848.pcapng
```

**Tiempo estimado:** 1.5 – 2 horas (la mayor parte es la descarga e instalación del sistema invitado).

---

## 1. Requisitos del equipo anfitrión (host)

| Recurso | Mínimo | Recomendado |
| :--- | :--- | :--- |
| RAM | 4 GB libres | 8 GB o más |
| Disco libre | 25 GB | 40 GB |
| CPU | 64 bits con virtualización habilitada | 2+ núcleos |
| Conexión a Internet | Sí (dentro de la VM) | – |

### Verificar la virtualización

- **Windows:** Administrador de tareas → *Rendimiento* → *CPU* → debe decir **"Virtualización: habilitada"**.
  Si no aparece, actívala en la BIOS/UEFI (`Intel VT-x` o `AMD-V`).
- **Linux:** `egrep -c '(vmx|svm)' /proc/cpuinfo` → debe devolver un número mayor que 0.
- **macOS Intel:** soportado. **macOS con chip Apple Silicon (M1/M2/M3):** VirtualBox tiene soporte
  limitado → usa **VMware Fusion Player** o **UTM** (ambos gratuitos para uso personal) y sigue esta
  misma guía cambiando solo el hipervisor.

---

## 2. Instalar VirtualBox

Descarga desde el sitio oficial: **<https://www.virtualbox.org/wiki/Downloads>**

| Host | Qué descargar |
| :--- | :--- |
| **Windows** | *Windows hosts* → ejecutar el `.exe` → *Next* → *Next* → *Install*. Acepta el aviso de "interfaces de red" (es normal, crea el adaptador virtual) |
| **macOS** | *macOS / Intel hosts* → abrir el `.dmg` → ejecutar el instalador. Si macOS bloquea la extensión: *Ajustes del sistema → Privacidad y seguridad → Permitir* |
| **Ubuntu / Debian** | `sudo apt update && sudo apt install -y virtualbox virtualbox-ext-pack` |
| **Arch / Manjaro** | `sudo pacman -S virtualbox virtualbox-host-modules-arch` |
| **Fedora** | `sudo dnf install -y VirtualBox` |

> **El Extension Pack NO es necesario** para esta práctica. Solo sirve para USB 2.0/3.0 y escritorio remoto.

### ⚠️ Si usas Windows y algo falla

Windows con **Hyper-V / WSL2 / Credential Guard** activos puede impedir que VirtualBox arranque
(da el error `VERR_NEM_VM_CREATE_FAILED` o `0x80004005`). Solución: desactivar Hyper-V desde
*Activar o desactivar características de Windows*, o ejecutar en PowerShell como administrador:

```powershell
bcdedit /set hypervisorlaunchtype off
```

…y **reiniciar**. (Anótalo para volver a activarlo después si lo necesitas.)

---

## 3. Descargar la ISO del sistema invitado

El enunciado recomienda **Ubuntu Desktop** o **Kali Linux**, *"por traer Wireshark preinstalado"*.

| Opción | Descarga | Ventaja | Tamaño |
| :--- | :--- | :--- | :--- |
| **Ubuntu Desktop 24.04 LTS** *(recomendada)* | <https://ubuntu.com/download/desktop> | Más estable y ligera para virtualizar; Wireshark se instala con un comando | ~6 GB |
| **Kali Linux** | <https://www.kali.org/get-kali/#kali-installer-images> | Ya trae Wireshark instalado | ~4 GB |

> Elige **Ubuntu Desktop** si es tu primera VM. Si eliges Kali, en el instalador selecciona el
> escritorio **XFCE** (el más liviano para virtualizar).

---

## 4. Crear la máquina virtual

En VirtualBox: **Nueva** (o `Ctrl+N`).

### 4.1 Nombre y sistema

| Campo | Valor |
| :--- | :--- |
| Nombre | `Wireshark-Proyecto2` |
| Carpeta ISO | la que descargaste |
| Tipo | Linux |
| Versión | Ubuntu (64-bit) / Debian (64-bit) si es Kali |
| ☑ *Omitir instalación desatendida* | **Márcalo** si quieres control total del instalador |

### 4.2 Hardware

| Campo | Valor | Por qué |
| :--- | :--- | :--- |
| Memoria base | **4096 MB** (mínimo 2048) | Wireshark + navegador necesitan RAM |
| Procesadores | **2 CPU** | Acelera la instalación |
| Disco duro | **25 GB**, *Reservado dinámicamente*, tipo VDI | Ocupa solo lo que usa |

### 4.3 🔴 Configuración de red — EL PASO MÁS IMPORTANTE

**Configuración → Red → Adaptador 1:**

| Campo | Valor |
| :--- | :--- |
| ☑ *Activar adaptador de red* | marcado |
| ☑ *Cable conectado* | marcado |
| **Conectado a** | **`NAT`** ✅ |
| Adaptador avanzado → Tipo de adaptador | Intel PRO/1000 MT Desktop (o el que venga por defecto) |

> **Por qué NAT y no otro modo:**
>
> | Modo | ¿Sirve? | Motivo |
> | :--- | :--- | :--- |
> | **NAT** | ✅ **Sí** | La VM sale a Internet a través del host, pero **el tráfico capturado es solo el de la VM**. Es exactamente lo que pide el enunciado |
> | **Red interna** | ⚠️ Solo | Aísla totalmente la VM: no hay Internet, así que **no funcionarían** los escenarios de DNS, HTTP/HTTPS ni ICMP contra servidores públicos (serviría solo si montas una segunda VM como servidor) |
> | **Adaptador puente** | ❌ **No** | Capturarías el tráfico de **toda la red física**, incluido el del host y de otros equipos — justo lo que el enunciado prohíbe |
> | **Solo anfitrión** | ❌ No | Sin salida a Internet |

**Esta decisión hay que documentarla en el manual** (rúbrica 1.3: *"capturados desde máquina virtual"*).
Sirve esta frase:

> *"La captura se generó dentro de una máquina virtual con VirtualBox, configurada en modo **NAT**,
> lo que garantiza que el tráfico capturado provenga únicamente de la VM y no del equipo anfitrión,
> tal como exige la sección 4.5 del enunciado."*

### 4.4 Pantalla y extras

- **Pantalla → Memoria de video:** 128 MB.
- **Opciones avanzadas → Portapapeles compartido:** *Bidireccional*; **Arrastrar y soltar:** *Bidireccional*.
  (Facilita copiar el script y sacar el `.pcapng`.) Requiere las *Guest Additions*, que instalaremos al final.

---

## 5. Instalar el sistema invitado

1. Selecciona la VM → **Iniciar**.
2. Elige *Instalar Ubuntu* (o el instalador de Kali) → idioma → **Instalación normal** →
   *Descargar actualizaciones al instalar* (desmárcalo si tu Internet es lento) → **Borrar el disco**
   (es el disco virtual, no el tuyo).
3. Usuario y contraseña: los que quieras. **Anótalos.**
4. Al terminar: reiniciar, expulsar la ISO si lo pide, e iniciar sesión en el escritorio.

### 5.1 Guest Additions (para carpetas compartidas y resolución)

Con la VM encendida: menú **Dispositivos → Insertar imagen de CD de las Guest Additions** →
abre la terminal dentro de la VM y ejecuta:

```bash
sudo apt update
sudo apt install -y build-essential dkms linux-headers-$(uname -r)
sudo mount /dev/cdrom /mnt
sudo /mnt/VBoxLinuxAdditions.run
sudo reboot
```

---

## 6. Preparar Wireshark dentro de la VM

Abre la **Terminal** dentro de la VM:

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y tshark curl dnsutils iputils-ping git
```

Durante la instalación de `tshark` aparece esta pregunta:

```text
Should non-superusers be able to capture packets?  →  <Yes>
```

Responde **Yes** (así `dumpcap` funciona sin `sudo`). Luego agrega tu usuario al grupo:

```bash
sudo usermod -aG wireshark $USER
```

**Cierra sesión y vuelve a entrar** (o reinicia la VM) para que el grupo tome efecto. Verifica:

```bash
groups | grep wireshark        # debe aparecer "wireshark"
dumpcap -D                     # debe listar las interfaces (enp0s3, eth0, etc.)
```

> Si `dumpcap -D` da un error de permisos, ejecuta el script con `sudo` y listo.

---

## 7. Copiar el script de captura a la VM

Elige **una** de las tres opciones:

### Opción A — Carpetas compartidas (recomendada, sirve también para sacar el archivo)

1. Apaga la VM. En VirtualBox: **Configuración → Carpetas compartidas → Añadir**.
2. Carpeta anfitriona: la carpeta `Wireshark` de tu repo (`.../Proyecto_2/Wireshark`).
   Nombre: `Wireshark`. Marca ☑ *Montar automáticamente* y ☑ *Hacer permanente*.
3. Enciende la VM y ejecuta:

```bash
sudo usermod -aG vboxsf $USER
sudo reboot
```

4. Al volver, la carpeta aparece en `/media/sf_Wireshark`. Ahí tienes el script **y** ahí mismo
   puedes dejar el `.pcapng` para que aparezca en tu repo automáticamente.

```bash
ls /media/sf_Wireshark/
```

### Opción B — Clonar el repositorio desde la VM *(la más limpia)*

```bash
git clone https://github.com/Emmagx/REDES2_2S2026_202300848.git
cd REDES2_2S2026_202300848/Proyecto_2/Wireshark
chmod +x generar_trafico.sh
```

### Opción C — Copiar y pegar (si nada más funciona)

```bash
nano ~/generar_trafico.sh      # pega el contenido del script
chmod +x ~/generar_trafico.sh
```

---

## 8. Generar y capturar el tráfico (los 4 escenarios)

```bash
cd ~                                   # o /media/sf_Wireshark, o donde tengas el script
chmod +x generar_trafico.sh
sudo ./generar_trafico.sh
```

El script hace todo solo, **con la captura corriendo en segundo plano**:

| Escenario | Tráfico que genera | Duración |
| :--- | :--- | :--- |
| **1. Three-way handshake TCP** | `curl http://example.com` y `http://www.gstatic.com/generate_204` | ~4 s |
| **2. Resolución DNS** | `dig @8.8.8.8 example.com A`, `MX`, y `@1.1.1.1 www.wikipedia.org AAAA` | ~6 s |
| **3. HTTP vs HTTPS** | `curl http://example.com` y `curl https://example.com` + `https://www.wikipedia.org` | ~8 s |
| **4. ICMP** | `ping -c 4 8.8.8.8` y `ping -c 4 1.1.1.1` | ~10 s |

Al terminar, **el propio script verifica** que la captura contenga SYN, SYN-ACK, DNS, HTTP, TLS e
ICMP, y te imprime el conteo de cada uno. Debe verse así:

```text
[+] Captura finalizada: captura_wireshark_202300848.pcapng  (xxx KB)

=== VERIFICACIÓN - protocolos presentes en la captura ===
  TCP SYN (escenario 1)        3
  TCP SYN-ACK (escenario 1)    3
  DNS (escenario 2)            8
  HTTP (escenario 3)           2
  TLS (escenario 3)            5
  ICMP (escenario 4)           8
```

> Si algún contador sale en **0**, el script te avisa. Lo más común es que HTTP salga en 0 porque tu
> red fuerza HTTPS: en ese caso usa `http://neverssl.com` (sitio que **solo** responde por HTTP) y
> vuelve a ejecutar.

**Tiempo total de la captura: ~40 segundos.**

---

## 9. Verificar la captura dentro de la VM

```bash
capinfos captura_wireshark_202300848.pcapng      # debe decir: File type: pcapng, Number of packets: N
tshark -r captura_wireshark_202300848.pcapng -q -z io,phs | head -30
```

Y ábrela con la interfaz gráfica para tomar las capturas de pantalla del manual:

```bash
wireshark captura_wireshark_202300848.pcapng
```

### Filtros para las capturas de pantalla (evidencia para el manual)

| Escenario | Filtro de visualización |
| :--- | :--- |
| 1. Three-way handshake | `tcp.flags.syn == 1` |
| 2. DNS | `dns` |
| 3. HTTP (texto plano) | `http.request` |
| 3. HTTPS (TLS) | `tls.handshake` |
| 4. ICMP | `icmp` |
| Todo junto | `tcp.flags.syn == 1 \|\| dns \|\| http \|\| tls \|\| icmp` |

📸 **Captura pantalla de cada filtro** — son la evidencia de la rúbrica 1.3 y van en el manual.

---

## 10. Sacar el `.pcapng` de la VM al repositorio

Debe quedar exactamente en:

```text
Proyecto_2/Wireshark/captura_wireshark_202300848.pcapng
```

| Método | Cómo |
| :--- | :--- |
| **Carpeta compartida** *(opción A)* | Copia el archivo dentro de `/media/sf_Wireshark/` y ya aparece en tu repo: `cp captura_wireshark_202300848.pcapng /media/sf_Wireshark/` |
| **Git desde la VM** *(opción B)* | `cp captura_wireshark_202300848.pcapng REDES2_2S2026_202300848/Proyecto_2/Wireshark/` y luego `git add . && git commit -m "docs: captura wireshark" && git push` |
| **Arrastrar y soltar** | Con las Guest Additions, arrastra el archivo desde la VM al escritorio del host |
| **scp con reenvío de puertos NAT** | En VirtualBox: *Configuración → Red → Avanzado → Reenvío de puertos* → añade `ssh / TCP / 127.0.0.1 / 2222 / 22`. Luego desde el host: `scp -P 2222 usuario@127.0.0.1:~/captura_wireshark_202300848.pcapng .` |

**Verifica el nombre exacto:** `captura_wireshark_202300848.pcapng` (es lo que revisa el auxiliar).

---

## 11. Completar el análisis (rúbrica 1.2 y 1.3)

Abre [`ANALISIS_WIRESHARK.md`](ANALISIS_WIRESHARK.md) y rellena las tablas marcadas con
*"completar con los valores reales"*:

| Qué completar | Dónde mirarlo en Wireshark |
| :--- | :--- |
| IPs de origen y destino del SYN | Columna *Source* / *Destination* del paquete `SYN` |
| Números de secuencia (Seq / Ack) | *Sequence Number* / *Acknowledgment Number* en los detalles del paquete |
| TTL observado | *Time to Live* dentro de la capa IP |
| Tipo de registro y TTL del DNS | Paquete de respuesta DNS → *Answers* |
| Versión de TLS y cipher suite | `Server Hello` → *Cipher Suite* |
| RTT del ping | Salida del `ping` en la terminal, o *Statistics → Conversations* |
| Puerto efímero usado | *Source Port* del paquete SYN |

El texto conceptual de los 4 protocolos **ya está redactado** en ese documento: solo faltan tus valores.

---

## 12. Checklist final

```
[ ] VirtualBox instalado y VM creada
[ ] Red del adaptador 1 en modo NAT (NO adaptador puente)  <-- CRITICO
[ ] Sistema invitado instalado y con Internet
[ ] tshark / dumpcap instalados y usuario en el grupo wireshark
[ ] generar_trafico.sh ejecutado DENTRO de la VM
[ ] La verificacion del script muestra SYN, SYN-ACK, DNS, HTTP, TLS e ICMP > 0
[ ] Archivo llamado exactamente captura_wireshark_202300848.pcapng
[ ] Copiado a Proyecto_2/Wireshark/ en el repositorio
[ ] Verificado con capinfos que abre correctamente
[ ] Capturas de pantalla de los 5 filtros guardadas para el manual
[ ] Tablas de ANALISIS_WIRESHARK.md completadas con valores reales
[ ] En el manual se documenta: hipervisor usado + modo de red
[ ] Commit y push en Git
```

---

## 13. Preguntas frecuentes

**¿Puedo capturar en mi computadora y decir que fue en la VM?**
No. La rúbrica 1.3 lo dice explícitamente: *"no fue generada en máquina virtual"* cae en
"Necesita mejorar" (0–7 de 14 puntos). Y el auxiliar puede preguntarlo en la evaluación oral.

**La VM no tiene Internet.**
Revisa que el adaptador 1 esté en **NAT**, con *Cable conectado* marcado. Dentro de la VM:
`ping -c 3 8.8.8.8`. Si no responde, apaga la VM y revisa la configuración del adaptador.

**`dumpcap` dice que no tengo permisos.**
Ejecuta el script con `sudo`, o cierra sesión y vuelve a entrar para que tome efecto el grupo
`wireshark` (`sudo usermod -aG wireshark $USER`).

**El escenario HTTP sale en 0.**
Tu red está forzando HTTPS. Usa `http://neverssl.com` (responde solo por HTTP) o
`http://www.gstatic.com/generate_204` y vuelve a ejecutar el script.

**¿Sirve el modo "Red interna"?**
Solo si montas una segunda VM que actúe como servidor DNS/HTTP. Para los escenarios contra
servidores públicos (**8.8.8.8**, **example.com**) necesitas salida a Internet → **NAT**.

**¿Cuánto debe durar la captura?**
Lo que dura el script: ~40 segundos. No necesitas capturas largas; el enunciado pide
*"tráfico controlado"*.

**¿Puedo usar VMware en lugar de VirtualBox?**
Sí. El enunciado dice *"software como VirtualBox o VMware Workstation Player"*. Solo cambia la
gestión de la VM; el modo de red equivalente es **NAT**, y el resto de la guía (secciones 6 a 12)
es idéntico.
