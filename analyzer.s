/*
 * Mini Cloud Log Analyzer - Variante C
 * Detectar el primer evento critico (HTTP 503)
 *
 * Arquitectura: ARM64 (AArch64)
 * Sistema: Linux
 * Assembler: GNU Assembler (as)
 */

    .data
    // Mensajes de salida
msg_found:      .ascii  "Primer 503 encontrado en linea: "
msg_found_len = . - msg_found

msg_not_found:  .ascii  "No se encontro ningun codigo 503\n"
msg_not_found_len = . - msg_not_found

msg_newline:    .ascii  "\n"
msg_newline_len = 1

    .bss
    // Buffer para lectura de stdin
    .align  4
buffer:         .space  4096            // Buffer de entrada

    .text
    .global _start
    .type   _start, %function

/* ============================================
 * PUNTO DE ENTRADA
 * ============================================ */
_start:
    // Registros de proposito general:
    // x19 = contador de lineas (1-based)
    // x20 = numero acumulado (codigo HTTP actual)
    // x21 = flag: 1 si ya encontramos 503, 0 si no
    // x22 = linea donde se encontro el primer 503
    // x23 = descriptor de archivo (stdin = 0)
    // x24 = bytes leidos / indice en buffer
    // x25 = direccion base del buffer
    // x26 = indice actual dentro del buffer

    MOV     x19, #1                 // Linea actual = 1
    MOV     x20, #0                 // Numero acumulado = 0
    MOV     x21, #0                 // Flag encontrado = false
    MOV     x22, #0                 // Linea del primer 503
    MOV     x23, #0                 // stdin = 0
    LDR     x25, =buffer            // x25 = direccion buffer

read_loop:
    // ========================================
    // syscall read(0, buffer, 4096)
    // ========================================
    MOV     x0, x23                 // fd = stdin (0)
    MOV     x1, x25                 // buf = buffer
    MOV     x2, #4096               // count = 4096
    MOV     x8, #63                 // syscall: read
    SVC     #0

    // Verificar resultado de read
    CMP     x0, #0
    B.LE    end_program             // Si <= 0, EOF o error

    MOV     x26, #0                 // indice = 0
    MOV     x24, x0                 // x24 = bytes leidos

process_buffer:
    // ========================================
    // Procesar cada byte del buffer
    // ========================================
    CMP     x26, x24                // indice < bytes_leidos?
    B.GE    read_loop               // Si no, leer mas

    // Cargar byte actual
    LDRB    w27, [x25, x26]         // w27 = buffer[indice]

    // Verificar si es newline (0x0A)
    CMP     w27, #0x0A
    B.EQ    handle_newline

    // Verificar si es digito ('0' = 48 a '9' = 57)
    CMP     w27, #'0'
    B.LT    next_char               // Si < '0', ignorar
    CMP     w27, #'9'
    B.GT    next_char               // Si > '9', ignorar

    // ========================================
    // Es un digito: acumular en x20
    // numero = numero * 10 + (digito - '0')
    // ========================================
    SUB     w27, w27, #'0'          // Convertir ASCII a valor
    MOV     x28, #10
    MUL     x20, x20, x28           // x20 = x20 * 10
    ADD     x20, x20, x27           // x20 = x20 + digito

next_char:
    ADD     x26, x26, #1            // indice++
    B       process_buffer

handle_newline:
    // ========================================
    // Fin de linea: verificar si el numero es 503
    // ========================================

    // Primero verificar si ya encontramos uno
    CMP     x21, #1
    B.EQ    already_found           // Si ya encontramos, solo resetear

    // Comparar con 503
    CMP     x20, #503
    B.NE    not_503

    // ========================================
    // ¡ES 503! Primera ocurrencia
    // ========================================
    MOV     x21, #1                 // flag = true
    MOV     x22, x19                // guardar linea actual

not_503:
already_found:
    // Resetear numero para siguiente linea
    MOV     x20, #0
    // Incrementar contador de lineas
    ADD     x19, x19, #1
    // Siguiente caracter
    ADD     x26, x26, #1
    B       process_buffer

end_program:
    // ========================================
    // Verificar si encontramos 503
    // ========================================
    CMP     x21, #1
    B.EQ    print_found

    // ========================================
    // NO SE ENCONTRO 503
    // ========================================
    MOV     x0, #1                  // fd = stdout (1)
    LDR     x1, =msg_not_found      // buf
    LDR     x2, =msg_not_found_len  // len
    MOV     x8, #64                 // syscall: write
    SVC     #0
    B       exit_program

print_found:
    // ========================================
    // IMPRIMIR: "Primer 503 encontrado en linea: X"
    // ========================================

    // 1. Imprimir mensaje fijo
    MOV     x0, #1                  // fd = stdout
    LDR     x1, =msg_found          // buf
    LDR     x2, =msg_found_len      // len
    MOV     x8, #64                 // syscall: write
    SVC     #0

    // 2. Convertir numero de linea (x22) a ASCII y imprimir
    // Usamos stack como buffer temporal (max 20 digitos)
    MOV     x0, x22                 // numero a convertir
    BL      print_number

    // 3. Imprimir newline
    MOV     x0, #1
    LDR     x1, =msg_newline
    MOV     x2, #1
    MOV     x8, #64
    SVC     #0

exit_program:
    // ========================================
    // syscall exit(0)
    // ========================================
    MOV     x0, #0                  // status = 0
    MOV     x8, #93                 // syscall: exit
    SVC     #0

/* ============================================
 * FUNCION: print_number
 * Convierte un numero entero positivo a ASCII
 * y lo imprime en stdout
 * Entrada: x0 = numero a imprimir
 * ============================================ */
print_number:
    // Guardar registros
    STP     x29, x30, [SP, #-16]!
    MOV     x29, SP

    // Reservar espacio en stack (32 bytes)
    SUB     SP, SP, #32

    MOV     x1, #0                  // contador de digitos
    MOV     x2, #10                 // divisor
    ADD     x3, SP, #31             // x3 = puntero al final del buffer

    // Caso especial: numero = 0
    CMP     x0, #0
    B.NE    convert_loop

    MOV     w4, #'0'
    STRB    w4, [x3]
    MOV     x1, #1
    B       print_digits

convert_loop:
    CMP     x0, #0
    B.EQ    print_digits

    UDIV    x5, x0, x2              // x5 = x0 / 10
    MUL     x6, x5, x2              // x6 = x5 * 10
    SUB     x6, x0, x6              // x6 = x0 % 10 (digito)

    ADD     w6, w6, #'0'            // Convertir a ASCII
    STRB    w6, [x3]                // Guardar digito
    SUB     x3, x3, #1              // Mover puntero atras
    ADD     x1, x1, #1              // contador++

    MOV     x0, x5                  // x0 = x0 / 10
    B       convert_loop

print_digits:
    // x3 apunta al ultimo digito guardado
    // x1 = cantidad de digitos
    // Calcular direccion de inicio
    ADD     x3, x3, #1              // Ajustar puntero al primer digito

    // syscall write(1, x3, x1)
    MOV     x4, x1                  // guardar cantidad de digitos
    MOV     x0, #1                  // fd = stdout
    MOV     x1, x3                  // buf = digitos
    MOV     x2, x4                  // len = digitos
    MOV     x8, #64                 // syscall: write
    SVC     #0

    // Restaurar stack y registros
    ADD     SP, SP, #32
    LDP     x29, x30, [SP], #16
    RET
