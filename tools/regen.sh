#!/bin/sh
# Erzeugt src/basict.asm neu aus original/BASICT.COM.
# Aufruf aus basic-t/:  sh tools/regen.sh
set -e
T=$(cd "$(dirname "$0")" && pwd); R=$(dirname "$T"); W="$R/build/regen"
rm -rf "$W"; mkdir -p "$W/src"
cp "$R/original/BASICT.COM" "$T"/*.py "$T/header.inc" "$W/"
cd "$W"
python3 gram.py   # Grammatik-Knoten und Aktionen
python3 optab.py  # Laufzeit-Opcodetabelle
python3 scan.py   # Zustandstabelle der Zeichen-Erkennung
python3 trace.py  # Ablaufverfolgung Code/Daten
python3 gen.py    # AS-Quelltext erzeugen
python3 split.py  # in Module aufteilen (INCLUDE)
rm -f "$R"/src/*.inc; cp src/basict.asm src/*.inc "$R/src/"
echo "src/basict.asm neu erzeugt"
