;**********************************************************************
;* BASIC-T  (VEB Transformatoren- und Roentgenwerk Dresden)           *
;* "GRAPHIK-BASIC" Version 3.1 vom 03.03.86, R. Heyne                 *
;* CP/M-COM-Datei BASICT.COM, rueckuebersetzt fuer AS (A. Arnold):    *
;*   asl -cpu z80undoc -L basict.asm && p2bin basict.p BASICT.COM     *
;* Ergebnis ist byte-identisch zum Original (20480 Byte).             *
;**********************************************************************
;
; FUNKTIONSWEISE
;   1. Eine eingegebene Zeile wird von der Syntaxmaschine (SYN_MATCH)
;      anhand einer Grammatik-Tabelle geprueft und sofort in einen
;      kompakten Zwischencode uebersetzt (Opcodes + Operanden).
;   2. Gespeichert wird nur der Zwischencode; LIST rekonstruiert den
;      Text daraus.
;   3. RUN arbeitet den Zwischencode in RUNLOOP ab: Opcode holen,
;      Routine ueber OPTAB anspringen. IX ist der Codezeiger.
;
; SPEICHERKARTE
;   0100H-0306H  Start, Initialisierung, Hauptschleife, Syntaxmaschine
;   0307H-0344H  RULETAB  Startadressen der 31 Grammatik-Regeln
;   0345H-1270H  Grammatik-Knoten und Syntaxaktionen (S_xxx)
;   1271H-1342H  OPTAB    Sprungtabelle der Laufzeit (Opcode/2)
;   1343H-25FFH  Laufzeitroutinen (X_xxx), Ausdruecke, Zwischencode
;   2600H-32FFH  Gleitkomma-Arithmetik und Zahlenwandlung
;   3300H-36FFH  Zeilenverwaltung, Fehler, Meldungen, Zeichen-E/A
;   3700H-3AFFH  DRVTAB (Treiber-Haken), Datei-E/A ueber BDOS
;   3B00H-3E27H  Grafikmodul (DOT, LINE, FILL, TEST, OFF)
;   4000H-43ADH  Arbeitsspeicher (am Ende als DS-Labels; nicht in der
;                Datei). Das Original enthielt ab 4000H nur einen beim
;                SAVE mitgespeicherten Speicherrest; er entfaellt hier.
;
; SYNTAX-KNOTEN (Kommentar "KW/TOK/RULE/EPS") der Grammatik:
;   Bit7 letzte Alternative, Bit6 Aktionsbyte folgt (rel. vorwaerts),
;   Bit5 Folgezeiger folgt (rel. vorzeichenbehaftet, 0=Regelende),
;   Bit4..3: 00=leer (EPS)  01=Schluesselwort (KW, Bit2..0=Laenge-1)
;            10=Tokenklasse (TOK)  11=Unterregel (RULE, Index)
;   "-> S_xxx" = Syntaxaktion, "next" = Folgeknoten.
;
; NAMEN
;   S_xxx  Syntaxaktion zum Schluesselwort xxx (erzeugt Zwischencode)
;   X_xxx  Laufzeitroutine zum Schluesselwort xxx (ueber OPTAB)
;   G_xxx  Grafikmodul,  FP_xxx Gleitkomma,  Lxxxx noch unbenannt
;   Ein "?" im Kommentar kennzeichnet eine Vermutung.
;
; Rechte Spalte: Adresse und Originalbytes jedes Befehls.

        CPU     Z80UNDOC
        RELAXED ON

BDOS    EQU     0005H                   ; CP/M-Systemaufruf, Funktion in C
GPORT   EQU     08H                     ; Bit7=1: normaler RAM, Bit7=0: Video-RAM
GRAM    EQU     9000H                   ; 4 KByte Pixelspeicher 256x128, 32 Byte/Zeile

; Ladeadresse des Codes. Standard 0100H (CP/M, byte-identisch).
; Anders z. B. mit:  asl -D CODE_ORG=0200H ...  Dann steht bei 0100H
; nur ein Sprung nach START, und das Speicherabbild ab 3E28H entfaellt.
; Der Code muss unter RAM_BASE bleiben.
RAM_BASE EQU    4000H                   ; Beginn des Arbeitsspeichers
        IFNDEF  CODE_ORG
CODE_ORG EQU    0100H
        ENDIF
        IF      CODE_ORG<>0100H
        ORG     0100H
        JP      START
        ENDIF
        ORG     CODE_ORG
