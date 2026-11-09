# BASIC-T: Assemblieren mit AS (Alfred Arnold) und Vergleich mit dem Original
ASL   ?= asl
P2BIN ?= p2bin
BUILD := build

all: $(BUILD)/BASICT.COM

$(BUILD)/BASICT.COM: src/basict.asm
	mkdir -p $(BUILD)
	$(ASL) -cpu z80undoc -L -q -o $(BUILD)/basict.p -olist $(BUILD)/basict.lst src/basict.asm
	$(P2BIN) -q $(BUILD)/basict.p $@

check: $(BUILD)/BASICT.COM
	cd original && sha256sum -c BASICT.sha256
	test $$(wc -c < $(BUILD)/BASICT.COM) -eq 16128
	cmp -n 16128 $(BUILD)/BASICT.COM original/BASICT.COM
	cmp $(BUILD)/BASICT.COM bin/BASICT.COM || { echo "bin/BASICT.COM veraltet: make bin"; exit 1; }
	$(ASL) -cpu z80undoc -q -D CODE_ORG=0200H -D RAM_BASE=4000H -o $(BUILD)/b200.p src/basict.asm
	$(P2BIN) -q -l 0 $(BUILD)/b200.p $(BUILD)/BASICT-0200H.COM
	cmp $(BUILD)/BASICT-0200H.COM bin/BASICT-0200H.COM || { echo "bin/BASICT-0200H.COM veraltet: make bin"; exit 1; }
	@echo "IDENTISCH mit dem Original (0100H-3FFFH; ab 4000H nur Speicherrest)"

# Gebaute Datei fuer den Browser-Emulator ablegen
bin: $(BUILD)/BASICT.COM
	mkdir -p bin
	cp $(BUILD)/BASICT.COM bin/BASICT.COM
	$(ASL) -cpu z80undoc -q -D CODE_ORG=0200H -D RAM_BASE=4000H -o $(BUILD)/b200.p src/basict.asm
	$(P2BIN) -q -l 0 $(BUILD)/b200.p bin/BASICT-0200H.COM

# Probe: an anderer Adresse assemblieren (Standard 0200H)
RELOC ?= 0200H
RAM ?= 4000H
reloc:
	mkdir -p $(BUILD)
	$(ASL) -cpu z80undoc -q -D CODE_ORG=$(RELOC) -D RAM_BASE=$(RAM) -o $(BUILD)/reloc.p src/basict.asm
	$(P2BIN) -q -l 0 $(BUILD)/reloc.p $(BUILD)/BASICT-$(RELOC)-$(RAM).COM
	@echo "erzeugt: $(BUILD)/BASICT-$(RELOC)-$(RAM).COM"

regen:
	sh tools/regen.sh

clean:
	rm -rf $(BUILD)

.PHONY: all bin check reloc regen clean
