#!/usr/bin/env bash
# =============================================================================
#  Proyecto 2 - Redes de Computadoras 2 - Carné 202300848
#  Generador y capturador de tráfico para la sección 4.5 (Wireshark)
#
#  Genera y captura los CUATRO escenarios exigidos por el enunciado:
#    1. Three-way handshake TCP
#    2. Resolución DNS (contra 8.8.8.8 / 1.1.1.1)
#    3. Petición HTTP vs HTTPS
#    4. ICMP (Echo Request / Echo Reply)
#
#  USO (DENTRO DE LA MÁQUINA VIRTUAL):
#      chmod +x generar_trafico.sh
#      sudo ./generar_trafico.sh
#
#  El archivo resultante debe llamarse captura_wireshark_202300848.pcapng
# =============================================================================

set -uo pipefail

OUT="${1:-captura_wireshark_202300848.pcapng}"
DURACION_MAX="${DURACION_MAX:-120}"

# -----------------------------------------------------------------------------
# 0. Utilidades
# -----------------------------------------------------------------------------
rojo()  { printf '\033[1;31m%s\033[0m\n' "$*"; }
verde() { printf '\033[1;32m%s\033[0m\n' "$*"; }
info()  { printf '\033[1;34m[*]\033[0m %s\n' "$*"; }
paso()  { printf '\n\033[1;33m=== %s ===\033[0m\n' "$*"; }

faltan=0
for cmd in dumpcap curl ping getent; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    rojo "Falta el comando '$cmd'. Instálalo antes de continuar."
    faltan=1
  fi
done
[ "$faltan" -eq 1 ] && exit 1

if ! command -v dig >/dev/null 2>&1 && ! command -v nslookup >/dev/null 2>&1; then
  rojo "Falta 'dig' o 'nslookup' para el escenario DNS."
  exit 1
fi

# -----------------------------------------------------------------------------
# 1. Detectar la interfaz de red y comprobar permisos de captura
# -----------------------------------------------------------------------------
IFACE="${2:-}"
if [ -z "$IFACE" ]; then
  IFACE="$(ip route get 8.8.8.8 2>/dev/null \
            | awk '{for(i=1;i<=NF;i++) if($i=="dev"){print $(i+1); exit}}')"
fi
[ -z "$IFACE" ] && IFACE="$(ip -o link show up | awk -F': ' '!/ lo /{print $2; exit}')"

info "Interfaz de captura : $IFACE"
info "Archivo de salida   : $OUT"

SONDEO="$(mktemp -u /tmp/.probe_dumpcap_XXXXXX.pcapng)"
if ! dumpcap -i "$IFACE" -a duration:1 -w "$SONDEO" >/dev/null 2>&1; then
  rojo "No se puede capturar en '$IFACE'."
  echo "  Ejecuta el script con sudo, o agrega tu usuario al grupo 'wireshark':"
  echo "     sudo usermod -aG wireshark \$USER && newgrp wireshark"
  echo "  (en algunas distribuciones hay que reiniciar la sesión después)"
  echo
  echo "  Interfaces disponibles:"
  dumpcap -D || true
  rm -f "$SONDEO"
  exit 1
fi
rm -f "$SONDEO"

# -----------------------------------------------------------------------------
# 2. Arrancar la captura en segundo plano
# -----------------------------------------------------------------------------
rm -f "$OUT"
info "Iniciando captura (máximo ${DURACION_MAX}s)..."
dumpcap -i "$IFACE" -w "$OUT" -a "duration:${DURACION_MAX}" >/dev/null 2>&1 &
CAPTURE_PID=$!
sleep 3   # dar tiempo a que dumpcap abra el archivo

fin_captura() {
  if kill -0 "$CAPTURE_PID" 2>/dev/null; then
    sleep 2
    kill -INT "$CAPTURE_PID" 2>/dev/null
    wait "$CAPTURE_PID" 2>/dev/null
  fi
}
trap 'fin_captura; rojo "Captura interrumpida"; exit 130' INT TERM

# -----------------------------------------------------------------------------
# 3. ESCENARIO 1 — Three-way handshake TCP
# -----------------------------------------------------------------------------
paso "ESCENARIO 1/4 - Three-way handshake TCP (SYN, SYN-ACK, ACK)"
info "curl -v http://example.com  (fuerza TCP puerto 80 en texto plano)"
curl -sS -m 10 -v http://example.com/ -o /dev/null 2>&1 | grep -Ei 'connect|syn|http/' | head -5
sleep 2

info "Segunda conexión TCP: www.gstatic.com:80"
curl -sS -m 10 -o /dev/null "http://www.gstatic.com/generate_204" 2>/dev/null
sleep 2

# -----------------------------------------------------------------------------
# 4. ESCENARIO 2 — Resolución DNS
# -----------------------------------------------------------------------------
paso "ESCENARIO 2/4 - Resolución DNS (UDP/53)"
if command -v dig >/dev/null 2>&1; then
  info "dig @8.8.8.8 example.com A"
  dig +time=3 +tries=1 @8.8.8.8 example.com A 2>/dev/null | grep -E '^;|example.com' | head -12
  sleep 1
  info "dig @8.8.8.8 example.com MX   (tipo de registro distinto)"
  dig +time=3 +tries=1 @8.8.8.8 example.com MX 2>/dev/null | grep -E '^;|example.com' | head -10
  sleep 1
  info "dig @1.1.1.1 www.wikipedia.org AAAA"
  dig +time=3 +tries=1 @1.1.1.1 www.wikipedia.org AAAA 2>/dev/null | grep -E '^;|wikipedia' | head -10
else
  info "nslookup example.com 8.8.8.8"
  nslookup example.com 8.8.8.8 2>/dev/null | head -12
  sleep 1
  info "nslookup www.wikipedia.org 1.1.1.1"
  nslookup www.wikipedia.org 1.1.1.1 2>/dev/null | head -12
fi
sleep 2

# -----------------------------------------------------------------------------
# 5. ESCENARIO 3 — HTTP vs HTTPS
# -----------------------------------------------------------------------------
paso "ESCENARIO 3/4 - Petición HTTP vs HTTPS (comparar capturas)"
info "HTTP  -> http://example.com  (tráfico en texto plano, puerto 80)"
curl -sS -m 10 -o /dev/null -D - "http://example.com/" 2>/dev/null | head -6
sleep 2

info "HTTPS -> https://example.com (handshake TLS, tráfico cifrado, puerto 443)"
curl -sS -m 15 -o /dev/null -D - "https://example.com/" 2>/dev/null | head -6
sleep 2

info "HTTPS adicional con TLS 1.3 -> https://www.wikipedia.org"
curl -sS -m 15 -o /dev/null "https://www.wikipedia.org/" 2>/dev/null
sleep 2

# -----------------------------------------------------------------------------
# 6. ESCENARIO 4 — ICMP
# -----------------------------------------------------------------------------
paso "ESCENARIO 4/4 - ICMP (Echo Request / Echo Reply)"
info "ping -c 4 8.8.8.8"
ping -c 4 -W 3 8.8.8.8 2>&1 | tail -5
sleep 2

info "ping -c 4 1.1.1.1"
ping -c 4 -W 3 1.1.1.1 2>&1 | tail -5
sleep 3

# -----------------------------------------------------------------------------
# 7. Detener la captura y verificar el contenido
# -----------------------------------------------------------------------------
fin_captura
trap - INT TERM

if [ ! -s "$OUT" ]; then
  rojo "El archivo '$OUT' está vacío o no se creó. Revisa los permisos de captura."
  exit 1
fi

verde "Captura finalizada: $OUT  ($(du -h "$OUT" | cut -f1))"

paso "VERIFICACIÓN - protocolos presentes en la captura"
if command -v tshark >/dev/null 2>&1; then
  tshark -r "$OUT" -q -z io,phs 2>/dev/null | head -40

  echo
  info "Conteo de los paquetes clave:"
  for f in \
    "TCP SYN (escenario 1):tcp.flags.syn==1 && tcp.flags.ack==0" \
    "TCP SYN-ACK (escenario 1):tcp.flags.syn==1 && tcp.flags.ack==1" \
    "DNS (escenario 2):dns" \
    "HTTP (escenario 3):http.request" \
    "TLS (escenario 3):tls.handshake" \
    "ICMP (escenario 4):icmp" ; do
    etiqueta="${f%%:*}"; filtro="${f#*:}"
    n=$(tshark -r "$OUT" -Y "$filtro" 2>/dev/null | wc -l)
    printf '  %-28s %s\n' "$etiqueta" "$n"
  done

  if [ "$(tshark -r "$OUT" -Y 'http.request' 2>/dev/null | wc -l)" -eq 0 ] \
     || [ "$(tshark -r "$OUT" -Y 'tls.handshake' 2>/dev/null | wc -l)" -eq 0 ]; then
    echo
    rojo "ADVERTENCIA: falta HTTP o TLS. Si tu red fuerza HTTPS en todo,"
    rojo "usa un sitio que soporte HTTP plano (p. ej. http://neverssl.com)."
  fi
else
  info "tshark no está instalado; abre el archivo manualmente en Wireshark."
fi

cat <<EOF

=============================================================================
 LISTO. Ahora:
   1. Copia '$OUT' al repositorio como Proyecto_2/Wireshark/captura_wireshark_202300848.pcapng
   2. Completa las tablas de Wireshark/ANALISIS_WIRESHARK.md con tus valores reales
   3. En Wireshark usa estos filtros de visualización:
        tcp.flags.syn == 1          -> three-way handshake
        dns                         -> resolución DNS
        http.request                -> petición HTTP en texto plano
        tls.handshake               -> handshake TLS de HTTPS
        icmp                        -> Echo Request / Echo Reply
=============================================================================
EOF
