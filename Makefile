# Makefile para Mini Cloud Log Analyzer - Variante C
# Arquitectura: ARM64

AS      = as
LD      = ld
ASFLAGS = -g
LDFLAGS =

TARGET  = analyzer
SRC     = analyzer.s
OBJ     = analyzer.o

.PHONY: all clean run test

all: $(TARGET)

$(TARGET): $(OBJ)
	$(LD) $(LDFLAGS) -o $@ $<

$(OBJ): $(SRC)
	$(AS) $(ASFLAGS) -o $@ $<

run: $(TARGET)
	cat logs.txt | ./$(TARGET)

test: $(TARGET)
	@echo "=== Prueba con logs.txt ==="
	cat logs.txt | ./$(TARGET)

clean:
	rm -f $(TARGET) $(OBJ)
