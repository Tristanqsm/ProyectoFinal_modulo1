## CUESTIONARIO DE ETAPAS

Este README servira para justificar lo realizado en cada etapa del proyecto al contestar las preguntas de cada etapa:)

---

### ETAPA 1: 
**Comandos usados:**
1. Organizar el proyecto.
El primer paso de este proyecto es crear la carpeta principal llamada sec_guard y dentro de ella crear las siguientes subcarpetas:
capturas/: registros originales.
preparados/: archivos transformados para su procesamiento.
fuentes/: programas en lenguaje C.
scripts/: programas Shell.
resultados/: informes generados.
evidencias/: pruebas y documentación.

Para ello se utilizaron los siguientes comandos:
```bash
#Para la carpeta principal:
mkdir sec_guard
cd sec_guard

#Para las subcarpetas:
mkdir capturas preparados fuentes scripts resultados evidencias
```

2. Asignación y revisión de permisos
Primero cambie los permisos de los **directorios** para que solo el propietario pueda hacer ejecuciones y asi mantener la estructura del proyecto segura. Para esta etapa del proyecto me parece lo necesario, aunque quiza mas adelante deba modificarlo. Para realizar esta modificacion de permisos utilice el comando find para buscar de forma recursiva todos los directorios y sobre estos ejecutar el comando chmod y usar los valores 700 (drwx------):
```bash
find . -type d -exec chmod 700 {} +
```

Despues cambie los permisos de los **scripts**, aunque para realizarlo tuve que crear los scripts que se solicitan en la etapa 2 del proyecto (capturar.sh, normalizar.sh y ejecutar.sh). A los scripts les otorgue permisos de lectura, escritura y ejecución solo al propietario (700).
Para ello utilice el comando chmod 700 (-rwx------) sobre todos los archivos .sh dentro de scripts/:
```bash
touch scripts/{capturar.sh,normalizar.sh,ejecutar.sh}
chmod 700 scripts/*.sh 2>/dev/null || true
```

Por ultimo configure los archivos restantes para que solo el dueño pueda leerlos y escribirlos, para ello utilice el comando find para buscar de forma recursiva todos los archivos que no son .sh y sobre estos ejecutar el comando chmod y usar los valores 600 (-rw-------):
```bash
find . -type f ! -name "*.sh" -exec chmod 600 {} +
```

3. Generación de enlaces y registro de metadatos
En este requerimiento se debe crear el directorio evidencias/pruebas/ donde debe:
- Generar un enlace simbólico al directorio recién creado (este debe estar almacenado en el directorio principal sec_guard).
- Crear un archivo de prueba prueba_doc.txt y agregar la información del sistema con el comando correcto.
- Generar un enlace duro hardlink.txt al archivo de prueba creado..
- Cambiar el nombre del archivo original. 
- En el documento link_record.txt en el directorio evidencias para cada archivo utilizado en la prueba debe registrar, permisos, propietario, tamaño, inodo y marcas de tiempo.

Para realizar lo anterior use los siguientes comandos:

```bash
#Crear la carpeta de pruebas y aplicar el enlace simbolico
mkdir evidencias/pruebas/
ln -s evidencias/pruebas enlace_pruebas

#Agregar informacion al archivo de prueba
uname -a > evidencias/pruebas/prueba_doc.txt

#Generar el enlace duro apuntando al archivo creado
ln evidencias/pruebas/prueba_doc.txt evidencias/pruebas/hardlink.txt

#Cambiar el nombre del archivo original
mv evidencias/pruebas/prueba_doc.txt evidencias/pruebas/prueba_renombrado.txt

#Registrar permisos, propietario, tamaño, inodo y marcas de tiempo en evidencias/link_record.txt
stat evidencias/pruebas/prueba_renombrado.txt evidencias/pruebas/hardlink.txt > evidencias/link_record.txt
```


**Cuestionario:**
- ¿Por qué los permisos adecuados para un directorio pueden ser distintos de los necesarios para un archivo de datos?
Para un archivo de datos basta con permisos de lectura y escritura (r, w). Un directorio requiere obligatoriamente el permiso de ejecución (x) para permitir entrar a su contenido, sin x en el directorio, el usuario no puede leer los archivos internos aunque los archivos tengan r--.

- ¿Qué diferencia existe entre el archivo original y su enlace duro?
No existe diferencia ya que ambos apuntan al mismo bloque de datos en el sistema de archivos, quiza la unica diferencia esta en el nombre del archivo, aunque renombrar o eliminar el archivo original no afecta el acceso a los datos mediante el enlace duro.

- ¿Cuál es la utilidad de establecer enlaces simbólicos en el desarrollo de un sistema?
Nos ayuda a crear atajos absolutos o relativos a directorios o ejecutables sin duplicarlos, asi ahorramos  espacio en el disco.

- ¿Qué información de los metadatos permite reconocer cambios en un archivo?
mtime: Indica cuándo se alteró el contenido del archivo.
ctime: Registra cuándo cambiaron los metadatos o el inodo.
Número de Inodo y Tamaño: Verifican la identidad de los datos y detectar modificaciones en el volumen del archivo. 

---
### ETAPA 2:
**Comandos usados:**
1. Validar la existencia e integridad de paquete_auditoria.tar.gz, extraer su contenido y validar la existencia de al menos 3 archivos.
Como primer paso fue descargar el archivo comprimido y moverlo a la carpeta de capturas/estáticos.
Una vez realizado lo anterior, coloque los siguientes comandos para validar y descomprimir el archivo comprimido:
```bash
tar -tzf capturas/estaticos/paquete_auditoria.tar.gz > /dev/null
tar -zxf capturas/estaticos/paquete_auditoria.tar.gz -C capturas/estaticos/
```

2. Depuración de configuración utilizando procesamiento de texto avanzado para **sshd_config**:
Luego para procesar sshd_config y pasarlo a la carpeta preparados cambiando el puerto a 8080, habilitar el hostkey y eliminar los comentarios y las lineas vacias revise el archivo de sshd_config y pude notar que el Port y los Hostkey empezaban como comentario (con #), por lo que con un sed y una expresion regular cambie estas lineas por lineas que ya no empiecen con #, despues con un grep filtre por solo aquellas lineas que no contengan # y por ultimo, para borrar los saltos de linea use una expresion regular que haga referencia a una linea donde solo hay espacios. Al final el comando y el archivo sshd_activo.txt quedaron de la siguiente manera:
```bash
sed -E -e 's/^#?[[:space:]]*Port[[:space:]]+[0-9]+/Port 8080/' -e 's/^#?[[:space:]]*(HostKey[[:space:]]+.*)/\1/' capturas/estaticos/sshd_config | grep -v "#" | grep -v '^[[:space:]]*$' > preparados/sshd_activo.txt
```

3. Depuración de configuración utilizando procesamiento de texto avanzado para **secure.log**:
Extraer usuarios creados de secure.log -> preparados/usuarios_creados.txt 
Para realizar esto use el comando grep para filtrar por las lineas que contengan el patron “nex user”, luego con un awk le di formato a la salida para solo tener los nombres de los usuarios, su UID y su GID. Al final el comando y el archivo usuarios_creados.txt quedaron de la siguiente manera:
```bash
grep 'new user' capturas/estaticos/secure.log | awk -F'[,=]' '{printf "Usuario: %-20s UID: %-8s GID: %s\n", $2, $4, $6}' > preparados/usuarios_creados.txt
```

4. Depuración de configuración utilizando procesamiento de texto avanzado para **net_traffic.log**:
Extraer conexiones SYN de net_traffic.log -> preparados/conexiones_syn.txt
Para realizar esto es importante revisar la estructura del archivo net_traffic.log, al analizarlo pude notar que las direcciones IP y puerto de origen estan en la columna 2, mientras que las de destino estan en la columna 3 por lo que puedo usar un awk para imprimir solo esas columnas. Ya solo por ultimo use un grep para solo seleccionar las lineas que hagan referencia a una peticion TCP, que son aquellas que tienen Flags [S], por lo que filtre con grep solo aquellas lineas que tengan este patron en ellas. Al final el comando y el archivo conexiones_syn.txt quedaron de la siguiente manera:
```bash
grep "Flags \[S\]" capturas/estaticos/net_traffic.log | awk '{
    split($3, origen, ".");
    split($5, destino, ".");
    ip_origen=origen[1]"."origen[2]"."origen[3]"."origen[4]; port_origen=origen[5];
    ip_destino=destino[1]"."destino[2]"."destino[3]"."destino[4]; port_destino=destino[5];
    print ip_origen ":" port_origen " -> " ip_destino ":" port_destino;
}' > preparados/conexiones_syn.txt
```

**Cuestionario:**
- ¿Qué transformación necesita la salida de cada utilería para convertirse en un registro del archivo normalizado?
Se requiere eliminar encabezados, suprimir símbolos de unidades, limpiar espacios en blanco y proyectar únicamente el par CATEGORIA VALOR estructurado en una sola línea.

- ¿Por qué un valor cero puede ser válido y no debe confundirse con una captura fallida?
Un valor 0 en la categoría PERMISOS indica que hay cero archivos desprotegidos. Una captura fallida representa la imposibilidad de consultar la utilería del sistema y debemos manejarla mediante códigos de retorno como HTTP/POSIX o un mensaje a stderr.

- ¿Cómo comprobarán que la cantidad del encabezado corresponde a los registros conservados?
Contando las líneas que contienen pares de datos mediante wc -l y comparando este entero contra el valor leído en la línea 2 del encabezado en los scripts de auditoría Shell.

- ¿Por qué el orden de las instrucciones dentro del flujo de sed es estrictamente determinante al habilitar directivas y eliminar comentarios? 
Si se eliminan las líneas comentadas antes de procesar las directivas, la información se nos puede borrar (me paso). Por ende, primero se deben identificar y transformar las líneas comentadas de interés con el comando sed y después filtrar el resultado con grep para quitar las lineas con comentarios extras y  las líneas vacías.

- ¿Qué estrategia se empleó para aislar el puerto sin limitar obtener correctamente los cuatro octetos de la IP? 
Utilice la función split() de awk y especifique que se usara el punto como delimitador de campo sobre la cadena $3. Esto permite reconstruir los cuatro octetos del arreglo origen[1] a origen[4] y tener el puerto separado en origen[5].

---
### ETAPA 3:
**Comandos usados:**
**Cuestionario:**