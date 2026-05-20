# Mini Cloud Log Analyzer - ARM64

Detecta el primer evento critico `HTTP 503` desde entrada estandar con ensamblador ARM64.

## Archivos

- `analyzer.s`: código fuente ARM64.
- `Makefile`: compilación y pruebas.
- `run.sh`: script de ejecución.
- `logs.txt`: datos de prueba.

## Uso

```bash
make
cat logs.txt | ./analyzer
```

O bien:

```bash
chmod +x run.sh
./run.sh
```
