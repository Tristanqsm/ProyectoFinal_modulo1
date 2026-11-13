#!/usr/bin/env bash

echo "====================================================================="
echo "Iniciando captura...:)"

#Definicion de las variables que usaré
set -euo pipefail # Para que el script no falle si hay algun error

Dir_proyecto="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"  # Ruta base del script
Dir_telemetria="$Dir_proyecto/capturas/telemetria_raw.log"       # Ruta del archivo telemetria_raw.log
Fecha_hora=$(date "+%Y-%m-%d %H:%M:%S")                          # Fecha y hora actual


Ocupacion_disco=$(df -P "$HOME" | awk 'NR==2 {gsub(/%/, ""); print $5}') # Obtengo el % de ocupación del disco
if [[ -z "$Ocupacion_disco" || ! "$Ocupacion_disco" =~ ^[0-9]+$ ]]; then # Si el valor es nulo o no es un número
    echo "ERROR: No se pudo obtener la metrica de DISCO" >&2
    exit 1
fi

# Total de procesos de la cuenta del usuario
if ps -u "$USER" --no-headers >/dev/null 2>&1; then
    Cantidad_procesos=$(ps -u "$USER" --no-headers | wc -l | tr -d ' ')
else
    Cantidad_procesos=$(ps -u "$USER" -o pid= | wc -l | tr -d ' ')
fi
if [[ -z "$Cantidad_procesos" || ! "$Cantidad_procesos" =~ ^[0-9]+$ ]]; then
    echo "ERROR: No se pudo obtener la metrica de PROCESOS" >&2
    exit 1
fi

# Archivos regulares en sec_guard con escritura a grupo u otros
Permisos=$(find "$Dir_proyecto" -type f \( -perm -020 -o -perm -002 \) | wc -l | tr -d ' ')
if [[ -z "$Permisos" || ! "$Permisos" =~ ^[0-9]+$ ]]; then
    echo "ERROR: No se pudo obtener la metrica de PERMISOS" >&2
    exit 1
fi

# Escribir registros en capturas/telemetria_raw.log
echo "$Fecha_hora DISCO $Ocupacion_disco" >> "$Dir_telemetria"
echo "$Fecha_hora PROCESOS $Cantidad_procesos"  >> "$Dir_telemetria"
echo "$Fecha_hora PERMISOS $Permisos" >> "$Dir_telemetria"

echo ""
echo "Captura realizada correctamente a las $Fecha_hora."
echo "====================================================================="