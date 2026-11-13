#!/usr/bin/env bash
set -euo pipefail

# Definición de rutas base del proyecto para no tener errores jeje
DIR_SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIR_PROYECTO="$(cd "$DIR_SCRIPT/.." && pwd)"

DIR_CAPTURAS="$DIR_PROYECTO/capturas"
DIR_ESTATICOS="$DIR_CAPTURAS/estaticos"
DIR_PREPARADOS="$DIR_PROYECTO/preparados"
DIR_FUENTES="$DIR_PROYECTO/fuentes"
DIR_SCRIPTS="$DIR_PROYECTO/scripts"
DIR_RESULTADOS="$DIR_PROYECTO/resultados"
DIR_EVIDENCIAS="$DIR_PROYECTO/evidencias"

PAQUETE_TAR="$DIR_ESTATICOS/paquete_auditoria.tar.gz"
FUENTE_C="$DIR_FUENTES/sec_engine.c"
BINARIO_C="$DIR_FUENTES/sec_engine"
SCRIPT_CAPTURAR="$DIR_SCRIPTS/capturar.sh"
SCRIPT_NORMALIZAR="$DIR_SCRIPTS/normalizar.sh"
ARCH_NORMALIZADO="$DIR_PREPARADOS/mediciones_sec.txt"
INFORME_FINAL="$DIR_RESULTADOS/informe_monitoreo.txt"

# Función de escape para reportar errores y abortar de inmediato
error_exit() {
    echo "[-] ERROR CRÍTICO: $1" >&2
    echo "[-] Flujo abortado de inmediato para proteger los datos." >&2
    exit "${2:-1}"
}

echo "=============================================================================="
echo "          INICIANDO SECUENCIA DE OPERACIONES - SEC_GUARD                     "
echo "=============================================================================="
echo "[+] Directorio raíz del proyecto: $DIR_PROYECTO"
echo "[+] Fecha y hora de inicio: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""


# ETAPA 1: LIMPIEZA PREVENTIVA
echo ">>> [ETAPA 1/7] Limpieza preventiva..."

# Asegurar directorios requeridos
mkdir -p "$DIR_CAPTURAS" "$DIR_ESTATICOS" "$DIR_PREPARADOS" "$DIR_FUENTES" "$DIR_SCRIPTS" "$DIR_RESULTADOS" "$DIR_EVIDENCIAS/pruebas"

# Eliminar archivos viejos
if [ -d "$DIR_RESULTADOS" ]; then
    rm -f "$DIR_RESULTADOS"/*
fi

# Eliminar el binario anterior
rm -f "$BINARIO_C"

# Eliminar archivos intermedios
rm -f "$DIR_PREPARADOS/sshd_activo.txt" \
      "$DIR_PREPARADOS/usuarios_creados.txt" \
      "$DIR_PREPARADOS/conexiones_syn.txt" \
      "$DIR_PREPARADOS/mediciones_sec.txt"

echo "Limpieza preventiva completada exitosamente."
echo ""


# ETAPA 2: VALIDACIÓN Y EXTRACCIÓN DE PAQUETE ESTÁTICO
echo ">>> [ETAPA 2/7] Validación y extracción de paquete_auditoria.tar.gz..."

# Validar que exista el archivo
if [[ ! -f "$PAQUETE_TAR" ]]; then
    error_exit "El archivo físico '$PAQUETE_TAR' no existe." 10
fi

# Validar que no este corrupto
if ! tar -tzf "$PAQUETE_TAR" >/dev/null 2>&1; then
    error_exit "Fallo en la integridad estructural de '$PAQUETE_TAR'. Archivo corrupto o no es un tar.gz válido." 11
fi

# Descomprimir
if ! tar -zxf "$PAQUETE_TAR" -C "$DIR_ESTATICOS"; then
    error_exit "Error al descomprimir '$PAQUETE_TAR' en '$DIR_ESTATICOS'." 12
fi

# Verificar que esten los 3 archivos
for arch in "sshd_config" "secure.log" "net_traffic.log"; do
    if [[ ! -s "$DIR_ESTATICOS/$arch" ]]; then
        error_exit "El archivo requerido '$arch' no se encuentra o está vacío tras la extracción." 13
    fi
done

echo "Paquete .tar.gz validado en integridad y extraído correctamente."
echo ""


# ETAPA 3: AUDITORÍA Y TRANSFORMACIÓN DE ARCHIVOS ESTÁTICOS
echo ">>> [ETAPA 3/7] Auditoría y depuración de archivos estáticos..."

# Procesamiento sshd_config
if ! sed -E -e 's/^#?[[:space:]]*Port[[:space:]]+[0-9]+/Port 8080/' \
            -e 's/^#?[[:space:]]*(HostKey[[:space:]]+.*)/\1/' \
            "$DIR_ESTATICOS/sshd_config" | grep -v "#" | grep -v '^[[:space:]]*$' > "$DIR_PREPARADOS/sshd_activo.txt"; then
    error_exit "Fallo al procesar '$DIR_ESTATICOS/sshd_config'." 20
fi
if [[ ! -s "$DIR_PREPARADOS/sshd_activo.txt" ]]; then
    error_exit "El archivo 'preparados/sshd_activo.txt' resultante está vacío." 21
fi

# Procesamiento secure.log
if ! grep 'new user' "$DIR_ESTATICOS/secure.log" | awk -F'[,=]' '{printf "Usuario: %-20s UID: %-8s GID: %s\n", $2, $4, $6}' > "$DIR_PREPARADOS/usuarios_creados.txt"; then
    error_exit "Fallo al procesar '$DIR_ESTATICOS/secure.log'." 22
fi
if [[ ! -s "$DIR_PREPARADOS/usuarios_creados.txt" ]]; then
    error_exit "El archivo 'preparados/usuarios_creados.txt' resultante está vacío." 23
fi

# Procesamiento net_traffic.log
if ! grep "Flags \[S\]" "$DIR_ESTATICOS/net_traffic.log" | awk '{
    split($2, origen, ".");
    split($4, destino, ".");
    ip_origen =origen[1] "." origen[2] "." origen[3] "." origen[4]; port_origen=origen[5];
    ip_destino=destino[1]"."destino[2]"."destino[3]"."destino[4]; port_destino=destino[5];
    print "ORIGEN: " ip_origen ":" port_origen "   ->   DESTINO: " ip_destino ":" port_destino;
}' > "$DIR_PREPARADOS/conexiones_syn.txt"; then
    error_exit "Fallo al procesar '$DIR_ESTATICOS/net_traffic.log'." 24
fi
if [[ ! -s "$DIR_PREPARADOS/conexiones_syn.txt" ]]; then
    error_exit "El archivo 'preparados/conexiones_syn.txt' resultante está vacío." 25
fi

echo "Auditoría de archivos estáticos procesada correctamente en preparados/."
echo ""


# ETAPA 4: COMPILACIÓN CONTROLADA DEL ANALIZADOR EN C
echo ">>> [ETAPA 4/7] Compilación de sec_engine.c..."

if [[ ! -f "$FUENTE_C" ]]; then
    error_exit "El archivo fuente '$FUENTE_C' no existe." 30
fi

CFLAGS="-Wall -Wextra -Werror -pedantic -std=c99"
if ! gcc $CFLAGS "$FUENTE_C" -o "$BINARIO_C"; then
    error_exit "Fallo en la compilación de '$FUENTE_C' con banderas estrictas ($CFLAGS). Abortando sin ejecutar." 31
fi

if [[ ! -x "$BINARIO_C" ]]; then
    error_exit "El binario compilado '$BINARIO_C' no es ejecutable." 32
fi

echo "[✓] Compilación exitosa con banderas estrictas ($CFLAGS)."
echo ""


# ETAPA 5: CAPTURA DINÁMICA DE MÉTRICAS
echo ">>> [ETAPA 5/7] Ejecución de captura dinámica..."

if [[ ! -f "$SCRIPT_CAPTURAR" ]]; then
    error_exit "No se encontró el script de captura '$SCRIPT_CAPTURAR'." 40
fi

if ! bash "$SCRIPT_CAPTURAR"; then
    error_exit "Error en la ejecución de capturar.sh." 41
fi

if [[ ! -s "$DIR_CAPTURAS/telemetria_raw.log" ]]; then
    error_exit "El archivo '$DIR_CAPTURAS/telemetria_raw.log' no existe o está vacío." 42
fi

echo "Captura de telemetría realizada y registrada exitosamente."
echo ""


# ETAPA 6: NORMALIZACIÓN DE DATOS
echo ">>> [ETAPA 6/7] Normalización de datos..."

if [[ ! -f "$SCRIPT_NORMALIZAR" ]]; then
    error_exit "No se encontró el script de normalización '$SCRIPT_NORMALIZAR'." 50
fi

if ! bash "$SCRIPT_NORMALIZAR"; then
    error_exit "Error en la ejecución de normalizar.sh." 51
fi

if [[ ! -s "$ARCH_NORMALIZADO" ]]; then
    error_exit "El archivo normalizado '$ARCH_NORMALIZADO' no existe o está vacío." 52
fi

echo "Datos normalizados correctamente en mediciones_sec.txt."
echo ""


# ETAPA 7: EJECUCIÓN DEL ANALIZADOR EN C Y GENERACIÓN DE INFORME
echo ">>> [ETAPA 7/7] Ejecución del motor de análisis en C..."

if ! "$BINARIO_C" "$ARCH_NORMALIZADO" "$INFORME_FINAL"; then
    error_exit "El analizador sec_engine retornó código de error." 60
fi

if [[ ! -s "$INFORME_FINAL" ]]; then
    error_exit "El informe de salida '$INFORME_FINAL' no existe o está vacío." 61
fi

echo "Análisis en C ejecutado exitosamente."
echo ""


# RESUMEN Y RESULTADOS
echo "=============================================================================="
echo "          FLUJO COMPLETADO SATISFACTORIAMENTE            "
echo "=============================================================================="
echo "[+] Informe generado en: $INFORME_FINAL"
echo ""
echo "--- CONTENIDO DEL INFORME FINAL ---"
cat "$INFORME_FINAL"
echo "-----------------------------------"
echo "Ejecución finalizada exitosamente a las $(date '+%Y-%m-%d %H:%M:%S')."
