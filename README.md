# Mini Cloud Log Analyzer - Variante C (ARM64)

## Autor
[Nombre del estudiante]

## Objetivo
Este proyecto implementa un analizador de logs en **ARM64 Assembly (AArch64)** para Linux.
Lee códigos HTTP desde `stdin`, detecta la **primera aparición del código 503** y reporta en qué línea aparece.

---

## Análisis del Problema

Se requiere procesar una secuencia de líneas, donde cada línea contiene un código HTTP (por ejemplo `200`, `404`, `503`).

### Requisitos funcionales
1. Leer la entrada desde `stdin`.
2. Parsear cada línea para convertir texto ASCII a entero.
3. Detectar la primera ocurrencia de `503`.
4. Mostrar:
   - `Primer 503 encontrado en linea: X` si existe.
   - `No se encontro ningun codigo 503` si no existe.

### Consideraciones de diseño
- La lectura debe ser eficiente: usar `read` por bloques.
- El parsing debe tolerar caracteres no numéricos (ignorarlos).
- Solo se reporta la **primera** aparición de `503`, aunque existan más.

---

## Estrategia de Implementación

### 1) Entrada y Parsing
- Se usa la syscall `read` (**63**) para leer `stdin` en bloques de 4096 bytes.
- Cada byte se evalúa:
  - Si es dígito (`'0'` a `'9'`), se acumula en el número actual.
  - Si es `\n` (newline), termina la línea y se evalúa el código.
  - Cualquier otro carácter se ignora.

Fórmula de acumulación:

```text
numero = numero * 10 + (digito - '0')
```

### 2) Detección de 503
- Al cerrar cada línea (`\n`), se compara el número acumulado con `503`.
- Si coincide y aún no se había detectado:
  - Se activa un flag de encontrado.
  - Se guarda el número de línea actual.

### 3) Salida
- Se usa `write` (**64**) para imprimir mensajes en `stdout`.
- Si se encontró `503`, se imprime la línea (entero convertido a ASCII por rutina propia).
- El programa termina con `exit` (**93**).

---

## Registros utilizados (convención interna del programa)

| Registro | Propósito |
|---|---|
| `x19` | Contador de líneas (base 1) |
| `x20` | Número HTTP acumulado actual |
| `x21` | Flag de encontrado (`1` si ya apareció 503) |
| `x22` | Línea de la primera aparición de 503 |
| `x23` | File descriptor de entrada (`stdin = 0`) |
| `x24` | Cantidad de bytes leídos en el bloque |
| `x25` | Dirección base del buffer |
| `x26` | Índice dentro del buffer |
| `x27` | Byte actual en procesamiento |

---

## Syscalls Linux ARM64 utilizadas

| Syscall | Número | Uso |
|---|---:|---|
| `read` | 63 | Leer datos desde `stdin` |
| `write` | 64 | Escribir mensajes en `stdout` |
| `exit` | 93 | Finalizar el proceso |

---

## Estructura esperada del proyecto

```text
.
├── analyzer.s
├── Makefile
├── run.sh
├── logs.txt
└── README.md
```

---

## Compilación

```bash
make
```

También puedes recompilar desde cero:

```bash
make clean && make
```

---

## Ejecución

### Ejecución directa

```bash
cat logs.txt | ./analyzer
```

### Ejecución con script

```bash
chmod +x run.sh
./run.sh
```

---

## Caso de prueba ejemplo

Contenido de `logs.txt`:

```text
200
404
503
500
200
503
404
```

Salida esperada:

```text
Primer 503 encontrado en linea: 3
```

---

## Casos probados recomendados

1. **Caso normal**: existe un `503` en línea intermedia.
2. **Sin 503**: debe imprimir mensaje de no encontrado.
3. **Múltiples 503**: debe reportar solo la primera línea.
4. **503 en primera línea**: debe reportar línea 1.

---

## Complejidad

- **Tiempo:** `O(n)` donde `n` es la cantidad total de bytes procesados.
- **Espacio adicional:** `O(1)` (sin contar el buffer fijo de lectura).

---

## Notas técnicas

- El parser evalúa por bytes y es robusto ante entradas con caracteres no numéricos.
- El conteo de líneas es **1-based**.
- Si el flujo termina sin `503`, se informa explícitamente.
