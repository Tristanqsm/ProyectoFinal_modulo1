#!/usr/bin/env bash
set -euo pipefail

Dir_proyecto="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
Dir_telemetria="$Dir_proyecto/capturas/telemetria_raw.log"
Dir_preparados="$Dir_proyecto/preparados/mediciones_sec.txt"
Etiqueta="AuditoriaCursoC"

if [[ ! -f "$Dir_telemetria" ]]; then
    echo "ERROR: El archivo $Dir_telemetria no existe." >&2
    exit 1
fi

Registros_tmp=$(mktemp)
awk '{print $(NF-1), $NF}' "$Dir_telemetria" > "$Registros_tmp "
Total_registros=$(wc -l < "$Registros_tmp " | tr -d ' ')

{
    echo "$Etiqueta"
    echo "$Total_registros"
    cat "$Registros_tmp "
} > "$Dir_preparados"

rm -f "$Registros_tmp "
echo "Archivo normalizado generado en $Dir_preparados ($Total_registros registros)."