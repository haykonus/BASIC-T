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
	cmp $(BUILD)/BASICT.COM original/BASICT.COM
	cd $(BUILD) && sha256sum -c ../original/BASICT.sha256
	@echo "IDENTISCH mit dem Original"

regen:
	sh tools/regen.sh

clean:
	rm -rf $(BUILD)

.PHONY: all check regen clean
