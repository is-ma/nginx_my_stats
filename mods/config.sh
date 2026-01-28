# Configuración por defecto
LOG_FILE="/var/log/nginx/shield_access.log"
REFRESH_INTERVAL=2
TOP_N=30

# Variable para el número máximo de resultados mostrados
CURRENT_MAX_RESULTS="thirty"

# Arrays de configuración de modos
declare -A MODE_FIELD=(
    [date]=".date"
    [ip]=".ip"
    [method]=".method"  # Restaurado
    [status]=".status"
    [ua]=".ua"
    [uri]=".uri"
    [cache]=".cache"
    [lang]=".lang"
    [referer]=".referer"
    [host]=".host"
    [time]=".date"   # Temporal - usa el mismo campo que date por ahora
    [log]=""
)

declare -A MODE_TITLE=(
    [date]="Top Fechas"
    [ip]="Top IPs"
    [method]="Top Methods"  # Restaurado
    [status]="Top Status Codes"
    [ua]="Top User Agents"
    [uri]="Top URIs"
    [cache]="Top Cache Status"
    [lang]="Top Languages"
    [referer]="Top Referers"
    [host]="Top Hosts"
    [time]="Top Time"
    [log]="Selector de Log"
)

declare -A PERIOD_TITLE=(
    [now]="tiempo real"
    [hundred]="últimos 100"
    [thousand]="últimos 1000"
    [complete]="log completo"
)

declare -A MODE_HEADER=(
    [date]="Fecha"
    [ip]="IP"
    [method]="Method"  # Restaurado
    [status]="Status"
    [ua]="User Agent"
    [uri]="URI"
    [cache]="Cache"
    [lang]="Language"
    [referer]="Referer"
    [host]="Host"
    [time]="Time"
    [log]="Log File"
)

# Configuración para opciones de resultados
declare -A MAX_RESULTS_OPTIONS=(
    [ten]=10
    [twenty]=20
    [thirty]=30
)

declare -A MAX_RESULTS_TITLE=(
    [ten]="ten"
    [twenty]="twenty"
    [thirty]="thirty"
)
