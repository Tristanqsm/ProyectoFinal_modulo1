## CUESTIONARIO DE ETAPAS

Este README servira para justificar lo realizado en cada etapa del proyecto al contestar las preguntas de cada etapa:)

**ETAPA1:**
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
