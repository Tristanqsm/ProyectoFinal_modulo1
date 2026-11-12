// ENCABEZADOS
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// VARIABLES GLOBALES
#define MAX_LABEL 32
#define CAT_DISCO "DISCO"
#define CAT_PROCESOS "PROCESOS"
#define CAT_PERMISOS "PERMISOS"

// ESTRUCTURAS
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
} ResumenCategoria;

// FUNCIONES
// FUNCION PARA INICIALIZAR LAS VARIABLES DEL RESUMEN
void inicializar_resumen(ResumenCategoria *res, const char *nombre) {
  strncpy(res->nombre, nombre, sizeof(res->nombre) - 1);
  res->nombre[sizeof(res->nombre) - 1] = '\0';
  res->cantidad = 0;
  res->suma = 0;
  res->min = 0;
  res->max = 0;
  res->promedio = 0.0;
  res->alertas = 0;
}

// ACTUALIZA LOS DATOS DE LA CATEGORÍA
void actualizar_categoria(ResumenCategoria *res, int valor) {
  if (res->cantidad == 0) {
    res->min = valor;
    res->max = valor;
  } else {
    if (valor < res->min)
      res->min = valor;
    if (valor > res->max)
      res->max = valor;
  }
  res->cantidad++;
  res->suma += valor;

  // Evaluación directa de condiciones de alerta por categoría
  if (strcmp(res->nombre, CAT_DISCO) == 0 && valor >= 80) {
    res->alertas++;
  } else if (strcmp(res->nombre, CAT_PROCESOS) == 0 && valor >= 30) {
    res->alertas++;
  } else if (strcmp(res->nombre, CAT_PERMISOS) == 0 && valor > 0) {
    res->alertas++;
  }
}

// FUNCIÓN DE VALIDACIÓN
int validar_intervalo(const char *cat, int valor) {
  if (strcmp(cat, CAT_DISCO) == 0)
    return (valor >= 0 && valor <= 100);
  if (strcmp(cat, CAT_PROCESOS) == 0)
    return (valor >= 0 && valor <= 2000);
  if (strcmp(cat, CAT_PERMISOS) == 0)
    return (valor >= 0 && valor <= 200);
  return 0;
}

// FUNCIÓN PRINCIPAL
int main(int argc, char *argv[]) {
  if (argc != 3) {
    fprintf(stderr, "Uso: %s <archivo_entrada> <archivo_salida>\n", argv[0]);
    return 1;
  }

  // INICIO DE LA SECCION DE VALIDACION DE ERRORES--------------------------|
  FILE *fin = fopen(argv[1], "r");
  if (!fin) {
    perror("Error al abrir archivo de entrada");
    return 1;
  }

  char etiqueta[MAX_LABEL];
  int cantidad_declarada = 0;

  if (fscanf(fin, "%31s", etiqueta) != 1) {
    fprintf(stderr, "Error: No se pudo leer la etiqueta de identificacion.\n");
    fclose(fin);
    return 2;
  }

  if (fscanf(fin, "%d", &cantidad_declarada) != 1) {
    fprintf(stderr, "Error: No se pudo leer la cantidad total de registros.\n");
    fclose(fin);
    return 2;
  }

  if (cantidad_declarada < 0 || cantidad_declarada > 200) {
    fprintf(stderr, "Error: Cantidad de registros fuera de rango [0-200]: %d\n",
            cantidad_declarada);
    fclose(fin);
    return 2;
  }

  Medicion *mediciones = NULL;
  if (cantidad_declarada > 0) {
    mediciones = (Medicion *)malloc(cantidad_declarada * sizeof(Medicion));
    if (!mediciones) {
      fprintf(stderr, "Error: Fallo la asignacion de memoria dinamica.\n");
      fclose(fin);
      return 3;
    }
  }

  int registros_leidos = 0;
  char cat_buffer[16];
  int val_buffer;

  while (fscanf(fin, "%15s %d", cat_buffer, &val_buffer) == 2) {
    if (registros_leidos >= cantidad_declarada) {
      fprintf(
          stderr,
          "Error: El archivo contiene mas registros que los declarados (%d).\n",
          cantidad_declarada);
      free(mediciones);
      fclose(fin);
      return 4;
    }

    if (!validar_intervalo(cat_buffer, val_buffer)) {
      fprintf(stderr, "Error: Valor fuera de rango para %s: %d\n", cat_buffer,
              val_buffer);
      free(mediciones);
      fclose(fin);
      return 5;
    }

    strncpy(mediciones[registros_leidos].categoria, cat_buffer,
            sizeof(mediciones[registros_leidos].categoria) - 1);
    mediciones[registros_leidos]
        .categoria[sizeof(mediciones[registros_leidos].categoria) - 1] = '\0';
    mediciones[registros_leidos].valor = val_buffer;
    registros_leidos++;
  }

  fclose(fin);

  if (registros_leidos != cantidad_declarada) {
    fprintf(stderr,
            "Error: Se declararon %d registros pero solo se leyeron %d.\n",
            cantidad_declarada, registros_leidos);
    free(mediciones);
    return 6;
  }
  // FIN DE LA SECCION DE VALIDACION DE ERRORES--------------------------|

  // INICIALIZAR LAS VARIABLES DE LOS RESUMENES:
  ResumenCategoria res_disco, res_procesos, res_permisos;
  inicializar_resumen(&res_disco, CAT_DISCO);
  inicializar_resumen(&res_procesos, CAT_PROCESOS);
  inicializar_resumen(&res_permisos, CAT_PERMISOS);

  for (int i = 0; i < registros_leidos; i++) {
    if (strcmp(mediciones[i].categoria, CAT_DISCO) == 0) {
      actualizar_categoria(&res_disco, mediciones[i].valor);
    } else if (strcmp(mediciones[i].categoria, CAT_PROCESOS) == 0) {
      actualizar_categoria(&res_procesos, mediciones[i].valor);
    } else if (strcmp(mediciones[i].categoria, CAT_PERMISOS) == 0) {
      actualizar_categoria(&res_permisos, mediciones[i].valor);
    }
  }

  if (res_disco.cantidad > 0)
    res_disco.promedio = (double)res_disco.suma / res_disco.cantidad;
  if (res_procesos.cantidad > 0)
    res_procesos.promedio = (double)res_procesos.suma / res_procesos.cantidad;
  if (res_permisos.cantidad > 0)
    res_permisos.promedio = (double)res_permisos.suma / res_permisos.cantidad;

  FILE *fout = fopen(argv[2], "w");
  if (!fout) {
    perror("Error al crear archivo de informe");
    free(mediciones);
    return 7;
  }

  // ESCRIBIR EL INFORME
  fprintf(fout, "INFORME DE MONITOREO\n");
  fprintf(fout, "Etiqueta: %s\n", etiqueta);
  fprintf(fout, "Registros: %d\n", registros_leidos);

  ResumenCategoria *categorias[3] = {&res_disco, &res_procesos, &res_permisos};
  for (int i = 0; i < 3; i++) {
    fprintf(fout, "Categoria %s\n", categorias[i]->nombre);
    if (categorias[i]->cantidad == 0) {
      fprintf(fout, "- Sin datos\n");
    } else {
      fprintf(fout, "- Cantidad: %d\n", categorias[i]->cantidad);
      fprintf(fout, "- Suma: %ld\n", categorias[i]->suma);
      fprintf(fout, "- Minimo: %d\n", categorias[i]->min);
      fprintf(fout, "- Maximo: %d\n", categorias[i]->max);
      fprintf(fout, "- Promedio: %.2f\n", categorias[i]->promedio);
      fprintf(fout, "- Alertas: %d\n", categorias[i]->alertas);
    }
  }

  int total_alertas =
      res_disco.alertas + res_procesos.alertas + res_permisos.alertas;
  fprintf(fout, "Observaciones que cumplen condiciones de alerta: %d.\n",
          total_alertas);
  fprintf(fout, "Umbrales utilizados con fines didacticos.\n");

  fclose(fout);
  free(mediciones);
  return 0;
}
