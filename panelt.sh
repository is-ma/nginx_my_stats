#!/bin/bash

# =================================================
# top_stats - Monitor de estadísticas Nginx en tiempo real
# =================================================
# Muestra histogramas vivos de diferentes campos
# del log de Nginx con navegación por teclado
#
# Uso: top_stats [modo]
# Modos: date, ip, method, status, ua, uri (default: ip)
# Teclas: d=date, i=ip, m=method, s=status, a=agent, u=uri
# Salir: Ctrl+C
# =================================================

set -euo pipefail

# Configuración
LOG_FILE="/var/log/nginx/shield_access.log"
REFRESH_INTERVAL=1
TOP_N=30

# Colores
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

# Variables de estado
TAIL_PID=""
TEMP_FILE=""
CURRENT_MODE=""

# Configuración de modos: campo JSON y título
declare -A MODE_FIELD=(
    [date]=".date"
    [ip]=".ip"
    [method]=".method"
    [status]=".status"
    [ua]=".ua"
    [uri]=".uri"
)

declare -A MODE_TITLE=(
    [date]="Top Fechas en tiempo real"
    [ip]="Top IPs en tiempo real"
    [method]="Top Métodos HTTP en tiempo real"
    [status]="Top Status Codes en tiempo real"
    [ua]="Top User Agents en tiempo real"
    [uri]="Top URIs en tiempo real"
)

# Función de limpieza
cleanup() {
    stty echo 2>/dev/null || true
    echo -e "\n${YELLOW}Limpiando...${NC}"

    if [[ -n "$TAIL_PID" ]] && kill -0 "$TAIL_PID" 2>/dev/null; then
        kill "$TAIL_PID" 2>/dev/null || true
        echo -e "${GREEN}✓${NC} Proceso tail terminado"
    fi

    if [[ -n "$TEMP_FILE" ]] && [[ -f "$TEMP_FILE" ]]; then
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

    histogram=$(sort "$TEMP_FILE" 2>/dev/null | uniq -c | sort -nr | head -n "$TOP_N")

    output=$(printf '\033[H\033[J')
    output+=$(echo -e "${GREEN}=== ${MODE_TITLE[$CURRENT_MODE]} ===${NC}")
    output+=$'\n'
    output+=$(echo -e "${YELLOW}Teclas: [d] date  [i] ip  [m] method  [s] status  [a] agent  [u] uri  [Ctrl+C] salir${NC}")
    output+=$'\n\n'
    output+="$histogram"

    printf '%s\n' "$output"
}

# Función para iniciar el tail con el campo actual
start_tail() {
    local field="${MODE_FIELD[$CURRENT_MODE]}"

    # Crear nuevo archivo temporal
    TEMP_FILE=$(mktemp /tmp/nginx_stats_XXXXXX.tmp)

    # Iniciar tail en background
    sudo tail -f "$LOG_FILE" | jq --unbuffered -r "$field" >> "$TEMP_FILE" &
    TAIL_PID=$!
}

# Función para detener el tail actual
stop_tail() {
    if [[ -n "$TAIL_PID" ]] && kill -0 "$TAIL_PID" 2>/dev/null; then
        kill "$TAIL_PID" 2>/dev/null || true
    fi
    if [[ -n "$TEMP_FILE" ]] && [[ -f "$TEMP_FILE" ]]; then
        rm -f "$TEMP_FILE"
    fi
    TAIL_PID=""
    TEMP_FILE=""
}

# Función para cambiar de modo
switch_mode() {
    local new_mode="$1"

    if [[ "$new_mode" == "$CURRENT_MODE" ]]; then
        return
    fi

    stop_tail
    CURRENT_MODE="$new_mode"
    start_tail
}

# Configurar trap
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

# Determinar modo inicial (argumento o default)
CURRENT_MODE="${1:-ip}"

# Validar modo
if [[ -z "${MODE_FIELD[$CURRENT_MODE]:-}" ]]; then
    echo -e "${RED}Error:${NC} Modo inválido: $CURRENT_MODE"
    echo "Modos válidos: date, ip, method, status, ua, uri"
    exit 1
fi

# Iniciar
start_tail

# Loop principal
while true; do
    show_histogram

    if read -t "$REFRESH_INTERVAL" -n 1 key 2>/dev/null; then
        case "$key" in
            d) switch_mode "date" ;;
            i) switch_mode "ip" ;;
            m) switch_mode "method" ;;
            s) switch_mode "status" ;;
            a) switch_mode "ua" ;;
            u) switch_mode "uri" ;;
        esac
    fi
done
