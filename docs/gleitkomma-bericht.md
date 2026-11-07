# Gleitkomma-Rechnung von BASIC-T (COM-Datei 1986)

Die folgenden Ergebnisse beruhen auf dem Z80-Code des Originals und direkten
Emulator-Prüfläufen seiner Routinen. Es wurden **keine Rechenbefehle verändert**.
Die Kommentare und Konstantennamen werden reproduzierbar mit dem Quelltext
erzeugt. Adressen sind Laufzeitadressen; Dateioffset = Adresse − 0100H.

## 1. Zahlenformat

Kein IEEE-754-Format: fünf Byte, explizite 31-Bit-Betragsmantisse,
Vorzeichenbit und vorzeichenbehafteter 8-Bit-Binärexponent **ohne Bias**.

| Byte | Inhalt |
|---|---|
| 0 | Mantisse Bit 0–7 |
| 1 | Mantisse Bit 8–15 |
| 2 | Mantisse Bit 16–23 |
| 3, Bit 0–6 | Mantisse Bit 24–30 |
| 3, Bit 7 | Vorzeichen: 1 = negativ |
| 4 | Binärexponent e im Zweierkomplement |

Mit `M = LE32(Byte0…3) AND 7FFFFFFFH` gilt:

```text
x = (-1)^Vorzeichen * M * 2^(e-31)
40000000H <= M <= 7FFFFFFFH   (normalisierte Nichtnullwerte)
```

Bit 30 ist tatsächlich gespeichert, keine implizite Eins und kein separates
„Nichtnull“-Flag. Die schnellen Nulltests auf dieses Bit setzen normalisierte
Operanden voraus. Kanonische Null besteht aus fünf Nullbytes.

| Wert | Bytefolge |
|---|---|
| 0 | 00 00 00 00 00 |
| 0.5 | 00 00 00 40 00 |
| 1 | 00 00 00 40 01 |
| −1 | 00 00 00 C0 01 |
| 2 | 00 00 00 40 02 |

**Herleitung:** 3281H setzt bei der Integerwandlung zunächst e=31 und übernimmt
den Betrag. 285EH normalisiert durch Linksverschieben und entsprechendes
Vermindern des Exponenten. Multiplikation addiert, Division subtrahiert die
Exponenten ohne Bias-Korrektur.

Der intern darstellbare positive Betrag liegt rechnerisch zwischen `2^-129`
und `(1-2^-31)*2^127`. Das ist keine Garantie, dass alle Rechenwege an diesen
Grenzen funktionieren: Zwischenexponenten können vorher einen Fehler auslösen.
Die Sprachbeschreibung von 1983 nennt neun Dezimalstellen und einen Betrag des
normalisierten **Dezimalexponenten** bis 38.

## 2. Arbeitszellen und Aufrufkonvention

| Adresse | Bedeutung |
|---|---|
| 42E1H | FAC_TYPE: 1 = 16-Bit-Integer, 2 = Gleitkomma |
| 42E2H–42E6H | FAC: Ergebnis-/Hauptoperand |
| 42E7H–42EBH | ARG: zweiter Operand |
| 42ECH–42F0H | temporärer FP-Wert, je Funktion anders verwendet |
| 42F1H–42F5H | weiterer temporärer Wert; beim Einlesen Statusbytes |
| 42F6H–42FAH | weitere temporäre Werte bzw. Textzeiger |

`FAC_LOAD` (269FH) und `ARG_LOAD` (26A4H) erhalten die **Quelladresse in DE**;
`FAC_STORE` (26AEH) erhält die Zieladresse in DE. Alle kopieren fünf Byte.
Die früheren Kommentare mit Quelladresse HL waren falsch und sind korrigiert.
ADD/SUB/MUL/DIV laden ihren externen Operanden ebenfalls aus `(DE)`;
die Einstiege mit Suffix `_ARG` benutzen den schon geladenen zweiten Operanden.
Register und ARG sind nicht allgemein erhalten; MUL/DIV überlagern ARG_EXP
vorübergehend mit dem Ergebnisvorzeichen.

## 3. Grundrechenarten

### Addition/Subtraktion: 26B3H–2787H

1. Subtraktion schaltet ARGs Vorzeichen um und benutzt den Additionskern.
2. Nulloperanden werden früh abgefangen.
3. Signed Exponenten vergleichen. Bei Differenz ≥31 entfällt der kleinere Wert.
4. Kleineren Betrag auf den größeren Exponenten rechts ausrichten; das verändert
   dessen FAC-/ARG-Speicher und verwirft niedrige Bits.
5. Bei gleichen Vorzeichen Beträge addieren, sonst subtrahieren.
6. Übertrag: rechts schieben, Exponent erhöhen. Negatives Differenzergebnis:
   Betrag negieren und Vorzeichen wechseln. Anschließend normalisieren.

### Multiplikation: 278AH–27E9H

Vorzeichen per XOR, Exponenten signed addieren. 31 Schiebe-/Addierdurchläufe
verarbeiten die ARG-Mantisse und einen 32-Bit-Akkumulator BCDE. Es wird **kein
vollständiges 62-Bit-Produkt** zur späteren Rundung aufbewahrt. ARG wird zerstört.

### Division: 27ECH–285DH

Nichtrestaurierende binäre Division: der Teilrest bestimmt den nächsten
Subtraktions-/Additionsschritt, während 31 Quotientenbits in FAC entstehen.
Ergebnisexponent zunächst `eFAC-eARG+1`; anschließend normalisieren.
Der Schlussrest wird nicht zur Rundung ausgewertet.

**Verifizierter Sonderfall:** Der rohe FP-Kern prüft zuerst den Dividend.
`0/0` liefert dort 0, während `1/0` Fehler 40 auslöst. Das ist eine Aussage über
diesen Einstieg, nicht über alle Integer-/Typdispatchpfade im BASIC.

### Normalisierung: 285EH–2893H

Bit 30 gesetzt: bereits normalisiert. Sonst Betrag auf null testen oder nach
links verschieben, bis Bit 30 gesetzt ist; Exponent entsprechend vermindern.
Exponentenunterlauf führt zu Fehler 33, nicht zu stillem Löschen des Ergebnisses.

### Genauigkeit und Rundung

ADD/MUL/DIV enthalten **keine allgemeine Rundung zum nächsten FP-Wert**:
herausgeschobene Bits werden verworfen. Beispielsweise ergibt der Originalkern
`1 + 3*2^-32` genau 1, obwohl der nächstgelegene darstellbare Wert größer wäre.
31 Binärstellen entsprechen ungefähr neun Dezimalstellen, sind jedoch keine
Garantie für neun korrekte Dezimalstellen nach beliebig vielen Operationen.

## 4. Integerwandlung und INT

**3274H/3281H:** signed 16-/32-Bit-Integer nach Gleitkomma. 16-Bit-Werte sind
exakt darstellbar; der 32-Bit-Einstieg dient unter anderem der Überlaufpromotion.

**32B7H:** FP nach 16-Bit-Integer. Null bzw. e<0 → 0, e>15 → Fehler 31.
Das obere Mantissenwort wird verschoben; das letzte herausgeschobene Bit
rundet den Betrag auf. Danach folgt das Vorzeichen. `2.5 → 3`, `−2.5 → −3`.

Diese Rundung ist wegen der vorher abgeschnittenen unteren Mantissenbits
**nicht überall eine ideale mathematische Rundung**:

| Eingabe | Tatsächlicher FP_TO_INT16-Ausgang |
|---|---|
| 32767.5 | 32767 |
| −32767.5 | −32767 |
| 32768 | Fehler 31 |
| −32768 | Fehler 31, obwohl als signed Integer darstellbar |

**INT (2952H):** Abrunden nach −∞, nicht gerundete Integerkonvertierung.
`INT(−2.7)=−3`, `INT(−2)=−2`. FP-Typ bleibt in dieser Routine FP; Integer bleiben
unverändert. Das weicht von der pauschalen Ergebnis-Typaussage der Beschreibung
von 1983 ab. Der negative Pfad benutzt den FP-Wert `−(1−2^-31)`.

**ABS (1615H):** typabhängiger Betrag; der Integerpfad prüft Überlauf nicht,
deshalb bleibt `ABS(−32768)` bitmäßig 8000H. **SGN (1666H)** liefert Integer
−1, 0 oder +1.

## 5. Mathematische Funktionen

| Funktion | Adresse | Verfahren |
|---|---|---|
| SQR | 28D5H | vier Newton-Schritte `y=(y+x/y)/2` |
| LOG | 29D0H | Mantissen-/Exponentenzerlegung, transformiertes ungerades Polynom |
| EXP | 2A5BH | Taylorpolynom Grad 6, Zweierpotenz-Verkleinerung, Quadrieren |
| COS | 2AFBH | `SIN(pi/2−x)` |
| SIN | 2B09H | Modulo 2π, Drittelung, Polynom Grad 5, Dreifachwinkel |
| ATN | 2BC3H | rationale Kettenbruchnäherung, Vorzeichen-/Kehrwertreduktion |
| Potenz | 2C52H/2C53H | Typanpassung, dann `EXP(Exponent*LOG(Basis))` |
| RND | 2C85H | affiner FP-Generator mit Modulus |

### SQR

Startwert durch Exponentenhalbierung und Mantissenoberbyte 6DH bzw. 4DH.
**Vier** Iterationen: drei explizite CALLs und ein vierter Schritt durch
Durchfallen in 290AH. Negative Argumente → Fehler 41, Null bleibt Null.

### LOG

Für `x=m*2^e`, `m` in `[0.5,1)`, `a=1/sqrt(2)`, `z=(m−a)/(m+a)`:

```text
LOG(x) ~= [e-0.5 + z*(c1+c3*z^2+c5*z^4)] * ln(2)
c1 ~= 2.885391289368   (2D68H)
c3 ~= 0.961470631883   (2D6DH)
c5 ~= 0.598978649825   (2CD3H)
```

Null und negative Argumente → Fehler 41.

### EXP

`u=abs(x)/2^k`; bei notwendiger Verkleinerung `u` in `[1/16,1/8)`.
Verschachtelt `1+u+u^2/2!+…+u^6/6!` auswerten, danach k-mal quadrieren,
für negatives x den Kehrwert bilden. **abs(x)≥64 löst Fehler 32 aus, auch bei
negativen Argumenten.** Beispielsweise EXP(−64) wird nicht erfolgreich berechnet.

### SIN/COS

Winkel im Bogenmaß. Betrag modulo 2π reduzieren und durch 3 teilen, solange
er ≥0.1 ist. Auf kleinem r: `s ~= r−r^3/6+r^5/120`. Für jede Drittelung zurück
mit `s=3*s−4*s^3`, dann Vorzeichen anwenden. Die einfache FP-Winkelreduktion
verliert bei großen Argumenten Genauigkeit; eine globale Fehlergrenze ist nicht
nachgewiesen. **TAN steht in der Beschreibung von 1983, wurde aber als eigener
Grammatik-/Dispatch-/Rechenkern in dieser COM-Version nicht gefunden.**

### ATN

`t=abs(x)`, bei t>1 Kehrwert nehmen, `q=t*t`:

```text
R=t*(a0+b0/(q+a1+b1/(q+a2+b2/(q+a3))))
a0=0.174655438983   a1=6.762139201164
a2=3.316335430369   a3=1.448631539941
b0=3.709256259724   b1=-7.106760051101   b2=-0.264768620022
```

Bei Kehrwertreduktion `pi/2−R`, abschließend Vorzeichen anwenden.

### Potenz und RND

Potenzkern benutzt LOG/EXP, keinen separaten Integer-Potenzalgorithmus in diesem
Bereich. Nichtpositive Basen scheitern an LOG. Die genaue syntaktische Zuordnung
der beiden Potenzeinstiege ist noch nicht abschließend dokumentiert.

RND-Zustand liegt bei 41D5H:

```text
u = 24298*s + 99991.15625
s_neu = u - floor(u/199019)*199019
RND = s_neu/199019
```

Die Konstanten stammen direkt aus dem Original. Insbesondere ist das Inkrement
**nicht 99991**. Wegen FP-Arithmetik kein exakt ganzzahliger LCG.
Initialisierung, Periode und statistische Qualität sind noch nicht untersucht.

## 6. Dezimale Ein-/Ausgabe

**Einlesen (2E1BH):** Bis zu neun signifikante Ziffern als binären Mehrbytewert
mit `Wert*10+Ziffer` sammeln; weitere Ziffern abschneiden, nicht runden.
Führende Nullen verbrauchen das Budget nicht. Punktposition und E-Exponent
bestimmen die anschließende Skalierung mit 10^n.
`1.23456789123` erzeugt denselben FP-Wert wie `1.23456789`.

**Ausgabe (2FB2H, Dezimalpfad 2FFEH):** Mit Zehnerpotenzen skalieren,
Dezimalziffern erzeugen und eine Folgeziffer für die Rundung vorsehen.
Folgeziffer ≥5 rundet den Betrag auf (3133H–3157H), Übertrag über 9er-Ketten.
FP-Defaultformat: Breite 16, Exponentialform mit acht Nachkommastellen.
Integerdefault: Breite 7. Binär-/Hexausgabe benutzt den Integerpfad.

Konstanten im ASM sind jetzt benannte, einzeln abgegrenzte Originalbytes,
keine durch Host-Gleitkomma neu erzeugten Werte. Die Nullkonstante bei 2CD8H
teilt ihr fünftes Nullbyte mit dem Beginn der Einskonstante bei 2CDCH.

## 7. Fehler und verifizierte Ergebnisse

| Nummer | Bedeutung / Einstieg |
|---|---|
| 31 | Integerbereichsfehler, u. a. 32D2H |
| 32 | Exponentenüberlauf, 2CCAH |
| 33 | Exponentenunterlauf, 2CCEH |
| 40 | Division durch Null, 262EH |
| 41 | unzulässiges Funktionsargument, 2CC6H |

Ausgewählte direkte Läufe des Originalcodes:

| Rechnung | Originalergebnis |
|---|---|
| 1+2 | 3 |
| −3*2 | −6 |
| 3/2 | 1.5 |
| SQR(2) | 1.414213561453 |
| LOG(2) | 0.693147202022 |
| EXP(1) | 2.718281770125 |
| SIN(1) | 0.841470983811 |
| ATN(1) | 0.785398166627 |

Die Toleranzen der Tests gelten für diese Beispiele, **nicht als globaler
Genauigkeitsbeweis**. Direkte Kernprüfungen ersetzen auch keinen vollständigen
CP/M-Lauf mit Eingabe, Syntaxübersetzung und Programmausführung.

## 8. Reproduzieren und verbleibende Grenzen

```sh
python3 -m pip install -r tools/requirements-test.txt
python3 -m unittest discover -s tools -p test_fp.py
sh tools/regen.sh
make check
```

Der Emulator ist nur für die Tests nötig; das Assemblieren bleibt von Python-
Testpaketen und Node unabhängig. Tests laden das Original und halten vor RETURN
oder ERROR an; sie verändern nicht das historische Programm.

Offen: exhaustive Grenz-/Genauigkeitsanalyse, ungewöhnliche Parser-Eingaben,
RND-Periode/Initialisierung, vollständige indirekte Aufrufer und Potenz-Grammatik.
Zusätzliche teilweise als DB ausgegebene Integer-Eingaberoutinen
(2D81H–2DEDH) und nicht regulär benutzte Nebenpfade bleiben gesondert zu analysieren.