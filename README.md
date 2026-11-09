# BASIC-T – Rekonstruktion eines DDR-BASIC für CP/M (Z80/U880)

**VEB Transformatoren- und Röntgenwerk „Hermann Matern“ Dresden · 1983/1986**

Ein seltenes Z80/U880-BASIC für CP/M, vollständig rückübersetzt. BASIC-T wurde im
VEB Transformatoren- und Röntgenwerk „Hermann Matern“ Dresden entwickelt
(Sprachbeschreibung: R. Heyne, Stand 27.10.1983) und ist kein Klon eines bekannten
BASIC. Die hier vorliegende COM-Datei von 1986 enthält zusätzlich Grafikbefehle
(DOT, LINE, FILL, TEST …).

Der Quelltext für den Makroassembler [AS von Alfred Arnold](http://john.ccac.rwth-aachen.de:8000/as/as_EN.html)
ergibt eine Datei, die **Byte für Byte mit dem Original übereinstimmt** (0100H–3FFFH,
16128 Byte). Das Original ist 20480 Byte lang: Ab 4000H enthält es nur einen Rest
des Arbeitsspeichers, der 1986 beim `SAVE` mitgespeichert wurde. Dieser Rest gehört
nicht zum Programm und ist im Quelltext weggelassen.

## Schnellstart

```sh
$ cd basic-t
$ make check
IDENTISCH mit dem Original (0100H-3FFFH; ab 4000H nur Speicherrest)
```

Voraussetzungen: `asl` und `p2bin` (Paket *asl*, z. B. `nix profile install nixpkgs#asl`,
oder aus dem Quelltext bauen) sowie GNU make.

## Grafik-Hardware auf einen Blick

| | |
|---|---|
| **Auflösung** | 256 × 128 Punkte, 1 Bit pro Punkt |
| **Bildspeicher** | 9000H–9FFFH, 32 Byte pro Zeile, Ursprung unten links |
| **Umschaltung** | Port 08H: Bit 7 = 0 blendet Video-RAM ein |
| **Controller** | keiner – direkter CPU-Zugriff |
| **Befehle** | DOT, CDOT, LINE, CLINE, FILL, TEST, OFF |

Details und Herleitung in [`docs/grafik-bericht.md`](docs/grafik-bericht.md).

## Aufteilung des Video-Speichers

Bit 7 = 0 an Port 08H blendet ein 8-KByte-Fenster **8000H–9FFFH** ein
(Bit 7 = 1 schaltet zurück auf den normalen CP/M-Arbeitsspeicher; jeder Zugriff
mit `DI` … `EI`):

| Adressbereich | Größe | Funktion | Befund |
|---|---|---|---|
| 8000H–81FFH | 512 Byte | Zeichen-/ASCII-Speicher | wahrscheinlich: `OFF` löscht mit 00H; 32 × 16 oder 64 × 8 Zeichen |
| 8200H–83FFH | 512 Byte | Attribut-/Farbspeicher | wahrscheinlich: 1:1 zum Zeichenspeicher, `OFF` setzt 27H |
| 8400H–8FFFH | 3 KByte | ungenutzt | wird nie adressiert (Reserve oder Zeichensatz?) |
| 9000H–9FFFH | 4 KByte | Grafik-Pixelspeicher | sicher: 256 × 128, 1 Bit/Punkt, 32 Byte/Zeile |

Quelle: Routine `G_CLEAR` (3DEFH) und die Adressrechnung von DOT/LINE/FILL/TEST.

## Verzeichnisse

| Pfad | Inhalt |
|---|---|
| `src/basict.asm` | kommentierter Quelltext (AS, `CPU Z80UNDOC`, `ORG 0100H`) |
| `original/BASICT.COM` | Original-Programmdatei (1986) |
| `original/BASICT.sha256` | Prüfsumme des Originals |
| `docs/BASIC-T_Sprachbeschreibung.txt` | Sprachbeschreibung von 1983 |
| `docs/grafik-bericht.md` | Analyse der Grafikbefehle und Rückschlüsse auf die Grafik-Hardware |
| `docs/gleitkomma-bericht.md` | Zahlenformat, Rechenverfahren, Funktionen und verifizierte Sonderfälle |
| `tools/` | Python-Skripte, die den Quelltext aus dem Original erzeugen |
| `Makefile` | Assemblieren und Vergleich mit dem Original |

## Bauen und Prüfen

```sh
make check      # assembliert nach build/BASICT.COM und vergleicht mit original/
```

Den Quelltext aus dem Original neu erzeugen (Python 3, `pip install -r tools/requirements.txt`):

```sh
sh tools/regen.sh
```

### An einer anderen Adresse assemblieren

Alle Adressen im Programm (Sprünge, Tabellen, Zeiger auf Texte und
Grammatik) stehen als Namen im Quelltext. Deshalb lässt sich BASIC-T an
einer anderen Ladeadresse übersetzen:

```sh
make reloc                       # build/BASICT-0200H-4000H.COM, Code ab 0200H
make reloc RELOC=0180H           # beliebige andere Adresse
make reloc RELOC=0100H RAM=5000H # Arbeitsspeicher ab 5000H
```

`RAM` setzt `RAM_BASE`, den Beginn des Arbeitsspeichers. Weil viele
Routinen nur das untere Adressbyte setzen (z. B. `LD L,0E2H`), rundet
`ALIGN 100H` im Quelltext ihn auf die nächste 256-Byte-Grenze (xx00H)
auf; der Arbeitsspeicher beginnt dann bei der Marke `RAM_START`. Werte mit
Buchstaben vorn mit 0 schreiben (`RAM=0A000H`). Der Bereich 8000H–9FFFH
ist ungeeignet, dort wird bei Grafik der Bildspeicher eingeblendet.
Mit RAM ab 5000H, 0A000H (Code 0100H) und 6000H (Code 0200H) liefert
BASIC-T im Emulator denselben Bildschirm und dieselbe Grafik wie das
Original.

Bei 0100H steht dann nur ein Sprung nach `START`, die Füllbytes hinter
dem Programm entfallen. Der Arbeitsspeicher beginnt bei `RAM_BASE`
(Standard 4000H), darum muss der Code unter `RAM_BASE` enden
(bei 4000H Startadresse höchstens etwa 02D8H); sonst bricht AS mit einer
Fehlermeldung ab. Eine an 0200H und an 0180H übersetzte Fassung lief im
Emulator Befehl für Befehl genauso ab wie das Original (rund 5,7
Millionen Befehle: Rechnen, Unterprogramme, LIST, Laden von Diskette,
Grafik).

Bei jedem Push führt GitHub Actions beide Schritte automatisch aus
(`.github/workflows/basic-t.yml`, eine Ebene über diesem Ordner).

## Aufbau des Interpreters (Kurzfassung)

- **0100H–36FFH:** tabellengesteuerte Grammatik (`SYN_MATCH`, `RULETAB`). Sie übersetzt
  jede Zeile in Zwischencode, den die Laufzeit über `OPTAB` (1271H) ausführt.
- **3700H:** patchbare Treibertabelle (`DRVTAB`). Der Haken 3703H ist nur ein `RET`.
- **3B00H–3E27H:** Grafikmodul.
- **4000H–43ADH:** Arbeitsspeicher. Er steht am Ende des Quelltexts als Labels mit `DS`
  ab `RAM_BASE` (z. B. `ED_BUF`, `FAC`, `ARG`, `STACK_TOP`); Zellen, deren Zweck noch
  nicht sicher ist, heißen `V_xxxx`. Darüber liegt der BASIC-Programmspeicher.

Die Syntaxknoten stehen als `DB` im Quelltext. Ihr Kommentar zeigt, was sie bedeuten:
Schlüsselwort, Aktion und Folgeknoten.

## Wichtigste Ergebnisse zur Grafik

- 256 × 128 Punkte, 1 Bit pro Punkt. Bildspeicher 9000H–9FFFH, 32 Byte pro Zeile,
  Ursprung unten links. Adresse = 9000H + (127 − y) · 32 + x / 8, Bitmaske 80H >> (x AND 7).
- Der Video-RAM wird über **Port 08H** eingeblendet (Bit 7 = 0) und wieder ausgeblendet
  (Bit 7 = 1), jeweils mit gesperrten Interrupts.
- Es gibt keinen Grafik-Controller: Die CPU schreibt direkt in den Speicher.
  LINE/CLINE arbeiten mit einem Festkomma-Verfahren (DDA in 8.8), nicht mit Bresenham.
- Details in [`docs/grafik-bericht.md`](docs/grafik-bericht.md).

## Gleitkomma-Rechnung

- Fünf Byte: 31-Bit-Betragsmantisse, separates Vorzeichen und signed
  8-Bit-Binärexponent ohne Bias; kein IEEE-754.
- Grundrechenarten mit binären Schiebe-/Addier-/Divisionsverfahren; verlorene
  Bits werden abgeschnitten. Integerwandlung und Dezimalausgabe runden separat.
- SQR verwendet vier Newton-Schritte; LOG/EXP/SIN/COS/ATN arbeiten mit
  Argumentreduktion und Polynom- bzw. rationalen Näherungen.
- Originalcode unverändert; Randfälle wie `0/0` im FP-Kern und die
  Ganzzahlwandlung bei −32768 sind dokumentiert und direkt im Emulator geprüft.
- Herleitung, Adressen und Prüfergebnisse:
  [`docs/gleitkomma-bericht.md`](docs/gleitkomma-bericht.md).

Optionale Rechentests (nur Python, nicht zum Assemblieren erforderlich):

```sh
python3 -m pip install -r tools/requirements-test.txt
python3 -m unittest discover -s tools -p test_fp.py
```

## Stand und offene Punkte

Einige Bereiche, die das Programm nur auf Umwegen erreicht, stehen noch als `DB`.
Das gilt für Meldungstexte und einige Unterprogramme. Gleitkomma-Konstanten
stehen bewusst als benannte Originalbytes mit Wertkommentaren im Quelltext.
Noch nicht entschlüsselte Nebenpfade bleiben byte-genau erhalten.

## Rechte und Lizenz

Die Originaldatei und die Sprachbeschreibung sind historische Dokumente des
VEB TuR Dresden und werden hier zu Dokumentationszwecken bereitgestellt.
**Lizenz für die Werkzeuge und Kommentare: noch festzulegen.**

## Beispiele

`examples/APFELGK.GBA` (Apfelmännchen, Gleitkomma) und `examples/APFELINT.GBA` (dasselbe in Ganzzahlarithmetik).
