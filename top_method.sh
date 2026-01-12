#!/bin/bash

# =================================================
# top_method - Monitor de Métodos HTTP en tiempo real
# =================================================
# Muestra un histograma vivo de los métodos HTTP
# más frecuentes en el log de Nginx
#
# Uso: top_method
# Salir: Ctrl+C (limpia automáticamente)
# Teclas: d=date, i=ip, m=method, s=status, a=agent, u=uri
# =================================================

set -euo pipefail

# Configuración
LOG_FILE="/var/log/nginx/shield_access.log"
TEMP_FILE=$(mktemp /tmp/nginx_method_XXXXXX.tmp)
REFRESH_INTERVAL=1
TOP_N=30

# Colores para mejor legibilidad
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

# Variable para el PID del tail
TAIL_PID=""

# Función de limpieza
cleanup() {
    # Restaurar configuración del terminal
    stty echo 2>/dev/null || true

    echo -e "\n${YELLOW}Limpiando...${NC}"

    # Matar el proceso tail si existe
    if [[ -n "$TAIL_PID" ]] && kill -0 "$TAIL_PID" 2>/dev/null; then
        kill "$TAIL_PID" 2>/dev/null || true
        echo -e "${GREEN}✓${NC} Proceso tail terminado"
    fi

    # Borrar archivo temporal
    if [[ -f "$TEMP_FILE" ]]; then
        rm -f "$TEMP_FILE"
        echo -e "${GREEN}✓${NC} Archivo temporal eliminado"
    fi

    echo -e "${GREEN}¡Listo!${NC}"
    exit 0
}

# Función para mostrar el histograma (sin parpadeo)
show_histogram() {
    local output
    local histogram

    # Pre-computar el histograma
    histogram=$(sort "$TEMP_FILE" 2>/dev/null | uniq -c | sort -nr | head -n "$TOP_N")

    # Construir todo el output en una variable
    output=$(printf '\033[H\033[J')  # Clear screen (ANSI escape)
    output+=$(echo -e "${GREEN}=== Top Métodos HTTP en tiempo real ===${NC}")
    output+=$'\n'
    output+=$(echo -e "${YELLOW}Teclas: [d] date  [i] ip  [m] method  [s] status  [a] agent  [u] uri  [Ctrl+C] salir${NC}")
    output+=$'\n\n'
    output+="$histogram"

    # Mostrar todo de una vez
    printf '%s\n' "$output"
}

# Función para cambiar a otro script
switch_to_script() {
    local script="$1"

    # Limpiar recursos antes de cambiar
    if [[ -n "$TAIL_PID" ]] && kill -0 "$TAIL_PID" 2>/dev/null; then
        kill "$TAIL_PID" 2>/dev/null || true
    fi
    [[ -f "$TEMP_FILE" ]] && rm -f "$TEMP_FILE"

    # Desactivar trap para evitar mensajes de limpieza
    trap - SIGINT SIGTERM EXIT

    # Ejecutar el otro script
    exec "$(dirname "$0")/$script"
}

# Configurar trap para capturar Ctrl+C y otras señales
trap cleanup SIGINT SIGTERM EXIT

# Verificar que el log existe
if [[ ! -f "$LOG_FILE" ]]; then
    echo -e "${RED}Error:${NC} No se encuentra el archivo $LOG_FILE"
    exit 1
fi

# Verificar que jq está instalado
if ! command -v jq &> /dev/null; then
    echo -e "${RED}Error:${NC} jq no está instalado"
    echo "Instalar con: sudo apt-get install jq"
    exit 1
fi

# Iniciar el tail en background y capturar su PID
sudo tail -f "$LOG_FILE" | jq --unbuffered -r '.method' >> "$TEMP_FILE" &
TAIL_PID=$!

# Loop principal interactivo (reemplaza watch)
while true; do
    show_histogram

    # Leer tecla con timeout (permite refrescar automáticamente)
    if read -t "$REFRESH_INTERVAL" -n 1 key 2>/dev/null; then
        case "$key" in
            d) switch_to_script "top_date.sh" ;;
            i) switch_to_script "top_ip.sh" ;;
            m) ;; # Ya estamos en method
            s) switch_to_script "top_status.sh" ;;
            a) switch_to_script "top_ua.sh" ;;
            u) switch_to_script "top_uri.sh" ;;
        esac
    fi
done
