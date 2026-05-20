#!/bin/bash
# Script de ejecución para Mini Cloud Log Analyzer - Variante C

set -e

echo "=========================================="
echo "  Mini Cloud Log Analyzer - Variante C"
echo "  Detectar primer evento critico (503)"
echo "=========================================="

# Compilar
echo "[*] Compilando..."
make clean
make

# Verificar que existe archivo de logs
if [ ! -f "logs.txt" ]; then
    echo "[!] Error: No se encuentra logs.txt"
    exit 1
fi

echo "[*] Ejecutando analisis..."
echo "[*] Contenido de logs.txt:"
cat logs.txt
echo ""
echo "[*] Resultado del analisis:"
cat logs.txt | ./analyzer

echo ""
echo "[*] Prueba completada."
