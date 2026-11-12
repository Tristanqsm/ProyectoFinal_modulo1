## CUESTIONARIO DE ETAPAS

Este README servira para justificar lo realizado en cada etapa del proyecto al contestar las preguntas de cada etapa:)

---

### ETAPA 1: 
**Desarrollo:**
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
**Desarrollo:**
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
    split($2, origen, ".");
    split($4, destino, ".");
    ip_origen =origen[1] "." origen[2] "." origen[3] "." origen[4]; port_origen=origen[5];
    ip_destino=destino[1]"."destino[2]"."destino[3]"."destino[4]; port_destino=destino[5];
    print "ORIGEN: " ip_origen ":" port_origen "   ->   DESTINO: " ip_destino ":" port_destino;
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
**Desarrollo:**
1. Diseñar las estructuras.
Para la estructura de Medicion decidi dejar fijo la categoria con un tamaño de 16 y que esta tambien tenga el atributo para guardar el valor de la categoria. Por otra parte, para la estructura de ResumenCategoria decidi dejar el mismo valor para el nombre de la categoria (en 16), ademas agregue atributos que puedan ayudar a realizar el resumen de la categoria como la cantidad, la suma, el minimo, el maximo, el promedio, las alertas y el umbral.
```bash
typedef struct {
  char categoria[16];
  int valor;
} Medicion;

typedef struct {
  char nombre[16];
  int cantidad;
  long suma;
  int min;
  int max;
  double promedio;
  int alertas;
  int umbral ;
  int es_alerta_estricta; // 1 si > threshold, 0 si >= threshold
} ResumenCategoria;
```

2. Leer y validar la entrada.
Se validaron tanto los metadatos del encabezado como cada registro individual para prevenir que el buffer se desborde  y rechazar archivos corruptos, truncados o manipulados antes de hacer el calculo del resumen de las categorias. Todo esto se encuentra definido en la funcion principal, donde primero se busca que el archivo abra correctamente, luego que se pueda leer la etiqueta de identificacion, luego que se lea correctamente la cantidad de registros y despues que esta cantidad se encuentre en el intervalo de 0 a 200, luego que la asignacion de la memoria dinamica se haga correctamente, que el archivo no tenga mas registros de los que se declararon, que el valor este dentro del rango y luego que se lean todos los registros.

3. Reservar y utilizar memoria.
Como la cantidad de mediciones varía entre 0 y 200 en cada ejecución, la memoria dinámica evita desperdiciar espacio fijo y permite manejar archivos vacíos de cero registros sin fallar al intentar reservar 0 bytes. Para todo este proceso de la memoria dinamica estuve utilizando malloc para la creacion de la estructura de Medicion, sin embargo ya no quise usar malloc para hacer dinamico el tamaño de las categorias para evitar esos bucles de memoria.
```bash
Medicion *mediciones = NULL;
  if (cantidad_declarada > 0) {
    mediciones = (Medicion *)malloc(cantidad_declarada * sizeof(Medicion));
    if (!mediciones) { ... }
  }
```

4. Procesar por categoría.
Para el proceso de las categorias me di cuenta que seria mas eficiente crear una funcion para cada categoria, de esta manera me aseguro de que cada una se procese por separado y ademas puedo inicializar min y max con el primer valor real de esa categoria.
```bash
ResumenCategoria res_disco, res_procesos, res_permisos;
  inicializar_resumen(&res_disco, CAT_DISCO, 80, 0);
  inicializar_resumen(&res_procesos, CAT_PROCESOS, 30, 0);
  inicializar_resumen(&res_permisos, CAT_PERMISOS, 0, 1);
```
5. Escribir y finalizar correctamente.
Me encargue de hacer la apertura del archivo de salida antes de escribir y la invocación de fclose() y free() en todas las rutas de ejecución para evitar fugas de memoria.
```bash
if (!validar_intervalo(cat_buffer, val_buffer)) {
      fprintf(stderr, "Error: Valor fuera de rango para %s: %d\n", cat_buffer,
              val_buffer);
-->   free(mediciones);
-->   fclose(fin);
      return 5;
    }

-->  fclose(fout);
-->  free(mediciones);
  return 0;
```


**Cuestionario:**
- ¿Qué diferencia existe entre almacenar una medición y almacenar el resumen de una categoría?
Almacenar una medición guarda una observación individual atómica tal como ocurrió en un instante (categoría y valor). Almacenar el resumen guarda métricas estadísticas calculadas a partir de todas las observaciones agrupadas de esa categoría (cantidad, suma, mínimo, máximo, promedio y alertas).

- ¿Cómo evitarán una división entre cero o utilizar un mínimo que todavía no se ha inicializado?
La división entre cero se evita verificando explícitamente if (res.cantidad > 0) antes de calcular suma / cantidad (si es 0, se reporta "Sin datos"). El mínimo no inicializado se evita asignándole el valor de la primera medición válida de esa categoría (if (res.cantidad == 0) { res.min = valor; res.max = valor; }), en lugar de usar constantes arbitrarias.

- Si ocurre un error después de reservar memoria y abrir un archivo, ¿qué recursos deben liberar o cerrar?
Se debe liberar la memoria dinámica asignada en el heap mediante free(mediciones) y cerrar todo flujo de archivo abierto mediante fclose(fin) y/o fclose(fout) antes de retornar el código de error del programa.

---
### ETAPA 4:
**Desarrollo**


**Cuestionario:**