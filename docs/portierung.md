# Implementierung im Anwendersystem (Portierung)

Quelle: R. Heyne, „Basic-Compreter für U 880“, *radio fernsehen elektronik*
33 (1984) Heft 3, S. 150–152, Abschnitt „Implementierung im Anwendersystem“.
Abgeglichen mit dem CP/M-Code in `src/io_cpm.inc`.

## Prinzip laut Artikel

- Logische und physische Ein-/Ausgabe sind getrennt. Alle gerätespezifischen
  Teile liegen in einem eigenen Programmteil; nur dieser wird angepasst.
- Je Gerät gibt es einen **Steuerblock** und ein bis drei **Module**:
  - **E/A-Routine** (Pflicht): überträgt genau ein Zeichen im Register A.
  - **Open-Routine** (wahlfrei): Peripherie programmieren, Bildschirm löschen,
    Datei auf Diskette/Kassette suchen.
  - **Close-Routine** (wahlfrei): bei `CLOSE` oder (laut Steuerblock) bei
    Programmende, z. B. Verzeichniseintrag schreiben.
- Alle Module dürfen sämtliche Register verändern. Fehler meldet die Routine
  mit gesetztem **CY-Flag**.
- Bewusst keine Sprungvektor-Leiste: Treiber können vorhandene Routinen des
  Betriebssystems nutzen; Ein- und Ausgaben lassen sich im Programm oder im
  Direktmodus jedem Gerät zuweisen (z. B. Druckerausgabe auf Bildschirm).

## Steuerblock im CP/M-Code (9 Byte, Tabelle `DRVTAB`)

| Offset | Inhalt |
|---|---|
| +0 | Flags (Richtung Ein/Aus, automatisches Öffnen/Schließen …) |
| +1/+2 | Adresse der E/A-Routine (Pflicht) |
| +3/+4 | Parameter, z. B. Pufferlänge (`0FFFFH`, `0050H`) |
| +5/+6 | Open-Routine oder `0000H` |
| +7/+8 | Close-Routine oder `0000H` |

`DRV_DUMMY` (nur `RET`) dient als leere Routine. Die Blöcke `DEV_MTR/MTW`
und `DEV_FDR/FDW` sind die Lese-/Schreibkanäle für Dateien mit Open/Close.

## Aufteilung des Quelltexts

| Datei | Inhalt | Bei Portierung |
|---|---|---|
| `src/basict.asm` | Kopf, `CODE_ORG`/`RAM_BASE`, Includes | Adressen setzen |
| `src/core_syntax.inc` | Start, Hauptschleife, Syntaxmaschine, Grammatik | unverändert |
| `src/core_run.inc` | OPTAB, Laufzeit, Befehle, Zwischencode | unverändert |
| `src/core_fp.inc` | Gleitkomma | unverändert |
| `src/core_lines.inc` | Zeilen, Fehler, Meldungen | unverändert |
| `src/core_io.inc` | logische Kanalblock-E/A (`CH_OUT`, `CH_IN`, `DRV_CALL`) | unverändert |
| `src/io_cpm.inc` | BDOS-Anschluss Konsole/Drucker (`CONIN`, `CONOUT`), `DRVTAB`, `KBD_GET` | **anpassen** |
| `src/core_edit.inc` | Zeileneditor `ED_LINE`, braucht nur `CONIN`/`CONOUT` und Backspace 08H | unverändert |
| `src/io_cpmfile.inc` | Datei-E/A über FCB/DMA | **anpassen/ersetzen** |
| `src/gfx_tur.inc` | Grafik für die TuR-Hardware (Port 08H, 9000H) | **anpassen/ersetzen** |
| `src/ram.inc` | Arbeitsspeicher (DS-Labels) | unverändert |

Die Reihenfolge der Includes entspricht der Speicherreihenfolge und ist
für die Byte-Identität nötig. Hinweis: Startcode in `core_syntax.inc`
liest die BDOS-Adresse aus 0006H für den Speichertest; das ist nach bisheriger Prüfung die einzige
CP/M-Abhängigkeit außerhalb von `io_cpm.inc`/`io_cpmfile.inc`.

## Verwendete CP/M-Funktionen (io_cpm.inc, io_cpmfile.inc)

Alle Aufrufe gehen ueber `CALL BDOS` (0005H), Funktionsnummer in C.

| BDOS | Funktion | Routine | Zweck |
|---|---|---|---|
| 0 | Warmstart | `CPM_EXIT` | zurueck zu CP/M (BYE) |
| 2 | Konsole schreiben | `CONOUT` | Zeichen auf den Bildschirm |
| 5 | Drucker | `PRNOUT` | LPRINT/LLIST, 1EH -> CR+LF |
| 6 | Konsole direkt (E=0FFH) | `CONIN`, `KEY_POLL` | Taste lesen ohne Echo/Filter; `CONIN` wartet, `KEY_POLL` nicht (Abbruch B/W/C) |
| 15 | Datei oeffnen | `F_OPEN` | Datei zum Lesen oeffnen |
| 16 | Datei schliessen | `F_CLOSE` | nach dem Schreiben |
| 19 | Datei loeschen | `F_CREATE` | alte Fassung vor SAVE entfernen |
| 20 | Satz lesen | `F_GETB` | 128 Byte nach 0080H |
| 21 | Satz schreiben | `F_FLUSH` | 128 Byte aus 0080H |
| 22 | Datei anlegen | `F_CREATE` | neuen Eintrag erzeugen |

Bei einer Portierung ohne CP/M ersetzt man genau diese Routinen; die
Kanalbloecke (`DEV_KBD` ... `DEV_FDW`) und die logische E/A bleiben gleich.
