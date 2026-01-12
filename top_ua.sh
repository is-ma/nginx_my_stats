#!/bin/bash

# =================================================
# top_ua - Monitor de User Agents en tiempo real
# =================================================
# Muestra un histograma vivo de los User Agents
# más frecuentes en el log de Nginx
#
# Uso: top_ua
# Salir: Ctrl+C (limpia automáticamente)
# =================================================

set -euo pipefail

# Configuración
LOG_FILE="/var/log/nginx/shield_access.log"
TEMP_FILE=$(mktemp /tmp/nginx_ua_XXXXXX.tmp)
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
sudo tail -f "$LOG_FILE" | jq --unbuffered -r '.ua' >> "$TEMP_FILE" &
TAIL_PID=$!

# Iniciar el watch con el histograma
watch -n "$REFRESH_INTERVAL" "sort '$TEMP_FILE' | uniq -c | sort -nr | head -n $TOP_N"

# Esta línea normalmente no se alcanza porque watch bloquea,
# pero si watch termina por alguna razón, el trap se encarga de la limpieza
