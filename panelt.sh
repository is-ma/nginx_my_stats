#!/bin/bash

# =================================================
# panelt - Panel de estadísticas Nginx
# =================================================
# Muestra histogramas de diferentes campos del log
# de Nginx con navegación por teclado
#
# Uso: panelt [modo]
# Modos: date, ip, method, status, ua, uri (default: ip)
# Salir: Ctrl+C
# =================================================

set -uo pipefail

# Configuración
LOG_FILE="/var/log/nginx/shield_access.log"
REFRESH_INTERVAL=1
TOP_N=30

# Variables de estado
TAIL_PID=""
TEMP_FILE=""
CURRENT_MODE=""
CURRENT_PERIOD="now"

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
    [date]="Top Fechas"
    [ip]="Top IPs"
    [method]="Top Métodos HTTP"
    [status]="Top Status Codes"
    [ua]="Top User Agents"
    [uri]="Top URIs"
)

declare -A PERIOD_TITLE=(
    [now]="tiempo real"
    [hundred]="últimos 100"
    [thousand]="últimos 1000"
    [complete]="log completo"
)

# Función de limpieza
cleanup() {
    stty echo 2>/dev/null || true

    if [[ -n "$TAIL_PID" ]] && kill -0 "$TAIL_PID" 2>/dev/null; then
        kill "$TAIL_PID" 2>/dev/null || true
    fi

    if [[ -n "$TEMP_FILE" ]] && [[ -f "$TEMP_FILE" ]]; then
        rm -f "$TEMP_FILE"
    fi

    echo ""
    exit 0
}

# Función para mostrar el histograma (sin parpadeo)
show_histogram() {
    local output
    local histogram

    histogram=$(sort "$TEMP_FILE" 2>/dev/null | uniq -c | sort -nr | head -n "$TOP_N")

    output=$(printf '\033[H\033[J')
    output+="=== ${MODE_TITLE[$CURRENT_MODE]} (${PERIOD_TITLE[$CURRENT_PERIOD]}) ==="
    output+=$'\n'
    output+="Propiedad: [d] date  [i] ip  [m] method  [s] status  [a] agent  [u] uri"
    output+=$'\n'
    output+="Periodo: [n] now  [h] hundred  [t] thousand  [c] complete"
    output+=$'\n'
    output+="[Ctrl+C] salir"
    output+=$'\n\n'
    output+="$histogram"

    printf '%s\n' "$output"
}

# Función para cargar datos según el periodo
load_data() {
    local field="${MODE_FIELD[$CURRENT_MODE]}"
    local lines

    case "$CURRENT_PERIOD" in
        hundred)  lines=100 ;;
        thousand) lines=1000 ;;
        complete) lines="" ;;
        *)        return ;; # now no usa esta función
    esac

    # Crear archivo temporal
    TEMP_FILE=$(mktemp /tmp/nginx_stats_XXXXXX.tmp)

    if [[ -n "$lines" ]]; then
        sudo tail -n "$lines" "$LOG_FILE" | jq -r "$field" > "$TEMP_FILE"
    else
        sudo jq -r "$field" "$LOG_FILE" > "$TEMP_FILE"
    fi
}

# Función para iniciar el tail con el campo actual (modo now)
start_tail() {
    local field="${MODE_FIELD[$CURRENT_MODE]}"

    TEMP_FILE=$(mktemp /tmp/nginx_stats_XXXXXX.tmp)
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

# Función para cambiar de modo (propiedad)
switch_mode() {
    local new_mode="$1"

    if [[ "$new_mode" == "$CURRENT_MODE" ]]; then
        return
    fi

    stop_tail
    CURRENT_MODE="$new_mode"

    if [[ "$CURRENT_PERIOD" == "now" ]]; then
        start_tail
    else
        load_data
    fi
}

# Función para cambiar de periodo (siempre recomputa)
switch_period() {
    local new_period="$1"

    stop_tail
    CURRENT_PERIOD="$new_period"

    if [[ "$CURRENT_PERIOD" == "now" ]]; then
        start_tail
    else
        load_data
    fi
}

# Configurar trap
trap cleanup SIGINT SIGTERM EXIT

# Verificar que el log existe
if [[ ! -f "$LOG_FILE" ]]; then
    echo "Error: No se encuentra el archivo $LOG_FILE"
    exit 1
fi

# Verificar que jq está instalado
if ! command -v jq &> /dev/null; then
    echo "Error: jq no está instalado"
    echo "Instalar con: sudo apt-get install jq"
    exit 1
fi

# Determinar modo inicial (argumento o default)
CURRENT_MODE="${1:-ip}"

# Validar modo
if [[ -z "${MODE_FIELD[$CURRENT_MODE]:-}" ]]; then
    echo "Error: Modo inválido: $CURRENT_MODE"
    echo "Modos válidos: date, ip, method, status, ua, uri"
    exit 1
fi

# Iniciar en modo now
start_tail

# Loop principal
while true; do
    show_histogram

    if read -t "$REFRESH_INTERVAL" -n 1 key 2>/dev/null; then
        case "$key" in
            # Propiedades
            d) switch_mode "date" ;;
            i) switch_mode "ip" ;;
            m) switch_mode "method" ;;
            s) switch_mode "status" ;;
            a) switch_mode "ua" ;;
            u) switch_mode "uri" ;;
            # Periodos
            n) switch_period "now" ;;
            h) switch_period "hundred" ;;
            t) switch_period "thousand" ;;
            c) switch_period "complete" ;;
        esac
    fi
done
