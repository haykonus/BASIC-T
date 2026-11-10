# BASIC-T Grafik-Hardware und Grafikbefehle

## 1. Grafik-Hardware auf einen Blick

| | |
|---|---|
| **Auflösung** | 256 × 128 Punkte, 1 Bit pro Punkt |
| **Bildspeicher** | 9000H–9FFFH, 32 Byte pro Zeile, Ursprung unten links |
| **Umschaltung** | Port 08H: Bit 7 = 0 blendet Video-RAM ein |
| **Controller** | keiner – direkter CPU-Zugriff |
| **Befehle** | DOT, CDOT, LINE, CLINE, FILL, TEST, OFF |

## 2. Aufteilung des Video-Speichers

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

Wie das BASIC arbeitet: Es ist **kein Token-Interpreter wie MS-BASIC**. Eine tabellengesteuerte Grammatik (Syntaxknoten mit Schlüsselwort, Unterregel, Aktion und Folgezeiger) übersetzt jede Zeile in einen Zwischencode. Diesen Code führt eine Laufzeitschleife (1460H) über eine Sprungtabelle aus (OPTAB, 1271H). Das passt zur Sprachbeschreibung von 1983.

## 3. Grafikbefehle (neu gegenüber 1983)

In der Sprachbeschreibung von 1983 kommt kein Grafikbefehl vor. Alle folgenden Befehle sind neu:

| Befehl | Zwischencode | Laufzeit | Umsetzung |
|---|---|---|---|
| DOT x,y | BAH | 1DA1H | Punkt setzen (G_DOT 3B20H) |
| CDOT x,y | BCH | 1DA6H | Punkt löschen (3B24H) |
| LINE x1,y1,x2,y2 | BEH | 1DB7H | Linie setzen (3CE2H) |
| CLINE x1,y1,x2,y2 | C0H | 1DBCH | Linie löschen (3CE6H) |
| FILL x1,y1,x2,y2 | C2H | 1DC1H | Rechteck füllen (3BD1H). Eine Lösch-Variante steht bei 3BD5H, hat aber kein Schlüsselwort |
| TEST(x,y) | C4H | 1DD6H | Punkt lesen: −1 = gesetzt, 0 = frei |
| OFF | D0H/02 | 3DEFH | Grafik- und Video-RAM löschen (siehe unten) |
| PLOT, CLS, GLS, GLOAD, GSAVE, TEXT | B8H, C6H, C8H, CAH, CCH, CEH | → 3703H | nur Treiber-Haken, in dieser Datei leer (`RET`) |
| GIN, COL, GOL, REV, CREV, HARD, CHARD, PAUSE, BELL, COPY, RES | D0H/xx | → 3703H | ebenfalls leer |

Nur sieben Befehle sind also wirklich ausprogrammiert. Die übrigen springen in eine patchbare Treibertabelle, ähnlich wie die Beschreibung von 1983 es für den X-Y-Schreiber vorsieht. Vermutlich gab es für Plotter, Hardcopy, Farbe usw. gesonderte Treiber.

## 4. Was die Routinen über die Hardware verraten

### 4.1 Bildspeicher
```text
Adresse = 9000H + (127 - y) * 32 + x / 8
Bit     = 80H >> (x AND 7)        (Bit 7 = linkes Pixel)
```
- **Auflösung 256 × 128 Punkte, monochrom (1 Bit pro Punkt)**. Von x wird nur das Low-Byte benutzt (0-255), von y werden nur 7 Bit benutzt (`RES 7`, 0-127).
- **32 Byte pro Zeile, 128 Zeilen = 4 KByte, 9000H-9FFFH**, linear ohne Zeilensprung. Das spricht für einen einfachen Videozähler, nicht für einen Grafik-Controller.
- **Der Ursprung liegt unten links** (y wird invertiert), wie bei einem Plotter oder Koordinatensystem.
- Es gibt keine Abfrage von Status- oder Busy-Bits und keine Befehlsports. Die CPU schreibt direkt in den Speicher, es gibt **keinen Grafikprozessor**.

### 4.2 Speicherumschaltung über Port 08H
Jeder Zugriff auf den Bildspeicher läuft so ab:
```text
DI
OUT (08H),00H     ; Video-RAM in 8000H-9FFFH einblenden
  ... (HL) lesen/schreiben ...
OUT (08H),80H     ; normalen CP/M-RAM zurückschalten
EI
```
- Port 08H Bit 7 ist ein **Bank-/Seitenschalter**: Bei 0 liegt der Video-RAM im Adressbereich 8000H-9FFFH (8 KByte), bei 1 wieder der normale Arbeitsspeicher der TPA.
- Wegen `DI` darf während der Einblendung keine Interruptroutine auf diesen Bereich zugreifen. Der Rechner nutzt also Interrupts, etwa für Tastatur oder Uhr.
- Das Register A wird mit `EX AF,AF'` gerettet. Der Port ist offenbar nur beschreibbar, er wird nie gelesen.

### 4.3 Zweiter Bereich 8000H-83FFH
OFF löscht nicht nur den Pixelspeicher, sondern füllt auch:
- 8000H-81FFH mit 00H (512 Byte)
- 8200H-83FFH mit 27H (512 Byte)

Das deutet auf einen **Alphanumerik-Bildspeicher mit Attributen** im selben eingeblendeten Fenster hin: 512 Zeichen (etwa 32 × 16 oder 64 × 8) plus 512 Attribut-Bytes. 27H wäre dann das Standard-Attribut, zum Beispiel Vordergrund 7 = weiß und Hintergrund 2 im Format 0bbb0fff oder ähnlich. Möglich ist auch ein Farbattribut für die Grafik in Kacheln. Das ist **Vermutung**, denn die Befehle COL und GOL, die das klären würden, sind in dieser Datei leer.

### 4.4 Algorithmen
- **LINE/CLINE** arbeiten mit einem **DDA-Verfahren in 8.8-Festkomma**, nicht mit Bresenham. Die Steigung wird durch fortgesetzte Subtraktion berechnet, Schrittachse ist die längere Achse. Es gibt vier Fälle (Bit 1 = y fällt, Bit 2 = steil). Jeder Punkt wird einzeln gesetzt (3D95H), dabei wird für jeden Punkt neu umgeschaltet.
- **FILL** füllt das Rechteck zeilenweise: linkes und rechtes Teilbyte per Maske, dazwischen ganze Bytes FFH bzw. 00H.
- **TEST** liest das Byte und rotiert das gewünschte Bit ins Carry.
- **Clipping gibt es nicht.** Zu große Werte werden nur durch das Abschneiden auf 8 bzw. 7 Bit „gefaltet“.

## 5. Schlussfolgerung zur Hardware

| Merkmal | Befund | Sicherheit |
|---|---|---|
| Vollgrafik 256 × 128, 1 Bit/Pixel | Adressrechnung | sicher |
| 4 KByte Pixel-RAM linear, 32 Byte/Zeile | Adressrechnung, OFF löscht 1000H Byte | sicher |
| Video-RAM per Bankumschaltung (Port 08H, Bit 7) in 8000H-9FFFH | jeder Zugriff | sicher |
| kein Grafik-Controller, direkter CPU-Zugriff | keine Status-/Befehlsports | sicher |
| 1 KByte Text-/Attributspeicher 8000H-83FFH, Standardwert 27H | OFF | wahrscheinlich |
| Rechner mit Interrupts, CP/M auf vollem 64-KByte-RAM | DI/EI, Bankumschaltung | wahrscheinlich |

Die Hardware ist also eine einfache, selbst gebaute Bildspeicher-Karte am K1520-Bus. Typisch für Betriebs-Eigenentwicklungen der DDR: Video-RAM als umschaltbare Speicherbank, damit CP/M den ganzen Arbeitsspeicher behält, mit einem Ein-Bit-Steuerport auf E/A-Adresse 08H. Mir ist kein serienmäßiges Robotron-Gerät mit genau diesen Daten bekannt (256 × 128, Port 08H). Es dürfte sich um eine Entwicklung des TuR selbst handeln, eventuell für Röntgen- oder Messtechnik-Arbeitsplätze.


