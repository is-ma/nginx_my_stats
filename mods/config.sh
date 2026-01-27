# Configuración por defecto
LOG_FILE="/var/log/nginx/shield_access.log"
REFRESH_INTERVAL=2
TOP_N=30

# Arrays de configuración de modos
declare -A MODE_FIELD=(
    [date]=".date"
    [ip]=".ip"
    [method]=".method"
    [status]=".status"
    [ua]=".ua"
    [uri]=".uri"
    [cache]=".cache"
    [lang]=".lang"
    [referer]=".referer"
    [host]=".host"
)

declare -A MODE_TITLE=(
    [date]="Top Fechas"
    [ip]="Top IPs"
    [method]="Top Métodos HTTP"
    [status]="Top Status Codes"
    [ua]="Top User Agents"
    [uri]="Top URIs"
    [cache]="Top Cache Status"
    [lang]="Top Languages"
    [referer]="Top Referers"
    [host]="Top Hosts"
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
    [method]="Método"
    [status]="Status"
    [ua]="User Agent"
    [uri]="URI"
    [cache]="Cache"
    [status]="Status"
    [ua]="User Agent"
    [uri]="URI"
    [lang]="Language"
    [referer]="Referer"
    [host]="Host"
)
