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
;   4000H-50FFH  Abbild des Arbeitsspeichers (Variablen, Puffer);
;                wichtige Zellen: FAC 42E2H, ARG 42E7H, FAC_TYPE 42E1H
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

        ORG     0100H

;=====================================================================
; PROGRAMMSTART UND INITIALISIERUNG
; CP/M laedt die Datei nach 0100H und springt hierher.
; Stack nach 43ADH, dann Speichertest: ab 4000H wird jede Zelle mit
; 0FFH beschrieben und zurueckgelesen, bis RAM-Ende bzw. BDOS-Anfang
; (Adresse aus 0006H) erreicht ist. Danach Treiber und Begruessung.
;=====================================================================
START:
        NOP                             ; 0100  00
        NOP                             ; 0101  00
        NOP                             ; 0102  00
        NOP                             ; 0103  00
        NOP                             ; 0104  00
        NOP                             ; 0105  00
        LD      SP,43ADH                ; 0106  31ad43
        LD      HL,(0006H)              ; 0109  2a0600
        LD      DE,4001H                ; 010C  110140
        XOR     A                       ; 010F  af
        SBC     HL,DE                   ; 0110  ed52
        EX      DE,HL                   ; 0112  eb
        LD      HL,3FFFH                ; 0113  21ff3f
L0116:
        INC     HL                      ; 0116  23
        LD      (HL),0FFH               ; 0117  36ff
        LD      A,(HL)                  ; 0119  7e
        INC     A                       ; 011A  3c
        LD      (HL),A                  ; 011B  77
        JR      nz,L0126                ; 011C  2008
        CP      (HL)                    ; 011E  be
        JR      nz,L0126                ; 011F  2005
        DEC     DE                      ; 0121  1b
        LD      A,D                     ; 0122  7a
        OR      E                       ; 0123  b3
        JR      nz,L0116                ; 0124  20f0
L0126:
        DEC     HL                      ; 0126  2b
        LD      (41B7H),HL              ; 0127  22b741
        LD      (419CH),SP              ; 012A  ed739c41
        LD      HL,3704H                ; 012E  210437
        LD      DE,41FBH                ; 0131  11fb41
        LD      BC,37H                  ; 0134  013700
        LDIR                            ; 0137  edb0
        LD      HL,420DH                ; 0139  210d42
        LD      (41F1H),HL              ; 013C  22f141
        LD      (41F3H),HL              ; 013F  22f341
        LD      HL,41FBH                ; 0142  21fb41
        LD      (41F5H),HL              ; 0145  22f541
        LD      (41F7H),HL              ; 0148  22f741
        LD      A,0FFH                  ; 014B  3eff
        LD      (41B4H),A               ; 014D  32b441
; ---- Treiber-Initialisierung (DRVTAB: leer, nur RET)
        CALL    DRVTAB                  ; 0150  cd0037
        LD      HL,MSG_WELCOME          ; 0153  211934
        CALL    PRINT_STR               ; 0156  cde735
L0159:
        LD      SP,43ADH                ; 0159  31ad43
        LD      IX,410CH                ; 015C  dd210c41
        LD      (IX-1),1                ; 0160  dd36ff01
        LD      (IX),90H                ; 0164  dd360090
        LD      HL,41C1H                ; 0168  21c141
        SET     0,(HL)                  ; 016B  cbc6
        RES     7,(HL)                  ; 016D  cbbe
        LD      HL,408AH                ; 016F  218a40
        LD      (4084H),HL              ; 0172  228440
        XOR     A                       ; 0175  af
        LD      H,A                     ; 0176  67
        LD      L,H                     ; 0177  6c
        LD      (4088H),HL              ; 0178  228840
        LD      (4083H),A               ; 017B  328340
        LD      (418CH),HL              ; 017E  228c41
        LD      (41B5H),HL              ; 0181  22b541
        LD      (4192H),HL              ; 0184  229241
        LD      (4194H),HL              ; 0187  229441
        LD      (419EH),HL              ; 018A  229e41
        LD      (4198H),HL              ; 018D  229841
        LD      (4196H),HL              ; 0190  229641
        LD      (41A2H),HL              ; 0193  22a241
        LD      HL,41C2H                ; 0196  21c241
        BIT     0,(HL)                  ; 0199  cb46
        RES     0,(HL)                  ; 019B  cb86
        JR      nz,L01D4                ; 019D  2035
        CALL    CON_CR                  ; 019F  cd2f36
        BIT     2,(HL)                  ; 01A2  cb56
        RES     2,(HL)                  ; 01A4  cb96
        JR      z,L01C1                 ; 01A6  2819
        LD      HL,(41B9H)              ; 01A8  2ab941
        LD      (41BBH),HL              ; 01AB  22bb41
        PUSH    HL                      ; 01AE  e5
        CALL    L1343                   ; 01AF  cd4313
        POP     HL                      ; 01B2  e1
        LD      (418CH),HL              ; 01B3  228c41
        CALL    L2272                   ; 01B6  cd7222
        LD      HL,0                    ; 01B9  210000
        LD      (418CH),HL              ; 01BC  228c41
        JR      L01D4                   ; 01BF  1813
L01C1:
        LD      HL,(41BDH)              ; 01C1  2abd41
        LD      A,H                     ; 01C4  7c
        OR      L                       ; 01C5  b5
        JR      z,L01D4                 ; 01C6  280c
        LD      IY,4204H                ; 01C8  fd210442
        CALL    L255D                   ; 01CC  cd5d25
        LD      A,0A0H                  ; 01CF  3ea0
        CALL    CH_OUT                  ; 01D1  cddb34
L01D4:
        CALL    L3628                   ; 01D4  cd2836
        CALL    L026B                   ; 01D7  cd6b02
        LD      A,11                    ; 01DA  3e0b
        JP      nz,ERROR                ; 01DC  c25933
        LD      HL,41C1H                ; 01DF  21c141
        RES     0,(HL)                  ; 01E2  cb86
        LD      HL,(418CH)              ; 01E4  2a8c41
        LD      A,H                     ; 01E7  7c
        OR      L                       ; 01E8  b5
        LD      IY,(41F1H)              ; 01E9  fd2af141
        CALL    nz,L255D                ; 01ED  c45d25
        LD      HL,(4084H)              ; 01F0  2a8440
        CALL    L35DB                   ; 01F3  cddb35
        LD      HL,(41B5H)              ; 01F6  2ab541
        LD      A,H                     ; 01F9  7c
        OR      L                       ; 01FA  b5
        JR      z,L0202                 ; 01FB  2805
        CALL    L026A                   ; 01FD  cd6a02
        JR      L022C                   ; 0200  182a
L0202:
        LD      HL,(418CH)              ; 0202  2a8c41
        LD      A,H                     ; 0205  7c
        OR      L                       ; 0206  b5
        JR      nz,L0221                ; 0207  2018
        LD      A,(41C1H)               ; 0209  3ac141
        BIT     7,A                     ; 020C  cb7f
        LD      A,14                    ; 020E  3e0e
        JP      nz,ERROR                ; 0210  c25933
        LD      HL,410BH                ; 0213  210b41
        LD      (4190H),HL              ; 0216  229041
        LD      BC,418AH                ; 0219  018a41
        CALL    L143A                   ; 021C  cd3a14
        JR      L022C                   ; 021F  180b
L0221:
        LD      HL,(41BDH)              ; 0221  2abd41
        LD      DE,(41BFH)              ; 0224  ed5bbf41
        ADD     HL,DE                   ; 0228  19
        LD      (41BDH),HL              ; 0229  22bd41
L022C:
        CALL    L34B7                   ; 022C  cdb734
        JP      L0159                   ; 022F  c35901
        DB      31H,0ADH,43H,0CDH,0CEH,35H,21H,6BH ; 0232 1.C..5!k
        DB      34H,0CDH,0DBH,35H,0AFH,32H,0C1H,41H ; 023A 4..5.2.A
        DB      32H,0C2H,41H,0C3H,59H,01H ; 0242 2.A.Y.

;=====================================================================
; WARMSTART / HAUPTSCHLEIFE (Direktmodus)
; Setzt Flags (41C1H) zurueck, Ausgabekanal auf Konsole (41FBH)
; und wartet auf eine Eingabezeile. ERROR kehrt hierher zurueck.
;=====================================================================
WARMSTART:
        LD      A,(41C1H)               ; 0248  3ac141
        AND     4                       ; 024B  e604
        LD      (41C1H),A               ; 024D  32c141
        LD      HL,41FBH                ; 0250  21fb41
        LD      (41F5H),HL              ; 0253  22f541
        JR      L0261                   ; 0256  1809
L0258:
        CALL    CH_NEWLINE              ; 0258  cdc335
        LD      HL,3489H                ; 025B  218934
        CALL    L35DB                   ; 025E  cddb35
L0261:
        LD      HL,0                    ; 0261  210000
        CALL    L2272                   ; 0264  cd7222
        JP      L0159                   ; 0267  c35901
L026A:
        JP      (HL)                    ; 026A  e9
L026B:
        LD      HL,0345H                ; 026B  214503
        XOR     A                       ; 026E  af
        LD      B,A                     ; 026F  47
        JR      L0278                   ; 0270  1806

;=====================================================================
; SYNTAXMASCHINE (SYN_MATCH)
; Uebersetzt eine Quellzeile anhand der Grammatik-Knoten (ab 0345H)
; in Zwischencode. Jeder Knoten prueft Schluesselwort, Tokenklasse
; oder Unterregel; bei Erfolg wird die Aktion ausgefuehrt, die meist
; einen Opcode ueber EMIT_BYTE in den Zwischencode schreibt.
; Bei Fehlschlag wird die naechste Alternative (Bit7=0) versucht.
;=====================================================================
SYN_MATCH:
        LD      A,(4000H)               ; 0272  3a0040
        OR      A                       ; 0275  b7
        JR      nz,L0281                ; 0276  2009
L0278:
        PUSH    HL                      ; 0278  e5
        PUSH    IX                      ; 0279  dde5
        CALL    L0F6F                   ; 027B  cd6f0f
        POP     IX                      ; 027E  dde1
        POP     HL                      ; 0280  e1
L0281:
        LD      C,(HL)                  ; 0281  4e
        INC     HL                      ; 0282  23
        LD      A,18H                   ; 0283  3e18
        AND     C                       ; 0285  a1
        JR      z,L02EF                 ; 0286  2867
        CP      10H                     ; 0288  fe10
        JR      nz,L0293                ; 028A  2007
        LD      A,(4000H)               ; 028C  3a0040
        CP      (HL)                    ; 028F  be
        INC     HL                      ; 0290  23
        JR      L02D1                   ; 0291  183e
L0293:
        JR      nc,L02B8                ; 0293  3023
        LD      A,7                     ; 0295  3e07
        AND     C                       ; 0297  a1
        INC     A                       ; 0298  3c
        PUSH    BC                      ; 0299  c5
        LD      B,A                     ; 029A  47
        LD      A,(4002H)               ; 029B  3a0240
        CP      B                       ; 029E  b8
        JR      nz,L02AF                ; 029F  200e
        LD      DE,4003H                ; 02A1  110340
L02A4:
        LD      A,(DE)                  ; 02A4  1a
        CP      (HL)                    ; 02A5  be
        JR      nz,L02AF                ; 02A6  2007
        INC     HL                      ; 02A8  23
        INC     DE                      ; 02A9  13
        DJNZ    L02A4                   ; 02AA  10f8
        POP     BC                      ; 02AC  c1
        JR      L02EA                   ; 02AD  183b
L02AF:
        LD      A,B                     ; 02AF  78
        ADD     A,L                     ; 02B0  85
        LD      L,A                     ; 02B1  6f
        JR      nc,L02B5                ; 02B2  3001
        INC     H                       ; 02B4  24
L02B5:
        POP     BC                      ; 02B5  c1
        JR      L02D3                   ; 02B6  181b
L02B8:
        LD      A,(HL)                  ; 02B8  7e
        INC     HL                      ; 02B9  23
        PUSH    HL                      ; 02BA  e5
        PUSH    BC                      ; 02BB  c5
        LD      HL,RULETAB              ; 02BC  210703
        ADD     A,L                     ; 02BF  85
        LD      L,A                     ; 02C0  6f
        JR      nc,L02C4                ; 02C1  3001
        INC     H                       ; 02C3  24
L02C4:
        LD      A,(HL)                  ; 02C4  7e
        INC     HL                      ; 02C5  23
        LD      H,(HL)                  ; 02C6  66
        LD      L,A                     ; 02C7  6f
        LD      B,0                     ; 02C8  0600
        CALL    L0281                   ; 02CA  cd8102
        POP     BC                      ; 02CD  c1
        POP     HL                      ; 02CE  e1
        JR      z,L02EF                 ; 02CF  281e
L02D1:
        JR      z,L02EA                 ; 02D1  2817
L02D3:
        BIT     5,C                     ; 02D3  cb69
        JR      z,L02D8                 ; 02D5  2801
        INC     HL                      ; 02D7  23
L02D8:
        BIT     6,C                     ; 02D8  cb71
        JR      z,L02DD                 ; 02DA  2801
        INC     HL                      ; 02DC  23
L02DD:
        BIT     7,C                     ; 02DD  cb79
        JR      z,L0281                 ; 02DF  28a0
        LD      A,B                     ; 02E1  78
        AND     A                       ; 02E2  a7
        LD      A,11                    ; 02E3  3e0b
        JP      nz,ERROR                ; 02E5  c25933
        INC     A                       ; 02E8  3c
        RET                             ; 02E9  c9
L02EA:
        XOR     A                       ; 02EA  af
        LD      (4000H),A               ; 02EB  320040
        INC     B                       ; 02EE  04
L02EF:
        BIT     6,C                     ; 02EF  cb71
        CALL    nz,SYN_ACTION           ; 02F1  c4b825
        BIT     5,C                     ; 02F4  cb69
        JP      z,SYN_MATCH             ; 02F6  ca7202
        LD      A,(HL)                  ; 02F9  7e
        AND     A                       ; 02FA  a7
        RET     z                       ; 02FB  c8
        LD      E,A                     ; 02FC  5f
        LD      D,0                     ; 02FD  1600
        RLA                             ; 02FF  17
        JR      nc,L0303                ; 0300  3001
        DEC     D                       ; 0302  15
L0303:
        ADD     HL,DE                   ; 0303  19
        JP      SYN_MATCH               ; 0304  c37202

;=====================================================================
; RULETAB: 31 Startadressen der Grammatik-Regeln
; Index = Argument eines RULE-Knotens / 2.
;=====================================================================
RULETAB:
        DB      45H,03H,0CEH,03H,0BEH,04H,0CH,06H ; 0307 E.......
        DB      1BH,06H,87H,07H,8BH,08H,0CEH,0AH ; 030F ........
        DB      47H,0BH,92H,0BH,21H,0CH,0A4H,0CH ; 0317 G...!...
        DB      0E4H,0CH,0FAH,0CH,4EH,0DH,80H,0DH ; 031F ....N...
        DB      0F6H,0CH,89H,0DH,17H,0EH,28H,0EH ; 0327 ......(.
        DB      34H,0EH,11H,0EH,40H,0EH,58H,0EH ; 032F 4...@.X.
        DB      0D5H,0EH,33H,07H,26H,07H,80H,0CH ; 0337 ..3.&...
        DB      08H,0DH,1EH,09H,0FEH,09H ; 033F ......
        DB      38H,02H,00H             ; 0345 RULE 02
        DB      58H,36H,34H             ; 0348 RULE 36 -> L037E
        DB      70H,47H,4AH,00H         ; 034B TOK 47 -> L0397
        DB      6AH,52H,45H,4DH,72H,00H ; 034F KW "REM" -> S_REM
        DB      70H,48H,6EH,00H         ; 0355 TOK 48 -> S_REM
        DB      50H,84H,36H             ; 0359 TOK 84 -> L0391
        DB      70H,84H,33H,0FDH        ; 035C TOK 84 -> L0391 next 035C
        DB      38H,04H,15H             ; 0360 RULE 04 next 0377
        DB      98H,06H                 ; 0363 RULE 06 last
        DB      30H,46H,03H             ; 0365 TOK 46 next 036A
        DB      0A0H,11H                ; 0368 EPS next 037A last
        DB      38H,06H,0F9H            ; 036A RULE 06 next 0365
        DB      6AH,52H,45H,4DH,54H,00H ; 036D KW "REM" -> S_REM
        DB      0F0H,48H,50H,00H        ; 0373 TOK 48 -> S_REM last
        DB      30H,46H,0F4H            ; 0377 TOK 46 next 036D
        DB      0F0H,47H,34H,00H        ; 037A TOK 47 -> L03B0 last
L037E:
        LD      HL,(4088H)              ; 037E  2a8840
        LD      A,(HL)                  ; 0381  7e
        CP      20H                     ; 0382  fe20
        JR      nz,L0387                ; 0384  2001
        INC     HL                      ; 0386  23
L0387:
        LD      (4084H),HL              ; 0387  228440
        LD      HL,(4003H)              ; 038A  2a0340
        LD      (418CH),HL              ; 038D  228c41
        RET                             ; 0390  c9
L0391:
        LD      HL,(4003H)              ; 0391  2a0340
        JP      L221E                   ; 0394  c31e22
L0397:
        LD      HL,41C1H                ; 0397  21c141
        RES     2,(HL)                  ; 039A  cb96
        LD      HL,(4084H)              ; 039C  2a8440
        LD      (HL),1EH                ; 039F  361e
        LD      HL,(418CH)              ; 03A1  2a8c41
        LD      (41B9H),HL              ; 03A4  22b941
        LD      A,H                     ; 03A7  7c
        OR      L                       ; 03A8  b5
        RET     z                       ; 03A9  c8
        LD      HL,41C2H                ; 03AA  21c241
        SET     2,(HL)                  ; 03AD  cbd6
        RET                             ; 03AF  c9
L03B0:
        LD      HL,41C1H                ; 03B0  21c141
        RES     2,(HL)                  ; 03B3  cb96
        LD      HL,(418CH)              ; 03B5  2a8c41
        LD      DE,(41BDH)              ; 03B8  ed5bbd41
        AND     A                       ; 03BC  a7
        SBC     HL,DE                   ; 03BD  ed52
        CALL    nz,L046D                ; 03BF  c46d04
L03C2:
        JP      L2316                   ; 03C2  c31623

;=====================================================================
; SYNTAX-AKTIONEN (S_xxx)
; Von den Grammatik-Knoten angesprungen. Typisch: LD L,op bzw. LD A,op
; und Sprung nach EMIT_BYTE. Der Opcode ist der Index in OPTAB.
; Direktbefehle (NEW, LIST, RUN ...) laden statt dessen eine Adresse.
;=====================================================================
S_REM:
        CALL    L11F8                   ; 03C5  cdf811
        CP      1EH                     ; 03C8  fe1e
        JR      nz,S_REM                ; 03CA  20f9
        JR      L03C2                   ; 03CC  18f4
        DB      6AH,4EH,45H,57H,60H,5CH ; 03CE KW "NEW" -> S_NEW next 042F
        DB      6AH,4DH,45H,4DH,5FH,56H ; 03D4 KW "MEM" -> S_MEM next 042F
        DB      6CH,4EH,4FH,4DH,45H,4DH,5BH,4EH ; 03DA KW "NOMEM" -> S_NOMEM next 042F
        DB      6AH,42H,59H,45H,5FH,48H ; 03E2 KW "BYE" -> S_BYE next 042F
        DB      6BH,4CH,4FH,41H,44H,71H,41H ; 03E8 KW "LOAD" -> S_LOAD next 042F
        DB      6BH,53H,41H,56H,45H,6FH,2AH ; 03EF KW "SAVE" -> S_SAVE next 041F
        DB      6BH,4CH,49H,53H,54H,4FH,23H ; 03F6 KW "LIST" -> S_LIST next 041F
        DB      6DH,4EH,55H,4DH,42H,45H,52H,4BH,1AH ; 03FD KW "NUMBER" -> S_NUMBER next 041F
        DB      6DH,44H,45H,4CH,45H,54H,45H,33H,11H ; 0406 KW "DELETE" -> S_DELETE next 041F
        DB      6FH,52H,45H,4EH,55H,4DH,42H,45H,52H,3CH,06H ; 040F KW "RENUMBER" -> S_RENUMBER next 041F
        DB      0CAH,52H,55H,4EH,3BH    ; 041A KW "RUN" -> S_RUN last
        DB      78H,36H,56H,04H         ; 041F RULE 36 -> L0477 next 0426
        DB      0E0H,58H,0AH            ; 0423 EPS -> L047C next 042F last
        DB      30H,45H,04H             ; 0426 TOK 45 next 042C
        DB      0E0H,59H,04H            ; 0429 EPS -> L0483 next 042F last
        DB      0D8H,36H,5AH            ; 042C RULE 36 -> L0488 last
        DB      0B0H,47H,00H            ; 042F TOK 47 last
S_NEW:
        LD      HL,159AH                ; 0432  219a15
        JR      L0466                   ; 0435  182f
S_MEM:
        LD      A,1                     ; 0437  3e01
        JR      L043C                   ; 0439  1801
S_NOMEM:
        XOR     A                       ; 043B  af
L043C:
        LD      (41B4H),A               ; 043C  32b441
        RET                             ; 043F  c9
S_DELETE:
        LD      HL,1401H                ; 0440  210114
        JR      L046A                   ; 0443  1825
S_BYE:
        LD      HL,1414H                ; 0445  211414
        JR      L046A                   ; 0448  1820
S_LIST:
        LD      HL,1343H                ; 044A  214313
        JR      L0466                   ; 044D  1817
S_NUMBER:
        LD      HL,13E6H                ; 044F  21e613
        JR      L0466                   ; 0452  1812
S_RENUMBER:
        LD      HL,15C0H                ; 0454  21c015
        JR      L046A                   ; 0457  1811
S_RUN:
        LD      HL,1417H                ; 0459  211714
        JR      L046A                   ; 045C  180c
S_LOAD:
        LD      HL,13D3H                ; 045E  21d313
        JR      L046A                   ; 0461  1807
S_SAVE:
        LD      HL,13B6H                ; 0463  21b613
L0466:
        LD      (41B5H),HL              ; 0466  22b541
        RET                             ; 0469  c9
L046A:
        LD      (41B5H),HL              ; 046A  22b541
L046D:
        LD      HL,0                    ; 046D  210000
        LD      (41BDH),HL              ; 0470  22bd41
        LD      (41BFH),HL              ; 0473  22bf41
        RET                             ; 0476  c9
L0477:
        LD      HL,(4003H)              ; 0477  2a0340
        JR      L047F                   ; 047A  1803
L047C:
        CALL    L0483                   ; 047C  cd8304
L047F:
        LD      (41B9H),HL              ; 047F  22b941
        RET                             ; 0482  c9
L0483:
        LD      HL,0                    ; 0483  210000
        JR      L048B                   ; 0486  1803
L0488:
        LD      HL,(4003H)              ; 0488  2a0340
L048B:
        LD      (41BBH),HL              ; 048B  22bb41
        RET                             ; 048E  c9
        DB      0D0H,86H,1AH            ; 048F TOK 86 -> L04AB last
        DB      90H,41H                 ; 0492 TOK 41 last
        DB      78H,18H,20H,0CH         ; 0494 RULE 18 -> L04B6 next 04A3
        DB      0D8H,20H,1CH            ; 0498 RULE 20 -> L04B6 last
        DB      90H,42H                 ; 049B TOK 42 last
        DB      90H,62H                 ; 049D TOK 62 last
        DB      0F8H,1CH,18H,00H        ; 049F RULE 1C -> L04B9 last
        DB      90H,42H                 ; 04A3 TOK 42 last
        DB      90H,62H                 ; 04A5 TOK 62 last
        DB      0F8H,0EH,10H,00H        ; 04A7 RULE 0E -> L04B9 last
L04AB:
        LD      HL,(4003H)              ; 04AB  2a0340
        CALL    L221E                   ; 04AE  cd1e22
        LD      A,3CH                   ; 04B1  3e3c
        JP      EMIT_BYTE               ; 04B3  c3bc23
L04B6:
        JP      L23EE                   ; 04B6  c3ee23
L04B9:
        LD      A,3EH                   ; 04B9  3e3e
        JP      EMIT_BYTE               ; 04BB  c3bc23
        DB      2AH,44H,45H,46H,0CDH    ; 04BE KW "DEF" next 048F
        DB      6AH,46H,4FH,52H,0ACH,18H ; 04C3 KW "FOR" -> S_FOR next 04E0
        DB      2BH,4EH,45H,58H,54H,2CH ; 04C9 KW "NEXT" next 04FA
        DB      69H,49H,46H,0FBH,2BH    ; 04CF KW "IF" -> S_IF next 04FE
        DB      69H,4FH,4EH,0DCH,5BH    ; 04D4 KW "ON" -> S_ON next 0533
        DB      0EBH,44H,41H,54H,41H,78H,5FH ; 04D9 KW "DATA" -> S_DATA next 053E last
        DB      98H,18H                 ; 04E0 RULE 18 last
        DB      90H,62H                 ; 04E2 TOK 62 last
        DB      98H,0EH                 ; 04E4 RULE 0E last
        DB      0C9H,54H,4FH,98H        ; 04E6 KW "TO" -> S_TO last
        DB      98H,0EH                 ; 04EA RULE 0E last
        DB      6BH,53H,54H,45H,50H,9CH,04H ; 04EC KW "STEP" -> S_STEP next 04F6
        DB      0E0H,0A6H,00H           ; 04F3 EPS -> L059A last
        DB      0F8H,0EH,9FH,00H        ; 04F6 RULE 0E -> L0597 last
        DB      0F8H,18H,0A6H,00H       ; 04FA RULE 18 -> L05A2 last
        DB      78H,0EH,0C3H,0FH        ; 04FE RULE 0E -> L05C3 next 0510
        DB      0D8H,1CH,0C3H           ; 0502 RULE 1C -> L05C7 last
        DB      70H,63H,0CEH,04H        ; 0505 TOK 63 -> L05D5 next 050C
        DB      0D0H,62H,0CFH           ; 0509 TOK 62 -> L05DA last
        DB      0F8H,1CH,0D6H,0FH       ; 050C RULE 1C -> L05E4 next 051E last
        DB      70H,63H,0D8H,08H        ; 0510 TOK 63 -> L05EA next 051B
        DB      70H,62H,0D9H,04H        ; 0514 TOK 62 -> L05EF next 051B
        DB      0E0H,0E1H,04H           ; 0518 EPS -> L05FA next 051E last
        DB      0D8H,0EH,0E3H           ; 051B RULE 0E -> L0600 last
        DB      0CBH,54H,48H,45H,4EH,65H ; 051E KW "THEN" -> S_THEN last
        DB      0D8H,32H,62H            ; 0524 RULE 32 -> S_THEN last
        DB      6BH,45H,4CH,53H,45H,0D9H,03H ; 0527 KW "ELSE" -> S_ELSE next 0530
        DB      0A0H,00H                ; 052E EPS last
        DB      0B8H,32H,00H            ; 0530 RULE 32 last
        DB      0D8H,0EH,53H            ; 0533 RULE 0E -> S_THEN last
        DB      0D8H,32H,81H            ; 0536 RULE 32 -> L05B9 last
        DB      30H,45H,0FBH            ; 0539 TOK 45 next 0536
        DB      0A0H,00H                ; 053C EPS last
        DB      78H,18H,21H,0FH         ; 053E RULE 18 -> L0561 next 0550
        DB      78H,1EH,1DH,0BH         ; 0542 RULE 1E -> L0561 next 0550
        DB      78H,20H,19H,07H         ; 0546 RULE 20 -> L0561 next 0550
        DB      48H,2DH,21H             ; 054A KW "-" -> L056D
        DB      0D8H,16H,12H            ; 054D RULE 16 -> L0561 last
        DB      30H,45H,0ECH            ; 0550 TOK 45 next 053E
        DB      0E0H,14H,00H            ; 0553 EPS -> L0568 last
S_DATA:
        LD      HL,41C1H                ; 0556  21c141
        SET     3,(HL)                  ; 0559  cbde
        LD      HL,0                    ; 055B  210000
        JP      L23E0                   ; 055E  c3e023
L0561:
        LD      HL,410DH                ; 0561  210d41
        INC     (HL)                    ; 0564  34
        JP      L23EE                   ; 0565  c3ee23
L0568:
        LD      IX,410CH                ; 0568  dd210c41
        RET                             ; 056C  c9
L056D:
        LD      HL,41C2H                ; 056D  21c241
        SET     5,(HL)                  ; 0570  cbee
        RET                             ; 0572  c9
S_FOR:
        LD      A,80H                   ; 0573  3e80
        CALL    EMIT_BYTE               ; 0575  cdbc23
        LD      (IX+3),0                ; 0578  dd360300
        LD      IX,4113H                ; 057C  dd211341
        RET                             ; 0580  c9
S_TO:
        CALL    L254E                   ; 0581  cd4e25
        INC     A                       ; 0584  3c
        LD      (410FH),A               ; 0585  320f41
S_THEN:
        LD      A,0FFH                  ; 0588  3eff
        JP      EMIT_BYTE               ; 058A  c3bc23
S_STEP:
        CALL    S_THEN                  ; 058D  cd8805
        CALL    L254E                   ; 0590  cd4e25
        LD      (4110H),A               ; 0593  321041
        RET                             ; 0596  c9
L0597:
        CALL    S_THEN                  ; 0597  cd8805
L059A:
        CALL    L2430                   ; 059A  cd3024
        LD      (410DH),HL              ; 059D  220d41
        JR      L05AD                   ; 05A0  180b
L05A2:
        LD      A,82H                   ; 05A2  3e82
        CALL    L23EB                   ; 05A4  cdeb23
        LD      HL,0                    ; 05A7  210000
        CALL    L23E0                   ; 05AA  cde023
L05AD:
        LD      HL,41C1H                ; 05AD  21c141
        SET     7,(HL)                  ; 05B0  cbfe
        RET                             ; 05B2  c9
S_ON:
        LD      HL,84H                  ; 05B3  218400
        JP      L23E0                   ; 05B6  c3e023
L05B9:
        LD      HL,410DH                ; 05B9  210d41
        INC     (HL)                    ; 05BC  34
        LD      HL,0FFFFH               ; 05BD  21ffff
        JP      L23E0                   ; 05C0  c3e023
L05C3:
        LD      A,8AH                   ; 05C3  3e8a
        JR      L05C9                   ; 05C5  1802
L05C7:
        LD      A,8CH                   ; 05C7  3e8c
L05C9:
        LD      (410CH),A               ; 05C9  320c41
        RET                             ; 05CC  c9
S_IF:
        INC     IX                      ; 05CD  dd23
        INC     IX                      ; 05CF  dd23
        XOR     A                       ; 05D1  af
        JP      EMIT_BYTE               ; 05D2  c3bc23
L05D5:
        LD      A,(4001H)               ; 05D5  3a0140
        JR      L05DC                   ; 05D8  1802
L05DA:
        LD      A,2                     ; 05DA  3e02
L05DC:
        LD      (410DH),A               ; 05DC  320d41
        CALL    L05E4                   ; 05DF  cde405
        JR      S_THEN                  ; 05E2  18a4
L05E4:
        CALL    L0D6B                   ; 05E4  cd6b0d
        JP      L2430                   ; 05E7  c33024
L05EA:
        LD      A,(4001H)               ; 05EA  3a0140
        JR      L05F1                   ; 05ED  1802
L05EF:
        LD      A,2                     ; 05EF  3e02
L05F1:
        LD      (410DH),A               ; 05F1  320d41
L05F4:
        CALL    L2459                   ; 05F4  cd5924
        JP      L240A                   ; 05F7  c30a24
L05FA:
        LD      A,5                     ; 05FA  3e05
        LD      (410DH),A               ; 05FC  320d41
        RET                             ; 05FF  c9
L0600:
        LD      A,0                     ; 0600  3e00
        JP      L23EB                   ; 0602  c3eb23
S_ELSE:
        CALL    L254E                   ; 0605  cd4e25
        LD      (410EH),A               ; 0608  320e41
        RET                             ; 060B  c9
        DB      38H,08H,00H             ; 060C RULE 08
        DB      38H,0AH,00H             ; 060F RULE 0A
        DB      38H,0CH,00H             ; 0612 RULE 0C
        DB      38H,3AH,00H             ; 0615 RULE 3A
        DB      0B8H,3CH,00H            ; 0618 RULE 3C last
        DB      2CH,50H,52H,49H,4EH,54H,3BH ; 061B KW "PRINT" next 065C
        DB      6CH,49H,4EH,50H,55H,54H,0A8H,59H ; 0622 KW "INPUT" -> S_INPUT next 0682
        DB      6BH,45H,44H,49H,54H,0A7H,52H ; 062A KW "EDIT" -> S_EDIT next 0682
        DB      2BH,52H,45H,41H,44H,5BH ; 0631 KW "READ" next 0691
        DB      6EH,52H,45H,53H,54H,4FH,52H,45H,0BBH,5DH ; 0637 KW "RESTORE" -> S_RESTORE next 069D
        DB      6BH,4FH,50H,45H,4EH,0D7H,78H ; 0641 KW "OPEN" -> S_OPEN next 06BF
        DB      6CH,43H,4CH,4FH,53H,45H,0D3H,70H ; 0648 KW "CLOSE" -> S_CLOSE next 06BF
        DB      6AH,47H,45H,54H,0B1H,4EH ; 0650 KW "GET" -> S_GET next 06A3
        DB      0EAH,50H,55H,54H,0ABH,56H ; 0656 KW "PUT" -> S_GET next 06B1 last
        DB      78H,1CH,69H,0BH         ; 065C RULE 1C -> L06C7 next 066A
        DB      78H,0EH,60H,07H         ; 0660 RULE 0E -> L06C2 next 066A
        DB      38H,30H,0AH             ; 0664 RULE 30 next 0670
        DB      0E0H,64H,00H            ; 0667 EPS -> L06CC last
        DB      30H,45H,09H             ; 066A TOK 45 next 0675
        DB      0E0H,5EH,00H            ; 066D EPS -> L06CC last
        DB      30H,45H,03H             ; 0670 TOK 45 next 0675
        DB      0A0H,00H                ; 0673 EPS last
        DB      78H,1CH,50H,0F2H        ; 0675 RULE 1C -> L06C7 next 066A
        DB      78H,0EH,47H,0EEH        ; 0679 RULE 0E -> L06C2 next 066A
        DB      38H,30H,0F1H            ; 067D RULE 30 next 0670
        DB      20H,00H                 ; 0680 EPS
        DB      58H,1EH,43H             ; 0682 RULE 1E -> L06C7
        DB      78H,1AH,55H,04H         ; 0685 RULE 1A -> L06DC next 068C
        DB      0D8H,20H,5EH            ; 0689 RULE 20 -> L06E9 last
        DB      30H,45H,0F7H            ; 068C TOK 45 next 0685
        DB      0A0H,00H                ; 068F EPS last
        DB      78H,1AH,63H,04H         ; 0691 RULE 1A -> L06F6 next 0698
        DB      0D8H,20H,5FH            ; 0695 RULE 20 -> L06F6 last
        DB      30H,45H,0F7H            ; 0698 TOK 45 next 0691
        DB      0A0H,00H                ; 069B EPS last
        DB      38H,34H,00H             ; 069D RULE 34
        DB      0E0H,5EH,00H            ; 06A0 EPS -> L06FF last
        DB      98H,24H                 ; 06A3 RULE 24 last
        DB      78H,1AH,62H,04H         ; 06A5 RULE 1A -> L0709 next 06AC
        DB      0D8H,20H,62H            ; 06A9 RULE 20 -> L070D last
        DB      30H,45H,0F7H            ; 06AC TOK 45 next 06A5
        DB      0A0H,00H                ; 06AF EPS last
        DB      98H,24H                 ; 06B1 RULE 24 last
        DB      78H,0EH,5CH,04H         ; 06B3 RULE 0E -> L0711 next 06BA
        DB      0D8H,1CH,60H            ; 06B7 RULE 1C -> L0719 last
        DB      30H,45H,0F7H            ; 06BA TOK 45 next 06B3
        DB      0A0H,00H                ; 06BD EPS last
        DB      0B8H,2AH,00H            ; 06BF RULE 2A last
L06C2:
        LD      A,62H                   ; 06C2  3e62
L06C4:
        JP      EMIT_BYTE               ; 06C4  c3bc23
L06C7:
        LD      A,64H                   ; 06C7  3e64
L06C9:
        JP      L23EB                   ; 06C9  c3eb23
L06CC:
        LD      A,68H                   ; 06CC  3e68
        JR      L06C4                   ; 06CE  18f4
S_INPUT:
        LD      HL,41C2H                ; 06D0  21c241
        RES     3,(HL)                  ; 06D3  cb9e
        RET                             ; 06D5  c9
S_EDIT:
        LD      HL,41C2H                ; 06D6  21c241
        SET     3,(HL)                  ; 06D9  cbde
        RET                             ; 06DB  c9
L06DC:
        LD      A,76H                   ; 06DC  3e76
        LD      HL,41C2H                ; 06DE  21c241
        BIT     3,(HL)                  ; 06E1  cb5e
        JR      z,L06C9                 ; 06E3  28e4
        LD      A,7AH                   ; 06E5  3e7a
        JR      L06C9                   ; 06E7  18e0
L06E9:
        LD      A,78H                   ; 06E9  3e78
        LD      HL,41C2H                ; 06EB  21c241
        BIT     3,(HL)                  ; 06EE  cb5e
        JR      z,L06C9                 ; 06F0  28d7
        LD      A,7CH                   ; 06F2  3e7c
        JR      L06C9                   ; 06F4  18d3
L06F6:
        LD      A,96H                   ; 06F6  3e96
        JR      L06C9                   ; 06F8  18cf
S_RESTORE:
        LD      A,98H                   ; 06FA  3e98
L06FC:
        JP      EMIT_BYTE               ; 06FC  c3bc23
L06FF:
        LD      HL,0                    ; 06FF  210000
        JP      L23E0                   ; 0702  c3e023
S_GET:
        LD      A,0A4H                  ; 0705  3ea4
        JR      L06FC                   ; 0707  18f3
L0709:
        LD      A,0A6H                  ; 0709  3ea6
        JR      L06C9                   ; 070B  18bc
L070D:
        LD      A,0A8H                  ; 070D  3ea8
        JR      L06C9                   ; 070F  18b8
L0711:
        CALL    L2459                   ; 0711  cd5924
        LD      A,0AAH                  ; 0714  3eaa
        JP      L23DD                   ; 0716  c3dd23
L0719:
        LD      A,0ACH                  ; 0719  3eac
        JR      L06C9                   ; 071B  18ac
S_OPEN:
        LD      A,0AEH                  ; 071D  3eae
        JR      L0723                   ; 071F  1802
S_CLOSE:
        LD      A,0B0H                  ; 0721  3eb0
L0723:
        JP      EMIT_BYTE               ; 0723  c3bc23
        DB      78H,36H,33H,00H         ; 0726 RULE 36 -> L075B
        DB      0F0H,82H,02H,00H        ; 072A TOK 82 -> L072E last
L072E:
        LD      HL,(4003H)              ; 072E  2a0340
        JR      L0773                   ; 0731  1840
        DB      78H,36H,23H,00H         ; 0733 RULE 36 -> L0758
        DB      70H,82H,2AH,08H         ; 0737 TOK 82 -> L0763 next 0742
        DB      98H,06H                 ; 073B RULE 06 last
        DB      30H,46H,0FCH            ; 073D TOK 46 next 073B
        DB      0A0H,00H                ; 0740 EPS last
        DB      70H,62H,26H,0CH         ; 0742 TOK 62 -> L076A next 0751
        DB      70H,41H,37H,04H         ; 0746 TOK 41 -> L077F next 074D
        DB      0E0H,22H,00H            ; 074A EPS -> L076D last
        DB      98H,38H                 ; 074D RULE 38 last
        DB      90H,62H                 ; 074F TOK 62 last
        DB      0F8H,0EH,02H,0E9H       ; 0751 RULE 0E -> L0755 next 073D last
L0755:
        JP      L0822                   ; 0755  c32208
L0758:
        CALL    L0782                   ; 0758  cd8207
L075B:
        LD      HL,(4003H)              ; 075B  2a0340
        CALL    L21FE                   ; 075E  cdfe21
        JR      L077C                   ; 0761  1819
L0763:
        LD      HL,(4003H)              ; 0763  2a0340
        LD      (41C7H),HL              ; 0766  22c741
        RET                             ; 0769  c9
L076A:
        JP      L0D28                   ; 076A  c3280d
L076D:
        CALL    L0782                   ; 076D  cd8207
        LD      HL,(41C7H)              ; 0770  2ac741
L0773:
        LD      A,L                     ; 0773  7d
        AND     0E0H                    ; 0774  e6e0
        OR      4                       ; 0776  f604
        LD      L,A                     ; 0778  6f
        CALL    L21F9                   ; 0779  cdf921
L077C:
        JP      L23E0                   ; 077C  c3e023
L077F:
        JP      L0D1E                   ; 077F  c31e0d
L0782:
        LD      A,86H                   ; 0782  3e86
        JP      EMIT_BYTE               ; 0784  c3bc23
        DB      6BH,47H,4FH,54H,4FH,8DH,37H ; 0787 KW "GOTO" -> S_GOTO next 07C4
        DB      6CH,47H,4FH,53H,55H,42H,8AH,2FH ; 078E KW "GOSUB" -> S_GOSUB next 07C4
        DB      2AH,4CH,45H,54H,33H     ; 0796 KW "LET" next 07CD
        DB      38H,20H,35H             ; 079B RULE 20 next 07D2
        DB      38H,1AH,27H             ; 079E RULE 1A next 07C7
        DB      6BH,53H,54H,4FH,50H,9EH,00H ; 07A1 KW "STOP" -> S_STOP
        DB      2AH,45H,4EH,44H,2CH     ; 07A8 KW "END" next 07D8
        DB      6DH,52H,45H,54H,55H,52H,4EH,95H,00H ; 07AD KW "RETURN" -> S_RETURN
        DB      2CH,57H,49H,44H,54H,48H,23H ; 07B6 KW "WIDTH" next 07DF
        DB      0EBH,41H,53H,47H,4EH,53H,25H ; 07BD KW "ASGN" -> S_ASGN next 07E8 last
        DB      0B8H,34H,00H            ; 07C4 RULE 34 last
        DB      90H,62H                 ; 07C7 TOK 62 last
        DB      0F8H,0EH,57H,00H        ; 07C9 RULE 0E -> L0822 last
        DB      38H,1AH,0F8H            ; 07CD RULE 1A next 07C7
        DB      98H,20H                 ; 07D0 RULE 20 last
        DB      90H,62H                 ; 07D2 TOK 62 last
        DB      0F8H,1CH,51H,00H        ; 07D4 RULE 1C -> L0827 last
        DB      78H,0EH,55H,00H         ; 07D8 RULE 0E -> L082F
        DB      0E0H,57H,00H            ; 07DC EPS -> L0834 last
        DB      0D0H,85H,70H            ; 07DF TOK 85 -> L0851 last
        DB      90H,62H                 ; 07E2 TOK 62 last
        DB      0F8H,0EH,74H,00H        ; 07E4 RULE 0E -> L085A last
        DB      38H,26H,14H             ; 07E8 RULE 26 next 07FE
        DB      38H,28H,0AH             ; 07EB RULE 28 next 07F7
        DB      98H,24H                 ; 07EE RULE 24 last
        DB      90H,62H                 ; 07F0 TOK 62 last
        DB      38H,2EH,00H             ; 07F2 RULE 2E
        DB      20H,0AH                 ; 07F5 EPS next 0800
        DB      90H,62H                 ; 07F7 TOK 62 last
        DB      38H,2EH,00H             ; 07F9 RULE 2E
        DB      20H,06H                 ; 07FC EPS next 0803
        DB      90H,62H                 ; 07FE TOK 62 last
        DB      38H,2CH,00H             ; 0800 RULE 2C
        DB      90H,41H                 ; 0803 TOK 41 last
        DB      0D8H,36H,58H            ; 0805 RULE 36 -> L085F last
        DB      90H,45H                 ; 0808 TOK 45 last
        DB      0D8H,36H,65H            ; 080A RULE 36 -> L0871 last
        DB      90H,45H                 ; 080D TOK 45 last
        DB      0D8H,36H,67H            ; 080F RULE 36 -> L0878 last
        DB      0B0H,42H,00H            ; 0812 TOK 42 last
S_ASGN:
        LD      A,94H                   ; 0815  3e94
        JR      L081B                   ; 0817  1802
S_GOTO:
        LD      A,86H                   ; 0819  3e86
L081B:
        JP      EMIT_BYTE               ; 081B  c3bc23
S_GOSUB:
        LD      A,88H                   ; 081E  3e88
        JR      L081B                   ; 0820  18f9
L0822:
        LD      A,20H                   ; 0822  3e20
        JP      L23EB                   ; 0824  c3eb23
L0827:
        LD      A,60H                   ; 0827  3e60
        CALL    L23EB                   ; 0829  cdeb23
        JP      L23EE                   ; 082C  c3ee23
L082F:
        LD      A,92H                   ; 082F  3e92
        JP      EMIT_BYTE               ; 0831  c3bc23
L0834:
        LD      HL,41C1H                ; 0834  21c141
        BIT     5,(HL)                  ; 0837  cb6e
        RES     5,(HL)                  ; 0839  cbae
        JR      z,S_STOP                ; 083B  2807
        LD      IY,(41F7H)              ; 083D  fd2af741
        CALL    L35AB                   ; 0841  cdab35
S_STOP:
        LD      A,90H                   ; 0844  3e90
        JP      EMIT_BYTE               ; 0846  c3bc23
S_RETURN:
        LD      A,8EH                   ; 0849  3e8e
        CALL    EMIT_BYTE               ; 084B  cdbc23
        JP      L05AD                   ; 084E  c3ad05
L0851:
        LD      HL,(4003H)              ; 0851  2a0340
        CALL    L2143                   ; 0854  cd4321
        JP      L240A                   ; 0857  c30a24
L085A:
        LD      A,4EH                   ; 085A  3e4e
        JP      L23EB                   ; 085C  c3eb23
L085F:
        LD      HL,0                    ; 085F  210000
        LD      (41CEH),HL              ; 0862  22ce41
        LD      HL,(4003H)              ; 0865  2a0340
        LD      (41D0H),HL              ; 0868  22d041
        LD      A,6                     ; 086B  3e06
        LD      (41CBH),A               ; 086D  32cb41
        RET                             ; 0870  c9
L0871:
        LD      HL,(4003H)              ; 0871  2a0340
        LD      (41CCH),HL              ; 0874  22cc41
        RET                             ; 0877  c9
L0878:
        LD      HL,(4003H)              ; 0878  2a0340
        LD      (41D2H),HL              ; 087B  22d241
        LD      HL,41CBH                ; 087E  21cb41
        LD      BC,9                    ; 0881  010900
        CALL    L20A1                   ; 0884  cda120
        EX      DE,HL                   ; 0887  eb
        JP      L23E0                   ; 0888  c3e023
        DB      2AH,44H,49H,4DH,26H     ; 088B KW "DIM" next 08B5
        DB      6BH,43H,41H,4CH,4CH,65H,3FH ; 0890 KW "CALL" -> S_CALL next 08D5
        DB      6EH,4FH,55H,54H,43H,48H,41H,52H,5FH,35H ; 0897 KW "OUTCHAR" -> S_OUTCHAR next 08D5
        DB      6BH,50H,4FH,4BH,45H,5CH,32H ; 08A1 KW "POKE" -> S_POKE next 08D9
        DB      6BH,44H,4FH,4BH,45H,59H,2BH ; 08A8 KW "DOKE" -> S_DOKE next 08D9
        DB      0EAH,4FH,55H,54H,57H,25H ; 08AF KW "OUT" -> S_OUT next 08D9 last
        DB      70H,81H,2BH,08H         ; 08B5 TOK 81 -> L08E2 next 08C0
        DB      70H,82H,27H,04H         ; 08B9 TOK 82 -> L08E2 next 08C0
        DB      0D0H,83H,23H            ; 08BD TOK 83 -> L08E2 last
        DB      90H,41H                 ; 08C0 TOK 41 last
        DB      98H,0EH                 ; 08C2 RULE 0E last
        DB      70H,42H,27H,09H         ; 08C4 TOK 42 -> L08ED next 08D0
        DB      0D0H,45H,20H            ; 08C8 TOK 45 -> L08EA last
        DB      98H,0EH                 ; 08CB RULE 0E last
        DB      0D0H,42H,23H            ; 08CD TOK 42 -> L08F2 last
        DB      30H,45H,0E3H            ; 08D0 TOK 45 next 08B5
        DB      20H,00H                 ; 08D3 EPS
        DB      0F8H,0EH,38H,00H        ; 08D5 RULE 0E -> L090F last
        DB      98H,0EH                 ; 08D9 RULE 0E last
        DB      0D0H,45H,0DH            ; 08DB TOK 45 -> L08EA last
        DB      0F8H,0EH,35H,00H        ; 08DE RULE 0E -> L0915 last
L08E2:
        LD      HL,(4003H)              ; 08E2  2a0340
        SET     4,L                     ; 08E5  cbe5
        JP      L0CEF                   ; 08E7  c3ef0c
L08EA:
        JP      L05F4                   ; 08EA  c3f405
L08ED:
        LD      A,26H                   ; 08ED  3e26
        JP      L23EB                   ; 08EF  c3eb23
L08F2:
        LD      A,28H                   ; 08F2  3e28
        CALL    L23EB                   ; 08F4  cdeb23
        JP      L23EE                   ; 08F7  c3ee23
S_CALL:
        LD      L,9AH                   ; 08FA  2e9a
        JR      L090C                   ; 08FC  180e
S_OUTCHAR:
        LD      L,9CH                   ; 08FE  2e9c
        JR      L090C                   ; 0900  180a
S_POKE:
        LD      L,9EH                   ; 0902  2e9e
        JR      L090C                   ; 0904  1806
S_DOKE:
        LD      L,0A0H                  ; 0906  2ea0
        JR      L090C                   ; 0908  1802
S_OUT:
        LD      L,0A2H                  ; 090A  2ea2
L090C:
        JP      L0C10                   ; 090C  c3100c
L090F:
        LD      A,(4196H)               ; 090F  3a9641
        JP      EMIT_BYTE               ; 0912  c3bc23
L0915:
        LD      A,(4196H)               ; 0915  3a9641
        CALL    L23EB                   ; 0918  cdeb23
        JP      L24B9                   ; 091B  c3b924
        DB      6BH,50H,4CH,4FH,54H,7CH,55H ; 091E KW "PLOT" -> S_PLOT next 0979
        DB      6AH,44H,4FH,54H,7AH,4FH ; 0925 KW "DOT" -> S_DOT next 0979
        DB      6AH,47H,4CH,53H,78H,36H ; 092B KW "GLS" -> S_GLS next 0966
        DB      6BH,43H,44H,4FH,54H,75H,42H ; 0931 KW "CDOT" -> S_CDOT next 0979
        DB      6BH,4CH,49H,4EH,45H,72H,28H ; 0938 KW "LINE" -> S_LINE next 0966
        DB      6CH,43H,4CH,49H,4EH,45H,6EH,20H ; 093F KW "CLINE" -> S_CLINE next 0966
        DB      6BH,46H,49H,4CH,4CH,6BH,19H ; 0947 KW "FILL" -> S_FILL next 0966
        DB      6BH,54H,45H,53H,54H,68H,2EH ; 094E KW "TEST" -> S_TEST next 0982
        DB      6AH,43H,4CH,53H,66H,35H ; 0955 KW "CLS" -> S_CLS next 098F
        DB      0CCH,47H,4CH,4FH,41H,44H,62H ; 095B KW "GLOAD" -> S_GLOAD last
        DB      0F8H,1CH,91H,00H        ; 0962 RULE 1C -> L09F5 last
        DB      98H,0EH                 ; 0966 RULE 0E last
        DB      0D0H,45H,5EH            ; 0968 TOK 45 -> L09C8 last
        DB      98H,0EH                 ; 096B RULE 0E last
        DB      0D0H,45H,59H            ; 096D TOK 45 -> L09C8 last
        DB      98H,0EH                 ; 0970 RULE 0E last
        DB      0D0H,45H,54H            ; 0972 TOK 45 -> L09C8 last
        DB      0F8H,0EH,54H,00H        ; 0975 RULE 0E -> L09CB last
        DB      98H,0EH                 ; 0979 RULE 0E last
        DB      0D0H,45H,4BH            ; 097B TOK 45 -> L09C8 last
        DB      0F8H,0EH,5AH,00H        ; 097E RULE 0E -> L09DA last
        DB      98H,18H                 ; 0982 RULE 18 last
        DB      90H,62H                 ; 0984 TOK 62 last
        DB      98H,0EH                 ; 0986 RULE 0E last
        DB      0D0H,45H,3EH            ; 0988 TOK 45 -> L09C8 last
        DB      0F8H,0EH,55H,00H        ; 098B RULE 0E -> L09E2 last
        DB      98H,18H                 ; 098F RULE 18 last
        DB      90H,45H                 ; 0991 TOK 45 last
        DB      98H,18H                 ; 0993 RULE 18 last
        DB      90H,45H                 ; 0995 TOK 45 last
        DB      98H,18H                 ; 0997 RULE 18 last
        DB      90H,45H                 ; 0999 TOK 45 last
        DB      0F8H,18H,4DH,00H        ; 099B RULE 18 -> L09EA last
S_PLOT:
        LD      L,0B8H                  ; 099F  2eb8
        JR      L09C5                   ; 09A1  1822
S_DOT:
        LD      L,0BAH                  ; 09A3  2eba
        JR      L09C5                   ; 09A5  181e
S_GLS:
        LD      L,0C8H                  ; 09A7  2ec8
        JR      L09C5                   ; 09A9  181a
S_CDOT:
        LD      L,0BCH                  ; 09AB  2ebc
        JR      L09C5                   ; 09AD  1816
S_LINE:
        LD      L,0BEH                  ; 09AF  2ebe
        JR      L09C5                   ; 09B1  1812
S_CLINE:
        LD      L,0C0H                  ; 09B3  2ec0
        JR      L09C5                   ; 09B5  180e
S_FILL:
        LD      L,0C2H                  ; 09B7  2ec2
        JR      L09C5                   ; 09B9  180a
S_TEST:
        LD      L,0C4H                  ; 09BB  2ec4
        JR      L09C5                   ; 09BD  1806
S_CLS:
        LD      L,0C6H                  ; 09BF  2ec6
        JR      L09C5                   ; 09C1  1802
S_GLOAD:
        LD      L,0CAH                  ; 09C3  2eca
L09C5:
        JP      L0C10                   ; 09C5  c3100c
L09C8:
        JP      L05F4                   ; 09C8  c3f405
L09CB:
        LD      A,(4196H)               ; 09CB  3a9641
        CALL    L23EB                   ; 09CE  cdeb23
L09D1:
        CALL    L23EE                   ; 09D1  cdee23
L09D4:
        CALL    L23EE                   ; 09D4  cdee23
L09D7:
        JP      L24B9                   ; 09D7  c3b924
L09DA:
        LD      A,(4196H)               ; 09DA  3a9641
        CALL    L23EB                   ; 09DD  cdeb23
        JR      L09D7                   ; 09E0  18f5
L09E2:
        LD      A,(4196H)               ; 09E2  3a9641
        CALL    L23EB                   ; 09E5  cdeb23
        JR      L09D4                   ; 09E8  18ea
L09EA:
        LD      A,(4196H)               ; 09EA  3a9641
        CALL    L23EB                   ; 09ED  cdeb23
        CALL    L23EE                   ; 09F0  cdee23
        JR      L09D1                   ; 09F3  18dc
L09F5:
        LD      A,(4196H)               ; 09F5  3a9641
        CALL    L23EB                   ; 09F8  cdeb23
        JP      L24B9                   ; 09FB  c3b924
        DB      6AH,47H,49H,4EH,7EH,00H ; 09FE KW "GIN" -> S_GIN
        DB      6AH,4FH,46H,46H,7CH,00H ; 0A04 KW "OFF" -> S_OFF
        DB      6AH,43H,4FH,4CH,7AH,00H ; 0A0A KW "COL" -> S_COL
        DB      6AH,47H,4FH,4CH,78H,00H ; 0A10 KW "GOL" -> S_GOL
        DB      6AH,52H,45H,56H,76H,00H ; 0A16 KW "REV" -> S_REV
        DB      6BH,43H,52H,45H,56H,73H,00H ; 0A1C KW "CREV" -> S_CREV
        DB      6BH,48H,41H,52H,44H,70H,00H ; 0A23 KW "HARD" -> S_HARD
        DB      6CH,43H,48H,41H,52H,44H,6CH,00H ; 0A2A KW "CHARD" -> S_CHARD
        DB      6CH,50H,41H,55H,53H,45H,68H,00H ; 0A32 KW "PAUSE" -> S_PAUSE
        DB      6BH,42H,45H,4CH,4CH,65H,00H ; 0A3A KW "BELL" -> S_BELL
        DB      6BH,43H,4FH,50H,59H,62H,00H ; 0A41 KW "COPY" -> S_COPY
        DB      6AH,52H,45H,53H,60H,00H ; 0A48 KW "RES" -> S_RES
        DB      6BH,54H,45H,58H,54H,60H,1FH ; 0A4E KW "TEXT" -> S_TEXT next 0A73
        DB      0CCH,47H,53H,41H,56H,45H,5CH ; 0A55 KW "GSAVE" -> S_GSAVE last
        DB      98H,1CH                 ; 0A5C RULE 1C last
        DB      90H,45H                 ; 0A5E TOK 45 last
        DB      98H,0EH                 ; 0A60 RULE 0E last
        DB      0D0H,45H,58H            ; 0A62 TOK 45 -> L0ABC last
        DB      98H,0EH                 ; 0A65 RULE 0E last
        DB      0D0H,45H,53H            ; 0A67 TOK 45 -> L0ABC last
        DB      98H,0EH                 ; 0A6A RULE 0E last
        DB      0D0H,45H,4EH            ; 0A6C TOK 45 -> L0ABC last
        DB      0F8H,0EH,51H,00H        ; 0A6F RULE 0E -> L0AC2 last
        DB      98H,1CH                 ; 0A73 RULE 1C last
        DB      90H,45H                 ; 0A75 TOK 45 last
        DB      98H,0EH                 ; 0A77 RULE 0E last
        DB      0D0H,45H,41H            ; 0A79 TOK 45 -> L0ABC last
        DB      0F8H,0EH,41H,00H        ; 0A7C RULE 0E -> L0ABF last
S_GIN:
        LD      H,0                     ; 0A80  2600
        JR      L0AAE                   ; 0A82  182a
S_OFF:
        LD      H,2                     ; 0A84  2602
        JR      L0AAE                   ; 0A86  1826
S_COL:
        LD      H,4                     ; 0A88  2604
        JR      L0AAE                   ; 0A8A  1822
S_GOL:
        LD      H,6                     ; 0A8C  2606
        JR      L0AAE                   ; 0A8E  181e
S_REV:
        LD      H,8                     ; 0A90  2608
        JR      L0AAE                   ; 0A92  181a
S_CREV:
        LD      H,10                    ; 0A94  260a
        JR      L0AAE                   ; 0A96  1816
S_HARD:
        LD      H,12                    ; 0A98  260c
        JR      L0AAE                   ; 0A9A  1812
S_CHARD:
        LD      H,14                    ; 0A9C  260e
        JR      L0AAE                   ; 0A9E  180e
S_PAUSE:
        LD      H,10H                   ; 0AA0  2610
        JR      L0AAE                   ; 0AA2  180a
S_BELL:
        LD      H,12H                   ; 0AA4  2612
        JR      L0AAE                   ; 0AA6  1806
S_COPY:
        LD      H,14H                   ; 0AA8  2614
        JR      L0AAE                   ; 0AAA  1802
S_RES:
        LD      H,16H                   ; 0AAC  2616
L0AAE:
        LD      L,0D0H                  ; 0AAE  2ed0
        JP      L23E0                   ; 0AB0  c3e023
S_TEXT:
        LD      L,0CEH                  ; 0AB3  2ece
        JR      L0AB9                   ; 0AB5  1802
S_GSAVE:
        LD      L,0CCH                  ; 0AB7  2ecc
L0AB9:
        JP      L0C10                   ; 0AB9  c3100c
L0ABC:
        JP      L05F4                   ; 0ABC  c3f405
L0ABF:
        JP      L09E2                   ; 0ABF  c3e209
L0AC2:
        LD      A,(4196H)               ; 0AC2  3a9641
        CALL    L23EB                   ; 0AC5  cdeb23
        CALL    L23EE                   ; 0AC8  cdee23
        JP      L09D1                   ; 0ACB  c3d109
        DB      28H,2BH,08H             ; 0ACE KW "+" next 0AD8
        DB      68H,2DH,28H,04H         ; 0AD1 KW "-" -> L0AFB next 0AD8
        DB      50H,65H,28H             ; 0AD5 TOK 65 -> L0AFF
        DB      70H,41H,29H,10H         ; 0AD8 TOK 41 -> L0B03 next 0AEB
        DB      38H,1AH,12H             ; 0ADC RULE 1A next 0AF0
        DB      38H,10H,0FH             ; 0ADF RULE 10 next 0AF0
        DB      38H,16H,0CH             ; 0AE2 RULE 16 next 0AF0
        DB      38H,12H,09H             ; 0AE5 RULE 12 next 0AF0
        DB      0B8H,14H,06H            ; 0AE8 RULE 14 next 0AF0 last
        DB      98H,0EH                 ; 0AEB RULE 0E last
        DB      0D0H,42H,20H            ; 0AED TOK 42 -> L0B0F last
        DB      70H,61H,27H,0E5H        ; 0AF0 TOK 61 -> L0B19 next 0AD8
        DB      70H,66H,23H,0E1H        ; 0AF4 TOK 66 -> L0B19 next 0AD8
        DB      0E0H,3EH,00H            ; 0AF8 EPS -> L0B37 last
L0AFB:
        LD      A,0BAH                  ; 0AFB  3eba
        JR      L0B1C                   ; 0AFD  181d
L0AFF:
        LD      A,0BCH                  ; 0AFF  3ebc
        JR      L0B1C                   ; 0B01  1819
L0B03:
        LD      HL,0                    ; 0B03  210000
L0B06:
        LD      (4198H),HL              ; 0B06  229841
        CALL    L24A6                   ; 0B09  cda624
        JP      L248D                   ; 0B0C  c38d24
L0B0F:
        XOR     A                       ; 0B0F  af
        CALL    L0B1C                   ; 0B10  cd1c0b
        CALL    L2407                   ; 0B13  cd0724
        JP      L24B9                   ; 0B16  c3b924
L0B19:
        LD      A,(4001H)               ; 0B19  3a0140
L0B1C:
        CALL    L23FB                   ; 0B1C  cdfb23
        LD      (4198H),HL              ; 0B1F  229841
L0B22:
        LD      A,(4199H)               ; 0B22  3a9941
        LD      B,A                     ; 0B25  47
        LD      A,(4197H)               ; 0B26  3a9741
        CP      B                       ; 0B29  b8
        JP      c,L24A6                 ; 0B2A  daa624
        OR      B                       ; 0B2D  b0
        RET     z                       ; 0B2E  c8
        CALL    L24CC                   ; 0B2F  cdcc24
        CALL    L24B9                   ; 0B32  cdb924
        JR      L0B22                   ; 0B35  18eb
L0B37:
        XOR     A                       ; 0B37  af
        CALL    L0B1C                   ; 0B38  cd1c0b
        CALL    L2430                   ; 0B3B  cd3024
        LD      A,H                     ; 0B3E  7c
        AND     L                       ; 0B3F  a5
        INC     A                       ; 0B40  3c
        RET     z                       ; 0B41  c8
        LD      A,1EH                   ; 0B42  3e1e
        JP      L23DD                   ; 0B44  c3dd23
        DB      6AH,54H,4FH,50H,26H,00H ; 0B47 KW "TOP" -> S_TOP
        DB      6BH,53H,49H,5AH,45H,2CH,00H ; 0B4D KW "SIZE" -> S_SIZE
        DB      6DH,49H,4EH,43H,48H,41H,52H,2BH,00H ; 0B54 KW "INCHAR" -> S_INCHAR
        DB      6BH,45H,52H,52H,4EH,28H,00H ; 0B5D KW "ERRN" -> S_ERRN
        DB      6BH,45H,52H,4CH,4EH,25H,00H ; 0B64 KW "ERLN" -> S_ERLN
        DB      0EAH,52H,4EH,44H,13H,00H ; 0B6B KW "RND" -> S_RND last
S_TOP:
        LD      A,40H                   ; 0B71  3e40
L0B73:
        PUSH    AF                      ; 0B73  f5
        CALL    L248D                   ; 0B74  cd8d24
        POP     AF                      ; 0B77  f1
        CALL    EMIT_BYTE               ; 0B78  cdbc23
        JP      L2407                   ; 0B7B  c30724
S_SIZE:
        LD      A,42H                   ; 0B7E  3e42
        JR      L0B73                   ; 0B80  18f1
S_RND:
        LD      A,44H                   ; 0B82  3e44
        JR      L0B73                   ; 0B84  18ed
S_INCHAR:
        LD      A,7EH                   ; 0B86  3e7e
        JR      L0B73                   ; 0B88  18e9
S_ERRN:
        LD      A,0B4H                  ; 0B8A  3eb4
        JR      L0B73                   ; 0B8C  18e5
S_ERLN:
        LD      A,0B6H                  ; 0B8E  3eb6
        JR      L0B73                   ; 0B90  18e1
        DB      6AH,41H,42H,53H,58H,3CH ; 0B92 KW "ABS" -> S_ABS next 0BD3
        DB      6AH,41H,54H,4EH,56H,36H ; 0B98 KW "ATN" -> S_ATN next 0BD3
        DB      6AH,43H,4FH,53H,54H,30H ; 0B9E KW "COS" -> S_COS next 0BD3
        DB      6AH,45H,58H,50H,52H,2AH ; 0BA4 KW "EXP" -> S_EXP next 0BD3
        DB      6AH,49H,4EH,54H,50H,24H ; 0BAA KW "INT" -> S_INT next 0BD3
        DB      6AH,4CH,4FH,47H,4EH,1EH ; 0BB0 KW "LOG" -> S_LOG next 0BD3
        DB      6AH,53H,47H,4EH,4CH,18H ; 0BB6 KW "SGN" -> S_SGN next 0BD3
        DB      6AH,53H,49H,4EH,4AH,12H ; 0BBC KW "SIN" -> S_SIN next 0BD3
        DB      6AH,53H,51H,52H,48H,0CH ; 0BC2 KW "SQR" -> S_SQR next 0BD3
        DB      0D0H,86H,11H            ; 0BC8 TOK 86 -> L0BDB last
        DB      90H,41H                 ; 0BCB TOK 41 last
        DB      98H,0EH                 ; 0BCD RULE 0E last
        DB      0F0H,42H,16H,00H        ; 0BCF TOK 42 -> L0BE7 last
        DB      90H,41H                 ; 0BD3 TOK 41 last
        DB      98H,0EH                 ; 0BD5 RULE 0E last
        DB      0F0H,42H,3CH,00H        ; 0BD7 TOK 42 -> L0C15 last
L0BDB:
        LD      HL,(4003H)              ; 0BDB  2a0340
        CALL    L21F9                   ; 0BDE  cdf921
        CALL    L240A                   ; 0BE1  cd0a24
        JP      L0B03                   ; 0BE4  c3030b
L0BE7:
        LD      A,0B2H                  ; 0BE7  3eb2
        CALL    L23EB                   ; 0BE9  cdeb23
        JR      L0C1B                   ; 0BEC  182d
S_ABS:
        LD      L,2AH                   ; 0BEE  2e2a
        JR      L0C10                   ; 0BF0  181e
S_ATN:
        LD      L,2CH                   ; 0BF2  2e2c
        JR      L0C10                   ; 0BF4  181a
S_COS:
        LD      L,2EH                   ; 0BF6  2e2e
        JR      L0C10                   ; 0BF8  1816
S_EXP:
        LD      L,30H                   ; 0BFA  2e30
        JR      L0C10                   ; 0BFC  1812
S_INT:
        LD      L,32H                   ; 0BFE  2e32
        JR      L0C10                   ; 0C00  180e
S_LOG:
        LD      L,34H                   ; 0C02  2e34
        JR      L0C10                   ; 0C04  180a
S_SGN:
        LD      L,36H                   ; 0C06  2e36
        JR      L0C10                   ; 0C08  1806
S_SIN:
        LD      L,38H                   ; 0C0A  2e38
        JR      L0C10                   ; 0C0C  1802
S_SQR:
        LD      L,3AH                   ; 0C0E  2e3a
L0C10:
        LD      H,0                     ; 0C10  2600
        JP      L0B06                   ; 0C12  c3060b
L0C15:
        LD      A,(4196H)               ; 0C15  3a9641
        CALL    EMIT_BYTE               ; 0C18  cdbc23
L0C1B:
        CALL    L24B9                   ; 0C1B  cdb924
        JP      L2407                   ; 0C1E  c30724
        DB      6AH,4CH,45H,4EH,31H,20H ; 0C21 KW "LEN" -> S_LEN next 0C46
        DB      6AH,41H,53H,43H,2FH,1AH ; 0C27 KW "ASC" -> S_ASC next 0C46
        DB      6AH,56H,41H,4CH,2DH,14H ; 0C2D KW "VAL" -> S_VAL next 0C46
        DB      6BH,50H,45H,45H,4BH,39H,15H ; 0C33 KW "PEEK" -> S_PEEK next 0C4E
        DB      6BH,44H,45H,45H,4BH,36H,0EH ; 0C3A KW "DEEK" -> S_DEEK next 0C4E
        DB      0E9H,49H,4EH,35H,09H    ; 0C41 KW "IN" -> S_IN next 0C4E last
        DB      90H,41H                 ; 0C46 TOK 41 last
        DB      98H,1CH                 ; 0C48 RULE 1C last
        DB      0F0H,42H,16H,00H        ; 0C4A TOK 42 -> L0C62 last
        DB      90H,41H                 ; 0C4E TOK 41 last
        DB      98H,0EH                 ; 0C50 RULE 0E last
        DB      0F0H,42H,2AH,00H        ; 0C52 TOK 42 -> L0C7E last
S_LEN:
        LD      L,46H                   ; 0C56  2e46
        JR      L0C7B                   ; 0C58  1821
S_ASC:
        LD      L,5AH                   ; 0C5A  2e5a
        JR      L0C7B                   ; 0C5C  181d
S_VAL:
        LD      L,5CH                   ; 0C5E  2e5c
        JR      L0C7B                   ; 0C60  1819
L0C62:
        LD      HL,0FFFFH               ; 0C62  21ffff
        CALL    L2450                   ; 0C65  cd5024
        LD      A,(4196H)               ; 0C68  3a9641
        CALL    L23DD                   ; 0C6B  cddd23
        JP      L24B9                   ; 0C6E  c3b924
S_PEEK:
        LD      L,48H                   ; 0C71  2e48
        JR      L0C7B                   ; 0C73  1806
S_DEEK:
        LD      L,4AH                   ; 0C75  2e4a
        JR      L0C7B                   ; 0C77  1802
S_IN:
        LD      L,4CH                   ; 0C79  2e4c
L0C7B:
        JP      L0C10                   ; 0C7B  c3100c
L0C7E:
        JR      L0C15                   ; 0C7E  1895
        DB      70H,89H,1DH,00H         ; 0C80 TOK 89 -> L0C9F
        DB      0F0H,8EH,02H,00H        ; 0C84 TOK 8E -> L0C88 last
L0C88:
        LD      DE,4003H                ; 0C88  110340
        CALL    FAC_LOAD                ; 0C8B  cd9f26
        CALL    FP_TO_INT16             ; 0C8E  cdb732
        LD      HL,(FAC)                ; 0C91  2ae242
        LD      (4003H),HL              ; 0C94  220340
L0C97:
        BIT     7,H                     ; 0C97  cb7c
        RET     z                       ; 0C99  c8
        LD      A,1FH                   ; 0C9A  3e1f
        JP      ERROR                   ; 0C9C  c35933
L0C9F:
        LD      HL,(4003H)              ; 0C9F  2a0340
        JR      L0C97                   ; 0CA2  18f3
        DB      70H,89H,0AH,00H         ; 0CA4 TOK 89 -> L0CB0
        DB      70H,8EH,1CH,00H         ; 0CA8 TOK 8E -> L0CC6
        DB      0F0H,8AH,18H,00H        ; 0CAC TOK 8A -> L0CC6 last
L0CB0:
        CALL    L0CDC                   ; 0CB0  cddc0c
        JR      z,L0CC2                 ; 0CB3  280d
        LD      DE,(4003H)              ; 0CB5  ed5b0340
        LD      HL,0                    ; 0CB9  210000
        AND     A                       ; 0CBC  a7
        SBC     HL,DE                   ; 0CBD  ed52
        LD      (4003H),HL              ; 0CBF  220340
L0CC2:
        LD      A,89H                   ; 0CC2  3e89
        JR      L0CD6                   ; 0CC4  1810
L0CC6:
        CALL    L0CDC                   ; 0CC6  cddc0c
        JR      z,L0CD4                 ; 0CC9  2809
        LD      HL,4006H                ; 0CCB  210640
        BIT     6,(HL)                  ; 0CCE  cb76
        JR      z,L0CD4                 ; 0CD0  2802
        SET     7,(HL)                  ; 0CD2  cbfe
L0CD4:
        LD      A,8AH                   ; 0CD4  3e8a
L0CD6:
        CALL    L2185                   ; 0CD6  cd8521
        JP      L240A                   ; 0CD9  c30a24
L0CDC:
        LD      HL,41C2H                ; 0CDC  21c241
        BIT     5,(HL)                  ; 0CDF  cb6e
        RES     5,(HL)                  ; 0CE1  cbae
        RET                             ; 0CE3  c9
        DB      70H,81H,06H,00H         ; 0CE4 TOK 81 -> L0CEC
        DB      0F0H,82H,02H,00H        ; 0CE8 TOK 82 -> L0CEC last
L0CEC:
        LD      HL,(4003H)              ; 0CEC  2a0340
L0CEF:
        CALL    L2143                   ; 0CEF  cd4321
        EX      DE,HL                   ; 0CF2  eb
        JP      L240A                   ; 0CF3  c30a24
        DB      0F0H,83H,1FH,08H        ; 0CF6 TOK 83 -> L0D17 next 0D01 last
        DB      70H,81H,1BH,04H         ; 0CFA TOK 81 -> L0D17 next 0D01
        DB      0D0H,82H,17H            ; 0CFE TOK 82 -> L0D17 last
        DB      70H,41H,1BH,04H         ; 0D01 TOK 41 -> L0D1E next 0D08
        DB      0E0H,22H,00H            ; 0D05 EPS -> L0D28 last
        DB      98H,0EH                 ; 0D08 RULE 0E last
        DB      70H,42H,24H,00H         ; 0D0A TOK 42 -> L0D30
        DB      0D0H,45H,1DH            ; 0D0E TOK 45 -> L0D2D last
        DB      98H,0EH                 ; 0D11 RULE 0E last
        DB      0F0H,42H,32H,00H        ; 0D13 TOK 42 -> L0D47 last
L0D17:
        LD      HL,(4003H)              ; 0D17  2a0340
        LD      (41C7H),HL              ; 0D1A  22c741
        RET                             ; 0D1D  c9
L0D1E:
        CALL    L0B03                   ; 0D1E  cd030b
        LD      HL,(41C7H)              ; 0D21  2ac741
        SET     4,L                     ; 0D24  cbe5
        JR      L0CEF                   ; 0D26  18c7
L0D28:
        LD      HL,(41C7H)              ; 0D28  2ac741
        JR      L0CEF                   ; 0D2B  18c2
L0D2D:
        JP      L05F4                   ; 0D2D  c3f405
L0D30:
        LD      A,22H                   ; 0D30  3e22
        CALL    EMIT_BYTE               ; 0D32  cdbc23
L0D35:
        CALL    L23EE                   ; 0D35  cdee23
        LD      HL,0ADH                 ; 0D38  21ad00
        CALL    L2543                   ; 0D3B  cd4325
        CALL    L23E0                   ; 0D3E  cde023
        CALL    L240A                   ; 0D41  cd0a24
        JP      L24B9                   ; 0D44  c3b924
L0D47:
        LD      A,24H                   ; 0D47  3e24
        CALL    L23EB                   ; 0D49  cdeb23
        JR      L0D35                   ; 0D4C  18e7
        DB      38H,1EH,06H             ; 0D4E RULE 1E next 0D56
        DB      38H,20H,03H             ; 0D51 RULE 20 next 0D56
        DB      98H,22H                 ; 0D54 RULE 22 last
        DB      70H,64H,13H,03H         ; 0D56 TOK 64 -> L0D6B next 0D5C
        DB      0A0H,00H                ; 0D5A EPS last
        DB      78H,1EH,1DH,07H         ; 0D5C RULE 1E -> L0D7B next 0D66
        DB      78H,20H,19H,03H         ; 0D60 RULE 20 -> L0D7B next 0D66
        DB      98H,22H                 ; 0D64 RULE 22 last
        DB      30H,64H,0F4H            ; 0D66 TOK 64 next 0D5C
        DB      0A0H,00H                ; 0D69 EPS last
L0D6B:
        LD      HL,34A5H                ; 0D6B  21a534
        CALL    L2450                   ; 0D6E  cd5024
        AND     A                       ; 0D71  a7
        SBC     HL,DE                   ; 0D72  ed52
        RET     z                       ; 0D74  c8
        ADD     HL,DE                   ; 0D75  19
        LD      A,5EH                   ; 0D76  3e5e
        JP      L23DD                   ; 0D78  c3dd23
L0D7B:
        LD      A,5EH                   ; 0D7B  3e5e
        JP      L23EB                   ; 0D7D  c3eb23
        DB      0F0H,8BH,02H,00H        ; 0D80 TOK 8B -> L0D84 last
L0D84:
        LD      A,8BH                   ; 0D84  3e8b
        JP      L0CD6                   ; 0D86  c3d60c
        DB      6CH,52H,49H,47H,48H,54H,4DH,19H ; 0D89 KW "RIGHT" -> S_RIGHT next 0DA9
        DB      6BH,4CH,45H,46H,54H,4AH,12H ; 0D91 KW "LEFT" -> S_LEFT next 0DA9
        DB      2AH,4DH,49H,44H,1CH     ; 0D98 KW "MID" next 0DB8
        DB      6AH,43H,48H,52H,33H,2AH ; 0D9D KW "CHR" -> S_CHR next 0DCC
        DB      0EAH,53H,54H,52H,31H,24H ; 0DA3 KW "STR" -> S_STR next 0DCC last
        DB      90H,41H                 ; 0DA9 TOK 41 last
        DB      38H,20H,03H             ; 0DAB RULE 20 next 0DB0
        DB      98H,1EH                 ; 0DAE RULE 1E last
        DB      90H,45H                 ; 0DB0 TOK 45 last
        DB      98H,0EH                 ; 0DB2 RULE 0E last
        DB      0F0H,42H,2FH,00H        ; 0DB4 TOK 42 -> L0DE5 last
        DB      90H,41H                 ; 0DB8 TOK 41 last
        DB      38H,20H,03H             ; 0DBA RULE 20 next 0DBF
        DB      98H,1EH                 ; 0DBD RULE 1E last
        DB      90H,45H                 ; 0DBF TOK 45 last
        DB      0D8H,0EH,39H            ; 0DC1 RULE 0E -> L0DFC last
        DB      90H,45H                 ; 0DC4 TOK 45 last
        DB      98H,0EH                 ; 0DC6 RULE 0E last
        DB      0F0H,42H,35H,00H        ; 0DC8 TOK 42 -> L0DFF last
        DB      90H,41H                 ; 0DCC TOK 41 last
        DB      98H,0EH                 ; 0DCE RULE 0E last
        DB      0F0H,42H,37H,00H        ; 0DD0 TOK 42 -> L0E09 last
S_CHR:
        LD      L,56H                   ; 0DD4  2e56
        JR      L0DE2                   ; 0DD6  180a
S_STR:
        LD      L,58H                   ; 0DD8  2e58
        JR      L0DE2                   ; 0DDA  1806
S_RIGHT:
        LD      L,50H                   ; 0DDC  2e50
        JR      L0DE2                   ; 0DDE  1802
S_LEFT:
        LD      L,52H                   ; 0DE0  2e52
L0DE2:
        JP      L0C10                   ; 0DE2  c3100c
L0DE5:
        LD      A,(4196H)               ; 0DE5  3a9641
        CALL    L23EB                   ; 0DE8  cdeb23
L0DEB:
        CALL    L24B9                   ; 0DEB  cdb924
L0DEE:
        LD      HL,(4192H)              ; 0DEE  2a9241
        LD      DE,34A5H                ; 0DF1  11a534
        AND     A                       ; 0DF4  a7
        SBC     HL,DE                   ; 0DF5  ed52
        RET     z                       ; 0DF7  c8
        EX      DE,HL                   ; 0DF8  eb
        JP      L240A                   ; 0DF9  c30a24
L0DFC:
        JP      L05F4                   ; 0DFC  c3f405
L0DFF:
        LD      A,54H                   ; 0DFF  3e54
        CALL    L23EB                   ; 0E01  cdeb23
        CALL    L23EE                   ; 0E04  cdee23
        JR      L0DEE                   ; 0E07  18e5
L0E09:
        LD      A,(4196H)               ; 0E09  3a9641
        CALL    EMIT_BYTE               ; 0E0C  cdbc23
        JR      L0DEB                   ; 0E0F  18da
        DB      38H,26H,00H             ; 0E11 RULE 26
        DB      38H,28H,00H             ; 0E14 RULE 28
        DB      0F0H,85H,02H,00H        ; 0E17 TOK 85 -> L0E1B last
L0E1B:
        LD      HL,(4003H)              ; 0E1B  2a0340
        CALL    L2143                   ; 0E1E  cd4321
        LD      HL,4                    ; 0E21  210400
        ADD     HL,DE                   ; 0E24  19
        JP      L23E0                   ; 0E25  c3e023
        DB      6AH,44H,41H,49H,5AH,00H ; 0E28 KW "DAI" -> S_DAI
        DB      0EAH,43H,4FH,49H,59H,00H ; 0E2E KW "COI" -> S_COI last
        DB      6AH,44H,41H,4FH,58H,00H ; 0E34 KW "DAO" -> S_DAO
        DB      0EAH,43H,4FH,4FH,57H,00H ; 0E3A KW "COO" -> S_COO last
        DB      6AH,52H,53H,49H,6FH,00H ; 0E40 KW "RSI" -> S_RSI
        DB      6AH,4DH,54H,52H,5BH,33H ; 0E46 KW "MTR" -> S_MTR next 0E7E
        DB      6AH,46H,44H,52H,4BH,2DH ; 0E4C KW "FDR" -> S_FDR next 0E7E
        DB      0EAH,4BH,45H,59H,59H,00H ; 0E52 KW "KEY" -> S_KEY last
        DB      6AH,52H,53H,4FH,64H,00H ; 0E58 KW "RSO" -> S_RSO
        DB      6AH,4DH,54H,57H,48H,1BH ; 0E5E KW "MTW" -> S_MTW next 0E7E
        DB      6AH,46H,44H,57H,38H,15H ; 0E64 KW "FDW" -> S_FDW next 0E7E
        DB      6AH,4CH,50H,52H,56H,00H ; 0E6A KW "LPR" -> S_LPR
        DB      6CH,44H,55H,4DH,4DH,59H,41H,00H ; 0E70 KW "DUMMY" -> S_DUMMY
        DB      0EAH,53H,43H,52H,40H,00H ; 0E78 KW "SCR" -> S_SCR last
        DB      78H,1EH,52H,00H         ; 0E7E RULE 1E -> L0ED2
        DB      0F0H,83H,4BH,00H        ; 0E82 TOK 83 -> L0ECF last
S_DAI:
        LD      HL,41F7H                ; 0E86  21f741
        JR      L0E98                   ; 0E89  180d
S_COI:
        LD      HL,41F5H                ; 0E8B  21f541
        JR      L0E98                   ; 0E8E  1808
S_DAO:
        LD      HL,41F3H                ; 0E90  21f341
        JR      L0E98                   ; 0E93  1803
S_COO:
        LD      HL,41F1H                ; 0E95  21f141
L0E98:
        JP      L23E0                   ; 0E98  c3e023
S_FDR:
        LD      HL,374CH                ; 0E9B  214c37
        JR      L0ECC                   ; 0E9E  182c
S_FDW:
        LD      HL,3755H                ; 0EA0  215537
        JR      L0ECC                   ; 0EA3  1827
S_MTR:
        LD      HL,373AH                ; 0EA5  213a37
        JR      L0ECC                   ; 0EA8  1822
S_MTW:
        LD      HL,3743H                ; 0EAA  214337
        JR      L0ECC                   ; 0EAD  181d
S_KEY:
        LD      L,0                     ; 0EAF  2e00
        JR      L0EC6                   ; 0EB1  1813
S_RSI:
        LD      L,24H                   ; 0EB3  2e24
        JR      L0EC6                   ; 0EB5  180f
S_DUMMY:
        LD      HL,34ACH                ; 0EB7  21ac34
        JR      L0ECC                   ; 0EBA  1810
S_SCR:
        LD      L,12H                   ; 0EBC  2e12
        JR      L0EC6                   ; 0EBE  1806
S_RSO:
        LD      L,1BH                   ; 0EC0  2e1b
        JR      L0EC6                   ; 0EC2  1802
S_LPR:
        LD      L,2DH                   ; 0EC4  2e2d
L0EC6:
        LD      H,0                     ; 0EC6  2600
        LD      DE,41FBH                ; 0EC8  11fb41
        ADD     HL,DE                   ; 0ECB  19
L0ECC:
        JP      L23E0                   ; 0ECC  c3e023
L0ECF:
        CALL    L0CEC                   ; 0ECF  cdec0c
L0ED2:
        JP      L23EE                   ; 0ED2  c3ee23
        DB      6BH,50H,41H,47H,45H,3DH,00H ; 0ED5 KW "PAGE" -> S_PAGE
        DB      6BH,53H,4BH,49H,50H,3AH,00H ; 0EDC KW "SKIP" -> S_SKIP
        DB      6AH,43H,4FH,4CH,38H,27H ; 0EE3 KW "COL" -> L0F1F next 0F0F
        DB      6AH,54H,41H,42H,36H,21H ; 0EE9 KW "TAB" -> S_TAB next 0F0F
        DB      6AH,48H,45H,58H,4AH,12H ; 0EEF KW "HEX" -> S_HEX next 0F06
        DB      6AH,42H,49H,4EH,3DH,0CH ; 0EF5 KW "BIN" -> S_BIN next 0F06
        DB      6AH,46H,49H,58H,2CH,06H ; 0EFB KW "FIX" -> S_FIX next 0F06
        DB      0CAH,46H,4CH,4FH,2AH    ; 0F01 KW "FLO" -> S_FLO last
        DB      0D8H,36H,40H            ; 0F06 RULE 36 -> L0F48 last
        DB      90H,49H                 ; 0F09 TOK 49 last
        DB      0F8H,36H,40H,00H        ; 0F0B RULE 36 -> L0F4D last
        DB      90H,41H                 ; 0F0F TOK 41 last
        DB      98H,0EH                 ; 0F11 RULE 0E last
        DB      0F0H,42H,13H,00H        ; 0F13 TOK 42 -> L0F28 last
S_PAGE:
        LD      A,66H                   ; 0F17  3e66
        JR      L0F42                   ; 0F19  1827
S_SKIP:
        LD      A,68H                   ; 0F1B  3e68
        JR      L0F42                   ; 0F1D  1823
L0F1F:
        LD      L,6AH                   ; 0F1F  2e6a
        JR      L0F25                   ; 0F21  1802
S_TAB:
        LD      L,6CH                   ; 0F23  2e6c
L0F25:
        JP      L0C10                   ; 0F25  c3100c
L0F28:
        JP      L0C15                   ; 0F28  c3150c
S_FIX:
        LD      A,6EH                   ; 0F2B  3e6e
        JR      L0F31                   ; 0F2D  1802
S_FLO:
        LD      A,70H                   ; 0F2F  3e70
L0F31:
        LD      HL,0900H                ; 0F31  210009
        JR      L0F42                   ; 0F34  180c
S_BIN:
        LD      A,72H                   ; 0F36  3e72
        LD      HL,1001H                ; 0F38  210110
        JR      L0F42                   ; 0F3B  1805
S_HEX:
        LD      A,74H                   ; 0F3D  3e74
        LD      HL,0401H                ; 0F3F  210104
L0F42:
        LD      (41C3H),HL              ; 0F42  22c341
        JP      EMIT_BYTE               ; 0F45  c3bc23
L0F48:
        LD      HL,2001H                ; 0F48  210120
        JR      L0F50                   ; 0F4B  1803
L0F4D:
        LD      HL,(41C3H)              ; 0F4D  2ac341
L0F50:
        LD      A,(4004H)               ; 0F50  3a0440
        AND     A                       ; 0F53  a7
        JR      z,L0F5B                 ; 0F54  2805
L0F56:
        LD      A,27H                   ; 0F56  3e27
        JP      ERROR                   ; 0F58  c35933
L0F5B:
        LD      A,(4003H)               ; 0F5B  3a0340
        INC     H                       ; 0F5E  24
        CP      H                       ; 0F5F  bc
        JR      nc,L0F56                ; 0F60  30f4
        CP      L                       ; 0F62  bd
        JR      c,L0F56                 ; 0F63  38f1
        CP      (IX-1)                  ; 0F65  ddbeff
        JR      z,L0F6C                 ; 0F68  2802
        JR      nc,L0F56                ; 0F6A  30ea
L0F6C:
        JP      EMIT_BYTE               ; 0F6C  c3bc23
L0F6F:
        LD      A,0                     ; 0F6F  3e00
        LD      (4000H),A               ; 0F71  320040
        LD      (4001H),A               ; 0F74  320140
        LD      (4002H),A               ; 0F77  320240
L0F7A:
        CALL    L11F8                   ; 0F7A  cdf811
        LD      (4003H),A               ; 0F7D  320340
        LD      A,B                     ; 0F80  78
        OR      A                       ; 0F81  b7
        JR      z,L0F7A                 ; 0F82  28f6
        SUB     20H                     ; 0F84  d620
        JR      c,L0FE7                 ; 0F86  385f
        CP      10                      ; 0F88  fe0a
        JR      nc,L0F99                ; 0F8A  300d
        LD      HL,101EH                ; 0F8C  211e10
        ADD     A,L                     ; 0F8F  85
        LD      L,A                     ; 0F90  6f
        JR      nc,L0F94                ; 0F91  3001
        INC     H                       ; 0F93  24
L0F94:
        LD      A,(HL)                  ; 0F94  7e
        LD      (4000H),A               ; 0F95  320040
        RET                             ; 0F98  c9
L0F99:
        SUB     20H                     ; 0F99  d620
        JR      c,L0FE7                 ; 0F9B  384a
        CP      11                      ; 0F9D  fe0b
        JR      nc,L0FE7                ; 0F9F  3046
        LD      HL,1028H                ; 0FA1  212810
        ADD     A,A                     ; 0FA4  87
        ADD     A,L                     ; 0FA5  85
        LD      L,A                     ; 0FA6  6f
        JR      nc,L0FAA                ; 0FA7  3001
        INC     H                       ; 0FA9  24
L0FAA:
        LD      A,(HL)                  ; 0FAA  7e
        INC     HL                      ; 0FAB  23
        LD      H,(HL)                  ; 0FAC  66
        LD      L,A                     ; 0FAD  6f
        LD      A,(4003H)               ; 0FAE  3a0340
        LD      IX,4003H                ; 0FB1  dd210340
        JR      L0FBA                   ; 0FB5  1803
L0FB7:
        CALL    L11F8                   ; 0FB7  cdf811
L0FBA:
        LD      (IX),A                  ; 0FBA  dd7700
L0FBD:
        LD      C,(HL)                  ; 0FBD  4e
        INC     HL                      ; 0FBE  23
        LD      A,(IX)                  ; 0FBF  dd7e00
        RRC     C                       ; 0FC2  cb09
        CALL    c,L3638                 ; 0FC4  dc3836
        RRC     C                       ; 0FC7  cb09
        JR      c,L0FED                 ; 0FC9  3822
        CP      (HL)                    ; 0FCB  be
        JR      z,L0FEC                 ; 0FCC  281e
        LD      A,B                     ; 0FCE  78
        OR      80H                     ; 0FCF  f680
        CP      (HL)                    ; 0FD1  be
        JR      z,L0FEC                 ; 0FD2  2818
        INC     HL                      ; 0FD4  23
        LD      A,C                     ; 0FD5  79
        RRCA                            ; 0FD6  0f
        RRCA                            ; 0FD7  0f
        JR      nc,L0FDB                ; 0FD8  3001
        INC     HL                      ; 0FDA  23
L0FDB:
        RRCA                            ; 0FDB  0f
        JR      nc,L0FDF                ; 0FDC  3001
        INC     HL                      ; 0FDE  23
L0FDF:
        RRCA                            ; 0FDF  0f
        RRCA                            ; 0FE0  0f
        JR      nc,L0FE4                ; 0FE1  3001
        INC     HL                      ; 0FE3  23
L0FE4:
        RRCA                            ; 0FE4  0f
        JR      nc,L0FBD                ; 0FE5  30d6
L0FE7:
        LD      A,10                    ; 0FE7  3e0a
        JP      ERROR                   ; 0FE9  c35933
L0FEC:
        INC     HL                      ; 0FEC  23
L0FED:
        RRC     C                       ; 0FED  cb09
        JR      nc,L0FFA                ; 0FEF  3009
        INC     IX                      ; 0FF1  dd23
        LD      A,(4002H)               ; 0FF3  3a0240
        INC     A                       ; 0FF6  3c
        LD      (4002H),A               ; 0FF7  320240
L0FFA:
        LD      (IX),0                  ; 0FFA  dd360000
        RRC     C                       ; 0FFE  cb09
        JR      nc,L1007                ; 1000  3005
        LD      A,(HL)                  ; 1002  7e
        INC     HL                      ; 1003  23
        LD      (4001H),A               ; 1004  320140
L1007:
        RRC     C                       ; 1007  cb09
        CALL    c,SYN_ACTION            ; 1009  dcb825
        RRC     C                       ; 100C  cb09
        RET     c                       ; 100E  d8
        RRC     C                       ; 100F  cb09
        JR      nc,L0FB7                ; 1011  30a4
        LD      A,(HL)                  ; 1013  7e
        LD      E,A                     ; 1014  5f
        LD      D,0                     ; 1015  1600
        RLA                             ; 1017  17
        JR      nc,L101B                ; 1018  3001
        DEC     D                       ; 101A  15
L101B:
        ADD     HL,DE                   ; 101B  19
        JR      L0FB7                   ; 101C  1899
        DB      47H,41H,42H,45H,46H,62H,43H,44H ; 101E GABEFbCD
        DB      48H,49H,3EH,10H,6FH,10H,66H,10H ; 1026 HI>.o.f.
        DB      69H,10H,9EH,10H,6CH,10H,0D5H,10H ; 102E i...l...
        DB      7FH,10H,89H,10H,67H,11H,94H,10H ; 1036 ....g...
        DB      02H,40H,0C0H,07H,30H,0A0H,09H,0D6H ; 103E .@..0...
        DB      0EH,0F8H,44H,0C0H,0F5H,0B3H,04H,0C3H ; 1046 ..D.....
        DB      0E7H,0FH,3EH,8BH,18H,46H,3AH,0C2H ; 104E ..>..F:.
        DB      41H,0CBH,67H,0C8H,3EH,20H,2AH,88H ; 1056 A.g.> *.
        DB      40H,2BH,86H,77H,0DDH,77H,0FFH,0C9H ; 105E @+.w.w..
        DB      0BEH,2CH,0EH,0BEH,20H,0BH,0BEH,44H ; 1066 .,.. ..D
        DB      08H,1EH,4EH,05H,2CH,2AH,68H,0A3H ; 106E ..N.,*h.
        DB      3EH,01H,32H,02H,40H,3EH,61H,18H ; 1076 >.2.@>a.
        DB      1BH,1AH,04H,0FH,28H,3EH,05H,28H ; 107E ....(>.(
        DB      3DH,06H,0A3H,1AH,01H,05H,28H,3DH ; 1086 =.....(=
        DB      03H,0A3H,3EH,63H,18H,06H,02H,0B0H ; 108E ..>c....
        DB      21H,01H,3EH,64H,32H,00H,40H,0C9H ; 1096 !.>d2.@.
        DB      06H,40H,4EH,0FH,48H,41H,90H,18H ; 109E .@N.HA..
        DB      48H,4FH,92H,1CH,40H,58H,16H,0C4H ; 10A6 HO..@X..
        DB      0C6H,37H,48H,41H,94H,0AH,80H,4FH ; 10AE .7HA...O
        DB      40H,54H,12H,0C8H,52H,96H,0BH,80H ; 10B6 @T..R...
        DB      4EH,0C0H,44H,06H,88H,4FH,98H,80H ; 10BE N.D..O..
        DB      52H,0B0H,2EH,08H,0B0H,2EH,01H,3EH ; 10C6 R......>
        DB      65H,18H,0C9H,3EH,66H,18H,0C5H,06H ; 10CE e..>f...
        DB      44H,0C6H,0FEH,44H,2EH,09H,44H,45H ; 10D6 D..D..DE
        DB      10H,34H,25H,19H,0B3H,22H,84H,0C6H ; 10DE .4%.."..
        DB      44H,0C6H,0FEH,44H,45H,03H,0B3H,24H ; 10E6 D..DE..$
        DB      44H,2BH,03H,04H,2DH,84H,0C6H,34H ; 10EE D+..-..4
        DB      0C6H,1AH,0B3H,18H,0CDH,0C7H,2DH,0DAH ; 10F6 ......-.
        DB      0E7H,0FH,3EH,89H,0C3H,58H,11H,0CDH ; 10FE ..>..X..
        DB      1BH,11H,0CDH,94H,26H,38H,07H,3EH ; 1106 ....&8.>
        DB      8EH,18H,05H,0CDH,1BH,11H,3EH,8AH ; 110E ......>.
        DB      0EH,05H,0C3H,5FH,11H,11H,03H,40H ; 1116 ..._...@
        DB      0CDH,1BH,2EH,11H,03H,40H,0C3H,0AEH ; 111E .....@..
        DB      26H,40H,27H,03H,0C3H,43H,44H,30H ; 1126 &@'..CD0
        DB      0FEH,44H,31H,0FBH,0B3H,22H,40H,27H ; 112E .D1.."@'
        DB      03H,0C3H,36H,44H,0C6H,0FEH,44H,41H ; 1136 ..6D..DA
        DB      0FBH,44H,42H,0F8H,44H,43H,0F5H,44H ; 113E .DB.DC.D
        DB      44H,0F2H,44H,45H,0EFH,44H,46H,0ECH ; 1146 D.DE.DF.
        DB      0B3H,01H,0CDH,99H,2DH,18H,03H,0CDH ; 114E ....-...
        DB      82H,2DH,22H,03H,40H,3EH,89H,0EH ; 1156 .-".@>..
        DB      02H,32H,00H,40H,79H,32H,02H,40H ; 115E .2.@y2.@
        DB      0C9H,44H,48H,0CBH,44H,42H,0BBH,86H ; 1166 .DH.DB..
        DB      44H,0C9H,0FEH,44H,0C6H,0FBH,30H,25H ; 116E D..D..0%
        DB      0CH,30H,24H,0DH,30H,26H,0EH,30H ; 1176 .0$.0&.0
        DB      3AH,0FH,0B3H,1AH,06H,81H,18H,0AH ; 117E :.......
        DB      06H,83H,18H,06H,06H,85H,18H,02H ; 1186 ........
        DB      06H,84H,3AH,02H,40H,0FEH,03H,78H ; 118E ..:.@..x
        DB      38H,53H,0C3H,0E7H,0FH,3AH,02H,40H ; 1196 8S...:.@
        DB      0FEH,02H,38H,32H,0EDH,5BH,03H,40H ; 119E ..82.[.@
        DB      20H,30H,21H,49H,46H,0EDH,52H,28H ; 11A6  0!IF.R(
        DB      20H,21H,4FH,4EH,0A7H,0EDH,52H,28H ; 11AE  !ON..R(
        DB      18H,21H,54H,4FH,0A7H,0EDH,52H,28H ; 11B6 .!TO..R(
        DB      10H,21H,49H,4EH,0A7H,0EDH,52H,28H ; 11BE .!IN..R(
        DB      08H,21H,41H,54H,0A7H,0EDH,52H,20H ; 11C6 .!AT..R
        DB      05H,3EH,20H,0C3H,9AH,10H,3EH,82H ; 11CE .> ...>.
        DB      18H,13H,0FEH,05H,30H,0F3H,21H,46H ; 11D6 ....0.!F
        DB      4EH,0A7H,0EDH,52H,20H,0EBH,3EH,86H ; 11DE N..R .>.
        DB      2AH,05H,40H,18H,03H,2AH,03H,40H ; 11E6 *.@..*.@
        DB      32H,00H,40H,0CDH,6FH,21H,22H,03H ; 11EE 2.@.o!".
        DB      40H,0C9H                ; 11F6 @.
L11F8:
        PUSH    HL                      ; 11F8  e5
        CALL    L3645                   ; 11F9  cd4536
        AND     7FH                     ; 11FC  e67f
        LD      HL,41C2H                ; 11FE  21c241
        RES     4,(HL)                  ; 1201  cba6
        CP      61H                     ; 1203  fe61
        JR      c,L120F                 ; 1205  3808
        CP      7BH                     ; 1207  fe7b
        JR      nc,L120F                ; 1209  3004
        SET     4,(HL)                  ; 120B  cbe6
        SUB     20H                     ; 120D  d620
L120F:
        LD      HL,(4088H)              ; 120F  2a8840
        LD      C,A                     ; 1212  4f
        LD      A,H                     ; 1213  7c
        OR      L                       ; 1214  b5
        JR      nz,L121A                ; 1215  2003
        LD      HL,408AH                ; 1217  218a40
L121A:
        LD      (HL),C                  ; 121A  71
        INC     HL                      ; 121B  23
        LD      (4088H),HL              ; 121C  228840
        LD      A,C                     ; 121F  79
        PUSH    AF                      ; 1220  f5
        CP      1EH                     ; 1221  fe1e
        LD      B,20H                   ; 1223  0620
        JR      z,L1244                 ; 1225  281d
        SUB     20H                     ; 1227  d620
        JR      c,L1247                 ; 1229  381c
        CP      21H                     ; 122B  fe21
        JR      c,L123B                 ; 122D  380c
        CP      3BH                     ; 122F  fe3b
        LD      B,49H                   ; 1231  0649
        JR      c,L1244                 ; 1233  380f
        SUB     1AH                     ; 1235  d61a
        CP      26H                     ; 1237  fe26
        JR      nc,L1247                ; 1239  300c
L123B:
        LD      HL,124BH                ; 123B  214b12
        ADD     A,L                     ; 123E  85
        LD      L,A                     ; 123F  6f
        JR      nc,L1243                ; 1240  3001
        INC     H                       ; 1242  24
L1243:
        LD      B,(HL)                  ; 1243  46
L1244:
        POP     AF                      ; 1244  f1
        POP     HL                      ; 1245  e1
        RET                             ; 1246  c9
L1247:
        LD      B,0FFH                  ; 1247  06ff
        JR      L1244                   ; 1249  18f9
        DB      00H,4AH,40H,28H,03H,04H,05H,40H ; 124B .J@(...@
        DB      21H,22H,41H,42H,23H,43H,44H,45H ; 1253 !"AB#CDE
        DB      46H,46H,46H,46H,46H,46H,46H,46H ; 125B FFFFFFFF
        DB      46H,46H,29H,24H,47H,25H,48H,07H ; 1263 FF)$G%H.
        DB      08H,26H,09H,27H,0AH,0BH ; 126B .&.'..

;=====================================================================
; OPTAB: SPRUNGTABELLE DER LAUFZEIT
; Opcode (gerade Zahl) / 2 = Eintrag. Je Eintrag Adresse der
; Ausfuehrungsroutine. Der Kommentar nennt das Schluesselwort, dessen
; Syntaxaktion diesen Opcode erzeugt (sofern eindeutig erkennbar).
;=====================================================================
OPTAB:
        DW      L25E9                   ; 1271 Opcode 00H
        DW      L25EA                   ; 1273 Opcode 02H
        DW      L2621                   ; 1275 Opcode 04H
        DW      L2622                   ; 1277 Opcode 06H
        DW      FP_POWER_ENTRY          ; 1279 Opcode 08H
        DW      FP_POWER_DISPATCH       ; 127B Opcode 0AH
        DW      L25DB                   ; 127D Opcode 0CH
        DW      L2607                   ; 127F Opcode 0EH
        DW      L15E2                   ; 1281 Opcode 10H
        DW      X_SCR                   ; 1283 Opcode 12H SCR
        DW      L15F0                   ; 1285 Opcode 14H
        DW      L15F9                   ; 1287 Opcode 16H
        DW      L1602                   ; 1289 Opcode 18H
        DW      L161B                   ; 128B Opcode 1AH
        DW      L160C                   ; 128D Opcode 1CH
        DW      L15C1                   ; 128F Opcode 1EH
        DW      L15D1                   ; 1291 Opcode 20H
        DW      L19EE                   ; 1293 Opcode 22H
        DW      X_RSI                   ; 1295 Opcode 24H RSI
        DW      L195D                   ; 1297 Opcode 26H
        DW      L1966                   ; 1299 Opcode 28H
        DW      X_ABS                   ; 129B Opcode 2AH ABS
        DW      X_ATN                   ; 129D Opcode 2CH ATN
        DW      X_COS                   ; 129F Opcode 2EH COS
        DW      X_EXP                   ; 12A1 Opcode 30H EXP
        DW      X_INT                   ; 12A3 Opcode 32H INT
        DW      X_LOG                   ; 12A5 Opcode 34H LOG
        DW      X_SGN                   ; 12A7 Opcode 36H SGN
        DW      X_SIN                   ; 12A9 Opcode 38H SIN
        DW      X_SQR                   ; 12AB Opcode 3AH SQR
        DW      L1849                   ; 12AD Opcode 3CH
        DW      L1881                   ; 12AF Opcode 3EH
        DW      X_TOP                   ; 12B1 Opcode 40H TOP
        DW      X_SIZE                  ; 12B3 Opcode 42H SIZE
        DW      X_RND                   ; 12B5 Opcode 44H RND
        DW      X_LEN                   ; 12B7 Opcode 46H LEN
        DW      X_PEEK                  ; 12B9 Opcode 48H PEEK
        DW      X_DEEK                  ; 12BB Opcode 4AH DEEK
        DW      X_IN                    ; 12BD Opcode 4CH IN
        DW      L15D0                   ; 12BF Opcode 4EH
        DW      X_RIGHT                 ; 12C1 Opcode 50H RIGHT
        DW      X_LEFT                  ; 12C3 Opcode 52H LEFT
        DW      L1CE8                   ; 12C5 Opcode 54H
        DW      X_CHR                   ; 12C7 Opcode 56H CHR
        DW      X_STR                   ; 12C9 Opcode 58H STR
        DW      X_ASC                   ; 12CB Opcode 5AH ASC
        DW      X_VAL                   ; 12CD Opcode 5CH VAL
        DW      L1D0D                   ; 12CF Opcode 5EH
        DW      L1B8F                   ; 12D1 Opcode 60H
        DW      L1BE5                   ; 12D3 Opcode 62H
        DW      L1BF5                   ; 12D5 Opcode 64H
        DW      X_PAGE                  ; 12D7 Opcode 66H PAGE
        DW      X_SKIP                  ; 12D9 Opcode 68H SKIP
        DW      X_COL                   ; 12DB Opcode 6AH COL
        DW      X_TAB                   ; 12DD Opcode 6CH TAB
        DW      X_FIX                   ; 12DF Opcode 6EH FIX
        DW      X_FLO                   ; 12E1 Opcode 70H FLO
        DW      X_BIN                   ; 12E3 Opcode 72H BIN
        DW      X_HEX                   ; 12E5 Opcode 74H HEX
        DW      L1AF6                   ; 12E7 Opcode 76H
        DW      L1B62                   ; 12E9 Opcode 78H
        DW      L1AE7                   ; 12EB Opcode 7AH
        DW      L1B56                   ; 12ED Opcode 7CH
        DW      X_INCHAR                ; 12EF Opcode 7EH INCHAR
        DW      X_FOR                   ; 12F1 Opcode 80H FOR
        DW      L1805                   ; 12F3 Opcode 82H
        DW      L1815                   ; 12F5 Opcode 84H
        DW      X_GOTO                  ; 12F7 Opcode 86H GOTO
        DW      X_GOSUB                 ; 12F9 Opcode 88H GOSUB
        DW      L1935                   ; 12FB Opcode 8AH
        DW      L1909                   ; 12FD Opcode 8CH
        DW      X_RETURN                ; 12FF Opcode 8EH RETURN
        DW      X_STOP                  ; 1301 Opcode 90H STOP
        DW      L1D50                   ; 1303 Opcode 92H
        DW      X_ASGN                  ; 1305 Opcode 94H ASGN
        DW      L1739                   ; 1307 Opcode 96H
        DW      X_RESTORE               ; 1309 Opcode 98H RESTORE
        DW      X_CALL                  ; 130B Opcode 9AH CALL
        DW      X_OUTCHAR               ; 130D Opcode 9CH OUTCHAR
        DW      X_POKE                  ; 130F Opcode 9EH POKE
        DW      X_DOKE                  ; 1311 Opcode A0H DOKE
        DW      X_OUT                   ; 1313 Opcode A2H OUT
        DW      X_GET                   ; 1315 Opcode A4H GET,PUT
        DW      L1C85                   ; 1317 Opcode A6H
        DW      L1C9F                   ; 1319 Opcode A8H
        DW      L1C58                   ; 131B Opcode AAH
        DW      L1C77                   ; 131D Opcode ACH
        DW      X_OPEN                  ; 131F Opcode AEH OPEN
        DW      X_CLOSE                 ; 1321 Opcode B0H CLOSE
        DW      L18B2                   ; 1323 Opcode B2H
        DW      X_ERRN                  ; 1325 Opcode B4H ERRN
        DW      X_ERLN                  ; 1327 Opcode B6H ERLN
        DW      OP_PLOT                 ; 1329 Opcode B8H PLOT
        DW      OP_DOT                  ; 132B Opcode BAH DOT
        DW      OP_CDOT                 ; 132D Opcode BCH CDOT
        DW      OP_LINE                 ; 132F Opcode BEH LINE
        DW      OP_CLINE                ; 1331 Opcode C0H CLINE
        DW      OP_FILL                 ; 1333 Opcode C2H FILL
        DW      OP_TEST                 ; 1335 Opcode C4H TEST
        DW      X_CLS                   ; 1337 Opcode C6H CLS
        DW      X_GLS                   ; 1339 Opcode C8H GLS
        DW      X_GLOAD                 ; 133B Opcode CAH GLOAD
        DW      X_GSAVE                 ; 133D Opcode CCH GSAVE
        DW      X_TEXT                  ; 133F Opcode CEH TEXT
        DW      OP_GSUB                 ; 1341 Opcode D0H
L1343:
        CALL    L224D                   ; 1343  cd4d22
L1346:
        CALL    L225F                   ; 1346  cd5f22
        RET     z                       ; 1349  c8
L134A:
        XOR     A                       ; 134A  af
L134B:
        LD      (41B9H),A               ; 134B  32b941
        CALL    L226A                   ; 134E  cd6a22
        JR      nz,L1361                ; 1351  200e
L1353:
        LD      A,(41B9H)               ; 1353  3ab941
        AND     A                       ; 1356  a7
        RET     z                       ; 1357  c8
        CALL    L35BF                   ; 1358  cdbf35
        LD      HL,MSG_NOSRC            ; 135B  215734
        JP      L35DB                   ; 135E  c3db35
L1361:
        PUSH    HL                      ; 1361  e5
        LD      HL,4                    ; 1362  210400
        ADD     HL,BC                   ; 1365  09
        LD      E,(HL)                  ; 1366  5e
        INC     HL                      ; 1367  23
        LD      D,(HL)                  ; 1368  56
        EX      DE,HL                   ; 1369  eb
        LD      A,H                     ; 136A  7c
        OR      L                       ; 136B  b5
        JR      nz,L1387                ; 136C  2019
        LD      A,(41B9H)               ; 136E  3ab941
        AND     A                       ; 1371  a7
        CALL    nz,L35BF                ; 1372  c4bf35
        POP     HL                      ; 1375  e1
        LD      IY,(41F1H)              ; 1376  fd2af141
        CALL    L255D                   ; 137A  cd5d25
        CALL    L34B7                   ; 137D  cdb734
        CALL    LINE_NEXT               ; 1380  cd1f33
        LD      A,1                     ; 1383  3e01
        JR      L134B                   ; 1385  18c4
L1387:
        EX      (SP),HL                 ; 1387  e3
        PUSH    HL                      ; 1388  e5
        CALL    L1353                   ; 1389  cd5313
        LD      HL,41C1H                ; 138C  21c141
        BIT     5,(HL)                  ; 138F  cb6e
        JR      z,L1399                 ; 1391  2806
        LD      IY,(41F3H)              ; 1393  fd2af341
        JR      L13A6                   ; 1397  180d
L1399:
        LD      HL,41C2H                ; 1399  21c241
        BIT     2,(HL)                  ; 139C  cb56
        JR      z,L13A6                 ; 139E  2806
        RES     2,(HL)                  ; 13A0  cb96
        LD      IY,4204H                ; 13A2  fd210442
L13A6:
        POP     HL                      ; 13A6  e1
        CALL    L255D                   ; 13A7  cd5d25
        POP     HL                      ; 13AA  e1
        CALL    L239E                   ; 13AB  cd9e23
        CALL    L34B7                   ; 13AE  cdb734
        CALL    LINE_NEXT               ; 13B1  cd1f33
        JR      L134A                   ; 13B4  1894
        DB      21H,0C1H,41H,0CBH,0EEH,0FDH,2AH,0F3H ; 13B6 !.A...*.
        DB      41H,0CDH,83H,35H,0CDH,43H,13H,21H ; 13BE A..5.C.!
        DB      9DH,34H,0CDH,08H,36H,21H,0C1H,41H ; 13C6 .4..6!.A
        DB      0CBH,0AEH,0C3H,0ABH,35H,21H,0C1H,41H ; 13CE ....5!.A
        DB      0CBH,0EEH,0FDH,2AH,0F7H,41H,0FDH,0CBH ; 13D6 ...*.A..
        DB      00H,46H,0CCH,83H,35H,0C3H,59H,01H ; 13DE .F..5.Y.
        DB      2AH,0B9H,41H,7CH,0B5H,20H,03H,21H ; 13E6 *.A|. .!
        DB      64H,00H,22H,0BDH,41H,2AH,0BBH,41H ; 13EE d.".A*.A
        DB      7CH,0B5H,20H,03H,21H,0AH,00H,22H ; 13F6 |. .!.."
        DB      0BFH,41H,0C9H,0CDH,4DH,22H,0CDH,5FH ; 13FE .A..M"._
        DB      22H,0C8H,0CDH,6AH,22H,0C8H,22H,8CH ; 1406 "..j".".
        DB      41H,0CDH,7EH,22H,18H,0F4H,0C3H,5EH ; 140E A.~"...^
        DB      37H,0CDH,4DH,22H,0CDH,8FH,14H,0CDH ; 1416 7.M"....
        DB      5FH,22H,0CAH,76H,15H,3EH,07H,0CDH ; 141E _".v.>..
        DB      6CH,22H,0CAH,76H,15H,0F5H,0CDH,3AH ; 1426 l".v...:
        DB      14H,0F1H,0CBH,4FH,0C2H,76H,15H,0CDH ; 142E ...O.v..
        DB      26H,33H,18H,0E9H        ; 1436 &3..
L143A:
        LD      HL,6                    ; 143A  210600
        ADD     HL,BC                   ; 143D  09
        LD      E,(HL)                  ; 143E  5e
        INC     HL                      ; 143F  23
        LD      D,(HL)                  ; 1440  56
        LD      A,D                     ; 1441  7a
        OR      E                       ; 1442  b3
        LD      (41DAH),BC              ; 1443  ed43da41
        JR      z,L145C                 ; 1447  2813
        PUSH    DE                      ; 1449  d5
        POP     IX                      ; 144A  dde1
        LD      A,E                     ; 144C  7b
        ADD     A,(IX)                  ; 144D  dd8600
        INC     IX                      ; 1450  dd23
        INC     A                       ; 1452  3c
        LD      (41DCH),A               ; 1453  32dc41
        CALL    L34B7                   ; 1456  cdb734
        CALL    RUNLOOP                 ; 1459  cd6014
L145C:
        LD      HL,(41DAH)              ; 145C  2ada41
        RET                             ; 145F  c9

;=====================================================================
; LAUFZEITSCHLEIFE (RUNLOOP)
; IX zeigt in den Zwischencode. Opcode holen, ueber OPTAB springen.
; Die Routinen X_xxx kehren mit RET hierher zurueck.
;=====================================================================
RUNLOOP:
        LD      A,(41DCH)               ; 1460  3adc41
        CP      IXL                     ; 1463  ddbd
        RET     z                       ; 1465  c8
        LD      A,(IX)                  ; 1466  dd7e00
        CP      0FFH                    ; 1469  feff
        INC     IX                      ; 146B  dd23
        RET     z                       ; 146D  c8
        LD      HL,OPTAB                ; 146E  217112
        ADD     A,L                     ; 1471  85
        LD      L,A                     ; 1472  6f
        JR      nc,L1476                ; 1473  3001
        INC     H                       ; 1475  24
L1476:
        LD      E,(HL)                  ; 1476  5e
        INC     HL                      ; 1477  23
        LD      D,(HL)                  ; 1478  56
        LD      HL,RUNLOOP              ; 1479  216014
        PUSH    HL                      ; 147C  e5
        PUSH    DE                      ; 147D  d5
        LD      A,(IX-1)                ; 147E  dd7eff
        CP      19H                     ; 1481  fe19
        RET     nc                      ; 1483  d0
        CP      15                      ; 1484  fe0f
        JP      c,L1EDE                 ; 1486  dade1e
        CALL    L1EDE                   ; 1489  cdde1e
        JP      L1F1B                   ; 148C  c31b1f
        DB      0EDH,4BH,0B2H,41H,78H,0B1H,0C4H,2CH ; 148F .K.Ax..,
        DB      17H,0AFH,32H,02H,40H,32H,0E4H,41H ; 1497 ..2.@2.A
        DB      21H,0C1H,41H,0CBH,0CEH,0CBH,0A6H,0CBH ; 149F !.A.....
        DB      56H,0C0H,21H,0A6H,41H,0CDH,45H,15H ; 14A7 V.!.A.E.
        DB      28H,08H,71H,23H,70H,0CDH,40H,15H ; 14AF (.q#p.@.
        DB      20H,0F8H,21H,0AAH,41H,0CDH,45H,15H ; 14B7  .!.A.E.
        DB      28H,08H,71H,23H,70H,0CDH,40H,15H ; 14BF (.q#p.@.
        DB      20H,0F8H,21H,0A8H,41H,11H,0AAH,41H ; 14C7  .!.A..A
        DB      0CDH,48H,15H,28H,0FH,0EBH,21H,06H ; 14CF .H.(..!.
        DB      00H,09H,01H,02H,00H,0EDH,0B0H,0CDH ; 14D7 ........
        DB      40H,15H,20H,0F1H,21H,00H,00H,0E5H ; 14DF @. .!...
        DB      21H,0B0H,41H,0CDH,26H,33H,0E5H,22H ; 14E7 !.A.&3."
        DB      0DAH,41H,01H,06H,00H,09H,7EH,23H ; 14EF .A....~#
        DB      66H,6FH,23H,7EH,23H,5EH,23H,56H ; 14F7 fo#~#^#V
        DB      0FEH,80H,20H,03H,0D5H,18H,25H,0FEH ; 14FF .. ...%.
        DB      82H,0E1H,20H,20H,0E3H,0A7H,0EDH,52H ; 1507 ..  ...R
        DB      20H,24H,0D1H,0E1H,0E5H,09H,7EH,23H ; 150F  $....~#
        DB      66H,6FH,09H,73H,23H,72H,0E1H,0EBH ; 1517 fo.s#r..
        DB      09H,7EH,23H,66H,6FH,23H,23H,23H ; 151F .~#fo###
        DB      23H,73H,23H,72H,0CDH,1FH,33H,20H ; 1527 #s#r..3
        DB      0BDH,0E1H,7CH,0B5H,28H,05H,3EH,15H ; 152F ..|.(.>.
        DB      0C3H,59H,33H,21H,0C1H,41H,0CBH,0D6H ; 1537 .Y3!.A..
        DB      0C9H,0CDH,1FH,33H,18H,0AH,11H,0B0H ; 153F ...3....
        DB      41H,0EDH,53H,0C3H,41H,0CDH,26H,33H ; 1547 A.S.A.&3
        DB      0C8H,22H,0DAH,41H,23H,23H,23H,23H ; 154F .".A####
        DB      4EH,23H,46H,23H,0E5H,2AH,9AH,41H ; 1557 N#F#.*.A
        DB      0E5H,60H,69H,3EH,02H,0EDH,5BH,0C3H ; 155F .`i>..[.
        DB      41H,0CDH,35H,33H,0E1H,22H,9AH,41H ; 1567 A.53.".A
        DB      0E1H,0C0H,3EH,14H,0C3H,59H,33H ; 156F ..>..Y3
X_STOP:
        LD      HL,41ACH                ; 1576  21ac41
        CALL    LINE_SET                ; 1579  cd2633
        JR      z,L1592                 ; 157C  2814
L157E:
        INC     HL                      ; 157E  23
        INC     HL                      ; 157F  23
        INC     HL                      ; 1580  23
        LD      A,(HL)                  ; 1581  7e
        AND     A                       ; 1582  a7
        JR      nz,L158D                ; 1583  2008
        DEC     HL                      ; 1585  2b
        LD      A,(HL)                  ; 1586  7e
        CP      4                       ; 1587  fe04
        JR      nc,L158D                ; 1589  3002
        LD      (HL),0ADH               ; 158B  36ad
L158D:
        CALL    LINE_NEXT               ; 158D  cd1f33
        JR      nz,L157E                ; 1590  20ec
L1592:
        LD      HL,41C1H                ; 1592  21c141
        RES     1,(HL)                  ; 1595  cb8e
        JP      L0258                   ; 1597  c35802
        DB      21H,9EH,41H,06H,16H,36H,00H,23H ; 159A !.A..6.#
        DB      10H,0FBH,21H,0ADH,43H,22H,9CH,41H ; 15A2 ..!.C".A
        DB      0AFH,32H,0C1H,41H,21H,0DH,42H,22H ; 15AA .2.A!.B"
        DB      0F1H,41H,22H,0F3H,41H,21H,0FBH,41H ; 15B2 .A".A!.A
        DB      22H,0F7H,41H,0C3H,6DH,04H,0C9H ; 15BA ".A.m..

;=====================================================================
; AUSFUEHRUNGSROUTINEN (X_xxx) DER BEFEHLE UND FUNKTIONEN
; Ausdruecke liegen als Postfix-Zwischencode vor; das Ergebnis steht
; im Gleitkomma-Akku FAC (42E2H, 5 Byte), Typ in FAC_TYPE (42E1H).
;=====================================================================
L15C1:
        CALL    L1E97                   ; 15C1  cd971e
L15C4:
        LD      HL,FAC_TYPE             ; 15C4  21e142
        JR      c,L15CD                 ; 15C7  3804
        AND     3                       ; 15C9  e603
        LD      (HL),A                  ; 15CB  77
        INC     HL                      ; 15CC  23
L15CD:
        EX      DE,HL                   ; 15CD  eb
        LDIR                            ; 15CE  edb0
L15D0:
        RET                             ; 15D0  c9
L15D1:
        CALL    L1E97                   ; 15D1  cd971e
L15D4:
        PUSH    BC                      ; 15D4  c5
        CALL    nc,L1F54                ; 15D5  d4541f
        POP     BC                      ; 15D8  c1
        LD      HL,FAC                  ; 15D9  21e242
        JR      nc,L15DF                ; 15DC  3001
        DEC     HL                      ; 15DE  2b
L15DF:
        LDIR                            ; 15DF  edb0
        RET                             ; 15E1  c9
L15E2:
        LD      A,L                     ; 15E2  7d
        AND     E                       ; 15E3  a3
        LD      L,A                     ; 15E4  6f
        LD      A,H                     ; 15E5  7c
        AND     D                       ; 15E6  a2
        JR      L1607                   ; 15E7  181e
X_SCR:
        LD      A,L                     ; 15E9  7d
        OR      E                       ; 15EA  b3
        LD      L,A                     ; 15EB  6f
        LD      A,H                     ; 15EC  7c
        OR      D                       ; 15ED  b2
        JR      L1607                   ; 15EE  1817
L15F0:
        LD      A,L                     ; 15F0  7d
        AND     E                       ; 15F1  a3
        CPL                             ; 15F2  2f
        LD      L,A                     ; 15F3  6f
        LD      A,H                     ; 15F4  7c
        AND     D                       ; 15F5  a2
        CPL                             ; 15F6  2f
        JR      L1607                   ; 15F7  180e
L15F9:
        LD      A,L                     ; 15F9  7d
        OR      E                       ; 15FA  b3
        CPL                             ; 15FB  2f
        LD      L,A                     ; 15FC  6f
        LD      A,H                     ; 15FD  7c
        OR      D                       ; 15FE  b2
        CPL                             ; 15FF  2f
        JR      L1607                   ; 1600  1805
L1602:
        LD      A,L                     ; 1602  7d
        XOR     E                       ; 1603  ab
        LD      L,A                     ; 1604  6f
        LD      A,H                     ; 1605  7c
        XOR     D                       ; 1606  aa
L1607:
        LD      H,A                     ; 1607  67
        LD      (FAC),HL                ; 1608  22e242
        RET                             ; 160B  c9
L160C:
        CALL    FAC_TO_INT              ; 160C  cd851f
        LD      DE,0FFFFH               ; 160F  11ffff
        EX      DE,HL                   ; 1612  eb
        JR      L1629                   ; 1613  1814
; ---- ABS: Betrag typabhaengig; Integer -32768 bleibt 8000H (kein Ueberlauftest).
X_ABS:
        CALL    L1FD1                   ; 1615  cdd11f
        BIT     0,C                     ; 1618  cb41
        RET     z                       ; 161A  c8
L161B:
        LD      A,(FAC_TYPE)            ; 161B  3ae142
        DEC     A                       ; 161E  3d
        JP      nz,FP_NEG               ; 161F  c24729
        LD      DE,(FAC)                ; 1622  ed5be242
        LD      HL,0                    ; 1626  210000
L1629:
        AND     A                       ; 1629  a7
        SBC     HL,DE                   ; 162A  ed52
        LD      (FAC),HL                ; 162C  22e242
        RET                             ; 162F  c9
X_CALL:
        CALL    FAC_TO_INT              ; 1630  cd851f
        LD      DE,163AH                ; 1633  113a16
        PUSH    IX                      ; 1636  dde5
        PUSH    DE                      ; 1638  d5
        JP      (HL)                    ; 1639  e9
        DB      0DDH,0E1H,0C9H          ; 163A ...
X_OUTCHAR:
        CALL    FAC_TO_INT              ; 163D  cd851f
        LD      A,L                     ; 1640  7d
        JP      L35F7                   ; 1641  c3f735
X_POKE:
        CALL    FAC_TO_INT              ; 1644  cd851f
        PUSH    HL                      ; 1647  e5
        CALL    EVAL_INT                ; 1648  cd821f
        POP     DE                      ; 164B  d1
        LD      (HL),E                  ; 164C  73
        RET                             ; 164D  c9
X_DOKE:
        CALL    FAC_TO_INT              ; 164E  cd851f
        PUSH    HL                      ; 1651  e5
        CALL    EVAL_INT                ; 1652  cd821f
        POP     DE                      ; 1655  d1
        LD      (HL),E                  ; 1656  73
        INC     HL                      ; 1657  23
        LD      (HL),D                  ; 1658  72
        RET                             ; 1659  c9
X_OUT:
        CALL    FAC_TO_INT              ; 165A  cd851f
        PUSH    HL                      ; 165D  e5
        CALL    EVAL_INT                ; 165E  cd821f
        LD      C,L                     ; 1661  4d
        POP     HL                      ; 1662  e1
        OUT     (C),L                   ; 1663  ed69
        RET                             ; 1665  c9
; ---- SGN: Integerergebnis -1, 0 oder +1; Vorzeichenklassifikation in C.
X_SGN:
        CALL    L1FD1                   ; 1666  cdd11f
        LD      A,C                     ; 1669  79
        LD      HL,0FFFFH               ; 166A  21ffff
        RRA                             ; 166D  1f
        JR      c,L16C9                 ; 166E  3859
        INC     HL                      ; 1670  23
        RRA                             ; 1671  1f
        JR      c,L16C9                 ; 1672  3855
        INC     HL                      ; 1674  23
        JR      L16C9                   ; 1675  1852
X_TOP:
        LD      HL,(41B7H)              ; 1677  2ab741
        JR      L16C9                   ; 167A  184d
X_SIZE:
        LD      HL,(41B7H)              ; 167C  2ab741
        LD      DE,(419CH)              ; 167F  ed5b9c41
        AND     A                       ; 1683  a7
        SBC     HL,DE                   ; 1684  ed52
        JR      L16C9                   ; 1686  1841
X_LEN:
        CALL    L1E80                   ; 1688  cd801e
        LD      L,B                     ; 168B  68
        JR      L16C7                   ; 168C  1839
X_DEEK:
        CALL    FAC_TO_INT              ; 168E  cd851f
        LD      E,(HL)                  ; 1691  5e
        INC     HL                      ; 1692  23
        LD      D,(HL)                  ; 1693  56
        EX      DE,HL                   ; 1694  eb
        JR      L16C9                   ; 1695  1832
X_ASC:
        CALL    L1E80                   ; 1697  cd801e
        DEC     B                       ; 169A  05
        LD      A,24H                   ; 169B  3e24
        JP      nz,ERROR                ; 169D  c25933
        EX      DE,HL                   ; 16A0  eb
        CALL    L1BBF                   ; 16A1  cdbf1b
        JR      L16C6                   ; 16A4  1820
X_VAL:
        CALL    L1E80                   ; 16A6  cd801e
        LD      A,B                     ; 16A9  78
        ADD     A,E                     ; 16AA  83
        LD      L,A                     ; 16AB  6f
        LD      A,0                     ; 16AC  3e00
        ADC     A,D                     ; 16AE  8a
        LD      H,A                     ; 16AF  67
        LD      A,(HL)                  ; 16B0  7e
        LD      (HL),1EH                ; 16B1  361e
        PUSH    HL                      ; 16B3  e5
        PUSH    AF                      ; 16B4  f5
        CALL    FP_PARSE_DECIMAL        ; 16B5  cd1b2e
        POP     BC                      ; 16B8  c1
        POP     HL                      ; 16B9  e1
        LD      (HL),B                  ; 16BA  70
        LD      A,2                     ; 16BB  3e02
        LD      (FAC_TYPE),A            ; 16BD  32e142
        JP      L1BBF                   ; 16C0  c3bf1b
X_PEEK:
        CALL    FAC_TO_INT              ; 16C3  cd851f
L16C6:
        LD      L,(HL)                  ; 16C6  6e
L16C7:
        LD      H,0                     ; 16C7  2600
L16C9:
        JP      L1F6E                   ; 16C9  c36e1f
X_IN:
        CALL    FAC_TO_INT              ; 16CC  cd851f
        LD      C,L                     ; 16CF  4d
        IN      L,(C)                   ; 16D0  ed68
        JR      L16C7                   ; 16D2  18f3
X_INCHAR:
        LD      IY,(41F7H)              ; 16D4  fd2af741
        LD      A,IYL                   ; 16D8  fd7d
        SUB     0FBH                    ; 16DA  d6fb
        JR      z,L16E3                 ; 16DC  2805
        CALL    L3550                   ; 16DE  cd5035
        JR      L16F4                   ; 16E1  1811
L16E3:
        LD      A,(41E4H)               ; 16E3  3ae441
        LD      L,A                     ; 16E6  6f
        XOR     A                       ; 16E7  af
        LD      (41E4H),A               ; 16E8  32e441
        OR      L                       ; 16EB  b5
        JR      nz,L16C7                ; 16EC  20d9
L16EE:
        CALL    L356D                   ; 16EE  cd6d35
        AND     A                       ; 16F1  a7
        JR      z,L16EE                 ; 16F2  28fa
L16F4:
        LD      L,A                     ; 16F4  6f
        JR      L16C7                   ; 16F5  18d0
X_ERRN:
        LD      A,(41E3H)               ; 16F7  3ae341
        JR      L16F4                   ; 16FA  18f8
X_ERLN:
        LD      HL,(41E1H)              ; 16FC  2ae141
        JR      L16C9                   ; 16FF  18c8
X_RESTORE:
        CALL    FETCH_WORD              ; 1701  cd661e
        LD      A,H                     ; 1704  7c
        OR      L                       ; 1705  b5
        LD      BC,(41B2H)              ; 1706  ed4bb241
        JR      z,L1728                 ; 170A  281c
        LD      DE,6                    ; 170C  110600
        ADD     HL,DE                   ; 170F  19
        LD      E,(HL)                  ; 1710  5e
        INC     HL                      ; 1711  23
        LD      D,(HL)                  ; 1712  56
        LD      HL,2                    ; 1713  210200
        ADD     HL,DE                   ; 1716  19
        LD      E,(HL)                  ; 1717  5e
        INC     HL                      ; 1718  23
        LD      D,(HL)                  ; 1719  56
        EX      DE,HL                   ; 171A  eb
        LD      DE,41B2H                ; 171B  11b241
        LD      A,2                     ; 171E  3e02
        CALL    LINE_FIND               ; 1720  cd3533
L1723:
        LD      A,40H                   ; 1723  3e40
        JP      z,ERROR                 ; 1725  ca5933
L1728:
        LD      A,B                     ; 1728  78
        OR      C                       ; 1729  b1
        JR      z,L1723                 ; 172A  28f7
L172C:
        LD      HL,4                    ; 172C  210400
        ADD     HL,BC                   ; 172F  09
        LD      (41DEH),HL              ; 1730  22de41
        LD      A,1                     ; 1733  3e01
        LD      (41E0H),A               ; 1735  32e041
        RET                             ; 1738  c9
L1739:
        LD      HL,(41DEH)              ; 1739  2ade41
        LD      A,H                     ; 173C  7c
        OR      L                       ; 173D  b5
        JR      z,L1754                 ; 173E  2814
        LD      A,(41E0H)               ; 1740  3ae041
        DEC     A                       ; 1743  3d
        CP      (HL)                    ; 1744  be
        INC     A                       ; 1745  3c
        INC     A                       ; 1746  3c
        LD      (41E0H),A               ; 1747  32e041
        JR      c,L175E                 ; 174A  3812
        DEC     HL                      ; 174C  2b
        DEC     HL                      ; 174D  2b
        DEC     HL                      ; 174E  2b
        LD      B,(HL)                  ; 174F  46
        DEC     HL                      ; 1750  2b
        LD      C,(HL)                  ; 1751  4e
        LD      A,B                     ; 1752  78
        OR      C                       ; 1753  b1
L1754:
        LD      A,41H                   ; 1754  3e41
        JP      z,ERROR                 ; 1756  ca5933
        CALL    L172C                   ; 1759  cd2c17
        JR      L1739                   ; 175C  18db
L175E:
        DEC     A                       ; 175E  3d
        DEC     HL                      ; 175F  2b
        ADD     A,A                     ; 1760  87
        ADD     A,L                     ; 1761  85
        LD      L,A                     ; 1762  6f
        JR      nc,L1766                ; 1763  3001
        INC     H                       ; 1765  24
L1766:
        LD      E,(HL)                  ; 1766  5e
        INC     HL                      ; 1767  23
        LD      D,(HL)                  ; 1768  56
        LD      HL,2                    ; 1769  210200
        ADD     HL,DE                   ; 176C  19
        LD      A,3                     ; 176D  3e03
        AND     (HL)                    ; 176F  a6
        CP      3                       ; 1770  fe03
        JR      nz,L177C                ; 1772  2008
        INC     HL                      ; 1774  23
        INC     HL                      ; 1775  23
        LD      E,(HL)                  ; 1776  5e
        INC     HL                      ; 1777  23
        LD      D,(HL)                  ; 1778  56
        JP      L1B95                   ; 1779  c3951b
L177C:
        EX      DE,HL                   ; 177C  eb
        CALL    L1E74                   ; 177D  cd741e
        CALL    L1E9A                   ; 1780  cd9a1e
        CALL    L15C4                   ; 1783  cdc415
        CALL    L1E97                   ; 1786  cd971e
        PUSH    AF                      ; 1789  f5
        AND     3                       ; 178A  e603
        CP      3                       ; 178C  fe03
        LD      A,25H                   ; 178E  3e25
        JP      z,ERROR                 ; 1790  ca5933
        POP     AF                      ; 1793  f1
        JP      L15D4                   ; 1794  c3d415
X_FOR:
        PUSH    IX                      ; 1797  dde5
        LD      A,(IX+3)                ; 1799  dd7e03
        AND     A                       ; 179C  a7
        JR      nz,L17AC                ; 179D  200d
        LD      HL,1                    ; 179F  210100
        LD      (FAC_TYPE),HL           ; 17A2  22e142
        LD      (FAC),HL                ; 17A5  22e242
        LD      C,4                     ; 17A8  0e04
        JR      L17B5                   ; 17AA  1809
L17AC:
        CALL    L1FC9                   ; 17AC  cdc91f
        CALL    RUNLOOP                 ; 17AF  cd6014
        CALL    L1FD1                   ; 17B2  cdd11f
L17B5:
        POP     IX                      ; 17B5  dde1
        PUSH    BC                      ; 17B7  c5
        PUSH    IX                      ; 17B8  dde5
        LD      HL,41C1H                ; 17BA  21c141
        BIT     4,(HL)                  ; 17BD  cb66
        JR      z,L17CB                 ; 17BF  280a
        RES     4,(HL)                  ; 17C1  cba6
        CALL    L1EDE                   ; 17C3  cdde1e
        CALL    L25DB                   ; 17C6  cddb25
        JR      L17D3                   ; 17C9  1808
L17CB:
        LD      A,6                     ; 17CB  3e06
        CALL    L1FC9                   ; 17CD  cdc91f
        CALL    RUNLOOP                 ; 17D0  cd6014
L17D3:
        POP     IX                      ; 17D3  dde1
        PUSH    IX                      ; 17D5  dde5
        CALL    L15D1                   ; 17D7  cdd115
        DEC     IX                      ; 17DA  dd2b
        DEC     IX                      ; 17DC  dd2b
        LD      A,(IX+2)                ; 17DE  dd7e02
        CALL    L1FC9                   ; 17E1  cdc91f
        CALL    RUNLOOP                 ; 17E4  cd6014
        POP     IX                      ; 17E7  dde1
        CALL    L1EDE                   ; 17E9  cdde1e
        CALL    L25EA                   ; 17EC  cdea25
        CALL    L1FD1                   ; 17EF  cdd11f
        LD      A,C                     ; 17F2  79
        POP     BC                      ; 17F3  c1
        CP      C                       ; 17F4  b9
        JR      nz,L1803                ; 17F5  200c
        INC     IX                      ; 17F7  dd23
        INC     IX                      ; 17F9  dd23
        CALL    FETCH_WORD              ; 17FB  cd661e
        LD      (41DAH),HL              ; 17FE  22da41
        POP     DE                      ; 1801  d1
        RET                             ; 1802  c9
L1803:
        POP     DE                      ; 1803  d1
        RET                             ; 1804  c9
L1805:
        INC     IX                      ; 1805  dd23
        INC     IX                      ; 1807  dd23
        LD      HL,41C1H                ; 1809  21c141
        SET     4,(HL)                  ; 180C  cbe6
        CALL    FETCH_WORD              ; 180E  cd661e
        EX      DE,HL                   ; 1811  eb
        JP      L18DD                   ; 1812  c3dd18
L1815:
        LD      L,(IX)                  ; 1815  dd6e00
        INC     IX                      ; 1818  dd23
        LD      H,0                     ; 181A  2600
        PUSH    HL                      ; 181C  e5
        CALL    RUNLOOP                 ; 181D  cd6014
        CALL    FAC_TO_INT              ; 1820  cd851f
        POP     DE                      ; 1823  d1
        JR      nz,L1847                ; 1824  2021
        AND     A                       ; 1826  a7
        EX      DE,HL                   ; 1827  eb
        SBC     HL,DE                   ; 1828  ed52
        JR      c,L1847                 ; 182A  381b
        LD      A,E                     ; 182C  7b
        AND     A                       ; 182D  a7
        JR      z,L1847                 ; 182E  2817
        DEC     A                       ; 1830  3d
        JR      z,L1843                 ; 1831  2810
        LD      B,A                     ; 1833  47
L1834:
        LD      A,(IX)                  ; 1834  dd7e00
        INC     IX                      ; 1837  dd23
        AND     (IX)                    ; 1839  dda600
        INC     A                       ; 183C  3c
        JR      nz,L1834                ; 183D  20f5
        INC     IX                      ; 183F  dd23
        DJNZ    L1834                   ; 1841  10f1
L1843:
        POP     DE                      ; 1843  d1
        JP      RUNLOOP                 ; 1844  c36014
L1847:
        POP     DE                      ; 1847  d1
        RET                             ; 1848  c9
L1849:
        LD      HL,41C2H                ; 1849  21c241
        BIT     1,(HL)                  ; 184C  cb4e
        RES     1,(HL)                  ; 184E  cb8e
        JR      nz,L1854                ; 1850  2002
        POP     DE                      ; 1852  d1
        RET                             ; 1853  c9
L1854:
        CALL    FETCH_VAR               ; 1854  cd711e
        EX      DE,HL                   ; 1857  eb
        PUSH    DE                      ; 1858  d5
        LD      A,H                     ; 1859  7c
        OR      L                       ; 185A  b5
        JR      nz,L185E                ; 185B  2001
        DEC     HL                      ; 185D  2b
L185E:
        CALL    L240A                   ; 185E  cd0a24
        POP     HL                      ; 1861  e1
        LD      (HL),0                  ; 1862  3600
        DEC     HL                      ; 1864  2b
        LD      (HL),0                  ; 1865  3600
        DEC     HL                      ; 1867  2b
        DEC     HL                      ; 1868  2b
        CALL    L240A                   ; 1869  cd0a24
        LD      HL,(4192H)              ; 186C  2a9241
        LD      A,15                    ; 186F  3e0f
        AND     (HL)                    ; 1871  a6
        CP      3                       ; 1872  fe03
        DEC     IX                      ; 1874  dd2b
        DEC     IX                      ; 1876  dd2b
        JP      nz,L15D1                ; 1878  c2d115
        LD      HL,4002H                ; 187B  210240
        JP      L1B8C                   ; 187E  c38c1b
L1881:
        CALL    L2430                   ; 1881  cd3024
        LD      A,(HL)                  ; 1884  7e
        INC     HL                      ; 1885  23
        INC     HL                      ; 1886  23
        LD      E,(HL)                  ; 1887  5e
        INC     HL                      ; 1888  23
        LD      D,(HL)                  ; 1889  56
        PUSH    HL                      ; 188A  e5
        AND     15                      ; 188B  e60f
        CP      3                       ; 188D  fe03
        JR      z,L1896                 ; 188F  2805
        CALL    L1E9A                   ; 1891  cd9a1e
        JR      L189D                   ; 1894  1807
L1896:
        CALL    L1E83                   ; 1896  cd831e
        LD      C,B                     ; 1899  48
        LD      B,0                     ; 189A  0600
        INC     BC                      ; 189C  03
L189D:
        EX      DE,HL                   ; 189D  eb
        CALL    L2057                   ; 189E  cd5720
        CALL    L2430                   ; 18A1  cd3024
        EX      DE,HL                   ; 18A4  eb
        POP     HL                      ; 18A5  e1
        LD      A,D                     ; 18A6  7a
        AND     E                       ; 18A7  a3
        INC     A                       ; 18A8  3c
        JR      nz,L18AC                ; 18A9  2001
        INC     DE                      ; 18AB  13
L18AC:
        LD      (HL),D                  ; 18AC  72
        DEC     HL                      ; 18AD  2b
        LD      (HL),E                  ; 18AE  73
        JP      X_RETURN                ; 18AF  c3e618
L18B2:
        LD      HL,41C2H                ; 18B2  21c241
        SET     1,(HL)                  ; 18B5  cbce
X_GOSUB:
        LD      (41CDH),IX              ; 18B7  dd22cd41
        LD      HL,(41DAH)              ; 18BB  2ada41
        LD      (41CBH),HL              ; 18BE  22cb41
        LD      HL,41CBH                ; 18C1  21cb41
        LD      A,(41DCH)               ; 18C4  3adc41
        LD      (41CFH),A               ; 18C7  32cf41
        LD      BC,5                    ; 18CA  010500
        LD      DE,41A0H                ; 18CD  11a041
        CALL    L2085                   ; 18D0  cd8520
X_GOTO:
        CALL    FETCH_WORD              ; 18D3  cd661e
        LD      DE,6                    ; 18D6  110600
        ADD     HL,DE                   ; 18D9  19
        LD      E,(HL)                  ; 18DA  5e
        INC     HL                      ; 18DB  23
        LD      D,(HL)                  ; 18DC  56
L18DD:
        LD      HL,41DBH                ; 18DD  21db41
        LD      (HL),D                  ; 18E0  72
        DEC     HL                      ; 18E1  2b
        LD      (HL),E                  ; 18E2  73
        POP     DE                      ; 18E3  d1
        POP     DE                      ; 18E4  d1
        RET                             ; 18E5  c9
X_RETURN:
        LD      HL,41A0H                ; 18E6  21a041
        LD      (419AH),HL              ; 18E9  229a41
        LD      C,7                     ; 18EC  0e07
        CALL    L204B                   ; 18EE  cd4b20
        LD      A,3CH                   ; 18F1  3e3c
        JP      c,ERROR                 ; 18F3  da5933
        INC     HL                      ; 18F6  23
        LD      C,(HL)                  ; 18F7  4e
        INC     HL                      ; 18F8  23
        LD      B,(HL)                  ; 18F9  46
        INC     HL                      ; 18FA  23
        LD      A,(HL)                  ; 18FB  7e
        LD      (41DCH),A               ; 18FC  32dc41
        LD      (41DAH),DE              ; 18FF  ed53da41
        INC     BC                      ; 1903  03
        INC     BC                      ; 1904  03
        PUSH    BC                      ; 1905  c5
        POP     IX                      ; 1906  dde1
        RET                             ; 1908  c9
L1909:
        PUSH    IX                      ; 1909  dde5
        LD      A,(IX)                  ; 190B  dd7e00
        PUSH    AF                      ; 190E  f5
        INC     IX                      ; 190F  dd23
        INC     IX                      ; 1911  dd23
        CALL    RUNLOOP                 ; 1913  cd6014
        LD      A,(4002H)               ; 1916  3a0240
        PUSH    AF                      ; 1919  f5
        CALL    RUNLOOP                 ; 191A  cd6014
        POP     BC                      ; 191D  c1
        LD      C,B                     ; 191E  48
        LD      A,(4002H)               ; 191F  3a0240
        SUB     C                       ; 1922  91
        LD      B,A                     ; 1923  47
        LD      DE,4003H                ; 1924  110340
        LD      H,0                     ; 1927  2600
        LD      L,C                     ; 1929  69
        ADD     HL,DE                   ; 192A  19
        EX      DE,HL                   ; 192B  eb
        CALL    L1FE9                   ; 192C  cde91f
        XOR     A                       ; 192F  af
        LD      (4002H),A               ; 1930  320240
        JR      L1945                   ; 1933  1810
L1935:
        PUSH    IX                      ; 1935  dde5
        LD      A,(IX)                  ; 1937  dd7e00
        PUSH    AF                      ; 193A  f5
        INC     IX                      ; 193B  dd23
        INC     IX                      ; 193D  dd23
        CALL    RUNLOOP                 ; 193F  cd6014
        CALL    L1FD1                   ; 1942  cdd11f
L1945:
        POP     AF                      ; 1945  f1
        AND     C                       ; 1946  a1
        JR      z,L194E                 ; 1947  2805
        POP     DE                      ; 1949  d1
L194A:
        POP     DE                      ; 194A  d1
        JP      RUNLOOP                 ; 194B  c36014
L194E:
        POP     IX                      ; 194E  dde1
        XOR     A                       ; 1950  af
        OR      (IX+1)                  ; 1951  ddb601
        JR      nz,L1958                ; 1954  2002
        POP     DE                      ; 1956  d1
        RET                             ; 1957  c9
L1958:
        CALL    L1FC9                   ; 1958  cdc91f
        JR      L194A                   ; 195B  18ed
L195D:
        LD      DE,1                    ; 195D  110100
        PUSH    DE                      ; 1960  d5
        CALL    FAC_TO_INT              ; 1961  cd851f
        JR      L1971                   ; 1964  180b
L1966:
        CALL    FAC_TO_INT              ; 1966  cd851f
        PUSH    HL                      ; 1969  e5
        CALL    EVAL_INT                ; 196A  cd821f
        CALL    L1A5A                   ; 196D  cd5a1a
        EX      (SP),HL                 ; 1970  e3
L1971:
        CALL    L1A5A                   ; 1971  cd5a1a
        PUSH    HL                      ; 1974  e5
        CALL    L1EC4                   ; 1975  cdc41e
        CALL    nz,L19B2                ; 1978  c4b219
        POP     DE                      ; 197B  d1
        LD      (IY+4),E                ; 197C  fd7304
        LD      (IY+5),D                ; 197F  fd7205
        LD      HL,0                    ; 1982  210000
L1985:
        ADD     HL,DE                   ; 1985  19
        DJNZ    L1985                   ; 1986  10fd
        EX      DE,HL                   ; 1988  eb
        POP     BC                      ; 1989  c1
        LD      (IY+6),C                ; 198A  fd7106
        LD      (IY+7),B                ; 198D  fd7007
        CALL    L1F9A                   ; 1990  cd9a1f
        LD      A,3DH                   ; 1993  3e3d
        JP      c,ERROR                 ; 1995  da5933
        CALL    L20B5                   ; 1998  cdb520
        LD      (IY+8),L                ; 199B  fd7508
        LD      (IY+9),H                ; 199E  fd7409
        LD      A,3                     ; 19A1  3e03
        AND     (IY+2)                  ; 19A3  fda602
        CP      3                       ; 19A6  fe03
        RET     nz                      ; 19A8  c0
        LD      (HL),0                  ; 19A9  3600
        LD      D,H                     ; 19AB  54
        LD      E,L                     ; 19AC  5d
        INC     DE                      ; 19AD  13
        DEC     BC                      ; 19AE  0b
        LDIR                            ; 19AF  edb0
        RET                             ; 19B1  c9
L19B2:
        PUSH    BC                      ; 19B2  c5
        INC     HL                      ; 19B3  23
        LD      C,(HL)                  ; 19B4  4e
        LD      HL,0                    ; 19B5  210000
L19B8:
        ADD     HL,DE                   ; 19B8  19
        DJNZ    L19B8                   ; 19B9  10fd
        LD      B,(IY+7)                ; 19BB  fd4607
        EX      DE,HL                   ; 19BE  eb
        CALL    L1F9A                   ; 19BF  cd9a1f
        LD      L,(IY+8)                ; 19C2  fd6e08
        LD      H,(IY+9)                ; 19C5  fd6609
        LD      A,3                     ; 19C8  3e03
        AND     (IY+2)                  ; 19CA  fda602
        CP      3                       ; 19CD  fe03
        JR      nz,L19E9                ; 19CF  2018
        PUSH    BC                      ; 19D1  c5
        PUSH    HL                      ; 19D2  e5
L19D3:
        LD      E,(HL)                  ; 19D3  5e
        INC     HL                      ; 19D4  23
        LD      D,(HL)                  ; 19D5  56
        INC     HL                      ; 19D6  23
        PUSH    HL                      ; 19D7  e5
        EX      DE,HL                   ; 19D8  eb
        LD      A,H                     ; 19D9  7c
        OR      L                       ; 19DA  b5
        PUSH    BC                      ; 19DB  c5
        CALL    nz,L2053                ; 19DC  c45320
        POP     BC                      ; 19DF  c1
        POP     HL                      ; 19E0  e1
        DEC     BC                      ; 19E1  0b
        DEC     BC                      ; 19E2  0b
        LD      A,B                     ; 19E3  78
        OR      C                       ; 19E4  b1
        JR      nz,L19D3                ; 19E5  20ec
        POP     HL                      ; 19E7  e1
        POP     BC                      ; 19E8  c1
L19E9:
        CALL    L2057                   ; 19E9  cd5720
        POP     BC                      ; 19EC  c1
        RET                             ; 19ED  c9
L19EE:
        LD      DE,1                    ; 19EE  110100
        PUSH    DE                      ; 19F1  d5
        CALL    FAC_TO_INT              ; 19F2  cd851f
        JR      L1A02                   ; 19F5  180b
X_RSI:
        CALL    FAC_TO_INT              ; 19F7  cd851f
        PUSH    HL                      ; 19FA  e5
        CALL    EVAL_INT                ; 19FB  cd821f
        CALL    L1A5A                   ; 19FE  cd5a1a
        EX      (SP),HL                 ; 1A01  e3
L1A02:
        CALL    L1A5A                   ; 1A02  cd5a1a
        PUSH    HL                      ; 1A05  e5
        CALL    L1EC4                   ; 1A06  cdc41e
        LD      A,3EH                   ; 1A09  3e3e
        JP      z,ERROR                 ; 1A0B  ca5933
        POP     HL                      ; 1A0E  e1
        EX      DE,HL                   ; 1A0F  eb
        AND     A                       ; 1A10  a7
        SBC     HL,DE                   ; 1A11  ed52
        CCF                             ; 1A13  3f
        JR      nc,L1A3F                ; 1A14  3029
        LD      HL,0                    ; 1A16  210000
        DEC     DE                      ; 1A19  1b
        LD      A,B                     ; 1A1A  78
L1A1B:
        ADD     HL,DE                   ; 1A1B  19
        DJNZ    L1A1B                   ; 1A1C  10fd
        LD      D,(IY+9)                ; 1A1E  fd5609
        LD      E,(IY+8)                ; 1A21  fd5e08
        ADD     HL,DE                   ; 1A24  19
        EX      DE,HL                   ; 1A25  eb
        LD      B,(IY+5)                ; 1A26  fd4605
        LD      C,(IY+4)                ; 1A29  fd4e04
        LD      HL,0                    ; 1A2C  210000
L1A2F:
        ADD     HL,BC                   ; 1A2F  09
        DEC     A                       ; 1A30  3d
        JR      nz,L1A2F                ; 1A31  20fc
        EX      DE,HL                   ; 1A33  eb
        EX      (SP),HL                 ; 1A34  e3
        LD      B,(IY+7)                ; 1A35  fd4607
        LD      C,(IY+6)                ; 1A38  fd4e06
        DEC     HL                      ; 1A3B  2b
        PUSH    HL                      ; 1A3C  e5
        SBC     HL,BC                   ; 1A3D  ed42
L1A3F:
        LD      A,3FH                   ; 1A3F  3e3f
        JP      nc,ERROR                ; 1A41  d25933
        POP     BC                      ; 1A44  c1
        POP     HL                      ; 1A45  e1
        CALL    L1F9D                   ; 1A46  cd9d1f
        CALL    FETCH_WORD              ; 1A49  cd661e
        INC     HL                      ; 1A4C  23
        INC     HL                      ; 1A4D  23
        LD      A,(IY+2)                ; 1A4E  fd7e02
        AND     13H                     ; 1A51  e613
        LD      (HL),A                  ; 1A53  77
        INC     HL                      ; 1A54  23
        INC     HL                      ; 1A55  23
        LD      (HL),C                  ; 1A56  71
        INC     HL                      ; 1A57  23
        LD      (HL),B                  ; 1A58  70
        RET                             ; 1A59  c9
L1A5A:
        BIT     7,H                     ; 1A5A  cb7c
        JR      nz,L1A61                ; 1A5C  2003
        LD      A,H                     ; 1A5E  7c
        OR      L                       ; 1A5F  b5
        RET     nz                      ; 1A60  c0
L1A61:
        LD      A,3FH                   ; 1A61  3e3f
        JP      ERROR                   ; 1A63  c35933
X_ASGN:
        CALL    FETCH_WORD              ; 1A66  cd661e
        PUSH    HL                      ; 1A69  e5
        CALL    FETCH_WORD              ; 1A6A  cd661e
        EX      (SP),HL                 ; 1A6D  e3
        LD      E,(HL)                  ; 1A6E  5e
        INC     HL                      ; 1A6F  23
        LD      D,(HL)                  ; 1A70  56
        LD      A,(DE)                  ; 1A71  1a
        BIT     4,A                     ; 1A72  cb67
        JR      z,L1A89                 ; 1A74  2813
        PUSH    HL                      ; 1A76  e5
        PUSH    DE                      ; 1A77  d5
        LD      DE,41F6H                ; 1A78  11f641
        AND     A                       ; 1A7B  a7
        SBC     HL,DE                   ; 1A7C  ed52
        POP     DE                      ; 1A7E  d1
        JR      z,L1A88                 ; 1A7F  2807
        LD      BC,0B9H                 ; 1A81  01b900
        EX      DE,HL                   ; 1A84  eb
        CALL    L2057                   ; 1A85  cd5720
L1A88:
        POP     HL                      ; 1A88  e1
L1A89:
        LD      D,H                     ; 1A89  54
        LD      E,L                     ; 1A8A  5d
        EX      (SP),HL                 ; 1A8B  e3
        BIT     4,(HL)                  ; 1A8C  cb66
        JR      z,L1AD7                 ; 1A8E  2847
        PUSH    HL                      ; 1A90  e5
        AND     A                       ; 1A91  a7
        LD      HL,41F6H                ; 1A92  21f641
        SBC     HL,DE                   ; 1A95  ed52
        LD      HL,4231H                ; 1A97  213142
        JR      z,L1AA2                 ; 1A9A  2806
        LD      BC,0B9H                 ; 1A9C  01b900
        CALL    L20B5                   ; 1A9F  cdb520
L1AA2:
        POP     DE                      ; 1AA2  d1
        PUSH    HL                      ; 1AA3  e5
        EX      DE,HL                   ; 1AA4  eb
        LD      BC,9                    ; 1AA5  010900
        LDIR                            ; 1AA8  edb0
        PUSH    DE                      ; 1AAA  d5
        CALL    L1E80                   ; 1AAB  cd801e
        POP     HL                      ; 1AAE  e1
        LD      A,6                     ; 1AAF  3e06
        CP      B                       ; 1AB1  b8
        JR      nc,L1AB5                ; 1AB2  3001
        LD      B,A                     ; 1AB4  47
L1AB5:
        SUB     B                       ; 1AB5  90
        LD      C,A                     ; 1AB6  4f
        CP      6                       ; 1AB7  fe06
        JR      z,L1AC1                 ; 1AB9  2806
L1ABB:
        LD      A,(DE)                  ; 1ABB  1a
        LD      (HL),A                  ; 1ABC  77
        INC     HL                      ; 1ABD  23
        INC     DE                      ; 1ABE  13
        DJNZ    L1ABB                   ; 1ABF  10fa
L1AC1:
        LD      A,C                     ; 1AC1  79
        AND     A                       ; 1AC2  a7
        JR      z,L1ACB                 ; 1AC3  2806
L1AC5:
        LD      (HL),20H                ; 1AC5  3620
        INC     HL                      ; 1AC7  23
        DEC     C                       ; 1AC8  0d
        JR      nz,L1AC5                ; 1AC9  20fa
L1ACB:
        LD      B,0A1H                  ; 1ACB  06a1
        LD      A,B                     ; 1ACD  78
        AND     A                       ; 1ACE  a7
        JR      z,L1AD6                 ; 1ACF  2805
L1AD1:
        LD      (HL),0                  ; 1AD1  3600
        INC     HL                      ; 1AD3  23
        DJNZ    L1AD1                   ; 1AD4  10fb
L1AD6:
        POP     HL                      ; 1AD6  e1
L1AD7:
        POP     DE                      ; 1AD7  d1
        EX      DE,HL                   ; 1AD8  eb
        LD      (HL),D                  ; 1AD9  72
        DEC     HL                      ; 1ADA  2b
        LD      (HL),E                  ; 1ADB  73
        LD      BC,41F5H                ; 1ADC  01f541
        AND     A                       ; 1ADF  a7
        SBC     HL,BC                   ; 1AE0  ed42
        RET     nz                      ; 1AE2  c0
        EX      DE,HL                   ; 1AE3  eb
        SET     6,(HL)                  ; 1AE4  cbf6
        RET                             ; 1AE6  c9
L1AE7:
        CALL    CON_CR                  ; 1AE7  cd2f36
        CALL    L15C1                   ; 1AEA  cdc115
        CALL    L1BE9                   ; 1AED  cde91b
        DEC     IX                      ; 1AF0  dd2b
        DEC     IX                      ; 1AF2  dd2b
        JR      L1AF9                   ; 1AF4  1803
L1AF6:
        CALL    CON_CR                  ; 1AF6  cd2f36
L1AF9:
        PUSH    IX                      ; 1AF9  dde5
L1AFB:
        CALL    L3628                   ; 1AFB  cd2836
        CALL    L0F6F                   ; 1AFE  cd6f0f
        LD      A,(4001H)               ; 1B01  3a0140
        CP      20H                     ; 1B04  fe20
        PUSH    AF                      ; 1B06  f5
        JR      z,L1B0D                 ; 1B07  2804
        CP      2CH                     ; 1B09  fe2c
        JR      nz,L1B10                ; 1B0B  2003
L1B0D:
        CALL    L0F6F                   ; 1B0D  cd6f0f
L1B10:
        LD      A,(4000H)               ; 1B10  3a0040
        CP      89H                     ; 1B13  fe89
        LD      B,1                     ; 1B15  0601
        JR      z,L1B39                 ; 1B17  2820
        CP      8AH                     ; 1B19  fe8a
        JR      z,L1B38                 ; 1B1B  281b
        CP      8EH                     ; 1B1D  fe8e
        JR      z,L1B38                 ; 1B1F  2817
L1B21:
        LD      A,0C2H                  ; 1B21  3ec2
        CALL    ERROR                   ; 1B23  cd5933
        LD      HL,41FBH                ; 1B26  21fb41
        LD      (41F7H),HL              ; 1B29  22f741
        LD      HL,0                    ; 1B2C  210000
        LD      (4088H),HL              ; 1B2F  228840
        CALL    CON_CR                  ; 1B32  cd2f36
        POP     AF                      ; 1B35  f1
        JR      L1AFB                   ; 1B36  18c3
L1B38:
        INC     B                       ; 1B38  04
L1B39:
        LD      A,B                     ; 1B39  78
        LD      (FAC_TYPE),A            ; 1B3A  32e142
        LD      DE,4003H                ; 1B3D  110340
        CALL    FAC_LOAD                ; 1B40  cd9f26
        CALL    L0F6F                   ; 1B43  cd6f0f
        LD      A,(4000H)               ; 1B46  3a0040
        CP      47H                     ; 1B49  fe47
        JR      nz,L1B21                ; 1B4B  20d4
        POP     AF                      ; 1B4D  f1
        CALL    z,L161B                 ; 1B4E  cc1b16
        POP     IX                      ; 1B51  dde1
        JP      L15D1                   ; 1B53  c3d115
L1B56:
        CALL    CON_CR                  ; 1B56  cd2f36
        CALL    L1BF9                   ; 1B59  cdf91b
        DEC     IX                      ; 1B5C  dd2b
        DEC     IX                      ; 1B5E  dd2b
        JR      L1B65                   ; 1B60  1803
L1B62:
        CALL    CON_CR                  ; 1B62  cd2f36
L1B65:
        CALL    L3628                   ; 1B65  cd2836
        LD      IY,(41F7H)              ; 1B68  fd2af741
        LD      HL,4003H                ; 1B6C  210340
        LD      B,0FFH                  ; 1B6F  06ff
L1B71:
        CALL    L3550                   ; 1B71  cd5035
        LD      (HL),A                  ; 1B74  77
        INC     HL                      ; 1B75  23
        LD      DE,(4088H)              ; 1B76  ed5b8840
        INC     DE                      ; 1B7A  13
        LD      (4088H),DE              ; 1B7B  ed538840
        CP      1EH                     ; 1B7F  fe1e
        JR      z,L1B86                 ; 1B81  2803
        DJNZ    L1B71                   ; 1B83  10ec
        INC     B                       ; 1B85  04
L1B86:
        LD      A,B                     ; 1B86  78
        CPL                             ; 1B87  2f
        LD      HL,4002H                ; 1B88  210240
        LD      (HL),A                  ; 1B8B  77
L1B8C:
        PUSH    HL                      ; 1B8C  e5
        JR      L1B96                   ; 1B8D  1807
L1B8F:
        CALL    L1E80                   ; 1B8F  cd801e
        JR      z,L1B95                 ; 1B92  2801
        DEC     DE                      ; 1B94  1b
L1B95:
        PUSH    DE                      ; 1B95  d5
L1B96:
        CALL    L1E80                   ; 1B96  cd801e
        PUSH    HL                      ; 1B99  e5
        DEC     DE                      ; 1B9A  1b
        PUSH    AF                      ; 1B9B  f5
        AND     3                       ; 1B9C  e603
        CP      3                       ; 1B9E  fe03
        LD      A,25H                   ; 1BA0  3e25
        JP      nz,ERROR                ; 1BA2  c25933
        POP     AF                      ; 1BA5  f1
        JR      z,L1BAC                 ; 1BA6  2804
        EX      DE,HL                   ; 1BA8  eb
        CALL    L2053                   ; 1BA9  cd5320
L1BAC:
        EX      DE,HL                   ; 1BAC  eb
        POP     HL                      ; 1BAD  e1
        EX      (SP),HL                 ; 1BAE  e3
        LD      A,H                     ; 1BAF  7c
        OR      L                       ; 1BB0  b5
        LD      DE,0                    ; 1BB1  110000
        JR      z,L1BBB                 ; 1BB4  2805
        LD      A,(HL)                  ; 1BB6  7e
        AND     A                       ; 1BB7  a7
        CALL    nz,L209D                ; 1BB8  c49d20
L1BBB:
        POP     HL                      ; 1BBB  e1
        LD      (HL),D                  ; 1BBC  72
        DEC     HL                      ; 1BBD  2b
        LD      (HL),E                  ; 1BBE  73
L1BBF:
        XOR     A                       ; 1BBF  af
        LD      (4002H),A               ; 1BC0  320240
        RET                             ; 1BC3  c9
X_FIX:
        CALL    FETCH_WORD              ; 1BC4  cd661e
        LD      E,H                     ; 1BC7  5c
        JR      L1BD0                   ; 1BC8  1806
X_FLO:
        CALL    FETCH_WORD              ; 1BCA  cd661e
        LD      E,H                     ; 1BCD  5c
        SET     7,E                     ; 1BCE  cbfb
L1BD0:
        LD      D,L                     ; 1BD0  55
        JP      NUMBER_SET_FORMAT       ; 1BD1  c34432
X_BIN:
        LD      A,60H                   ; 1BD4  3e60
        JR      L1BDA                   ; 1BD6  1802
X_HEX:
        LD      A,20H                   ; 1BD8  3e20
L1BDA:
        CALL    FETCH_WORD              ; 1BDA  cd661e
        OR      H                       ; 1BDD  b4
        LD      E,A                     ; 1BDE  5f
        LD      D,L                     ; 1BDF  55
        LD      (42FBH),DE              ; 1BE0  ed53fb42
        RET                             ; 1BE4  c9
L1BE5:
        LD      IY,(41F3H)              ; 1BE5  fd2af341
L1BE9:
        LD      DE,4003H                ; 1BE9  110340
        CALL    NUMBER_FORMAT           ; 1BEC  cdb22f
        LD      HL,4004H                ; 1BEF  210440
        JP      L3620                   ; 1BF2  c32036
L1BF5:
        LD      IY,(41F3H)              ; 1BF5  fd2af341
L1BF9:
        CALL    L1E80                   ; 1BF9  cd801e
        RET     z                       ; 1BFC  c8
        EX      DE,HL                   ; 1BFD  eb
        CALL    L3620                   ; 1BFE  cd2036
        JR      L1BBF                   ; 1C01  18bc
X_PAGE:
        LD      A,11                    ; 1C03  3e0b
        JP      L35F7                   ; 1C05  c3f735
X_TAB:
        CALL    FAC_TO_INT              ; 1C08  cd851f
        LD      B,L                     ; 1C0B  45
L1C0C:
        LD      A,B                     ; 1C0C  78
        AND     A                       ; 1C0D  a7
        RET     z                       ; 1C0E  c8
L1C0F:
        CALL    L35F5                   ; 1C0F  cdf535
        DJNZ    L1C0F                   ; 1C12  10fb
        RET                             ; 1C14  c9
X_COL:
        CALL    FAC_TO_INT              ; 1C15  cd851f
        LD      B,L                     ; 1C18  45
        LD      IY,(41F3H)              ; 1C19  fd2af341
        LD      A,(IY+4)                ; 1C1D  fd7e04
        SUB     (IY+3)                  ; 1C20  fd9603
        CP      B                       ; 1C23  b8
        RET     z                       ; 1C24  c8
        JR      c,L1C2C                 ; 1C25  3805
        CALL    X_SKIP                  ; 1C27  cdf135
        LD      A,1                     ; 1C2A  3e01
L1C2C:
        LD      C,A                     ; 1C2C  4f
        LD      A,B                     ; 1C2D  78
        SUB     C                       ; 1C2E  91
        LD      B,A                     ; 1C2F  47
        JR      L1C0C                   ; 1C30  18da
X_OPEN:
        CALL    X_GET                   ; 1C32  cd461c
        LD      IY,(41F9H)              ; 1C35  fd2af941
        JP      L3583                   ; 1C39  c38335
X_CLOSE:
        CALL    X_GET                   ; 1C3C  cd461c
        LD      IY,(41F9H)              ; 1C3F  fd2af941
        JP      L35AB                   ; 1C43  c3ab35
X_GET:
        CALL    FETCH_WORD              ; 1C46  cd661e
        LD      E,(HL)                  ; 1C49  5e
        INC     HL                      ; 1C4A  23
        LD      D,(HL)                  ; 1C4B  56
        LD      A,D                     ; 1C4C  7a
        OR      E                       ; 1C4D  b3
        LD      A,51H                   ; 1C4E  3e51
        JP      z,ERROR                 ; 1C50  ca5933
        EX      DE,HL                   ; 1C53  eb
        LD      (41F9H),HL              ; 1C54  22f941
        RET                             ; 1C57  c9
L1C58:
        CALL    L1E97                   ; 1C58  cd971e
        JR      nc,L1C67                ; 1C5B  300a
        INC     DE                      ; 1C5D  13
        DEC     BC                      ; 1C5E  0b
        AND     7                       ; 1C5F  e607
        CP      1                       ; 1C61  fe01
        JR      nz,L1C68                ; 1C63  2003
        LD      C,2                     ; 1C65  0e02
L1C67:
        LD      B,C                     ; 1C67  41
L1C68:
        LD      IY,(41F9H)              ; 1C68  fd2af941
        CALL    CH_OUT                  ; 1C6C  cddb34
L1C6F:
        LD      A,(DE)                  ; 1C6F  1a
        INC     DE                      ; 1C70  13
        CALL    CH_OUT                  ; 1C71  cddb34
        DJNZ    L1C6F                   ; 1C74  10f9
        RET                             ; 1C76  c9
L1C77:
        CALL    L1E80                   ; 1C77  cd801e
        JR      nz,L1C7F                ; 1C7A  2003
        LD      DE,34ACH                ; 1C7C  11ac34
L1C7F:
        INC     B                       ; 1C7F  04
        DEC     DE                      ; 1C80  1b
        LD      A,3                     ; 1C81  3e03
        JR      L1C68                   ; 1C83  18e3
L1C85:
        LD      IY,(41F9H)              ; 1C85  fd2af941
        CALL    L1E97                   ; 1C89  cd971e
        LD      B,C                     ; 1C8C  41
        LD      C,A                     ; 1C8D  4f
        CALL    L3550                   ; 1C8E  cd5035
        CP      C                       ; 1C91  b9
L1C92:
        LD      A,25H                   ; 1C92  3e25
        JP      nz,ERROR                ; 1C94  c25933
L1C97:
        CALL    L3550                   ; 1C97  cd5035
        LD      (DE),A                  ; 1C9A  12
        INC     DE                      ; 1C9B  13
        DJNZ    L1C97                   ; 1C9C  10f9
        RET                             ; 1C9E  c9
L1C9F:
        LD      IY,(41F9H)              ; 1C9F  fd2af941
        CALL    L3550                   ; 1CA3  cd5035
        CP      3                       ; 1CA6  fe03
        JR      nz,L1C92                ; 1CA8  20e8
        CALL    L3550                   ; 1CAA  cd5035
        LD      DE,4002H                ; 1CAD  110240
        PUSH    DE                      ; 1CB0  d5
        LD      (DE),A                  ; 1CB1  12
        INC     DE                      ; 1CB2  13
        LD      B,A                     ; 1CB3  47
        AND     A                       ; 1CB4  a7
        CALL    nz,L1C97                ; 1CB5  c4971c
        JP      L1B96                   ; 1CB8  c3961b
X_LEFT:
        CALL    L1E80                   ; 1CBB  cd801e
        RET     z                       ; 1CBE  c8
        PUSH    DE                      ; 1CBF  d5
        PUSH    BC                      ; 1CC0  c5
        CALL    FAC_TO_INT              ; 1CC1  cd851f
        JR      nz,L1D08                ; 1CC4  2042
        POP     BC                      ; 1CC6  c1
        POP     DE                      ; 1CC7  d1
L1CC8:
        LD      A,B                     ; 1CC8  78
        CP      L                       ; 1CC9  bd
        JR      c,L1D2C                 ; 1CCA  3860
        LD      B,L                     ; 1CCC  45
        JR      L1D2C                   ; 1CCD  185d
X_RIGHT:
        CALL    L1E80                   ; 1CCF  cd801e
        RET     z                       ; 1CD2  c8
        PUSH    DE                      ; 1CD3  d5
        PUSH    BC                      ; 1CD4  c5
        CALL    FAC_TO_INT              ; 1CD5  cd851f
        JR      nz,L1D08                ; 1CD8  202e
        POP     BC                      ; 1CDA  c1
        POP     DE                      ; 1CDB  d1
        LD      A,B                     ; 1CDC  78
        SUB     L                       ; 1CDD  95
        JR      c,L1D2C                 ; 1CDE  384c
        ADD     A,E                     ; 1CE0  83
        LD      E,A                     ; 1CE1  5f
        JR      nc,L1CE5                ; 1CE2  3001
        INC     D                       ; 1CE4  14
L1CE5:
        LD      B,L                     ; 1CE5  45
        JR      L1D2C                   ; 1CE6  1844
L1CE8:
        CALL    FAC_TO_INT              ; 1CE8  cd851f
        JR      nz,L1D08                ; 1CEB  201b
        PUSH    HL                      ; 1CED  e5
        CALL    EVAL_INT                ; 1CEE  cd821f
        JR      nz,L1D08                ; 1CF1  2015
        PUSH    HL                      ; 1CF3  e5
        CALL    L1E80                   ; 1CF4  cd801e
        POP     HL                      ; 1CF7  e1
        LD      A,L                     ; 1CF8  7d
        POP     HL                      ; 1CF9  e1
        LD      H,A                     ; 1CFA  67
        DEC     H                       ; 1CFB  25
        LD      A,B                     ; 1CFC  78
        SUB     H                       ; 1CFD  94
        LD      B,A                     ; 1CFE  47
        RET     c                       ; 1CFF  d8
        LD      A,H                     ; 1D00  7c
        ADD     A,E                     ; 1D01  83
        LD      E,A                     ; 1D02  5f
        JR      nc,L1D06                ; 1D03  3001
        INC     D                       ; 1D05  14
L1D06:
        JR      L1CC8                   ; 1D06  18c0
L1D08:
        LD      A,23H                   ; 1D08  3e23
        JP      ERROR                   ; 1D0A  c35933
L1D0D:
        CALL    L1E80                   ; 1D0D  cd801e
        JR      L1D2C                   ; 1D10  181a
X_STR:
        LD      DE,40EAH                ; 1D12  11ea40
        PUSH    DE                      ; 1D15  d5
        CALL    NUMBER_FORMAT           ; 1D16  cdb22f
        POP     HL                      ; 1D19  e1
        INC     HL                      ; 1D1A  23
        JR      L1D2B                   ; 1D1B  180e
X_CHR:
        CALL    FAC_TO_INT              ; 1D1D  cd851f
        LD      A,L                     ; 1D20  7d
        LD      HL,42E3H                ; 1D21  21e342
        LD      (HL),A                  ; 1D24  77
        LD      B,1                     ; 1D25  0601
        JR      L1D2B                   ; 1D27  1802
        DB      46H,23H                 ; 1D29 F#
L1D2B:
        EX      DE,HL                   ; 1D2B  eb
L1D2C:
        LD      HL,4002H                ; 1D2C  210240
        LD      A,B                     ; 1D2F  78
        OR      A                       ; 1D30  b7
        RET     z                       ; 1D31  c8
        LD      A,(HL)                  ; 1D32  7e
        AND     A                       ; 1D33  a7
        LD      C,A                     ; 1D34  4f
        INC     HL                      ; 1D35  23
        JR      z,L1D3D                 ; 1D36  2805
        ADD     A,L                     ; 1D38  85
        LD      L,A                     ; 1D39  6f
        JR      nc,L1D3D                ; 1D3A  3001
        INC     H                       ; 1D3C  24
L1D3D:
        LD      A,C                     ; 1D3D  79
        ADD     A,B                     ; 1D3E  80
        JR      c,L1D4B                 ; 1D3F  380a
        LD      C,B                     ; 1D41  48
        LD      B,0                     ; 1D42  0600
        EX      DE,HL                   ; 1D44  eb
        LDIR                            ; 1D45  edb0
        LD      (4002H),A               ; 1D47  320240
        RET                             ; 1D4A  c9
L1D4B:
        LD      A,22H                   ; 1D4B  3e22
        JP      ERROR                   ; 1D4D  c35933
L1D50:
        CALL    FAC_TO_INT              ; 1D50  cd851f
        PUSH    HL                      ; 1D53  e5
        LD      DE,(41B7H)              ; 1D54  ed5bb741
        AND     A                       ; 1D58  a7
        SBC     HL,DE                   ; 1D59  ed52
        EX      DE,HL                   ; 1D5B  eb
        POP     HL                      ; 1D5C  e1
        RET     z                       ; 1D5D  c8
        JP      nc,L2024                ; 1D5E  d22420
        LD      DE,(419CH)              ; 1D61  ed5b9c41
        AND     A                       ; 1D65  a7
        SBC     HL,DE                   ; 1D66  ed52
        LD      A,4                     ; 1D68  3e04
        JP      c,ERROR                 ; 1D6A  da5933
        ADD     HL,DE                   ; 1D6D  19
        LD      (41B7H),HL              ; 1D6E  22b741
        RET                             ; 1D71  c9
; ---- Opcode D0h: Grafik-Unterfunktion (GIN,OFF,COL,...) ueber GSUBTAB
OP_GSUB:
        LD      A,(IX)                  ; 1D72  dd7e00
        INC     IX                      ; 1D75  dd23
        LD      HL,GSUBTAB              ; 1D77  21841d
        ADD     A,L                     ; 1D7A  85
        LD      L,A                     ; 1D7B  6f
        JR      nc,L1D7F                ; 1D7C  3001
        INC     HL                      ; 1D7E  23
L1D7F:
        LD      E,(HL)                  ; 1D7F  5e
        INC     HL                      ; 1D80  23
        LD      D,(HL)                  ; 1D81  56
        EX      DE,HL                   ; 1D82  eb
        JP      (HL)                    ; 1D83  e9
; ---- GSUBTAB: 12 Unterfunktionen, alle ausser OFF zeigen auf DRV_DUMMY
GSUBTAB:
        DB      03H,37H,0EFH,3DH,03H,37H,03H,37H ; 1D84 .7.=.7.7
        DB      03H,37H,03H,37H,03H,37H,03H,37H ; 1D8C .7.7.7.7
        DB      03H,37H,03H,37H,03H,37H,03H,37H ; 1D94 .7.7.7.7
; ---- PLOT: nur Treiber-Haken 3703H (leer)
OP_PLOT:
        LD      HL,DRV_DUMMY            ; 1D9C  210337
        JR      GARG_XY                 ; 1D9F  1808
; ---- DOT x,y   -> G_DOT
OP_DOT:
        LD      HL,G_DOT                ; 1DA1  21203b
        JR      GARG_XY                 ; 1DA4  1803
; ---- CDOT x,y  -> G_CDOT
OP_CDOT:
        LD      HL,G_CDOT               ; 1DA6  21243b
; ---- x,y holen: GY1=y, GX1=x, dann Ziel (Stack) anspringen
GARG_XY:
        PUSH    HL                      ; 1DA9  e5
L1DAA:
        CALL    FAC_TO_INT              ; 1DAA  cd851f
L1DAD:
        LD      (GY1),HL                ; 1DAD  22023b
        CALL    EVAL_INT                ; 1DB0  cd821f
        LD      (GX1),HL                ; 1DB3  22003b
        RET                             ; 1DB6  c9
; ---- LINE x1,y1,x2,y2 -> G_LINE
OP_LINE:
        LD      HL,G_LINE               ; 1DB7  21e23c
        JR      GARG_XYXY               ; 1DBA  1808
; ---- CLINE x1,y1,x2,y2 -> G_CLINE
OP_CLINE:
        LD      HL,G_CLINE              ; 1DBC  21e63c
        JR      GARG_XYXY               ; 1DBF  1803
; ---- FILL x1,y1,x2,y2 -> G_FILL (Rechteck)
OP_FILL:
        LD      HL,G_FILL               ; 1DC1  21d13b
GARG_XYXY:
        PUSH    HL                      ; 1DC4  e5
L1DC5:
        CALL    FAC_TO_INT              ; 1DC5  cd851f
        LD      (GY2),HL                ; 1DC8  22063b
        CALL    EVAL_INT                ; 1DCB  cd821f
        LD      (GX2),HL                ; 1DCE  22043b
        CALL    EVAL_INT                ; 1DD1  cd821f
        JR      L1DAD                   ; 1DD4  18d7
; ---- TEST(x,y): -1 wenn Punkt gesetzt, sonst 0
OP_TEST:
        LD      HL,G_TEST               ; 1DD6  21823b
        CALL    GARG_XY                 ; 1DD9  cda91d
        LD      HL,0                    ; 1DDC  210000
        JR      nc,L1DE2                ; 1DDF  3001
        DEC     HL                      ; 1DE1  2b
L1DE2:
        CALL    L1F6E                   ; 1DE2  cd6e1f
        JP      L15D1                   ; 1DE5  c3d115
X_GLOAD:
        CALL    L1E80                   ; 1DE8  cd801e
        RET     z                       ; 1DEB  c8
        EX      DE,HL                   ; 1DEC  eb
        DEC     HL                      ; 1DED  2b
        JP      DRV_DUMMY               ; 1DEE  c30337
X_GSAVE:
        CALL    L1DC5                   ; 1DF1  cdc51d
        CALL    L1E80                   ; 1DF4  cd801e
        RET     z                       ; 1DF7  c8
        EX      DE,HL                   ; 1DF8  eb
        DEC     HL                      ; 1DF9  2b
        JP      DRV_DUMMY               ; 1DFA  c30337
X_TEXT:
        CALL    L1DAA                   ; 1DFD  cdaa1d
        CALL    L1E80                   ; 1E00  cd801e
        RET     z                       ; 1E03  c8
        EX      DE,HL                   ; 1E04  eb
        DEC     HL                      ; 1E05  2b
        JP      DRV_DUMMY               ; 1E06  c30337
X_CLS:
        CALL    DRV_DUMMY               ; 1E09  cd0337
        LD      A,H                     ; 1E0C  7c
        PUSH    HL                      ; 1E0D  e5
        CALL    L1E13                   ; 1E0E  cd131e
        POP     HL                      ; 1E11  e1
        LD      A,L                     ; 1E12  7d
L1E13:
        PUSH    AF                      ; 1E13  f5
        CALL    L1E1A                   ; 1E14  cd1a1e
        POP     AF                      ; 1E17  f1
        JR      L1E1E                   ; 1E18  1804
L1E1A:
        RRCA                            ; 1E1A  0f
        RRCA                            ; 1E1B  0f
        RRCA                            ; 1E1C  0f
        RRCA                            ; 1E1D  0f
L1E1E:
        AND     15                      ; 1E1E  e60f
        LD      L,A                     ; 1E20  6f
        CALL    L16C7                   ; 1E21  cdc716
        JP      L15D1                   ; 1E24  c3d115
X_GLS:
        CALL    FAC_TO_INT              ; 1E27  cd851f
        CALL    L1E5C                   ; 1E2A  cd5c1e
        JR      nz,L1E55                ; 1E2D  2026
        LD      L,A                     ; 1E2F  6f
        PUSH    HL                      ; 1E30  e5
        CALL    L1E59                   ; 1E31  cd591e
        POP     HL                      ; 1E34  e1
        JR      nz,L1E55                ; 1E35  201e
        ADD     A,A                     ; 1E37  87
        ADD     A,A                     ; 1E38  87
        ADD     A,A                     ; 1E39  87
        ADD     A,A                     ; 1E3A  87
        OR      L                       ; 1E3B  b5
        LD      L,A                     ; 1E3C  6f
        PUSH    HL                      ; 1E3D  e5
        CALL    L1E59                   ; 1E3E  cd591e
        POP     HL                      ; 1E41  e1
        JR      nz,L1E55                ; 1E42  2011
        LD      H,A                     ; 1E44  67
        PUSH    HL                      ; 1E45  e5
        CALL    L1E59                   ; 1E46  cd591e
        POP     HL                      ; 1E49  e1
        JR      nz,L1E55                ; 1E4A  2009
        ADD     A,A                     ; 1E4C  87
        ADD     A,A                     ; 1E4D  87
        ADD     A,A                     ; 1E4E  87
        ADD     A,A                     ; 1E4F  87
        OR      H                       ; 1E50  b4
        LD      H,A                     ; 1E51  67
        JP      DRV_DUMMY               ; 1E52  c30337
L1E55:
        LD      A,1FH                   ; 1E55  3e1f
        SCF                             ; 1E57  37
        RET                             ; 1E58  c9
L1E59:
        CALL    EVAL_INT                ; 1E59  cd821f
L1E5C:
        RET     nz                      ; 1E5C  c0
        LD      A,L                     ; 1E5D  7d
        AND     0F0H                    ; 1E5E  e6f0
        RET     nz                      ; 1E60  c0
        LD      A,L                     ; 1E61  7d
        AND     15                      ; 1E62  e60f
        CP      A                       ; 1E64  bf
        RET                             ; 1E65  c9

;=====================================================================
; FETCH_WORD: 16-Bit-Operand aus dem Zwischencode
; Ein: IX = Codezeiger. Aus: HL = Wort, IX += 2.
;=====================================================================
FETCH_WORD:
        LD      L,(IX)                  ; 1E66  dd6e00
        INC     IX                      ; 1E69  dd23
        LD      H,(IX)                  ; 1E6B  dd6600
        INC     IX                      ; 1E6E  dd23
        RET                             ; 1E70  c9
; ---- FETCH_VAR: Variablenadresse aus Code holen, Typ/Wert lesen
FETCH_VAR:
        CALL    FETCH_WORD              ; 1E71  cd661e
L1E74:
        INC     HL                      ; 1E74  23
        INC     HL                      ; 1E75  23
        LD      D,(HL)                  ; 1E76  56
        INC     HL                      ; 1E77  23
        INC     HL                      ; 1E78  23
        LD      E,(HL)                  ; 1E79  5e
        INC     HL                      ; 1E7A  23
        LD      A,(HL)                  ; 1E7B  7e
        OR      E                       ; 1E7C  b3
        LD      A,D                     ; 1E7D  7a
        LD      D,(HL)                  ; 1E7E  56
        RET                             ; 1E7F  c9
L1E80:
        CALL    FETCH_VAR               ; 1E80  cd711e
L1E83:
        LD      B,A                     ; 1E83  47
        BIT     4,A                     ; 1E84  cb67
        JR      z,L1E8C                 ; 1E86  2804
        EX      DE,HL                   ; 1E88  eb
        LD      E,(HL)                  ; 1E89  5e
        INC     HL                      ; 1E8A  23
        LD      D,(HL)                  ; 1E8B  56
L1E8C:
        EX      DE,HL                   ; 1E8C  eb
        LD      A,H                     ; 1E8D  7c
        OR      L                       ; 1E8E  b5
        LD      A,B                     ; 1E8F  78
        LD      B,L                     ; 1E90  45
        JR      z,L1E95                 ; 1E91  2802
        LD      B,(HL)                  ; 1E93  46
        INC     HL                      ; 1E94  23
L1E95:
        EX      DE,HL                   ; 1E95  eb
        RET                             ; 1E96  c9
L1E97:
        CALL    FETCH_VAR               ; 1E97  cd711e
L1E9A:
        LD      BC,6                    ; 1E9A  010600
        CP      8CH                     ; 1E9D  fe8c
        SCF                             ; 1E9F  37
        JR      z,L1EAB                 ; 1EA0  2809
        DEC     C                       ; 1EA2  0d
        AND     7                       ; 1EA3  e607
        CP      1                       ; 1EA5  fe01
        JR      nz,L1EAB                ; 1EA7  2002
        LD      C,2                     ; 1EA9  0e02
L1EAB:
        PUSH    AF                      ; 1EAB  f5
        LD      A,D                     ; 1EAC  7a
        OR      E                       ; 1EAD  b3
        JR      nz,L1EBE                ; 1EAE  200e
        PUSH    HL                      ; 1EB0  e5
        PUSH    BC                      ; 1EB1  c5
        CALL    L20B5                   ; 1EB2  cdb520
        POP     BC                      ; 1EB5  c1
        LD      (HL),2                  ; 1EB6  3602
        POP     DE                      ; 1EB8  d1
        EX      DE,HL                   ; 1EB9  eb
        LD      (HL),D                  ; 1EBA  72
        DEC     HL                      ; 1EBB  2b
        LD      (HL),E                  ; 1EBC  73
        INC     HL                      ; 1EBD  23
L1EBE:
        POP     AF                      ; 1EBE  f1
        RET     nc                      ; 1EBF  d0
        LD      A,(DE)                  ; 1EC0  1a
        SET     7,A                     ; 1EC1  cbff
        RET                             ; 1EC3  c9
L1EC4:
        CALL    FETCH_WORD              ; 1EC4  cd661e
        PUSH    HL                      ; 1EC7  e5
        POP     IY                      ; 1EC8  fde1
        INC     HL                      ; 1ECA  23
        INC     HL                      ; 1ECB  23
        LD      A,(HL)                  ; 1ECC  7e
        LD      B,2                     ; 1ECD  0602
        AND     3                       ; 1ECF  e603
        CP      B                       ; 1ED1  b8
        JR      nz,L1ED6                ; 1ED2  2002
        LD      B,5                     ; 1ED4  0605
L1ED6:
        INC     HL                      ; 1ED6  23
        INC     HL                      ; 1ED7  23
        LD      E,(HL)                  ; 1ED8  5e
        INC     HL                      ; 1ED9  23
        LD      D,(HL)                  ; 1EDA  56
        LD      A,D                     ; 1EDB  7a
        OR      E                       ; 1EDC  b3
        RET                             ; 1EDD  c9
L1EDE:
        CALL    L1E97                   ; 1EDE  cd971e
        PUSH    AF                      ; 1EE1  f5
        AND     3                       ; 1EE2  e603
        DEC     A                       ; 1EE4  3d
        JR      nz,L1EED                ; 1EE5  2006
        LD      A,(FAC_TYPE)            ; 1EE7  3ae142
        DEC     A                       ; 1EEA  3d
        JR      nz,L1F06                ; 1EEB  2019
L1EED:
        POP     AF                      ; 1EED  f1
        EX      DE,HL                   ; 1EEE  eb
        LD      DE,ARG                  ; 1EEF  11e742
        JR      nc,L1EF6                ; 1EF2  3002
        INC     HL                      ; 1EF4  23
        DEC     C                       ; 1EF5  0d
L1EF6:
        LDIR                            ; 1EF6  edb0
        AND     3                       ; 1EF8  e603
        DEC     A                       ; 1EFA  3d
        RET     z                       ; 1EFB  c8
        PUSH    AF                      ; 1EFC  f5
        LD      A,(FAC_TYPE)            ; 1EFD  3ae142
        DEC     A                       ; 1F00  3d
        CALL    z,INT16_TO_FP           ; 1F01  cc7432
        POP     AF                      ; 1F04  f1
        RET                             ; 1F05  c9
L1F06:
        POP     AF                      ; 1F06  f1
        LD      DE,FAC                  ; 1F07  11e242
        CALL    ARG_LOAD                ; 1F0A  cda426
        DEC     IX                      ; 1F0D  dd2b
        DEC     IX                      ; 1F0F  dd2b
        CALL    L15C1                   ; 1F11  cdc115
        CALL    INT16_TO_FP             ; 1F14  cd7432
        LD      A,0FFH                  ; 1F17  3eff
        ADD     A,A                     ; 1F19  87
        RET                             ; 1F1A  c9
L1F1B:
        LD      A,(FAC_TYPE)            ; 1F1B  3ae142
        DEC     A                       ; 1F1E  3d
        JR      nz,L1F29                ; 1F1F  2008
        LD      DE,(ARG)                ; 1F21  ed5be742
        LD      HL,(FAC)                ; 1F25  2ae242
        RET                             ; 1F28  c9
L1F29:
        CALL    FP_TO_INT16             ; 1F29  cdb732
        LD      HL,(FAC)                ; 1F2C  2ae242
        PUSH    HL                      ; 1F2F  e5
        LD      DE,ARG                  ; 1F30  11e742
        CALL    FAC_LOAD                ; 1F33  cd9f26
        CALL    FP_TO_INT16             ; 1F36  cdb732
        LD      DE,(FAC)                ; 1F39  ed5be242
        POP     HL                      ; 1F3D  e1
        RET                             ; 1F3E  c9
L1F3F:
        LD      DE,ARG                  ; 1F3F  11e742
        PUSH    AF                      ; 1F42  f5
        LD      HL,FAC                  ; 1F43  21e242
        LD      BC,5                    ; 1F46  010500
L1F49:
        LD      A,(DE)                  ; 1F49  1a
        LDI                             ; 1F4A  eda0
        DEC     HL                      ; 1F4C  2b
        LD      (HL),A                  ; 1F4D  77
        INC     HL                      ; 1F4E  23
        JP      pe,L1F49                ; 1F4F  ea491f
        POP     AF                      ; 1F52  f1
        RET                             ; 1F53  c9
L1F54:
        PUSH    AF                      ; 1F54  f5
        PUSH    DE                      ; 1F55  d5
        AND     3                       ; 1F56  e603
        DEC     A                       ; 1F58  3d
        LD      A,(FAC_TYPE)            ; 1F59  3ae142
        JR      z,L1F64                 ; 1F5C  2806
        DEC     A                       ; 1F5E  3d
        CALL    z,INT16_TO_FP           ; 1F5F  cc7432
        JR      L1F68                   ; 1F62  1804
L1F64:
        DEC     A                       ; 1F64  3d
        CALL    nz,FP_TO_INT16          ; 1F65  c4b732
L1F68:
        LD      HL,FAC                  ; 1F68  21e242
        POP     DE                      ; 1F6B  d1
        POP     AF                      ; 1F6C  f1
        RET                             ; 1F6D  c9
L1F6E:
        LD      (FAC),HL                ; 1F6E  22e242
        RL      H                       ; 1F71  cb14
        LD      HL,0                    ; 1F73  210000
        JR      nc,L1F79                ; 1F76  3001
        DEC     HL                      ; 1F78  2b
L1F79:
        LD      (42E4H),HL              ; 1F79  22e442
        LD      A,1                     ; 1F7C  3e01
        LD      (FAC_TYPE),A            ; 1F7E  32e142
        RET                             ; 1F81  c9
; ---- EVAL_INT: Ausdruck auswerten und nach Ganzzahl wandeln
EVAL_INT:
        CALL    L15C1                   ; 1F82  cdc115

;=====================================================================
; FAC_TO_INT: FAC als 16-Bit-Ganzzahl nach HL
; Ist FAC_TYPE<>1 (Gleitkomma), wird zuerst gewandelt (32B7H).
; Aus: HL = Wert, A=H, Flags fuer Vorzeichen-/Bereichstest.
;=====================================================================
FAC_TO_INT:
        LD      A,(FAC_TYPE)            ; 1F85  3ae142
        DEC     A                       ; 1F88  3d
        CALL    nz,FP_TO_INT16          ; 1F89  c4b732
        LD      HL,(FAC)                ; 1F8C  2ae242
        LD      A,H                     ; 1F8F  7c
        OR      A                       ; 1F90  b7
        RET                             ; 1F91  c9
; ---- FAC_REQUIRE_FP: Typ 1 (Integer) exakt nach FP wandeln; sonst unveraendert.
FAC_REQUIRE_FP:
        LD      A,(FAC_TYPE)            ; 1F92  3ae142
        DEC     A                       ; 1F95  3d
        RET     nz                      ; 1F96  c0
        JP      INT16_TO_FP             ; 1F97  c37432
L1F9A:
        LD      HL,0                    ; 1F9A  210000
L1F9D:
        LD      A,10H                   ; 1F9D  3e10
        SRL     B                       ; 1F9F  cb38
        RR      C                       ; 1FA1  cb19
L1FA3:
        JR      nc,L1FB6                ; 1FA3  3011
        CCF                             ; 1FA5  3f
        SBC     HL,DE                   ; 1FA6  ed52
L1FA8:
        SRA     H                       ; 1FA8  cb2c
        RR      L                       ; 1FAA  cb1d
        RR      B                       ; 1FAC  cb18
        RR      C                       ; 1FAE  cb19
        DEC     A                       ; 1FB0  3d
        JR      z,L1FC1                 ; 1FB1  280e
        JR      c,L1FA8                 ; 1FB3  38f3
        ADD     HL,DE                   ; 1FB5  19
L1FB6:
        SRA     H                       ; 1FB6  cb2c
        RR      L                       ; 1FB8  cb1d
        RR      B                       ; 1FBA  cb18
        RR      C                       ; 1FBC  cb19
        DEC     A                       ; 1FBE  3d
        JR      nz,L1FA3                ; 1FBF  20e2
L1FC1:
        LD      A,H                     ; 1FC1  7c
        OR      L                       ; 1FC2  b5
        SCF                             ; 1FC3  37
        RET     nz                      ; 1FC4  c0
        LD      A,1FH                   ; 1FC5  3e1f
        CP      B                       ; 1FC7  b8
        RET                             ; 1FC8  c9
L1FC9:
        ADD     A,IXL                   ; 1FC9  dd85
        LD      IXL,A                   ; 1FCB  dd6f
        RET     nc                      ; 1FCD  d0
        INC     IXU                     ; 1FCE  dd24
        RET                             ; 1FD0  c9
L1FD1:
        LD      HL,FAC_TYPE             ; 1FD1  21e142
        LD      A,(HL)                  ; 1FD4  7e
        DEC     A                       ; 1FD5  3d
        JR      z,L1FDA                 ; 1FD6  2802
        INC     HL                      ; 1FD8  23
        INC     HL                      ; 1FD9  23
L1FDA:
        INC     HL                      ; 1FDA  23
        LD      A,(HL)                  ; 1FDB  7e
        INC     HL                      ; 1FDC  23
        LD      L,(HL)                  ; 1FDD  6e
        LD      C,2                     ; 1FDE  0e02
        OR      L                       ; 1FE0  b5
        RET     z                       ; 1FE1  c8
        DEC     C                       ; 1FE2  0d
        RL      L                       ; 1FE3  cb15
        RET     c                       ; 1FE5  d8
        LD      C,4                     ; 1FE6  0e04
        RET                             ; 1FE8  c9
L1FE9:
        LD      A,C                     ; 1FE9  79
        SUB     B                       ; 1FEA  90
        PUSH    AF                      ; 1FEB  f5
        JR      nc,L1FEF                ; 1FEC  3001
        LD      B,C                     ; 1FEE  41
L1FEF:
        LD      A,B                     ; 1FEF  78
        OR      B                       ; 1FF0  b0
        JR      nz,L1FFD                ; 1FF1  200a
        POP     AF                      ; 1FF3  f1
        LD      C,2                     ; 1FF4  0e02
        RET     z                       ; 1FF6  c8
        LD      C,1                     ; 1FF7  0e01
        RET     nc                      ; 1FF9  d0
        LD      C,4                     ; 1FFA  0e04
        RET                             ; 1FFC  c9
L1FFD:
        LD      A,(DE)                  ; 1FFD  1a
        INC     DE                      ; 1FFE  13
        CP      (HL)                    ; 1FFF  be
        INC     HL                      ; 2000  23
        JR      nz,L201D                ; 2001  201a
        DJNZ    L1FFD                   ; 2003  10f8
        POP     AF                      ; 2005  f1
        LD      C,2                     ; 2006  0e02
        RET     z                       ; 2008  c8
        LD      C,1                     ; 2009  0e01
        JR      nc,L2012                ; 200B  3005
        NEG                             ; 200D  ed44
        EX      DE,HL                   ; 200F  eb
        LD      C,4                     ; 2010  0e04
L2012:
        LD      B,A                     ; 2012  47
        LD      A,20H                   ; 2013  3e20
L2015:
        CP      (HL)                    ; 2015  be
        INC     HL                      ; 2016  23
        RET     nz                      ; 2017  c0
        DJNZ    L2015                   ; 2018  10fb
        LD      C,2                     ; 201A  0e02
        RET                             ; 201C  c9
L201D:
        POP     BC                      ; 201D  c1
        LD      C,1                     ; 201E  0e01
        RET     c                       ; 2020  d8
        LD      C,4                     ; 2021  0e04
        RET                             ; 2023  c9
L2024:
        LD      HL,(41B7H)              ; 2024  2ab741
L2027:
        INC     HL                      ; 2027  23
        LD      A,(HL)                  ; 2028  7e
        CPL                             ; 2029  2f
        LD      (HL),A                  ; 202A  77
        CP      (HL)                    ; 202B  be
        LD      (HL),0                  ; 202C  3600
        JR      nz,L2039                ; 202E  2009
        DEC     DE                      ; 2030  1b
        LD      A,D                     ; 2031  7a
        OR      E                       ; 2032  b3
        JR      nz,L2027                ; 2033  20f2
        LD      (41B7H),HL              ; 2035  22b741
        RET                             ; 2038  c9
L2039:
        LD      A,83H                   ; 2039  3e83
        PUSH    HL                      ; 203B  e5
        CALL    ERROR                   ; 203C  cd5933
        POP     HL                      ; 203F  e1
        DEC     HL                      ; 2040  2b
        LD      (41B7H),HL              ; 2041  22b741
        INC     HL                      ; 2044  23
        CALL    L255D                   ; 2045  cd5d25
        JP      CH_CRLF                 ; 2048  c3ce35
L204B:
        CALL    L3308                   ; 204B  cd0833
        RET     c                       ; 204E  d8
        LD      B,0                     ; 204F  0600
        JR      L2057                   ; 2051  1804
L2053:
        LD      C,(HL)                  ; 2053  4e
        INC     C                       ; 2054  0c
        LD      B,0                     ; 2055  0600
L2057:
        PUSH    HL                      ; 2057  e5
        ADD     HL,BC                   ; 2058  09
        LD      DE,(419CH)              ; 2059  ed5b9c41
        AND     A                       ; 205D  a7
        SBC     HL,DE                   ; 205E  ed52
        POP     HL                      ; 2060  e1
        JR      nz,L2068                ; 2061  2005
        LD      (419CH),HL              ; 2063  229c41
        JR      L2078                   ; 2066  1810
L2068:
        LD      A,B                     ; 2068  78
        AND     A                       ; 2069  a7
        JR      nz,L2072                ; 206A  2006
        LD      A,4                     ; 206C  3e04
        CP      C                       ; 206E  b9
        JR      c,L2072                 ; 206F  3801
        LD      C,A                     ; 2071  4f
L2072:
        LD      DE,41A4H                ; 2072  11a441
        CALL    L32FB                   ; 2075  cdfb32
L2078:
        INC     HL                      ; 2078  23
        INC     HL                      ; 2079  23
        LD      E,(HL)                  ; 207A  5e
        LD      (HL),C                  ; 207B  71
        INC     HL                      ; 207C  23
        LD      D,(HL)                  ; 207D  56
        LD      (HL),B                  ; 207E  70
        AND     A                       ; 207F  a7
        RET                             ; 2080  c9
L2081:
        LD      DE,(419AH)              ; 2081  ed5b9a41
L2085:
        PUSH    DE                      ; 2085  d5
        PUSH    HL                      ; 2086  e5
        INC     BC                      ; 2087  03
        INC     BC                      ; 2088  03
        CALL    L20B5                   ; 2089  cdb520
        EX      DE,HL                   ; 208C  eb
        POP     HL                      ; 208D  e1
        PUSH    DE                      ; 208E  d5
        INC     DE                      ; 208F  13
        INC     DE                      ; 2090  13
        DEC     BC                      ; 2091  0b
        DEC     BC                      ; 2092  0b
        LDIR                            ; 2093  edb0
        POP     HL                      ; 2095  e1
        POP     DE                      ; 2096  d1
        JP      L32FB                   ; 2097  c3fb32
L209A:
        LD      HL,4002H                ; 209A  210240
L209D:
        LD      C,(HL)                  ; 209D  4e
        INC     C                       ; 209E  0c
        LD      B,0                     ; 209F  0600
L20A1:
        LD      DE,(419AH)              ; 20A1  ed5b9a41
        PUSH    DE                      ; 20A5  d5
        PUSH    HL                      ; 20A6  e5
        CALL    L20B5                   ; 20A7  cdb520
        EX      DE,HL                   ; 20AA  eb
        POP     HL                      ; 20AB  e1
        PUSH    DE                      ; 20AC  d5
        LDIR                            ; 20AD  edb0
        POP     DE                      ; 20AF  d1
        POP     HL                      ; 20B0  e1
        LD      (419AH),HL              ; 20B1  229a41
        RET                             ; 20B4  c9
L20B5:
        LD      DE,41A4H                ; 20B5  11a441
        LD      HL,0FFFFH               ; 20B8  21ffff
        LD      (41C3H),HL              ; 20BB  22c341
        LD      A,B                     ; 20BE  78
        AND     A                       ; 20BF  a7
        JR      nz,L20C8                ; 20C0  2006
        LD      A,4                     ; 20C2  3e04
        CP      C                       ; 20C4  b9
        JR      c,L20C8                 ; 20C5  3801
        LD      C,A                     ; 20C7  4f
L20C8:
        LD      H,B                     ; 20C8  60
        LD      L,C                     ; 20C9  69
        PUSH    BC                      ; 20CA  c5
        LD      A,6                     ; 20CB  3e06
        CALL    LINE_FIND               ; 20CD  cd3533
        JR      z,L20FC                 ; 20D0  282a
        BIT     1,A                     ; 20D2  cb4f
        POP     BC                      ; 20D4  c1
        JP      nz,L3308                ; 20D5  c20833
        AND     A                       ; 20D8  a7
        SBC     HL,BC                   ; 20D9  ed42
        EX      DE,HL                   ; 20DB  eb
        LD      HL,(41C3H)              ; 20DC  2ac341
        SBC     HL,DE                   ; 20DF  ed52
        JR      c,L20F7                 ; 20E1  3814
        PUSH    DE                      ; 20E3  d5
        EX      DE,HL                   ; 20E4  eb
        LD      DE,4                    ; 20E5  110400
        SBC     HL,DE                   ; 20E8  ed52
        POP     DE                      ; 20EA  d1
        JR      c,L20F7                 ; 20EB  380a
        LD      HL,(419AH)              ; 20ED  2a9a41
        LD      (41C5H),HL              ; 20F0  22c541
        LD      (41C3H),DE              ; 20F3  ed53c341
L20F7:
        CALL    LINE_NEXT               ; 20F7  cd1f33
        JR      L20C8                   ; 20FA  18cc
L20FC:
        POP     BC                      ; 20FC  c1
        LD      HL,(41C3H)              ; 20FD  2ac341
        LD      A,H                     ; 2100  7c
        AND     L                       ; 2101  a5
        INC     A                       ; 2102  3c
        JR      nz,L212F                ; 2103  202a
        LD      HL,(41B7H)              ; 2105  2ab741
        LD      DE,(419CH)              ; 2108  ed5b9c41
        SBC     HL,DE                   ; 210C  ed52
        SBC     HL,BC                   ; 210E  ed42
        LD      A,2                     ; 2110  3e02
        JP      c,ERROR                 ; 2112  da5933
        LD      H,B                     ; 2115  60
        LD      L,C                     ; 2116  69
        ADD     HL,DE                   ; 2117  19
        LD      (419CH),HL              ; 2118  229c41
        PUSH    DE                      ; 211B  d5
        PUSH    BC                      ; 211C  c5
        EX      DE,HL                   ; 211D  eb
        LD      HL,(41B7H)              ; 211E  2ab741
        SBC     HL,DE                   ; 2121  ed52
        LD      DE,0C8H                 ; 2123  11c800
        SBC     HL,DE                   ; 2126  ed52
        LD      A,81H                   ; 2128  3e81
        CALL    c,ERROR                 ; 212A  dc5933
        JR      L2140                   ; 212D  1811
L212F:
        LD      DE,(41C5H)              ; 212F  ed5bc541
        CALL    L330C                   ; 2133  cd0c33
        PUSH    HL                      ; 2136  e5
        PUSH    BC                      ; 2137  c5
        ADD     HL,BC                   ; 2138  09
        LD      BC,(41C3H)              ; 2139  ed4bc341
        CALL    L2057                   ; 213D  cd5720
L2140:
        POP     BC                      ; 2140  c1
        POP     HL                      ; 2141  e1
        RET                             ; 2142  c9
L2143:
        LD      A,6                     ; 2143  3e06
        LD      DE,41ACH                ; 2145  11ac41
        PUSH    HL                      ; 2148  e5
        CALL    LINE_FIND               ; 2149  cd3533
        POP     HL                      ; 214C  e1
        LD      D,B                     ; 214D  50
        LD      E,C                     ; 214E  59
        BIT     1,A                     ; 214F  cb4f
        RET     nz                      ; 2151  c0
        PUSH    HL                      ; 2152  e5
        LD      (41CBH),HL              ; 2153  22cb41
        BIT     4,L                     ; 2156  cb65
        LD      HL,41D2H                ; 2158  21d241
        LD      B,6                     ; 215B  0606
L215D:
        LD      (HL),0                  ; 215D  3600
        DEC     HL                      ; 215F  2b
        DJNZ    L215D                   ; 2160  10fb
        DEC     HL                      ; 2162  2b
        LD      C,4                     ; 2163  0e04
        JR      z,L2169                 ; 2165  2802
        LD      C,8                     ; 2167  0e08
L2169:
        CALL    L2081                   ; 2169  cd8120
        EX      DE,HL                   ; 216C  eb
        POP     HL                      ; 216D  e1
        RET                             ; 216E  c9
        DB      0E6H,1FH,47H,7DH,0E6H,1FH,17H,17H ; 216F ..G}....
        DB      17H,6FH,7CH,0D6H,20H,0E6H,3FH,67H ; 2177 .o|. .?g
        DB      29H,29H,7DH,0B0H,6FH,0C9H ; 217F ))}.o.
L2185:
        LD      H,0                     ; 2185  2600
        LD      L,A                     ; 2187  6f
        LD      DE,41AEH                ; 2188  11ae41
L218B:
        LD      A,6                     ; 218B  3e06
        PUSH    HL                      ; 218D  e5
        CALL    LINE_FIND               ; 218E  cd3533
        BIT     1,A                     ; 2191  cb4f
        JR      z,L21C3                 ; 2193  282e
        PUSH    BC                      ; 2195  c5
        LD      A,L                     ; 2196  7d
        LD      HL,4                    ; 2197  210400
        ADD     HL,BC                   ; 219A  09
        LD      E,(HL)                  ; 219B  5e
        INC     HL                      ; 219C  23
        LD      D,(HL)                  ; 219D  56
        LD      HL,4002H                ; 219E  210240
        LD      B,(HL)                  ; 21A1  46
        CP      8BH                     ; 21A2  fe8b
        JR      z,L21A8                 ; 21A4  2802
        INC     HL                      ; 21A6  23
        DEC     B                       ; 21A7  05
L21A8:
        INC     B                       ; 21A8  04
        LD      C,B                     ; 21A9  48
        CALL    L1FE9                   ; 21AA  cde91f
        BIT     1,C                     ; 21AD  cb49
        POP     BC                      ; 21AF  c1
        POP     HL                      ; 21B0  e1
        JR      nz,L21BA                ; 21B1  2007
        PUSH    HL                      ; 21B3  e5
        CALL    LINE_NEXT               ; 21B4  cd1f33
        POP     HL                      ; 21B7  e1
        JR      L218B                   ; 21B8  18d1
L21BA:
        LD      (4003H),HL              ; 21BA  220340
        PUSH    BC                      ; 21BD  c5
        POP     HL                      ; 21BE  e1
        LD      (4005H),HL              ; 21BF  220540
        RET                             ; 21C2  c9
L21C3:
        LD      HL,(419AH)              ; 21C3  2a9a41
        EX      (SP),HL                 ; 21C6  e3
        PUSH    HL                      ; 21C7  e5
        LD      A,8BH                   ; 21C8  3e8b
        CP      L                       ; 21CA  bd
        LD      HL,4003H                ; 21CB  210340
        LD      A,(4002H)               ; 21CE  3a0240
        LD      C,A                     ; 21D1  4f
        LD      B,0                     ; 21D2  0600
        JR      nz,L21E0                ; 21D4  200a
        LD      A,C                     ; 21D6  79
        AND     A                       ; 21D7  a7
        JR      nz,L21DE                ; 21D8  2004
        LD      D,A                     ; 21DA  57
        LD      E,A                     ; 21DB  5f
        JR      L21E3                   ; 21DC  1805
L21DE:
        INC     BC                      ; 21DE  03
        DEC     HL                      ; 21DF  2b
L21E0:
        CALL    L20A1                   ; 21E0  cda120
L21E3:
        POP     HL                      ; 21E3  e1
        LD      (4003H),HL              ; 21E4  220340
        LD      (4005H),DE              ; 21E7  ed530540
        LD      HL,4003H                ; 21EB  210340
        LD      BC,4                    ; 21EE  010400
        POP     DE                      ; 21F1  d1
        CALL    L2081                   ; 21F2  cd8120
        LD      (4005H),HL              ; 21F5  220540
        RET                             ; 21F8  c9
L21F9:
        LD      DE,41A8H                ; 21F9  11a841
        JR      L2201                   ; 21FC  1803
L21FE:
        LD      DE,41A6H                ; 21FE  11a641
L2201:
        LD      (41CDH),HL              ; 2201  22cd41
        LD      HL,(418CH)              ; 2204  2a8c41
        LD      (41CBH),HL              ; 2207  22cb41
L220A:
        LD      HL,0FFFFH               ; 220A  21ffff
        LD      (41CFH),HL              ; 220D  22cf41
        LD      HL,41C1H                ; 2210  21c141
        SET     7,(HL)                  ; 2213  cbfe
        LD      HL,41CBH                ; 2215  21cb41
        LD      BC,6                    ; 2218  010600
        JP      L2085                   ; 221B  c38520
L221E:
        LD      DE,41AAH                ; 221E  11aa41
        LD      (41CBH),HL              ; 2221  22cb41
        LD      A,6                     ; 2224  3e06
        CALL    LINE_FIND               ; 2226  cd3533
        BIT     1,A                     ; 2229  cb4f
        JR      z,L2241                 ; 222B  2814
        LD      HL,4                    ; 222D  210400
        ADD     HL,BC                   ; 2230  09
        PUSH    DE                      ; 2231  d5
        LD      E,(HL)                  ; 2232  5e
        INC     HL                      ; 2233  23
        LD      D,(HL)                  ; 2234  56
        LD      HL,(418CH)              ; 2235  2a8c41
        AND     A                       ; 2238  a7
        SBC     HL,DE                   ; 2239  ed52
        LD      A,12                    ; 223B  3e0c
        JP      nz,ERROR                ; 223D  c25933
        POP     DE                      ; 2240  d1
L2241:
        LD      DE,(419AH)              ; 2241  ed5b9a41
        LD      HL,(418CH)              ; 2245  2a8c41
        LD      (41CDH),HL              ; 2248  22cd41
        JR      L220A                   ; 224B  18bd
L224D:
        LD      HL,(41BBH)              ; 224D  2abb41
        LD      A,H                     ; 2250  7c
        OR      L                       ; 2251  b5
        RET     nz                      ; 2252  c0
        LD      HL,(41B9H)              ; 2253  2ab941
        LD      A,H                     ; 2256  7c
        OR      L                       ; 2257  b5
        JR      nz,L225B                ; 2258  2001
        DEC     HL                      ; 225A  2b
L225B:
        LD      (41BBH),HL              ; 225B  22bb41
        RET                             ; 225E  c9
L225F:
        LD      DE,41B0H                ; 225F  11b041
        LD      HL,(41B9H)              ; 2262  2ab941
        LD      A,6                     ; 2265  3e06
        JP      LINE_FIND               ; 2267  c33533
L226A:
        LD      A,3                     ; 226A  3e03
        LD      HL,(41BBH)              ; 226C  2abb41
        JP      L3331                   ; 226F  c33133
L2272:
        LD      DE,41B0H                ; 2272  11b041
        LD      A,6                     ; 2275  3e06
        CALL    LINE_FIND               ; 2277  cd3533
        BIT     1,A                     ; 227A  cb4f
        JR      z,L229C                 ; 227C  281e
        LD      HL,4                    ; 227E  210400
        ADD     HL,BC                   ; 2281  09
        LD      E,(HL)                  ; 2282  5e
        INC     HL                      ; 2283  23
        LD      D,(HL)                  ; 2284  56
        INC     HL                      ; 2285  23
        PUSH    HL                      ; 2286  e5
        LD      A,E                     ; 2287  7b
        OR      D                       ; 2288  b2
        EX      DE,HL                   ; 2289  eb
        CALL    nz,L2053                ; 228A  c45320
        POP     HL                      ; 228D  e1
        LD      E,(HL)                  ; 228E  5e
        INC     HL                      ; 228F  23
        LD      D,(HL)                  ; 2290  56
        LD      A,D                     ; 2291  7a
        OR      E                       ; 2292  b3
        EX      DE,HL                   ; 2293  eb
        CALL    nz,L2053                ; 2294  c45320
        LD      C,8                     ; 2297  0e08
        CALL    L204B                   ; 2299  cd4b20
L229C:
        LD      HL,(419AH)              ; 229C  2a9a41
        PUSH    HL                      ; 229F  e5
        LD      DE,41A6H                ; 22A0  11a641
        LD      A,1                     ; 22A3  3e01
L22A5:
        PUSH    AF                      ; 22A5  f5
L22A6:
        LD      HL,(418CH)              ; 22A6  2a8c41
        LD      A,2                     ; 22A9  3e02
        CALL    LINE_FIND               ; 22AB  cd3533
        JR      z,L22B5                 ; 22AE  2805
        CALL    L22FD                   ; 22B0  cdfd22
        JR      L22A6                   ; 22B3  18f1
L22B5:
        LD      DE,41A8H                ; 22B5  11a841
        POP     AF                      ; 22B8  f1
        DEC     A                       ; 22B9  3d
        JR      z,L22A5                 ; 22BA  28e9
        LD      HL,41AAH                ; 22BC  21aa41
        CALL    LINE_SET                ; 22BF  cd2633
        JR      z,L22DD                 ; 22C2  2819
L22C4:
        LD      B,H                     ; 22C4  44
        LD      C,L                     ; 22C5  4d
        INC     HL                      ; 22C6  23
        INC     HL                      ; 22C7  23
        INC     HL                      ; 22C8  23
        INC     HL                      ; 22C9  23
        LD      E,(HL)                  ; 22CA  5e
        INC     HL                      ; 22CB  23
        LD      D,(HL)                  ; 22CC  56
        AND     A                       ; 22CD  a7
        LD      HL,(418CH)              ; 22CE  2a8c41
        SBC     HL,DE                   ; 22D1  ed52
        JR      nz,L22D8                ; 22D3  2003
        CALL    L22FD                   ; 22D5  cdfd22
L22D8:
        CALL    LINE_NEXT               ; 22D8  cd1f33
        JR      nz,L22C4                ; 22DB  20e7
L22DD:
        LD      DE,41B2H                ; 22DD  11b241
        LD      HL,(418CH)              ; 22E0  2a8c41
        LD      A,2                     ; 22E3  3e02
        CALL    LINE_FIND               ; 22E5  cd3533
        JR      z,L22F8                 ; 22E8  280e
        LD      H,B                     ; 22EA  60
        LD      L,C                     ; 22EB  69
        INC     BC                      ; 22EC  03
        INC     BC                      ; 22ED  03
        INC     BC                      ; 22EE  03
        INC     BC                      ; 22EF  03
        LD      A,(BC)                  ; 22F0  0a
        ADD     A,A                     ; 22F1  87
        ADD     A,5                     ; 22F2  c605
        LD      C,A                     ; 22F4  4f
        CALL    L204B                   ; 22F5  cd4b20
L22F8:
        POP     HL                      ; 22F8  e1
        LD      (419AH),HL              ; 22F9  229a41
        RET                             ; 22FC  c9
L22FD:
        LD      HL,6                    ; 22FD  210600
        ADD     HL,BC                   ; 2300  09
        LD      A,(HL)                  ; 2301  7e
        LD      (HL),0                  ; 2302  3600
        INC     HL                      ; 2304  23
        AND     (HL)                    ; 2305  a6
        LD      (HL),0                  ; 2306  3600
        INC     A                       ; 2308  3c
        JR      nz,L230E                ; 2309  2003
        LD      D,B                     ; 230B  50
        LD      E,C                     ; 230C  59
        RET                             ; 230D  c9
L230E:
        PUSH    BC                      ; 230E  c5
        LD      C,8                     ; 230F  0e08
        CALL    L204B                   ; 2311  cd4b20
        POP     DE                      ; 2314  d1
        RET                             ; 2315  c9
L2316:
        LD      A,IXL                   ; 2316  dd7d
        SUB     12                      ; 2318  d60c
        LD      (410BH),A               ; 231A  320b41
        LD      HL,(418CH)              ; 231D  2a8c41
        LD      A,H                     ; 2320  7c
        OR      L                       ; 2321  b5
        RET     z                       ; 2322  c8
        CALL    L2272                   ; 2323  cd7222
        CALL    L2374                   ; 2326  cd7423
        LD      DE,0                    ; 2329  110000
        LD      A,(41B4H)               ; 232C  3ab441
        AND     A                       ; 232F  a7
        CALL    nz,L209A                ; 2330  c49a20
        LD      (418EH),DE              ; 2333  ed538e41
        LD      DE,0                    ; 2337  110000
        LD      HL,410BH                ; 233A  210b41
        LD      A,(HL)                  ; 233D  7e
        AND     A                       ; 233E  a7
        CALL    nz,L209D                ; 233F  c49d20
        LD      (4190H),DE              ; 2342  ed539041
        LD      BC,6                    ; 2346  010600
        LD      HL,418CH                ; 2349  218c41
        CALL    L2081                   ; 234C  cd8120
        LD      HL,41C1H                ; 234F  21c141
        BIT     3,(HL)                  ; 2352  cb5e
        RET     z                       ; 2354  c8
        RES     3,(HL)                  ; 2355  cb9e
        LD      HL,(418CH)              ; 2357  2a8c41
        LD      (410BH),HL              ; 235A  220b41
        LD      DE,41B2H                ; 235D  11b241
        LD      A,4                     ; 2360  3e04
        CALL    LINE_FIND               ; 2362  cd3533
        LD      HL,410BH                ; 2365  210b41
        LD      A,(410DH)               ; 2368  3a0d41
        ADD     A,A                     ; 236B  87
        ADD     A,3                     ; 236C  c603
        LD      B,0                     ; 236E  0600
        LD      C,A                     ; 2370  4f
        JP      L2081                   ; 2371  c38120
L2374:
        LD      DE,(4084H)              ; 2374  ed5b8440
        DEC     DE                      ; 2378  1b
        LD      HL,4003H                ; 2379  210340
        LD      BC,0C0FFH               ; 237C  01ffc0
L237F:
        INC     DE                      ; 237F  13
        LD      A,(DE)                  ; 2380  1a
        CP      20H                     ; 2381  fe20
        JR      nz,L2388                ; 2383  2003
        INC     B                       ; 2385  04
        JR      L237F                   ; 2386  18f7
L2388:
        LD      A,0C0H                  ; 2388  3ec0
        CP      B                       ; 238A  b8
        JR      z,L2391                 ; 238B  2804
        LD      (HL),B                  ; 238D  70
        INC     HL                      ; 238E  23
        INC     C                       ; 238F  0c
        LD      B,A                     ; 2390  47
L2391:
        LD      A,(DE)                  ; 2391  1a
        LD      (HL),A                  ; 2392  77
        INC     HL                      ; 2393  23
        INC     C                       ; 2394  0c
        CP      1EH                     ; 2395  fe1e
        JR      nz,L237F                ; 2397  20e6
        LD      A,C                     ; 2399  79
        LD      (4002H),A               ; 239A  320240
        RET                             ; 239D  c9
L239E:
        LD      C,(HL)                  ; 239E  4e
L239F:
        INC     HL                      ; 239F  23
        LD      A,(HL)                  ; 23A0  7e
        AND     0C0H                    ; 23A1  e6c0
        CP      0C0H                    ; 23A3  fec0
        LD      A,(HL)                  ; 23A5  7e
        JR      z,L23B2                 ; 23A6  280a
        CALL    CH_OUT                  ; 23A8  cddb34
        LD      A,(HL)                  ; 23AB  7e
L23AC:
        DEC     C                       ; 23AC  0d
        JP      z,L3614                 ; 23AD  ca1436
        JR      L239F                   ; 23B0  18ed
L23B2:
        AND     3FH                     ; 23B2  e63f
        LD      B,A                     ; 23B4  47
L23B5:
        CALL    L3619                   ; 23B5  cd1936
        DJNZ    L23B5                   ; 23B8  10fb
        JR      L23AC                   ; 23BA  18f0

;=====================================================================
; ZWISCHENCODE-ERZEUGUNG
; EMIT_BYTE: A in den Zwischencode-Puffer schreiben.
;=====================================================================
EMIT_BYTE:
        LD      (IX),A                  ; 23BC  dd7700
        INC     IX                      ; 23BF  dd23
        PUSH    AF                      ; 23C1  f5
        CP      1EH                     ; 23C2  fe1e
        LD      A,(41C1H)               ; 23C4  3ac141
        RES     6,A                     ; 23C7  cbb7
        JR      nz,L23CD                ; 23C9  2002
        SET     6,A                     ; 23CB  cbf7
L23CD:
        LD      (41C1H),A               ; 23CD  32c141
        LD      A,IXL                   ; 23D0  dd7d
        SUB     12                      ; 23D2  d60c
        CP      7BH                     ; 23D4  fe7b
        LD      A,13                    ; 23D6  3e0d
        JP      nc,ERROR                ; 23D8  d25933
        POP     AF                      ; 23DB  f1
        RET                             ; 23DC  c9
L23DD:
        CALL    EMIT_BYTE               ; 23DD  cdbc23
L23E0:
        LD      (IX),L                  ; 23E0  dd7500
        INC     IX                      ; 23E3  dd23
        LD      (IX),H                  ; 23E5  dd7400
        INC     IX                      ; 23E8  dd23
        RET                             ; 23EA  c9
L23EB:
        CALL    EMIT_BYTE               ; 23EB  cdbc23
L23EE:
        CALL    L2430                   ; 23EE  cd3024
        JR      L23E0                   ; 23F1  18ed
        DB      3EH,1EH,0CDH,0EBH,23H,0C3H,30H,25H ; 23F3 >...#.0%
L23FB:
        LD      B,A                     ; 23FB  47
        RLCA                            ; 23FC  07
        RLCA                            ; 23FD  07
        RLCA                            ; 23FE  07
        AND     7                       ; 23FF  e607
        LD      H,A                     ; 2401  67
        LD      A,B                     ; 2402  78
        AND     1FH                     ; 2403  e61f
        LD      L,A                     ; 2405  6f
        RET                             ; 2406  c9
L2407:
        LD      HL,0FFFFH               ; 2407  21ffff
L240A:
        LD      DE,(4192H)              ; 240A  ed5b9241
        LD      (4192H),HL              ; 240E  229241
        LD      HL,(4194H)              ; 2411  2a9441
        LD      (4194H),DE              ; 2414  ed539441
        LD      A,H                     ; 2418  7c
        OR      L                       ; 2419  b5
        RET     z                       ; 241A  c8
        LD      A,H                     ; 241B  7c
        AND     L                       ; 241C  a5
        INC     A                       ; 241D  3c
        CALL    z,L2459                 ; 241E  cc5924
        LD      (41CBH),HL              ; 2421  22cb41
        LD      HL,41CBH                ; 2424  21cb41
        LD      DE,419EH                ; 2427  119e41
        LD      BC,2                    ; 242A  010200
        JP      L2085                   ; 242D  c38520
L2430:
        PUSH    AF                      ; 2430  f5
        LD      DE,419EH                ; 2431  119e41
        CALL    L330C                   ; 2434  cd0c33
        JR      c,L2440                 ; 2437  3807
        LD      BC,4                    ; 2439  010400
        CALL    L2057                   ; 243C  cd5720
        EX      DE,HL                   ; 243F  eb
L2440:
        LD      DE,(4194H)              ; 2440  ed5b9441
        LD      (4194H),HL              ; 2444  229441
        LD      HL,(4192H)              ; 2447  2a9241
        LD      (4192H),DE              ; 244A  ed539241
        POP     AF                      ; 244E  f1
        RET                             ; 244F  c9
L2450:
        LD      DE,(4192H)              ; 2450  ed5b9241
        LD      (4192H),HL              ; 2454  229241
        EX      DE,HL                   ; 2457  eb
        RET                             ; 2458  c9
L2459:
        LD      HL,41C1H                ; 2459  21c141
        BIT     6,(HL)                  ; 245C  cb76
        RES     6,(HL)                  ; 245E  cbb6
        JR      z,L2485                 ; 2460  2823
        LD      A,(IX-3)                ; 2462  dd7efd
        CP      1EH                     ; 2465  fe1e
        JR      nz,L2485                ; 2467  201c
        LD      H,(IX-1)                ; 2469  dd66ff
        LD      L,(IX-2)                ; 246C  dd6efe
        DEC     IX                      ; 246F  dd2b
        DEC     IX                      ; 2471  dd2b
        DEC     IX                      ; 2473  dd2b
        PUSH    HL                      ; 2475  e5
        INC     HL                      ; 2476  23
        INC     HL                      ; 2477  23
        LD      A,(HL)                  ; 2478  7e
        CP      0ACH                    ; 2479  feac
        JR      z,L2481                 ; 247B  2804
        CP      0ADH                    ; 247D  fead
        JR      nz,L2483                ; 247F  2002
L2481:
        RES     5,(HL)                  ; 2481  cbae
L2483:
        POP     HL                      ; 2483  e1
        RET                             ; 2484  c9
L2485:
        CALL    L2540                   ; 2485  cd4025
        LD      A,20H                   ; 2488  3e20
        JP      L23DD                   ; 248A  c3dd23
L248D:
        LD      HL,(4192H)              ; 248D  2a9241
        LD      A,H                     ; 2490  7c
        AND     L                       ; 2491  a5
        INC     A                       ; 2492  3c
        CALL    z,L2459                 ; 2493  cc5924
        LD      (4192H),HL              ; 2496  229241
        LD      HL,(4194H)              ; 2499  2a9441
        LD      A,H                     ; 249C  7c
        AND     L                       ; 249D  a5
        INC     A                       ; 249E  3c
        CALL    z,L2459                 ; 249F  cc5924
        LD      (4194H),HL              ; 24A2  229441
        RET                             ; 24A5  c9
L24A6:
        LD      DE,41A2H                ; 24A6  11a241
        LD      BC,2                    ; 24A9  010200
        LD      HL,4196H                ; 24AC  219641
        CALL    L2085                   ; 24AF  cd8520
        LD      HL,(4198H)              ; 24B2  2a9841
        LD      (4196H),HL              ; 24B5  229641
        RET                             ; 24B8  c9
L24B9:
        LD      DE,41A2H                ; 24B9  11a241
        CALL    L330C                   ; 24BC  cd0c33
        JR      c,L24C8                 ; 24BF  3807
        LD      BC,4                    ; 24C1  010400
        CALL    L2057                   ; 24C4  cd5720
        EX      DE,HL                   ; 24C7  eb
L24C8:
        LD      (4196H),HL              ; 24C8  229641
        RET                             ; 24CB  c9
L24CC:
        LD      A,(4197H)               ; 24CC  3a9741
        CP      5                       ; 24CF  fe05
        JR      c,L24EF                 ; 24D1  381c
        LD      HL,(4192H)              ; 24D3  2a9241
        LD      A,H                     ; 24D6  7c
        AND     L                       ; 24D7  a5
        INC     A                       ; 24D8  3c
        JR      z,L24E9                 ; 24D9  280e
        LD      HL,0FFFFH               ; 24DB  21ffff
        CALL    L2450                   ; 24DE  cd5024
        CALL    L2530                   ; 24E1  cd3025
        LD      A,1EH                   ; 24E4  3e1e
        CALL    L23DD                   ; 24E6  cddd23
L24E9:
        LD      A,(4196H)               ; 24E9  3a9641
        JP      EMIT_BYTE               ; 24EC  c3bc23
L24EF:
        LD      HL,(4194H)              ; 24EF  2a9441
        LD      A,H                     ; 24F2  7c
        AND     L                       ; 24F3  a5
        INC     A                       ; 24F4  3c
        JR      z,L2524                 ; 24F5  282d
        LD      HL,(4192H)              ; 24F7  2a9241
        LD      A,H                     ; 24FA  7c
        AND     L                       ; 24FB  a5
        INC     A                       ; 24FC  3c
        JR      nz,L2513                ; 24FD  2014
        LD      HL,(4194H)              ; 24FF  2a9441
        LD      (4192H),HL              ; 2502  229241
        LD      A,(4196H)               ; 2505  3a9641
        CP      9                       ; 2508  fe09
        JR      nc,L251E                ; 250A  3012
        INC     A                       ; 250C  3c
        INC     A                       ; 250D  3c
        LD      (4196H),A               ; 250E  329641
        JR      L251E                   ; 2511  180b
L2513:
        LD      HL,(4194H)              ; 2513  2a9441
        CALL    L2530                   ; 2516  cd3025
        LD      A,1EH                   ; 2519  3e1e
        CALL    L23DD                   ; 251B  cddd23
L251E:
        LD      HL,0FFFFH               ; 251E  21ffff
        LD      (4194H),HL              ; 2521  229441
L2524:
        CALL    L2430                   ; 2524  cd3024
        CALL    L2530                   ; 2527  cd3025
        LD      A,(4196H)               ; 252A  3a9641
        JP      L23DD                   ; 252D  c3dd23
L2530:
        INC     HL                      ; 2530  23
        INC     HL                      ; 2531  23
        LD      A,(HL)                  ; 2532  7e
        CP      8CH                     ; 2533  fe8c
        JR      z,L253B                 ; 2535  2804
        CP      8DH                     ; 2537  fe8d
        JR      nz,L253D                ; 2539  2002
L253B:
        SET     5,(HL)                  ; 253B  cbee
L253D:
        DEC     HL                      ; 253D  2b
        DEC     HL                      ; 253E  2b
        RET                             ; 253F  c9
L2540:
        LD      HL,0ACH                 ; 2540  21ac00
L2543:
        CALL    L2143                   ; 2543  cd4321
        EX      DE,HL                   ; 2546  eb
        INC     HL                      ; 2547  23
        INC     HL                      ; 2548  23
        RES     5,(HL)                  ; 2549  cbae
        DEC     HL                      ; 254B  2b
        DEC     HL                      ; 254C  2b
        RET                             ; 254D  c9
L254E:
        LD      A,IXL                   ; 254E  dd7d
        SUB     13                      ; 2550  d60d
        RET                             ; 2552  c9
L2553:
        LD      DE,41CBH                ; 2553  11cb41
        CALL    UINT8_TO_DECIMAL        ; 2556  cdee2d
        LD      B,2                     ; 2559  0602
        JR      L2565                   ; 255B  1808
L255D:
        LD      DE,41CBH                ; 255D  11cb41
        CALL    UINT16_TO_DECIMAL       ; 2560  cdf32d
        LD      B,4                     ; 2563  0604
L2565:
        LD      C,B                     ; 2565  48
        INC     C                       ; 2566  0c
        LD      HL,41CAH                ; 2567  21ca41
        LD      A,30H                   ; 256A  3e30
L256C:
        INC     HL                      ; 256C  23
        CP      (HL)                    ; 256D  be
        JR      nz,L2574                ; 256E  2004
        LD      (HL),20H                ; 2570  3620
        DJNZ    L256C                   ; 2572  10f8
L2574:
        LD      HL,41CBH                ; 2574  21cb41
        LD      B,C                     ; 2577  41
        CALL    L3620                   ; 2578  cd2036
        JP      L3619                   ; 257B  c31936
L257E:
        LD      HL,41C1H                ; 257E  21c141
        BIT     1,(HL)                  ; 2581  cb4e
        RET     z                       ; 2583  c8
        LD      HL,347FH                ; 2584  217f34
        CALL    PRINT_STR               ; 2587  cde735
        LD      HL,(41DAH)              ; 258A  2ada41
        INC     HL                      ; 258D  23
        INC     HL                      ; 258E  23
        LD      E,(HL)                  ; 258F  5e
        INC     HL                      ; 2590  23
        LD      D,(HL)                  ; 2591  56
        EX      DE,HL                   ; 2592  eb
        LD      (41B9H),HL              ; 2593  22b941
        CALL    L255D                   ; 2596  cd5d25
        JP      CH_CRLF                 ; 2599  c3ce35
L259C:
        LD      HL,41C1H                ; 259C  21c141
        BIT     1,(HL)                  ; 259F  cb4e
        RET     z                       ; 25A1  c8
        LD      HL,(41B9H)              ; 25A2  2ab941
        LD      A,H                     ; 25A5  7c
        OR      L                       ; 25A6  b5
        RET     z                       ; 25A7  c8
        LD      DE,(41BBH)              ; 25A8  ed5bbb41
        PUSH    DE                      ; 25AC  d5
        LD      (41BBH),HL              ; 25AD  22bb41
        CALL    L1346                   ; 25B0  cd4613
        POP     HL                      ; 25B3  e1
        LD      (41BBH),HL              ; 25B4  22bb41
        RET                             ; 25B7  c9
; ---- Aktionsbyte: Sprung nach (HL)+(HL), relativ vorwaerts
SYN_ACTION:
        PUSH    BC                      ; 25B8  c5
        PUSH    HL                      ; 25B9  e5
        LD      A,(HL)                  ; 25BA  7e
        ADD     A,L                     ; 25BB  85
        LD      L,A                     ; 25BC  6f
        JR      nc,L25C0                ; 25BD  3001
        INC     H                       ; 25BF  24
L25C0:
        PUSH    HL                      ; 25C0  e5
        LD      HL,25C6H                ; 25C1  21c625
        EX      (SP),HL                 ; 25C4  e3
        JP      (HL)                    ; 25C5  e9
        DB      0E1H,0C1H,23H,0C9H      ; 25C6 ..#.
L25CA:
        AND     A                       ; 25CA  a7
        PUSH    HL                      ; 25CB  e5
        SBC     HL,DE                   ; 25CC  ed52
        LD      L,2                     ; 25CE  2e02
        JR      z,L25D7                 ; 25D0  2805
        DEC     L                       ; 25D2  2d
        JR      nc,L25D7                ; 25D3  3002
        LD      L,4                     ; 25D5  2e04
L25D7:
        AND     L                       ; 25D7  a5
        LD      A,L                     ; 25D8  7d
        POP     HL                      ; 25D9  e1
        RET                             ; 25DA  c9
L25DB:
        JP      nz,FP_ADD_ARG           ; 25DB  c2c326
        CALL    L1F1B                   ; 25DE  cd1b1f
        AND     A                       ; 25E1  a7
        ADC     HL,DE                   ; 25E2  ed5a
        LD      DE,0                    ; 25E4  110000
        JR      L25F9                   ; 25E7  1810
L25E9:
        CCF                             ; 25E9  3f
L25EA:
        CALL    nc,L1F3F                ; 25EA  d43f1f
        JP      nz,FP_SUB_ARG           ; 25ED  c2b626
        CALL    L1F1B                   ; 25F0  cd1b1f
        AND     A                       ; 25F3  a7
        SBC     HL,DE                   ; 25F4  ed52
        LD      DE,0FFFFH               ; 25F6  11ffff
L25F9:
        JR      nc,L25FC                ; 25F9  3001
        DEC     DE                      ; 25FB  1b
L25FC:
        LD      (FAC),HL                ; 25FC  22e242
        RET     po                      ; 25FF  e0
        LD      (42E4H),DE              ; 2600  ed53e442
        JP      INT32_TO_FP             ; 2604  c38132
L2607:
        JP      nz,FP_MUL_ARG           ; 2607  c28d27
        CALL    L266F                   ; 260A  cd6f26
        PUSH    AF                      ; 260D  f5
        LD      A,11H                   ; 260E  3e11
        AND     A                       ; 2610  a7
L2611:
        RR      H                       ; 2611  cb1c
        RR      L                       ; 2613  cb1d
        RR      D                       ; 2615  cb1a
        RR      E                       ; 2617  cb1b
        DEC     A                       ; 2619  3d
        JR      z,L264B                 ; 261A  282f
        JR      nc,L2611                ; 261C  30f3
        ADD     HL,BC                   ; 261E  09
        JR      L2611                   ; 261F  18f0
L2621:
        CCF                             ; 2621  3f
L2622:
        CALL    nc,L1F3F                ; 2622  d43f1f
        JP      nz,FP_DIV_ARG           ; 2625  c2ef27
        CALL    L266F                   ; 2628  cd6f26
        PUSH    AF                      ; 262B  f5
        LD      A,B                     ; 262C  78
        OR      C                       ; 262D  b1
L262E:
        LD      A,28H                   ; 262E  3e28
        JP      z,ERROR                 ; 2630  ca5933
        LD      A,11H                   ; 2633  3e11
        SCF                             ; 2635  37
L2636:
        CCF                             ; 2636  3f
        RL      E                       ; 2637  cb13
        RL      D                       ; 2639  cb12
        ADC     HL,HL                   ; 263B  ed6a
        SBC     HL,BC                   ; 263D  ed42
        JR      nc,L2642                ; 263F  3001
        ADD     HL,BC                   ; 2641  09
L2642:
        DEC     A                       ; 2642  3d
        JR      nz,L2636                ; 2643  20f1
        JR      c,L2648                 ; 2645  3801
        INC     DE                      ; 2647  13
L2648:
        LD      HL,0                    ; 2648  210000
L264B:
        POP     AF                      ; 264B  f1
        AND     A                       ; 264C  a7
        JR      z,L265D                 ; 264D  280e
        PUSH    HL                      ; 264F  e5
        LD      HL,0                    ; 2650  210000
        AND     A                       ; 2653  a7
        SBC     HL,DE                   ; 2654  ed52
        EX      DE,HL                   ; 2656  eb
        LD      HL,0                    ; 2657  210000
        POP     BC                      ; 265A  c1
        SBC     HL,BC                   ; 265B  ed42
L265D:
        LD      (FAC),DE                ; 265D  ed53e242
        LD      (42E4H),HL              ; 2661  22e442
        BIT     7,D                     ; 2664  cb7a
        JR      z,L2669                 ; 2666  2801
        INC     HL                      ; 2668  23
L2669:
        LD      A,H                     ; 2669  7c
        OR      L                       ; 266A  b5
        RET     z                       ; 266B  c8
        JP      INT32_TO_FP             ; 266C  c38132
L266F:
        XOR     A                       ; 266F  af
        LD      HL,0                    ; 2670  210000
        LD      DE,(FAC)                ; 2673  ed5be242
        BIT     7,D                     ; 2677  cb7a
        JR      z,L2683                 ; 2679  2808
        XOR     1                       ; 267B  ee01
        SBC     HL,DE                   ; 267D  ed52
        EX      DE,HL                   ; 267F  eb
        LD      HL,0                    ; 2680  210000
L2683:
        LD      BC,(ARG)                ; 2683  ed4be742
        BIT     7,B                     ; 2687  cb78
        RET     z                       ; 2689  c8
        XOR     1                       ; 268A  ee01
        SBC     HL,BC                   ; 268C  ed42
        LD      B,H                     ; 268E  44
        LD      C,L                     ; 268F  4d
        LD      HL,0                    ; 2690  210000
        RET                             ; 2693  c9
        DB      3AH,0E6H,42H,0A7H,0CBH,7FH,0C0H,0FEH ; 2694 :.B.....
        DB      10H,3FH,0C9H            ; 269C .?.

;=====================================================================
; GLEITKOMMA: FORMAT UND SCHNITTSTELLEN
; FAC = 42E2H..42E6H; ARG = 42E7H..42EBH; FAC_TYPE: 1=Integer, 2=FP.
; Byte 0..2: Mantisse niederwertig zuerst; Byte 3 Bit0..6: Mantisse
; Bit24..30; Byte 3 Bit7: Vorzeichen (1=negativ). Byte 4: signed
; 8-Bit-Binaerexponent e im Zweierkomplement, KEIN Bias.
; Wert = (-1)^s * M * 2^(e-31), M = LE32(Byte0..3) AND 7FFFFFFFH.
; Nichtnull normalisiert: 40000000H <= M <= 7FFFFFFFH, also 31
; signifikante Binaerstellen. Bit6 in Byte3 ist die gespeicherte
; fuehrende Eins, kein eigenes Statusflag. Null: alle 5 Byte null.
; +1 = 00 00 00 40 01; -1 = 00 00 00 C0 01; 0.5 = 00 00 00 40 00.
; ADD/MUL/DIV verwerfen verlorene Bits; keine allgemeine Rundung
; zum naechsten FP-Wert. Integerwandlung und Textausgabe runden separat.
; FAC_LOAD: 5 Byte von (DE) nach FAC; Quelle NICHT in HL.
; Aufrufe veraendern Register und ARG; Details: docs/gleitkomma-bericht.md.
;=====================================================================
FAC_LOAD:
        LD      HL,FAC                  ; 269F  21e242
        JR      L26A7                   ; 26A2  1803
; ---- ARG_LOAD: 5 Byte von (DE) nach ARG; HL/DE/BC werden veraendert.
ARG_LOAD:
        LD      HL,ARG                  ; 26A4  21e742
L26A7:
        EX      DE,HL                   ; 26A7  eb
; ---- MOVE5: (DE) <- (HL), 5 Byte; HL/DE += 5, BC=0.
MOVE5:
        LD      BC,5                    ; 26A8  010500
        LDIR                            ; 26AB  edb0
        RET                             ; 26AD  c9
; ---- FAC_STORE: (DE) <- FAC, 5 Byte
FAC_STORE:
        LD      HL,FAC                  ; 26AE  21e242
        JR      MOVE5                   ; 26B1  18f5
; ---- FP_SUB: FAC <- FAC - (DE); Operand nach ARG laden, dessen Vorzeichen umkehren.
FP_SUB:
        CALL    ARG_LOAD                ; 26B3  cda426
FP_SUB_ARG:
        LD      A,(ARG_SIGN_MSB)        ; 26B6  3aea42
        XOR     80H                     ; 26B9  ee80
        LD      (ARG_SIGN_MSB),A        ; 26BB  32ea42
        JR      FP_ADD_ARG              ; 26BE  1803
; ---- FP_ADD: FAC <- FAC + (DE); Einstieg FP_ADD_ARG nutzt bereits geladenes ARG.
FP_ADD:
        CALL    ARG_LOAD                ; 26C0  cda426
FP_ADD_ARG:
        LD      A,(ARG_SIGN_MSB)        ; 26C3  3aea42
        BIT     6,A                     ; 26C6  cb77
        RET     z                       ; 26C8  c8
        LD      HL,FAC_SIGN_MSB         ; 26C9  21e542
        BIT     6,(HL)                  ; 26CC  cb76
        JR      nz,L26DB                ; 26CE  200b
FP_COPY_ARG:
        LD      L,0E7H                  ; 26D0  2ee7
        LD      DE,FAC                  ; 26D2  11e242
        LD      BC,5                    ; 26D5  010500
        LDIR                            ; 26D8  edb0
        RET                             ; 26DA  c9

;=====================================================================
; ADDITION: EXPONENTEN AUSRICHTEN
; eARG-eFAC signed vergleichen, auch signed Overflow beruecksichtigen.
; Ab Differenz 31 ist der kleinere Operand bedeutungslos und entfaellt.
; Sonst kleinere Mantisse im FAC/ARG-Speicher logisch rechts schieben;
; Vorzeichen sichern, verlorene Bits verwerfen, groesseren Exponenten nehmen.
;=====================================================================
L26DB:
        INC     L                       ; 26DB  2c
        LD      A,(ARG_EXP)             ; 26DC  3aeb42
        SUB     (HL)                    ; 26DF  96
        JP      po,L26E6                ; 26E0  e2e626
        RET     nc                      ; 26E3  d0
        JR      FP_COPY_ARG             ; 26E4  18ea
L26E6:
        JR      z,FP_ADD_MANTISSAS      ; 26E6  2849
        JP      m,L26F1                 ; 26E8  faf126
        CP      1FH                     ; 26EB  fe1f
        JR      nc,FP_COPY_ARG          ; 26ED  30e1
        JR      L26F8                   ; 26EF  1807
L26F1:
        LD      L,0EBH                  ; 26F1  2eeb
        NEG                             ; 26F3  ed44
        CP      1FH                     ; 26F5  fe1f
        RET     nc                      ; 26F7  d0
L26F8:
        LD      B,A                     ; 26F8  47
        ADD     A,(HL)                  ; 26F9  86
        LD      (FAC_EXP),A             ; 26FA  32e642
        LD      A,B                     ; 26FD  78
        DEC     L                       ; 26FE  2d
        LD      B,(HL)                  ; 26FF  46
        DEC     L                       ; 2700  2d
        LD      C,(HL)                  ; 2701  4e
        DEC     L                       ; 2702  2d
        LD      D,(HL)                  ; 2703  56
        DEC     L                       ; 2704  2d
        LD      E,(HL)                  ; 2705  5e
        PUSH    HL                      ; 2706  e5
        LD      H,B                     ; 2707  60
        RES     7,B                     ; 2708  cbb8
FP_ALIGN_BYTES:
        CP      8                       ; 270A  fe08
        JR      c,FP_ALIGN_BITS         ; 270C  380b
        LD      E,D                     ; 270E  5a
        LD      D,C                     ; 270F  51
        LD      C,B                     ; 2710  48
        LD      B,0                     ; 2711  0600
        SUB     8                       ; 2713  d608
        JR      z,L2724                 ; 2715  280d
        JR      FP_ALIGN_BYTES          ; 2717  18f1
FP_ALIGN_BITS:
        SRL     B                       ; 2719  cb38
        RR      C                       ; 271B  cb19
        RR      D                       ; 271D  cb1a
        RR      E                       ; 271F  cb1b
        DEC     A                       ; 2721  3d
        JR      nz,FP_ALIGN_BITS        ; 2722  20f5
L2724:
        LD      A,H                     ; 2724  7c
        AND     80H                     ; 2725  e680
        ADD     A,B                     ; 2727  80
        LD      B,A                     ; 2728  47
        POP     HL                      ; 2729  e1
        LD      (HL),E                  ; 272A  73
        INC     L                       ; 272B  2c
        LD      (HL),D                  ; 272C  72
        INC     L                       ; 272D  2c
        LD      (HL),C                  ; 272E  71
        INC     L                       ; 272F  2c
        LD      (HL),B                  ; 2730  70
; ---- Vorzeichen gleich: Betraege addieren; sonst subtrahieren und ggf. Vorzeichen wechseln.
FP_ADD_MANTISSAS:
        LD      A,(ARG_SIGN_MSB)        ; 2731  3aea42
        LD      DE,(42E4H)              ; 2734  ed5be442
        LD      HL,(FAC)                ; 2738  2ae242
        LD      BC,(ARG)                ; 273B  ed4be742
        XOR     D                       ; 273F  aa
        LD      A,D                     ; 2740  7a
        RES     7,D                     ; 2741  cbba
        JP      m,FP_SUB_MANTISSAS      ; 2743  fa6e27
        ADD     HL,BC                   ; 2746  09
        EX      DE,HL                   ; 2747  eb
        LD      BC,(42E9H)              ; 2748  ed4be942
        RES     7,B                     ; 274C  cbb8
        ADC     HL,BC                   ; 274E  ed4a
        JP      p,FP_STORE_RESULT       ; 2750  f27c27
; ---- Summenbit31 gesetzt: Mantisse halbieren, Exponent erhoehen; keine Aufrundung.
        SRL     H                       ; 2753  cb3c
        RR      L                       ; 2755  cb1d
        RR      D                       ; 2757  cb1a
        RR      E                       ; 2759  cb1b
        LD      B,A                     ; 275B  47
        LD      A,(FAC_EXP)             ; 275C  3ae642
        INC     A                       ; 275F  3c
        LD      (FAC_EXP),A             ; 2760  32e642
        LD      A,B                     ; 2763  78
        JP      po,FP_STORE_RESULT      ; 2764  e27c27
        ADD     A,A                     ; 2767  87
        JP      nc,FP_OVERFLOW          ; 2768  d2ca2c
        JP      FP_OVERFLOW             ; 276B  c3ca2c
FP_SUB_MANTISSAS:
        SBC     HL,BC                   ; 276E  ed42
        EX      DE,HL                   ; 2770  eb
        LD      BC,(42E9H)              ; 2771  ed4be942
        RES     7,B                     ; 2775  cbb8
        SBC     HL,BC                   ; 2777  ed42
        CALL    m,FP_NEGATE_MAGNITUDE   ; 2779  fc9428
; ---- Vorzeichen in HLDE einsetzen, nach FAC schreiben, anschliessend normalisieren.
FP_STORE_RESULT:
        AND     80H                     ; 277C  e680
        ADD     A,H                     ; 277E  84
        LD      H,A                     ; 277F  67
        LD      (42E4H),HL              ; 2780  22e442
        LD      (FAC),DE                ; 2783  ed53e242
        JP      FP_NORMALIZE            ; 2787  c35e28

;=====================================================================
; MULTIPLIKATION: 31 SCHIEBE-/ADDIERSCHRITTE
; FP_MUL: FAC <- FAC * (DE); FP_MUL_ARG benutzt geladenes ARG.
; Ergebnisvorzeichen per XOR, Exponenten signed addieren.
; BCDE ist der 32-Bit-Produktakku; ARG-Bits steuern Addition von FAC.
; Je Durchlauf Produkt rechts schieben; kein vollstaendiges 62-Bit-Produkt.
; ARG wird zerstoert; ARG_EXP dient voruebergehend als Vorzeichenspeicher.
;=====================================================================
FP_MUL:
        CALL    ARG_LOAD                ; 278A  cda426
FP_MUL_ARG:
        LD      HL,FAC_SIGN_MSB         ; 278D  21e542
        LD      A,(ARG_SIGN_MSB)        ; 2790  3aea42
        BIT     6,(HL)                  ; 2793  cb76
        RET     z                       ; 2795  c8
        BIT     6,A                     ; 2796  cb77
        JP      z,FP_ZERO               ; 2798  cabc28
        XOR     (HL)                    ; 279B  ae
        RES     7,(HL)                  ; 279C  cbbe
        INC     L                       ; 279E  2c
        LD      B,A                     ; 279F  47
        LD      A,(ARG_EXP)             ; 27A0  3aeb42
        ADD     A,(HL)                  ; 27A3  86
        JP      pe,L27E1                ; 27A4  eae127
        LD      (HL),A                  ; 27A7  77
        LD      A,B                     ; 27A8  78
        LD      (ARG_EXP),A             ; 27A9  32eb42
        LD      B,0                     ; 27AC  0600
        LD      C,B                     ; 27AE  48
        LD      D,B                     ; 27AF  50
        LD      E,B                     ; 27B0  58
        LD      A,1FH                   ; 27B1  3e1f
FP_MUL_BIT:
        LD      HL,ARG_SIGN_MSB         ; 27B3  21ea42
        SRL     (HL)                    ; 27B6  cb3e
        DEC     L                       ; 27B8  2d
        RR      (HL)                    ; 27B9  cb1e
        DEC     L                       ; 27BB  2d
        RR      (HL)                    ; 27BC  cb1e
        DEC     L                       ; 27BE  2d
        RR      (HL)                    ; 27BF  cb1e
        JR      nc,FP_MUL_SHIFT         ; 27C1  300c
        LD      HL,(FAC)                ; 27C3  2ae242
        ADD     HL,DE                   ; 27C6  19
        EX      DE,HL                   ; 27C7  eb
        LD      HL,(42E4H)              ; 27C8  2ae442
        ADC     HL,BC                   ; 27CB  ed4a
        LD      B,H                     ; 27CD  44
        LD      C,L                     ; 27CE  4d
FP_MUL_SHIFT:
        SRL     B                       ; 27CF  cb38
        RR      C                       ; 27D1  cb19
        RR      D                       ; 27D3  cb1a
        RR      E                       ; 27D5  cb1b
        DEC     A                       ; 27D7  3d
        JR      nz,FP_MUL_BIT           ; 27D8  20d9
        LD      H,B                     ; 27DA  60
        LD      L,C                     ; 27DB  69
        LD      A,(ARG_EXP)             ; 27DC  3aeb42
        JR      FP_STORE_RESULT         ; 27DF  189b
L27E1:
        JP      c,FP_UNDERFLOW          ; 27E1  dace2c
L27E4:
        BIT     7,B                     ; 27E4  cb78
        JP      z,FP_OVERFLOW           ; 27E6  caca2c
        JP      FP_OVERFLOW             ; 27E9  c3ca2c

;=====================================================================
; DIVISION: NICHTRESTAURIERENDE BINAERE DIVISION
; FP_DIV: FAC <- FAC / (DE); FP_DIV_ARG benutzt geladenes ARG.
; Ergebnisvorzeichen per XOR, Exponent = eFAC-eARG+1.
; 31 Quotientenbits durch Teilrest-Subtraktion/Addition und Verdopplung.
; Negative Teilreste bestimmen den naechsten Additionsschritt;
; Rest wird nicht fuer eine abschliessende Rundung ausgewertet.
; ACHTUNG: FAC null wird VOR Divisor-null geprueft: roher Kern 0/0=0,
; aber Nichtnull/0 -> Fehler 40. Aussage gilt fuer diesen FP-Einstieg.
;=====================================================================
FP_DIV:
        CALL    ARG_LOAD                ; 27EC  cda426
FP_DIV_ARG:
        LD      HL,ARG_SIGN_MSB         ; 27EF  21ea42
        LD      A,(HL)                  ; 27F2  7e
        RES     7,(HL)                  ; 27F3  cbbe
        LD      DE,(42E4H)              ; 27F5  ed5be442
        XOR     D                       ; 27F9  aa
        LD      B,A                     ; 27FA  47
        BIT     6,D                     ; 27FB  cb72
        RET     z                       ; 27FD  c8
        BIT     6,(HL)                  ; 27FE  cb76
        JP      z,L262E                 ; 2800  ca2e26
        INC     L                       ; 2803  2c
        LD      A,(FAC_EXP)             ; 2804  3ae642
        SUB     (HL)                    ; 2807  96
        CCF                             ; 2808  3f
        JP      pe,L27E1                ; 2809  eae127
        INC     A                       ; 280C  3c
        JP      pe,L27E4                ; 280D  eae427
        RES     7,D                     ; 2810  cbba
        LD      (FAC_EXP),A             ; 2812  32e642
        LD      (HL),B                  ; 2815  70
        LD      HL,(FAC)                ; 2816  2ae242
        LD      A,1FH                   ; 2819  3e1f
        AND     A                       ; 281B  a7
FP_DIV_SUBTRACT:
        LD      BC,(ARG)                ; 281C  ed4be742
        SBC     HL,BC                   ; 2820  ed42
        EX      DE,HL                   ; 2822  eb
        LD      BC,(42E9H)              ; 2823  ed4be942
        SBC     HL,BC                   ; 2827  ed42
        CCF                             ; 2829  3f
FP_DIV_QUOTIENT_BIT:
        EX      DE,HL                   ; 282A  eb
        LD      B,H                     ; 282B  44
        LD      C,L                     ; 282C  4d
        LD      HL,FAC                  ; 282D  21e242
        RL      (HL)                    ; 2830  cb16
        INC     L                       ; 2832  2c
        RL      (HL)                    ; 2833  cb16
        INC     L                       ; 2835  2c
        RL      (HL)                    ; 2836  cb16
        INC     L                       ; 2838  2c
        RL      (HL)                    ; 2839  cb16
        DEC     A                       ; 283B  3d
        JR      z,L2855                 ; 283C  2817
        LD      H,B                     ; 283E  60
        LD      L,C                     ; 283F  69
        ADD     HL,HL                   ; 2840  29
        RL      E                       ; 2841  cb13
        RL      D                       ; 2843  cb12
        JR      nc,FP_DIV_SUBTRACT      ; 2845  30d5
        LD      BC,(ARG)                ; 2847  ed4be742
        ADD     HL,BC                   ; 284B  09
        EX      DE,HL                   ; 284C  eb
        LD      BC,(42E9H)              ; 284D  ed4be942
        ADC     HL,BC                   ; 2851  ed4a
        JR      FP_DIV_QUOTIENT_BIT     ; 2853  18d5
L2855:
        RES     7,(HL)                  ; 2855  cbbe
        LD      A,(ARG_EXP)             ; 2857  3aeb42
        AND     80H                     ; 285A  e680
        ADD     A,(HL)                  ; 285C  86
        LD      (HL),A                  ; 285D  77

;=====================================================================
; NORMALISIERUNG
; Bit30 gesetzt: fertig. Sonst vorzeichenbereinigten Betrag auf null
; testen (Wortsumme plus Carry), ggf. FAC vollstaendig loeschen.
; Betrag links schieben bis Bit30=1; Exponent je Bit vermindern.
; Signed Exponentenunterlauf -> Fehler 33, NICHT still auf null setzen.
;=====================================================================
FP_NORMALIZE:
        LD      BC,(42E4H)              ; 285E  ed4be442
        BIT     6,B                     ; 2862  cb70
        RET     nz                      ; 2864  c0
        XOR     A                       ; 2865  af
        LD      HL,(FAC)                ; 2866  2ae242
        RES     7,B                     ; 2869  cbb8
        ADC     HL,BC                   ; 286B  ed4a
        JR      nz,L2871                ; 286D  2002
        JR      nc,FP_ZERO              ; 286F  304b
L2871:
        LD      HL,(FAC)                ; 2871  2ae242
FP_NORMALIZE_SHIFT:
        ADD     HL,HL                   ; 2874  29
        RL      C                       ; 2875  cb11
        RL      B                       ; 2877  cb10
        DEC     A                       ; 2879  3d
        BIT     6,B                     ; 287A  cb70
        JR      z,FP_NORMALIZE_SHIFT    ; 287C  28f6
        EX      DE,HL                   ; 287E  eb
        LD      HL,FAC_EXP              ; 287F  21e642
        ADD     A,(HL)                  ; 2882  86
        JP      pe,L27E1                ; 2883  eae127
        LD      (HL),A                  ; 2886  77
        DEC     L                       ; 2887  2d
        LD      A,(HL)                  ; 2888  7e
        AND     80H                     ; 2889  e680
        ADD     A,B                     ; 288B  80
        LD      (HL),A                  ; 288C  77
        DEC     L                       ; 288D  2d
        LD      (HL),C                  ; 288E  71
        LD      (FAC),DE                ; 288F  ed53e242
        RET                             ; 2893  c9
; ---- HLDE-Betrag als 32-Bit-Zweierkomplement negieren; Vorzeichen in A umschalten.
FP_NEGATE_MAGNITUDE:
        XOR     80H                     ; 2894  ee80
        LD      B,A                     ; 2896  47
        XOR     A                       ; 2897  af
        LD      C,A                     ; 2898  4f
        SUB     E                       ; 2899  93
        LD      E,A                     ; 289A  5f
        LD      A,C                     ; 289B  79
        SBC     A,D                     ; 289C  9a
        LD      D,A                     ; 289D  57
        LD      A,C                     ; 289E  79
        SBC     A,L                     ; 289F  9d
        LD      L,A                     ; 28A0  6f
        LD      A,C                     ; 28A1  79
        SBC     A,H                     ; 28A2  9c
        LD      H,A                     ; 28A3  67
        LD      A,B                     ; 28A4  78
        RET                             ; 28A5  c9
        DB      3EH,7FH,18H,02H,3EH,0FFH,21H,0E6H ; 28A6 >...>.!.
        DB      42H,36H,7FH             ; 28AE B6.
L28B1:
        DEC     L                       ; 28B1  2d
        LD      (HL),A                  ; 28B2  77
        DEC     L                       ; 28B3  2d
        LD      A,0FFH                  ; 28B4  3eff
        LD      (HL),A                  ; 28B6  77
        DEC     L                       ; 28B7  2d
        LD      (HL),A                  ; 28B8  77
        DEC     L                       ; 28B9  2d
        LD      (HL),A                  ; 28BA  77
        RET                             ; 28BB  c9
; ---- Kanonische FP-Null: alle fuenf FAC-Byte loeschen.
FP_ZERO:
        LD      HL,FAC                  ; 28BC  21e242
        LD      B,5                     ; 28BF  0605
        XOR     A                       ; 28C1  af
L28C2:
        LD      (HL),A                  ; 28C2  77
        INC     L                       ; 28C3  2c
        DJNZ    L28C2                   ; 28C4  10fc
        RET                             ; 28C6  c9
; ---- FAC quadrieren: FAC nach ARG kopieren, dann FP_MUL_ARG.
FP_SQUARE:
        LD      HL,FAC                  ; 28C7  21e242
        LD      DE,ARG                  ; 28CA  11e742
        LD      BC,5                    ; 28CD  010500
        LDIR                            ; 28D0  edb0
        JP      FP_MUL_ARG              ; 28D2  c38d27

;=====================================================================
; SQR: QUADRATWURZEL DURCH NEWTON-ITERATION
; Null bleibt null; negatives Argument -> Funktionsfehler 41.
; Startwert: Exponentenhalbierung, Mantissenoberbyte 6DH bzw. 4DH.
; Originalargument in 42ECH..42F0H; Schaetzwert in 42F1H..42F5H.
; VIER Newton-Schritte y=(y+x/y)/2: drei CALLs und ein Durchfallen.
;=====================================================================
X_SQR:
        CALL    FAC_REQUIRE_FP          ; 28D5  cd921f
        LD      HL,(FAC)                ; 28D8  2ae242
        LD      (42ECH),HL              ; 28DB  22ec42
        LD      A,H                     ; 28DE  7c
        OR      L                       ; 28DF  b5
        LD      HL,(42E4H)              ; 28E0  2ae442
        OR      H                       ; 28E3  b4
        OR      L                       ; 28E4  b5
        RET     z                       ; 28E5  c8
        BIT     7,H                     ; 28E6  cb7c
        JP      nz,FP_FUNCTION_ERROR    ; 28E8  c2c62c
        LD      (42EEH),HL              ; 28EB  22ee42
        LD      A,(FAC_EXP)             ; 28EE  3ae642
        LD      (42F0H),A               ; 28F1  32f042
        LD      L,6DH                   ; 28F4  2e6d
        SRA     A                       ; 28F6  cb2f
        JR      nc,L28FD                ; 28F8  3003
        INC     A                       ; 28FA  3c
        RES     5,L                     ; 28FB  cbad
L28FD:
        LD      H,A                     ; 28FD  67
        LD      (FAC_SIGN_MSB),HL       ; 28FE  22e542
        CALL    FP_SQRT_NEWTON          ; 2901  cd0a29
        CALL    FP_SQRT_NEWTON          ; 2904  cd0a29
        CALL    FP_SQRT_NEWTON          ; 2907  cd0a29
; ---- Newton-Schritt: bisherigen Schaetzwert sichern, x/y + y bilden, Exponent dekrementieren.
FP_SQRT_NEWTON:
        LD      BC,5                    ; 290A  010500
        LD      HL,FAC                  ; 290D  21e242
        LD      DE,42F1H                ; 2910  11f142
        LDIR                            ; 2913  edb0
        LD      BC,5                    ; 2915  010500
        LD      HL,42ECH                ; 2918  21ec42
        LD      DE,FAC                  ; 291B  11e242
        LDIR                            ; 291E  edb0
        LD      BC,5                    ; 2920  010500
        LD      HL,42F1H                ; 2923  21f142
        LD      DE,ARG                  ; 2926  11e742
        LDIR                            ; 2929  edb0
        CALL    FP_DIV_ARG              ; 292B  cdef27
        LD      BC,5                    ; 292E  010500
        LD      HL,42F1H                ; 2931  21f142
        LD      DE,ARG                  ; 2934  11e742
        LDIR                            ; 2937  edb0
        CALL    FP_ADD_ARG              ; 2939  cdc326
        LD      HL,FAC_EXP              ; 293C  21e642
        DEC     (HL)                    ; 293F  35
        RET                             ; 2940  c9
        DB      21H,0E5H,42H,0CBH,0BEH,0C9H ; 2941 !.B...
; ---- FP_NEG: Vorzeichen von FAC umkehren (falls ungleich 0)
FP_NEG:
        LD      HL,FAC_SIGN_MSB         ; 2947  21e542
        BIT     6,(HL)                  ; 294A  cb76
        RET     z                       ; 294C  c8
        LD      A,80H                   ; 294D  3e80
        XOR     (HL)                    ; 294F  ae
        LD      (HL),A                  ; 2950  77
        RET                             ; 2951  c9

;=====================================================================
; INT: ABRUNDEN NACH MINUS UNENDLICH
; Integer-Typ bleibt unveraendert; FP-Typ bleibt hier ebenfalls FP.
; Positive FP-Zahlen: Nachkommabits loeschen; e>=31 schon ganzzahlig.
; Negativer Pfad benutzt -(1-2^-31), dann Betrag/Abschneiden/Vorzeichen.
; INT(-2.7)=-3, INT(-2)=-2. Nicht mit gerundeter FP_TO_INT16 verwechseln.
;=====================================================================
X_INT:
        LD      A,(FAC_TYPE)            ; 2952  3ae142
        DEC     A                       ; 2955  3d
        RET     z                       ; 2956  c8
FP_FLOOR:
        LD      HL,(FAC_SIGN_MSB)       ; 2957  2ae542
        LD      A,H                     ; 295A  7c
        AND     A                       ; 295B  a7
        JP      m,L2962                 ; 295C  fa6229
        CP      1FH                     ; 295F  fe1f
        RET     nc                      ; 2961  d0
L2962:
        BIT     7,L                     ; 2962  cb7d
        JR      z,FP_TRUNC_POSITIVE     ; 2964  2815
        XOR     A                       ; 2966  af
        LD      HL,ARG_EXP              ; 2967  21eb42
        LD      (HL),A                  ; 296A  77
        CPL                             ; 296B  2f
        CALL    L28B1                   ; 296C  cdb128
        CALL    FP_ADD_ARG              ; 296F  cdc326
        CALL    FP_NEG                  ; 2972  cd4729
        CALL    FP_TRUNC_POSITIVE       ; 2975  cd7b29
        JP      FP_NEG                  ; 2978  c34729
FP_TRUNC_POSITIVE:
        LD      A,(FAC_EXP)             ; 297B  3ae642
        NEG                             ; 297E  ed44
        JP      p,FP_ZERO               ; 2980  f2bc28
        ADD     A,1FH                   ; 2983  c61f
        LD      HL,FAC                  ; 2985  21e242
L2988:
        SUB     8                       ; 2988  d608
        JR      c,L2992                 ; 298A  3806
        LD      (HL),0                  ; 298C  3600
        RET     z                       ; 298E  c8
        INC     L                       ; 298F  2c
        JR      L2988                   ; 2990  18f6
L2992:
        ADD     A,8                     ; 2992  c608
        LD      B,A                     ; 2994  47
        LD      A,0FFH                  ; 2995  3eff
L2997:
        ADD     A,A                     ; 2997  87
        DJNZ    L2997                   ; 2998  10fd
        AND     (HL)                    ; 299A  a6
        LD      (HL),A                  ; 299B  77
        RET                             ; 299C  c9
        DB      11H,0E7H,42H,21H,0E2H,42H,01H,05H ; 299D ..B!.B..
        DB      00H,0EDH,0B0H,0CDH,57H,29H,0CDH,47H ; 29A5 ....W).G
        DB      29H,0C3H,0C3H,26H       ; 29AD )..&
; ---- FAC <- 1-FAC; ARG wird mit dem bisherigen FAC belegt.
FP_ONE_MINUS:
        LD      HL,FP_SUB_ARG           ; 29B1  21b626
        JR      L29B9                   ; 29B4  1803
; ---- FAC <- 1/FAC; ARG wird mit dem bisherigen FAC belegt.
FP_RECIPROCAL:
        LD      HL,FP_DIV_ARG           ; 29B6  21ef27
L29B9:
        PUSH    HL                      ; 29B9  e5
        LD      DE,ARG                  ; 29BA  11e742
        LD      HL,FAC                  ; 29BD  21e242
        LD      BC,5                    ; 29C0  010500
        LDIR                            ; 29C3  edb0
        LD      HL,K_FP_ONE             ; 29C5  21dc2c
        LD      DE,FAC                  ; 29C8  11e242
        LD      C,5                     ; 29CB  0e05
        LDIR                            ; 29CD  edb0
        RET                             ; 29CF  c9

;=====================================================================
; LOG: NATUERLICHER LOGARITHMUS
; x=m*2^e, m in [0.5,1); x<=0 -> Funktionsfehler 41.
; a=1/sqrt(2), z=(m-a)/(m+a), q=z*z.
; LOG(x) ~= [e-0.5 + z*(c1+c3*q+c5*q*q)]*ln(2).
; c1:2D68H, c3:2D6DH, c5:2CD3H; ln(2):2D3BH.
;=====================================================================
X_LOG:
        CALL    FAC_REQUIRE_FP          ; 29D0  cd921f
        LD      HL,(FAC_SIGN_MSB)       ; 29D3  2ae542
        LD      A,L                     ; 29D6  7d
        AND     A                       ; 29D7  a7
        JP      z,FP_FUNCTION_ERROR     ; 29D8  cac62c
        JP      m,FP_FUNCTION_ERROR     ; 29DB  fac62c
        PUSH    HL                      ; 29DE  e5
        XOR     A                       ; 29DF  af
        LD      (FAC_EXP),A             ; 29E0  32e642
        LD      DE,42ECH                ; 29E3  11ec42
        CALL    FAC_STORE               ; 29E6  cdae26
        LD      DE,K_SQRT_HALF          ; 29E9  11632d
        CALL    FP_ADD                  ; 29EC  cdc026
        LD      DE,42F1H                ; 29EF  11f142
        CALL    FAC_STORE               ; 29F2  cdae26
        LD      DE,42ECH                ; 29F5  11ec42
        CALL    FAC_LOAD                ; 29F8  cd9f26
        LD      DE,K_SQRT_HALF          ; 29FB  11632d
        CALL    FP_SUB                  ; 29FE  cdb326
        LD      DE,42F1H                ; 2A01  11f142
        CALL    FP_DIV                  ; 2A04  cdec27
        LD      DE,42F1H                ; 2A07  11f142
        CALL    FAC_STORE               ; 2A0A  cdae26
        CALL    FP_SQUARE               ; 2A0D  cdc728
        LD      DE,42ECH                ; 2A10  11ec42
        CALL    FAC_STORE               ; 2A13  cdae26
        LD      DE,K_LOG_C5             ; 2A16  11d32c
        CALL    FP_MUL                  ; 2A19  cd8a27
        LD      DE,K_LOG_C3             ; 2A1C  116d2d
        CALL    FP_ADD                  ; 2A1F  cdc026
        LD      DE,42ECH                ; 2A22  11ec42
        CALL    FP_MUL                  ; 2A25  cd8a27
        LD      DE,K_LOG_C1             ; 2A28  11682d
        CALL    FP_ADD                  ; 2A2B  cdc026
        LD      DE,42F1H                ; 2A2E  11f142
        CALL    FP_MUL                  ; 2A31  cd8a27
        LD      DE,K_FP_HALF            ; 2A34  11132d
        CALL    FP_SUB                  ; 2A37  cdb326
        LD      DE,42ECH                ; 2A3A  11ec42
        CALL    FAC_STORE               ; 2A3D  cdae26
        POP     AF                      ; 2A40  f1
        LD      L,A                     ; 2A41  6f
        LD      H,0                     ; 2A42  2600
        BIT     7,L                     ; 2A44  cb7d
        JR      z,L2A49                 ; 2A46  2801
        DEC     H                       ; 2A48  25
L2A49:
        LD      (FAC),HL                ; 2A49  22e242
        CALL    INT16_TO_FP             ; 2A4C  cd7432
        LD      DE,42ECH                ; 2A4F  11ec42
        CALL    FP_ADD                  ; 2A52  cdc026
        LD      DE,K_LN_TWO             ; 2A55  113b2d
        JP      FP_MUL                  ; 2A58  c38a27

;=====================================================================
; EXP: TAYLORPOLYNOM MIT ARGUMENTVERKLEINERUNG
; u=abs(x)/2^k, bei Verkleinerung Exponent -3 (1/16 <= u < 1/8).
; Verschachtelte Auswertung von 1+u+u^2/2!+...+u^6/6!.
; Danach k-mal quadrieren; fuer negatives x Kehrwert bilden.
; Betrag wird zuerst geprueft: abs(x)>=64 -> Fehler 32, auch fuer x<0.
;=====================================================================
X_EXP:
        CALL    FAC_REQUIRE_FP          ; 2A5B  cd921f
        XOR     A                       ; 2A5E  af
        LD      B,A                     ; 2A5F  47
        LD      HL,FAC_SIGN_MSB         ; 2A60  21e542
        BIT     7,(HL)                  ; 2A63  cb7e
        JR      z,L2A6A                 ; 2A65  2803
        RES     7,(HL)                  ; 2A67  cbbe
        INC     A                       ; 2A69  3c
L2A6A:
        LD      C,A                     ; 2A6A  4f
        INC     L                       ; 2A6B  2c
        LD      A,(HL)                  ; 2A6C  7e
        AND     A                       ; 2A6D  a7
        JP      p,L2AF3                 ; 2A6E  f2f32a
L2A71:
        ADD     A,2                     ; 2A71  c602
        JP      m,L2A7A                 ; 2A73  fa7a2a
        INC     A                       ; 2A76  3c
        LD      B,A                     ; 2A77  47
        LD      (HL),0FDH               ; 2A78  36fd
L2A7A:
        PUSH    BC                      ; 2A7A  c5
        LD      DE,42ECH                ; 2A7B  11ec42
        CALL    FAC_STORE               ; 2A7E  cdae26
        LD      DE,K_FP_SIX             ; 2A81  11f52c
        CALL    FP_DIV                  ; 2A84  cdec27
        LD      DE,K_FP_ONE             ; 2A87  11dc2c
        CALL    FP_ADD                  ; 2A8A  cdc026
        LD      DE,42ECH                ; 2A8D  11ec42
        CALL    FP_MUL                  ; 2A90  cd8a27
        LD      DE,K_FP_FIVE            ; 2A93  11f02c
        CALL    FP_DIV                  ; 2A96  cdec27
        LD      DE,K_FP_ONE             ; 2A99  11dc2c
        CALL    FP_ADD                  ; 2A9C  cdc026
        LD      DE,42ECH                ; 2A9F  11ec42
        CALL    FP_MUL                  ; 2AA2  cd8a27
        LD      DE,K_FP_FOUR            ; 2AA5  11eb2c
        CALL    FP_DIV                  ; 2AA8  cdec27
        LD      DE,K_FP_ONE             ; 2AAB  11dc2c
        CALL    FP_ADD                  ; 2AAE  cdc026
        LD      DE,42ECH                ; 2AB1  11ec42
        CALL    FP_MUL                  ; 2AB4  cd8a27
        LD      DE,K_FP_THREE           ; 2AB7  11e62c
        CALL    FP_DIV                  ; 2ABA  cdec27
        LD      DE,K_FP_ONE             ; 2ABD  11dc2c
        CALL    FP_ADD                  ; 2AC0  cdc026
        LD      DE,42ECH                ; 2AC3  11ec42
        CALL    FP_MUL                  ; 2AC6  cd8a27
        LD      DE,K_FP_HALF            ; 2AC9  11132d
        CALL    FP_MUL                  ; 2ACC  cd8a27
        LD      DE,K_FP_ONE             ; 2ACF  11dc2c
        CALL    FP_ADD                  ; 2AD2  cdc026
        LD      DE,42ECH                ; 2AD5  11ec42
        CALL    FP_MUL                  ; 2AD8  cd8a27
        LD      DE,K_FP_ONE             ; 2ADB  11dc2c
        CALL    FP_ADD                  ; 2ADE  cdc026
        POP     BC                      ; 2AE1  c1
        LD      A,B                     ; 2AE2  78
        AND     A                       ; 2AE3  a7
        JR      z,L2AED                 ; 2AE4  2807
L2AE6:
        PUSH    BC                      ; 2AE6  c5
        CALL    FP_SQUARE               ; 2AE7  cdc728
        POP     BC                      ; 2AEA  c1
        DJNZ    L2AE6                   ; 2AEB  10f9
L2AED:
        LD      A,C                     ; 2AED  79
        AND     A                       ; 2AEE  a7
        CALL    nz,FP_RECIPROCAL        ; 2AEF  c4b629
        RET                             ; 2AF2  c9
L2AF3:
        CP      7                       ; 2AF3  fe07
        JP      nc,FP_OVERFLOW          ; 2AF5  d2ca2c
        JP      L2A71                   ; 2AF8  c3712a
; ---- COS(x)=SIN(pi/2-x); Winkel im Bogenmass, gemeinsamer SIN-Kern.
X_COS:
        CALL    FAC_REQUIRE_FP          ; 2AFB  cd921f
        LD      DE,K_PI_HALF            ; 2AFE  11182d
        CALL    FP_SUB                  ; 2B01  cdb326
        CALL    FP_NEG                  ; 2B04  cd4729
        JR      FP_SIN_CORE             ; 2B07  1803

;=====================================================================
; SIN: MODULOREDUKTION, DRITTELUNG UND DREIFACHWINKEL
; Betrag modulo 2*pi reduzieren: r=abs(x)-floor(abs(x)/(2*pi))*2*pi.
; Solange r>=0.1: r durch 3 teilen, Anzahl merken.
; Kleines Argument: s ~= r-r^3/6+r^5/120.
; Pro Drittelung rekonstruieren: s <- 3*s-4*s^3; Vorzeichen restaurieren.
; Keine hochpraezise Winkelreduktion: grosse Winkel verlieren Genauigkeit.
;=====================================================================
X_SIN:
        CALL    FAC_REQUIRE_FP          ; 2B09  cd921f
FP_SIN_CORE:
        LD      HL,FAC_SIGN_MSB         ; 2B0C  21e542
        BIT     7,(HL)                  ; 2B0F  cb7e
        JR      z,L2B15                 ; 2B11  2802
        RES     7,(HL)                  ; 2B13  cbbe
L2B15:
        PUSH    AF                      ; 2B15  f5
        XOR     A                       ; 2B16  af
        PUSH    AF                      ; 2B17  f5
        LD      DE,42ECH                ; 2B18  11ec42
        CALL    FAC_STORE               ; 2B1B  cdae26
        LD      DE,K_PI_TWO             ; 2B1E  11222d
        CALL    FP_DIV                  ; 2B21  cdec27
        CALL    FP_FLOOR                ; 2B24  cd5729
        LD      DE,K_PI_TWO             ; 2B27  11222d
        CALL    FP_MUL                  ; 2B2A  cd8a27
        LD      DE,42ECH                ; 2B2D  11ec42
        CALL    FP_SUB                  ; 2B30  cdb326
        CALL    FP_NEG                  ; 2B33  cd4729
L2B36:
        LD      DE,42ECH                ; 2B36  11ec42
        CALL    FAC_STORE               ; 2B39  cdae26
        LD      DE,K_FP_TENTH           ; 2B3C  11092d
        CALL    FP_SUB                  ; 2B3F  cdb326
        LD      A,(FAC_SIGN_MSB)        ; 2B42  3ae542
        RLA                             ; 2B45  17
        JR      c,L2B59                 ; 2B46  3811
        POP     AF                      ; 2B48  f1
        INC     A                       ; 2B49  3c
        PUSH    AF                      ; 2B4A  f5
        LD      DE,42ECH                ; 2B4B  11ec42
        CALL    FAC_LOAD                ; 2B4E  cd9f26
        LD      DE,K_FP_THREE           ; 2B51  11e62c
        CALL    FP_DIV                  ; 2B54  cdec27
        JR      L2B36                   ; 2B57  18dd
L2B59:
        LD      DE,42ECH                ; 2B59  11ec42
        CALL    FAC_LOAD                ; 2B5C  cd9f26
        CALL    FP_SQUARE               ; 2B5F  cdc728
        LD      DE,K_FP_HALF            ; 2B62  11132d
        CALL    FP_MUL                  ; 2B65  cd8a27
        LD      DE,42F1H                ; 2B68  11f142
        CALL    FAC_STORE               ; 2B6B  cdae26
        LD      DE,K_FP_HALF            ; 2B6E  11132d
        CALL    FP_MUL                  ; 2B71  cd8a27
        LD      DE,K_FP_FIVE            ; 2B74  11f02c
        CALL    FP_DIV                  ; 2B77  cdec27
        LD      DE,K_FP_ONE             ; 2B7A  11dc2c
        CALL    FP_SUB                  ; 2B7D  cdb326
        LD      DE,42F1H                ; 2B80  11f142
        CALL    FP_MUL                  ; 2B83  cd8a27
        LD      DE,K_FP_THREE           ; 2B86  11e62c
        CALL    FP_DIV                  ; 2B89  cdec27
        LD      DE,K_FP_ONE             ; 2B8C  11dc2c
        CALL    FP_ADD                  ; 2B8F  cdc026
        LD      DE,42ECH                ; 2B92  11ec42
        CALL    FP_MUL                  ; 2B95  cd8a27
        POP     AF                      ; 2B98  f1
        JR      z,L2BBE                 ; 2B99  2823
        LD      B,A                     ; 2B9B  47
; ---- Dreifachwinkelformel: s <- -(4*s*s-3)*s; Schleife je vorheriger Drittelung.
FP_SIN_TRIPLE:
        PUSH    BC                      ; 2B9C  c5
        LD      DE,42F1H                ; 2B9D  11f142
        CALL    FAC_STORE               ; 2BA0  cdae26
        CALL    FP_SQUARE               ; 2BA3  cdc728
        LD      DE,K_FP_FOUR            ; 2BA6  11eb2c
        CALL    FP_MUL                  ; 2BA9  cd8a27
        LD      DE,K_FP_THREE           ; 2BAC  11e62c
        CALL    FP_SUB                  ; 2BAF  cdb326
        LD      DE,42F1H                ; 2BB2  11f142
        CALL    FP_MUL                  ; 2BB5  cd8a27
        CALL    FP_NEG                  ; 2BB8  cd4729
        POP     BC                      ; 2BBB  c1
        DJNZ    FP_SIN_TRIPLE           ; 2BBC  10de
L2BBE:
        POP     AF                      ; 2BBE  f1
        CALL    nz,FP_NEG               ; 2BBF  c44729
        RET                             ; 2BC2  c9

;=====================================================================
; ATN: RATIONALE KETTENBRUCHNAEHERUNG
; Vorzeichen abspalten; abs(x)>1 mit t=1/abs(x), sonst t=abs(x).
; q=t*t; R=t*(a0+b0/(q+a1+b1/(q+a2+b2/(q+a3)))).
; Koeffizienten in 2D40H..2D5EH; bei Kehrwertreduktion pi/2-R.
; Zum Schluss Vorzeichen wiederherstellen; Ergebnis im Bogenmass.
;=====================================================================
X_ATN:
        CALL    FAC_REQUIRE_FP          ; 2BC3  cd921f
        LD      BC,0                    ; 2BC6  010000
        PUSH    BC                      ; 2BC9  c5
        LD      A,(FAC_SIGN_MSB)        ; 2BCA  3ae542
        RLA                             ; 2BCD  17
        JR      nc,L2BD6                ; 2BCE  3006
        POP     BC                      ; 2BD0  c1
        INC     B                       ; 2BD1  04
        PUSH    BC                      ; 2BD2  c5
        CALL    FP_NEG                  ; 2BD3  cd4729
L2BD6:
        CALL    FP_ONE_MINUS            ; 2BD6  cdb129
        LD      A,(FAC_SIGN_MSB)        ; 2BD9  3ae542
        RLA                             ; 2BDC  17
        PUSH    AF                      ; 2BDD  f5
        CALL    FP_ONE_MINUS            ; 2BDE  cdb129
        POP     AF                      ; 2BE1  f1
        JR      nc,L2BEA                ; 2BE2  3006
        CALL    FP_RECIPROCAL           ; 2BE4  cdb629
        POP     BC                      ; 2BE7  c1
        INC     C                       ; 2BE8  0c
        PUSH    BC                      ; 2BE9  c5
L2BEA:
        LD      DE,42F6H                ; 2BEA  11f642
        CALL    FAC_STORE               ; 2BED  cdae26
        CALL    FP_SQUARE               ; 2BF0  cdc728
        LD      DE,42F1H                ; 2BF3  11f142
        CALL    FAC_STORE               ; 2BF6  cdae26
        LD      DE,K_ATN_A3             ; 2BF9  114f2d
        CALL    FP_ADD                  ; 2BFC  cdc026
        CALL    FP_RECIPROCAL           ; 2BFF  cdb629
        LD      DE,K_ATN_B2             ; 2C02  115e2d
        CALL    FP_MUL                  ; 2C05  cd8a27
        LD      DE,K_ATN_A2             ; 2C08  114a2d
        CALL    FP_ADD                  ; 2C0B  cdc026
        LD      DE,42F1H                ; 2C0E  11f142
        CALL    FP_ADD                  ; 2C11  cdc026
        CALL    FP_RECIPROCAL           ; 2C14  cdb629
        LD      DE,K_ATN_B1             ; 2C17  11592d
        CALL    FP_MUL                  ; 2C1A  cd8a27
        LD      DE,K_ATN_A1             ; 2C1D  11452d
        CALL    FP_ADD                  ; 2C20  cdc026
        LD      DE,42F1H                ; 2C23  11f142
        CALL    FP_ADD                  ; 2C26  cdc026
        CALL    FP_RECIPROCAL           ; 2C29  cdb629
        LD      DE,K_ATN_B0             ; 2C2C  11542d
        CALL    FP_MUL                  ; 2C2F  cd8a27
        LD      DE,K_ATN_A0             ; 2C32  11402d
        CALL    FP_ADD                  ; 2C35  cdc026
        LD      DE,42F6H                ; 2C38  11f642
        CALL    FP_MUL                  ; 2C3B  cd8a27
        POP     BC                      ; 2C3E  c1
        DEC     C                       ; 2C3F  0d
        JR      nz,L2C4D                ; 2C40  200b
        PUSH    BC                      ; 2C42  c5
        LD      DE,K_PI_HALF            ; 2C43  11182d
        CALL    FP_SUB                  ; 2C46  cdb326
        CALL    FP_NEG                  ; 2C49  cd4729
        POP     BC                      ; 2C4C  c1
L2C4D:
        DEC     B                       ; 2C4D  05
        JP      z,FP_NEG                ; 2C4E  ca4729
        RET                             ; 2C51  c9
; ---- Potenz-Einstieg mit umgekehrtem Carry fuer Operandentransport/Typanpassung.
FP_POWER_ENTRY:
        CCF                             ; 2C52  3f
FP_POWER_DISPATCH:
        JR      nz,FP_POWER             ; 2C53  200c
        PUSH    AF                      ; 2C55  f5
        CALL    INT16_TO_FP             ; 2C56  cd7432
        CALL    L1F3F                   ; 2C59  cd3f1f
        CALL    INT16_TO_FP             ; 2C5C  cd7432
        POP     AF                      ; 2C5F  f1
        CCF                             ; 2C60  3f
; ---- Potenzkern: EXP(ARG*LOG(FAC)); ARG sichern, da LOG Arbeitszellen ueberschreibt.
FP_POWER:
        CALL    nc,L1F3F                ; 2C61  d43f1f
        LD      HL,(ARG)                ; 2C64  2ae742
        PUSH    HL                      ; 2C67  e5
        LD      HL,(42E9H)              ; 2C68  2ae942
        PUSH    HL                      ; 2C6B  e5
        LD      A,(ARG_EXP)             ; 2C6C  3aeb42
        PUSH    AF                      ; 2C6F  f5
        CALL    X_LOG                   ; 2C70  cdd029
        POP     AF                      ; 2C73  f1
        LD      (ARG_EXP),A             ; 2C74  32eb42
        POP     HL                      ; 2C77  e1
        LD      (42E9H),HL              ; 2C78  22e942
        POP     HL                      ; 2C7B  e1
        LD      (ARG),HL                ; 2C7C  22e742
        CALL    FP_MUL_ARG              ; 2C7F  cd8d27
        JP      X_EXP                   ; 2C82  c35b2a

;=====================================================================
; RND: AFFINER GENERATOR IN GLEITKOMMA
; Zustand s: 41D5H..41D9H. u=24298*s+99991.15625.
; s neu = u-floor(u/199019)*199019; Rueckgabe s neu/199019.
; Kein exakt ganzzahliger LCG: auch das Inkrement ist nicht ganzzahlig.
; Initialisierung/Periode/statistische Qualitaet hier nicht nachgewiesen.
;=====================================================================
X_RND:
        LD      A,2                     ; 2C85  3e02
        LD      (FAC_TYPE),A            ; 2C87  32e142
        LD      DE,41D5H                ; 2C8A  11d541
        CALL    FAC_LOAD                ; 2C8D  cd9f26
        LD      DE,K_RND_FACTOR         ; 2C90  11722d
        CALL    FP_MUL                  ; 2C93  cd8a27
        LD      DE,K_RND_INCREMENT      ; 2C96  11772d
        CALL    FP_ADD                  ; 2C99  cdc026
        LD      DE,42F1H                ; 2C9C  11f142
        CALL    FAC_STORE               ; 2C9F  cdae26
        LD      DE,K_RND_MODULUS        ; 2CA2  117c2d
        CALL    FP_DIV                  ; 2CA5  cdec27
        CALL    FP_FLOOR                ; 2CA8  cd5729
        LD      DE,K_RND_MODULUS        ; 2CAB  117c2d
        CALL    FP_MUL                  ; 2CAE  cd8a27
        LD      DE,42F1H                ; 2CB1  11f142
        CALL    FP_SUB                  ; 2CB4  cdb326
        CALL    FP_NEG                  ; 2CB7  cd4729
        LD      DE,41D5H                ; 2CBA  11d541
        CALL    FAC_STORE               ; 2CBD  cdae26
        LD      DE,K_RND_MODULUS        ; 2CC0  117c2d
        JP      FP_DIV                  ; 2CC3  c3ec27
; ---- Fehler 41 dezimal: unzulaessiges Funktionsargument (SQR/LOG).
FP_FUNCTION_ERROR:
        LD      A,29H                   ; 2CC6  3e29
        JR      L2CD0                   ; 2CC8  1806
; ---- Fehler 32 dezimal: Exponentenueberlauf.
FP_OVERFLOW:
        LD      A,20H                   ; 2CCA  3e20
        JR      L2CD0                   ; 2CCC  1802
; ---- Fehler 33 dezimal: Exponentenunterlauf.
FP_UNDERFLOW:
        LD      A,21H                   ; 2CCE  3e21
L2CD0:
        JP      ERROR                   ; 2CD0  c35933
K_LOG_C5:
        DB      18H,55H,0ABH,4CH,00H    ; 2CD3 LOG: c5 ~= 0.598978649825
K_FP_ZERO:
        DB      00H,00H,00H,00H         ; 2CD8 0
K_FP_ONE:
        DB      00H,00H,00H,40H,01H     ; 2CDC 1
K_FP_TWO:
        DB      00H,00H,00H,40H,02H     ; 2CE1 2
K_FP_THREE:
        DB      00H,00H,00H,60H,02H     ; 2CE6 3
K_FP_FOUR:
        DB      00H,00H,00H,40H,03H     ; 2CEB 4
K_FP_FIVE:
        DB      00H,00H,00H,50H,03H     ; 2CF0 5
K_FP_SIX:
        DB      00H,00H,00H,60H,03H     ; 2CF5 6
K_FP_SEVEN:
        DB      00H,00H,00H,70H,03H     ; 2CFA 7
K_FP_EIGHT:
        DB      00H,00H,00H,40H,04H     ; 2CFF 8
K_FP_NINE:
        DB      00H,00H,00H,48H,04H     ; 2D04 9
K_FP_TENTH:
        DB      66H,66H,66H,66H,0FDH    ; 2D09 0.1 (binaer angenaehert)
K_FP_THIRD:
        DB      55H,55H,55H,55H,0FFH    ; 2D0E 1/3 (binaer angenaehert)
K_FP_HALF:
        DB      00H,00H,00H,40H,00H     ; 2D13 0.5
K_PI_HALF:
        DB      51H,0EDH,87H,64H,01H    ; 2D18 pi/2 ~= 1.570796326734
K_PI:
        DB      51H,0EDH,87H,64H,02H    ; 2D1D pi ~= 3.141592653468
K_PI_TWO:
        DB      51H,0EDH,87H,64H,03H    ; 2D22 2*pi ~= 6.283185306937
K_FP_FIFTH:
        DB      66H,66H,66H,66H,0FEH    ; 2D27 1/5 (binaer angenaehert)
K_FP_1_27:
        DB      0F6H,12H,0DAH,4BH,0FCH  ; 2D2C 1/27 (binaer angenaehert)
K_LN_TEN:
        DB      0EEH,0C6H,0AEH,49H,02H  ; 2D31 ln(10) ~= 2.302585091442
K_LOG10_E:
        DB      55H,0ECH,2DH,6FH,0FFH   ; 2D36 log10(e) ~= 0.434294481995
K_LN_TWO:
        DB      0FCH,0BH,0B9H,58H,00H   ; 2D3B ln(2) ~= 0.693147180602
K_ATN_A0:
        DB      0DH,70H,6CH,59H,0FEH    ; 2D40 ATN: a0 ~= 0.174655438983
K_ATN_A1:
        DB      0E0H,0B8H,31H,6CH,03H   ; 2D45 ATN: a1 ~= 6.762139201164
K_ATN_A2:
        DB      7BH,6BH,1FH,6AH,02H     ; 2D4A ATN: a2 ~= 3.316335430369
K_ATN_A3:
        DB      10H,61H,0B6H,5CH,01H    ; 2D4F ATN: a3 ~= 1.448631539941
K_ATN_B0:
        DB      2FH,3AH,0B2H,76H,02H    ; 2D54 ATN: b0 ~= 3.709256259724
K_ATN_B1:
        DB      07H,4AH,0B5H,0F1H,03H   ; 2D59 ATN: b1 ~= -7.106760051101
K_ATN_B2:
        DB      54H,0E0H,0C7H,0C3H,0FFH ; 2D5E ATN: b2 ~= -0.264768620022
K_SQRT_HALF:
        DB      9AH,79H,82H,5AH,00H     ; 2D63 1/sqrt(2) ~= 0.707106781192
K_LOG_C1:
        DB      1DH,20H,55H,5CH,02H     ; 2D68 LOG: c1 ~= 2.885391289368
K_LOG_C3:
        DB      3CH,78H,11H,7BH,00H     ; 2D6D LOG: c3 ~= 0.961470631883
K_RND_FACTOR:
        DB      00H,00H,0EAH,5EH,0FH    ; 2D72 RND: Faktor 24298
K_RND_INCREMENT:
        DB      00H,0CAH,0A5H,61H,11H   ; 2D77 RND: Inkrement 99991.15625, NICHT 99991
K_RND_MODULUS:
        DB      00H,60H,2DH,61H,12H     ; 2D7C RND: Modulus 199019
        DB      00H,11H,04H,40H,21H,00H,00H,06H ; 2D81 ...@!...
        DB      11H,1AH,13H,0D6H,30H,28H,03H,3DH ; 2D89 ....0(.=
        DB      0C0H,37H,0EDH,6AH,10H,0F3H,18H,15H ; 2D91 .7.j....
        DB      11H,04H,40H,21H,00H,00H,0E5H,39H ; 2D99 ..@!...9
        DB      0CDH,0B5H,2DH,38H,0DH,0EDH,6FH,23H ; 2DA1 ..-8..o#
        DB      0EDH,6FH,2BH,28H,0F3H,3EH,1FH,0C3H ; 2DA9 .o+(.>..
        DB      59H,33H,0E1H,0C9H,1AH,13H,0D6H,30H ; 2DB1 Y3.....0
        DB      0D8H,0FEH,10H,3FH,0D0H,0D6H,07H,0FEH ; 2DB9 ...?....
        DB      0AH,0D8H,0FEH,10H,3FH,0C9H,11H,03H ; 2DC1 ....?...
        DB      40H,21H,00H,00H,1AH,0FEH,30H,3FH ; 2DC9 @!....0?
        DB      0D0H,0FEH,3AH,0D0H,3EH,0F0H,0A4H,37H ; 2DD1 ..:.>..7
        DB      0C0H,44H,4DH,29H,29H,09H,29H,1AH ; 2DD9 .DM)).).
        DB      13H,0E6H,0FH,85H,6FH,3EH,00H,8CH ; 2DE1 ....o>..
        DB      67H,37H,0F8H,18H,0DFH   ; 2DE9 g7...
UINT8_TO_DECIMAL:
        LD      L,A                     ; 2DEE  6f
        LD      H,0                     ; 2DEF  2600
        JR      L2DFF                   ; 2DF1  180c
UINT16_TO_DECIMAL:
        LD      BC,2710H                ; 2DF3  011027
        CALL    L2E0D                   ; 2DF6  cd0d2e
        LD      BC,03E8H                ; 2DF9  01e803
        CALL    L2E0D                   ; 2DFC  cd0d2e
L2DFF:
        LD      BC,64H                  ; 2DFF  016400
        CALL    L2E0D                   ; 2E02  cd0d2e
        LD      C,10                    ; 2E05  0e0a
        CALL    L2E0D                   ; 2E07  cd0d2e
        LD      A,L                     ; 2E0A  7d
        JR      L2E16                   ; 2E0B  1809
L2E0D:
        LD      A,0FFH                  ; 2E0D  3eff
        AND     A                       ; 2E0F  a7
L2E10:
        INC     A                       ; 2E10  3c
        SBC     HL,BC                   ; 2E11  ed42
        JR      nc,L2E10                ; 2E13  30fb
        ADD     HL,BC                   ; 2E15  09
L2E16:
        OR      30H                     ; 2E16  f630
        LD      (DE),A                  ; 2E18  12
        INC     DE                      ; 2E19  13
        RET                             ; 2E1A  c9

;=====================================================================
; DEZIMALTEXT NACH GLEITKOMMA
; DE zeigt auf Text. Ziffern binaer sammeln: Wert*10+Ziffer.
; Hoechstens 9 signifikante Ziffern; weitere abschneiden, NICHT runden.
; Fuehrende Nullen verbrauchen das Ziffernbudget nicht.
; Punkt, Vorzeichen und E-Exponent ueber 42F1H..42F5H verwalten.
; Danach normalisieren und mit 10^(E minus Nachkommastellen) skalieren.
;=====================================================================
FP_PARSE_DECIMAL:
        EX      DE,HL                   ; 2E1B  eb
        LD      (42F6H),HL              ; 2E1C  22f642
        LD      HL,42F5H                ; 2E1F  21f542
        LD      (HL),10                 ; 2E22  360a
        LD      B,13H                   ; 2E24  0613
        XOR     A                       ; 2E26  af
L2E27:
        DEC     L                       ; 2E27  2d
        LD      (HL),A                  ; 2E28  77
        DJNZ    L2E27                   ; 2E29  10fc
L2E2B:
        CALL    FP_READ_DIGIT           ; 2E2B  cd882f
        JR      c,L2E89                 ; 2E2E  3859
        LD      HL,42F1H                ; 2E30  21f142
        SET     0,(HL)                  ; 2E33  cbc6
        AND     A                       ; 2E35  a7
        JR      nz,L2E3C                ; 2E36  2004
        BIT     1,(HL)                  ; 2E38  cb4e
        JR      z,L2E74                 ; 2E3A  2838
L2E3C:
        LD      L,0F5H                  ; 2E3C  2ef5
        DEC     (HL)                    ; 2E3E  35
        JR      z,L2E7E                 ; 2E3F  283d
        LD      L,0F1H                  ; 2E41  2ef1
        BIT     1,(HL)                  ; 2E43  cb4e
        JR      nz,L2E4E                ; 2E45  2007
        SET     1,(HL)                  ; 2E47  cbce
        LD      L,0E2H                  ; 2E49  2ee2
        LD      (HL),D                  ; 2E4B  72
        JR      L2E74                   ; 2E4C  1826
L2E4E:
        LD      A,D                     ; 2E4E  7a
        LD      L,0E2H                  ; 2E4F  2ee2
        CALL    ARG_COPY_FROM_HL        ; 2E51  cd7330
        LD      H,42H                   ; 2E54  2642
        AND     A                       ; 2E56  a7
        CALL    L2FA4                   ; 2E57  cda42f
        CALL    L2FA4                   ; 2E5A  cda42f
        LD      C,A                     ; 2E5D  4f
        LD      E,0E6H                  ; 2E5E  1ee6
        LD      L,0E2H                  ; 2E60  2ee2
        CALL    L2F6A                   ; 2E62  cd6a2f
        CALL    L2FA4                   ; 2E65  cda42f
        LD      A,C                     ; 2E68  79
        LD      L,0E2H                  ; 2E69  2ee2
        ADD     A,(HL)                  ; 2E6B  86
        LD      (HL),A                  ; 2E6C  77
        JR      nc,L2E73                ; 2E6D  3004
L2E6F:
        INC     L                       ; 2E6F  2c
        INC     (HL)                    ; 2E70  34
        JR      z,L2E6F                 ; 2E71  28fc
L2E73:
        XOR     A                       ; 2E73  af
L2E74:
        LD      L,0F1H                  ; 2E74  2ef1
        BIT     2,(HL)                  ; 2E76  cb56
        JR      z,L2E2B                 ; 2E78  28b1
        INC     L                       ; 2E7A  2c
        INC     (HL)                    ; 2E7B  34
        JR      L2E2B                   ; 2E7C  18ad
L2E7E:
        INC     (HL)                    ; 2E7E  34
        LD      L,0F1H                  ; 2E7F  2ef1
        BIT     2,(HL)                  ; 2E81  cb56
        JR      nz,L2E2B                ; 2E83  20a6
        INC     L                       ; 2E85  2c
        DEC     (HL)                    ; 2E86  35
        JR      L2E2B                   ; 2E87  18a2
L2E89:
        ADD     A,2                     ; 2E89  c602
        JR      nz,L2E98                ; 2E8B  200b
        LD      HL,42F1H                ; 2E8D  21f142
        BIT     2,(HL)                  ; 2E90  cb56
        JR      nz,L2EE6                ; 2E92  2052
        SET     2,(HL)                  ; 2E94  cbd6
        JR      L2E2B                   ; 2E96  1893
L2E98:
        INC     A                       ; 2E98  3c
        JR      nz,L2EA2                ; 2E99  2007
        LD      A,80H                   ; 2E9B  3e80
L2E9D:
        LD      (42F4H),A               ; 2E9D  32f442
        JR      L2E2B                   ; 2EA0  1889
L2EA2:
        ADD     A,2                     ; 2EA2  c602
        JR      z,L2E9D                 ; 2EA4  28f7
        SUB     10H                     ; 2EA6  d610
        JR      nz,L2EDB                ; 2EA8  2031
L2EAA:
        LD      B,A                     ; 2EAA  47
        CALL    FP_READ_DIGIT           ; 2EAB  cd882f
        JR      c,L2ECD                 ; 2EAE  381d
        LD      C,A                     ; 2EB0  4f
        CALL    FP_READ_DIGIT           ; 2EB1  cd882f
        JR      c,L2EC2                 ; 2EB4  380c
        LD      A,C                     ; 2EB6  79
        RLCA                            ; 2EB7  07
        RLCA                            ; 2EB8  07
        ADD     A,C                     ; 2EB9  81
        RLCA                            ; 2EBA  07
        ADD     A,D                     ; 2EBB  82
        LD      C,A                     ; 2EBC  4f
        CALL    FP_READ_DIGIT           ; 2EBD  cd882f
        JR      nc,L2EF8                ; 2EC0  3036
L2EC2:
        DEC     B                       ; 2EC2  05
        LD      A,C                     ; 2EC3  79
        JR      nz,L2EC8                ; 2EC4  2002
        NEG                             ; 2EC6  ed44
L2EC8:
        LD      (42F3H),A               ; 2EC8  32f342
        JR      L2EE6                   ; 2ECB  1819
L2ECD:
        ADD     A,3                     ; 2ECD  c603
        JR      nz,L2ED4                ; 2ECF  2003
        INC     A                       ; 2ED1  3c
        JR      L2EAA                   ; 2ED2  18d6
L2ED4:
        ADD     A,2                     ; 2ED4  c602
        JR      z,L2EAA                 ; 2ED6  28d2
        XOR     A                       ; 2ED8  af
        JR      L2EC8                   ; 2ED9  18ed
L2EDB:
        ADD     A,1BH                   ; 2EDB  c61b
        JR      nz,L2EE6                ; 2EDD  2007
        LD      A,(42F1H)               ; 2EDF  3af142
        RRA                             ; 2EE2  1f
        JP      nc,L2E2B                ; 2EE3  d22b2e
L2EE6:
        LD      HL,42F1H                ; 2EE6  21f142
        BIT     0,(HL)                  ; 2EE9  cb46
        JR      nz,L2EFE                ; 2EEB  2011
        LD      A,(42F3H)               ; 2EED  3af342
        AND     A                       ; 2EF0  a7
        JR      z,L2F58                 ; 2EF1  2865
        LD      L,0E2H                  ; 2EF3  2ee2
        INC     (HL)                    ; 2EF5  34
        JR      L2F02                   ; 2EF6  180a
L2EF8:
        DEC     B                       ; 2EF8  05
        JR      nz,L2F4D                ; 2EF9  2052
L2EFB:
        JP      FP_UNDERFLOW            ; 2EFB  c3ce2c
L2EFE:
        BIT     1,(HL)                  ; 2EFE  cb4e
        JR      z,L2F58                 ; 2F00  2856
L2F02:
        LD      L,0E6H                  ; 2F02  2ee6
        LD      (HL),1FH                ; 2F04  361f
        CALL    FP_NORMALIZE            ; 2F06  cd5e28
        CALL    ARG_SET_ONE             ; 2F09  cd7030
        LD      HL,42F3H                ; 2F0C  21f342
        LD      A,(HL)                  ; 2F0F  7e
        DEC     L                       ; 2F10  2d
        SUB     (HL)                    ; 2F11  96
        LD      (HL),A                  ; 2F12  77
        JP      z,L2F50                 ; 2F13  ca502f
        JP      p,L2F1B                 ; 2F16  f21b2f
        NEG                             ; 2F19  ed44
L2F1B:
        LD      C,A                     ; 2F1B  4f
L2F1C:
        LD      L,0EAH                  ; 2F1C  2eea
        CALL    L2F59                   ; 2F1E  cd592f
        JP      p,L2F2C                 ; 2F21  f22c2f
        LD      E,0EAH                  ; 2F24  1eea
        LD      B,4                     ; 2F26  0604
        CALL    L2F7A                   ; 2F28  cd7a2f
        INC     (HL)                    ; 2F2B  34
L2F2C:
        INC     (HL)                    ; 2F2C  34
        INC     (HL)                    ; 2F2D  34
        INC     (HL)                    ; 2F2E  34
        JP      m,L2F46                 ; 2F2F  fa462f
        DEC     C                       ; 2F32  0d
        JR      nz,L2F1C                ; 2F33  20e7
        LD      A,(42F2H)               ; 2F35  3af242
        AND     A                       ; 2F38  a7
        JP      m,L2F41                 ; 2F39  fa412f
        CALL    FP_MUL_ARG              ; 2F3C  cd8d27
        JR      L2F50                   ; 2F3F  180f
L2F41:
        CALL    FP_DIV_ARG              ; 2F41  cdef27
        JR      L2F50                   ; 2F44  180a
L2F46:
        LD      A,(42F2H)               ; 2F46  3af242
        AND     A                       ; 2F49  a7
        JP      m,L2EFB                 ; 2F4A  fafb2e
L2F4D:
        JP      FP_OVERFLOW             ; 2F4D  c3ca2c
L2F50:
        LD      A,(42F4H)               ; 2F50  3af442
        LD      HL,FAC_SIGN_MSB         ; 2F53  21e542
        XOR     (HL)                    ; 2F56  ae
        LD      (HL),A                  ; 2F57  77
L2F58:
        RET                             ; 2F58  c9
L2F59:
        LD      D,H                     ; 2F59  54
        LD      E,0F0H                  ; 2F5A  1ef0
        LD      A,C                     ; 2F5C  79
        LD      BC,4                    ; 2F5D  010400
        LDDR                            ; 2F60  edb8
        LD      C,A                     ; 2F62  4f
        CALL    L2F75                   ; 2F63  cd752f
        CALL    L2F75                   ; 2F66  cd752f
        INC     HL                      ; 2F69  23
L2F6A:
        XOR     A                       ; 2F6A  af
        LD      B,4                     ; 2F6B  0604
L2F6D:
        INC     DE                      ; 2F6D  13
        LD      A,(DE)                  ; 2F6E  1a
        ADC     A,(HL)                  ; 2F6F  8e
        LD      (HL),A                  ; 2F70  77
        INC     HL                      ; 2F71  23
        DJNZ    L2F6D                   ; 2F72  10f9
        RET                             ; 2F74  c9
L2F75:
        LD      E,0F0H                  ; 2F75  1ef0
L2F77:
        XOR     A                       ; 2F77  af
        LD      B,4                     ; 2F78  0604
L2F7A:
        LD      A,(DE)                  ; 2F7A  1a
        RRA                             ; 2F7B  1f
        LD      (DE),A                  ; 2F7C  12
        DEC     DE                      ; 2F7D  1b
        DJNZ    L2F7A                   ; 2F7E  10fa
        LD      A,(42ECH)               ; 2F80  3aec42
        RRA                             ; 2F83  1f
        LD      (42ECH),A               ; 2F84  32ec42
        RET                             ; 2F87  c9
; ---- Textzeichen holen; ASCII 0..9 als Ziffer liefern, andere Zeichen mit Carry markieren.
FP_READ_DIGIT:
        LD      HL,(42F6H)              ; 2F88  2af642
        LD      A,(HL)                  ; 2F8B  7e
        INC     HL                      ; 2F8C  23
        LD      (42F6H),HL              ; 2F8D  22f642
        AND     7FH                     ; 2F90  e67f
        ADD     A,0C6H                  ; 2F92  c6c6
        RET     c                       ; 2F94  d8
        ADD     A,10                    ; 2F95  c60a
        LD      D,A                     ; 2F97  57
        CCF                             ; 2F98  3f
        RET                             ; 2F99  c9
L2F9A:
        CALL    L2FA0                   ; 2F9A  cda02f
        CALL    L2FA0                   ; 2F9D  cda02f
L2FA0:
        LD      L,0ECH                  ; 2FA0  2eec
        SLA     (HL)                    ; 2FA2  cb26
L2FA4:
        LD      L,0E2H                  ; 2FA4  2ee2
        RL      (HL)                    ; 2FA6  cb16
        INC     L                       ; 2FA8  2c
        RL      (HL)                    ; 2FA9  cb16
        INC     L                       ; 2FAB  2c
        RL      (HL)                    ; 2FAC  cb16
        INC     L                       ; 2FAE  2c
        RL      (HL)                    ; 2FAF  cb16
        RET                             ; 2FB1  c9

;=====================================================================
; NUMERISCHE TEXTAUSGABE
; Formatwort 42FBH/42FCH: Modus/Praezision und Feldbreite.
; Binaer-/Hexausgabe ueber Integer; Dezimalpfad ab FP_FORMAT_DECIMAL.
; FP-Default 1088H: Feldbreite 16, Exponentialform, 8 Nachkommastellen.
; Integer-Default 0700H: Feldbreite 7. Arbeitszellen werden ueberlagert.
;=====================================================================
NUMBER_FORMAT:
        PUSH    DE                      ; 2FB2  d5
        LD      HL,(42FBH)              ; 2FB3  2afb42
        BIT     5,L                     ; 2FB6  cb6d
        JR      z,FP_FORMAT_DECIMAL     ; 2FB8  2844
        BIT     6,L                     ; 2FBA  cb75
        PUSH    AF                      ; 2FBC  f5
        CALL    FAC_TO_INT              ; 2FBD  cd851f
        LD      DE,FAC                  ; 2FC0  11e242
        POP     AF                      ; 2FC3  f1
        JR      z,L2FD4                 ; 2FC4  280e
        LD      B,10H                   ; 2FC6  0610
L2FC8:
        ADC     HL,HL                   ; 2FC8  ed6a
        LD      A,0                     ; 2FCA  3e00
        ADC     A,30H                   ; 2FCC  ce30
        LD      (DE),A                  ; 2FCE  12
        INC     DE                      ; 2FCF  13
        DJNZ    L2FC8                   ; 2FD0  10f6
        JR      L2FD7                   ; 2FD2  1803
L2FD4:
        CALL    UINT16_TO_HEX           ; 2FD4  cd2932
L2FD7:
        DEC     DE                      ; 2FD7  1b
        LD      HL,(42FBH)              ; 2FD8  2afb42
        LD      A,L                     ; 2FDB  7d
        AND     1FH                     ; 2FDC  e61f
        LD      C,A                     ; 2FDE  4f
        LD      A,H                     ; 2FDF  7c
        PUSH    AF                      ; 2FE0  f5
        SUB     C                       ; 2FE1  91
        LD      B,A                     ; 2FE2  47
        POP     AF                      ; 2FE3  f1
        POP     HL                      ; 2FE4  e1
        ADD     A,L                     ; 2FE5  85
        LD      L,A                     ; 2FE6  6f
        JR      nc,L2FEA                ; 2FE7  3001
        INC     H                       ; 2FE9  24
L2FEA:
        EX      DE,HL                   ; 2FEA  eb
        LD      A,B                     ; 2FEB  78
        LD      B,0                     ; 2FEC  0600
        LDDR                            ; 2FEE  edb8
        AND     A                       ; 2FF0  a7
        JP      z,L31D7                 ; 2FF1  cad731
        EX      DE,HL                   ; 2FF4  eb
        LD      B,A                     ; 2FF5  47
L2FF6:
        LD      (HL),20H                ; 2FF6  3620
        DEC     HL                      ; 2FF8  2b
        DJNZ    L2FF6                   ; 2FF9  10fb
        JP      L31D7                   ; 2FFB  c3d731
; ---- Dezimalpfad: Betrag skalieren, Dezimalziffern bilden und Folgeziffer zur Rundung erzeugen.
FP_FORMAT_DECIMAL:
        LD      A,(FAC_TYPE)            ; 2FFE  3ae142
        DEC     A                       ; 3001  3d
        PUSH    AF                      ; 3002  f5
        CALL    z,INT16_TO_FP           ; 3003  cc7432
        LD      HL,(42FBH)              ; 3006  2afb42
        LD      BC,0700H                ; 3009  010007
        POP     AF                      ; 300C  f1
        JR      z,L3012                 ; 300D  2803
        LD      BC,1088H                ; 300F  018810
L3012:
        LD      A,H                     ; 3012  7c
        OR      L                       ; 3013  b5
        JR      nz,L301A                ; 3014  2004
        LD      (42FBH),BC              ; 3016  ed43fb42
L301A:
        POP     HL                      ; 301A  e1
        LD      (42F6H),HL              ; 301B  22f642
        LD      (42F8H),HL              ; 301E  22f842
        LD      HL,(FAC_SIGN_MSB)       ; 3021  2ae542
        LD      (42F1H),HL              ; 3024  22f142
        RES     7,L                     ; 3027  cbbd
        LD      (FAC_SIGN_MSB),HL       ; 3029  22e542
        XOR     A                       ; 302C  af
L302D:
        LD      (42F3H),A               ; 302D  32f342
        CALL    ARG_SET_ONE             ; 3030  cd7030
        LD      HL,FAC_EXP              ; 3033  21e642
        LD      C,(HL)                  ; 3036  4e
        LD      A,C                     ; 3037  79
        OR      A                       ; 3038  b7
        JP      z,L30C9                 ; 3039  cac930
        JP      m,L3061                 ; 303C  fa6130
        CP      7CH                     ; 303F  fe7c
        JR      c,L3050                 ; 3041  380d
        LD      HL,K_FP_1E10            ; 3043  21c430
        CALL    ARG_COPY_FROM_HL        ; 3046  cd7330
        CALL    FP_DIV_ARG              ; 3049  cdef27
        LD      A,10                    ; 304C  3e0a
        JR      L302D                   ; 304E  18dd
L3050:
        LD      A,C                     ; 3050  79
        LD      L,0EBH                  ; 3051  2eeb
        CP      (HL)                    ; 3053  be
        JR      c,L305C                 ; 3054  3806
        CALL    ARG_TIMES_TEN           ; 3056  cd7c30
        INC     (HL)                    ; 3059  34
        JR      L3050                   ; 305A  18f4
L305C:
        CALL    FP_DIV_ARG              ; 305C  cdef27
        JR      L3099                   ; 305F  1838
L3061:
        LD      A,C                     ; 3061  79
        LD      L,0EBH                  ; 3062  2eeb
        ADD     A,(HL)                  ; 3064  86
        ADD     A,4                     ; 3065  c604
        JP      p,L3096                 ; 3067  f29630
        CALL    ARG_TIMES_TEN           ; 306A  cd7c30
        DEC     (HL)                    ; 306D  35
        JR      L3061                   ; 306E  18f1
ARG_SET_ONE:
        LD      HL,K_FP_ONE             ; 3070  21dc2c
ARG_COPY_FROM_HL:
        LD      DE,ARG                  ; 3073  11e742
        LD      BC,5                    ; 3076  010500
        LDIR                            ; 3079  edb0
        RET                             ; 307B  c9
ARG_TIMES_TEN:
        DEC     L                       ; 307C  2d
        CALL    L2F59                   ; 307D  cd592f
        DEC     L                       ; 3080  2d
        BIT     7,(HL)                  ; 3081  cb7e
        JR      z,L308D                 ; 3083  2808
        EX      DE,HL                   ; 3085  eb
        CALL    L2F77                   ; 3086  cd772f
        LD      A,4                     ; 3089  3e04
        JR      L308F                   ; 308B  1802
L308D:
        LD      A,3                     ; 308D  3e03
L308F:
        LD      L,0EBH                  ; 308F  2eeb
        ADD     A,(HL)                  ; 3091  86
        LD      (HL),A                  ; 3092  77
        LD      L,0F3H                  ; 3093  2ef3
        RET                             ; 3095  c9
L3096:
        CALL    FP_MUL_ARG              ; 3096  cd8d27
L3099:
        LD      HL,FAC_EXP              ; 3099  21e642
        LD      A,(HL)                  ; 309C  7e
        OR      A                       ; 309D  b7
        JR      z,L30C9                 ; 309E  2829
        INC     (HL)                    ; 30A0  34
        EX      DE,HL                   ; 30A1  eb
        DEC     DE                      ; 30A2  1b
        CALL    L2F77                   ; 30A3  cd772f
        JR      L3099                   ; 30A6  18f1
; ---- Naechste ASCII-Dezimalziffer aus dem skalierten Mehrbyte-Betrag gewinnen.
FP_DECIMAL_DIGIT:
        LD      HL,FAC_SIGN_MSB         ; 30A8  21e542
        CALL    L2F59                   ; 30AB  cd592f
        DEC     L                       ; 30AE  2d
        LD      A,(HL)                  ; 30AF  7e
        RRA                             ; 30B0  1f
        RRA                             ; 30B1  1f
        RRA                             ; 30B2  1f
        RRA                             ; 30B3  1f
        AND     15                      ; 30B4  e60f
        OR      30H                     ; 30B6  f630
        LD      (42F2H),A               ; 30B8  32f242
        CALL    L2F9A                   ; 30BB  cd9a2f
        RES     7,(HL)                  ; 30BE  cbbe
        LD      A,(42F2H)               ; 30C0  3af242
        RET                             ; 30C3  c9
K_FP_1E10:
        DB      80H,7CH,81H,4AH,22H     ; 30C4 10000000000 (Dezimalausgabe grosser Betraege)
L30C9:
        CALL    FP_DECIMAL_DIGIT        ; 30C9  cda830
        CP      30H                     ; 30CC  fe30
        JR      nz,L30D6                ; 30CE  2006
        LD      L,0F3H                  ; 30D0  2ef3
        DEC     (HL)                    ; 30D2  35
        CALL    FP_DECIMAL_DIGIT        ; 30D3  cda830
L30D6:
        LD      DE,(42FBH)              ; 30D6  ed5bfb42
        BIT     7,E                     ; 30DA  cb7b
        RES     7,E                     ; 30DC  cbbb
        JR      z,L30E4                 ; 30DE  2804
        LD      C,E                     ; 30E0  4b
        INC     C                       ; 30E1  0c
        JR      L30F9                   ; 30E2  1815
L30E4:
        LD      L,0F3H                  ; 30E4  2ef3
        LD      A,(HL)                  ; 30E6  7e
        DEC     A                       ; 30E7  3d
        JP      m,L30FD                 ; 30E8  fafd30
        ADD     A,2                     ; 30EB  c602
        ADD     A,E                     ; 30ED  83
        CP      10                      ; 30EE  fe0a
        JR      c,L30F4                 ; 30F0  3802
        LD      A,10                    ; 30F2  3e0a
L30F4:
        CP      D                       ; 30F4  ba
        JR      c,L30F8                 ; 30F5  3801
        LD      A,D                     ; 30F7  7a
L30F8:
        LD      C,A                     ; 30F8  4f
L30F9:
        LD      B,0                     ; 30F9  0600
        JR      L310C                   ; 30FB  180f
L30FD:
        LD      C,E                     ; 30FD  4b
        INC     C                       ; 30FE  0c
        INC     C                       ; 30FF  0c
        LD      A,(HL)                  ; 3100  7e
        ADD     A,E                     ; 3101  83
        JP      p,L3108                 ; 3102  f20831
        LD      B,C                     ; 3105  41
        JR      L310C                   ; 3106  1804
L3108:
        LD      A,1                     ; 3108  3e01
        SUB     (HL)                    ; 310A  96
        LD      B,A                     ; 310B  47
L310C:
        LD      A,C                     ; 310C  79
        LD      (ARG),A                 ; 310D  32e742
        SUB     B                       ; 3110  90
        LD      C,A                     ; 3111  4f
        INC     B                       ; 3112  04
L3113:
        DEC     B                       ; 3113  05
        JR      z,L312F                 ; 3114  2819
        LD      A,30H                   ; 3116  3e30
        CALL    L311D                   ; 3118  cd1d31
        JR      L3113                   ; 311B  18f6
L311D:
        LD      HL,(42F8H)              ; 311D  2af842
        INC     HL                      ; 3120  23
        LD      (HL),A                  ; 3121  77
        LD      (42F8H),HL              ; 3122  22f842
        RET                             ; 3125  c9
L3126:
        LD      A,(42F2H)               ; 3126  3af242
        CALL    L311D                   ; 3129  cd1d31
        CALL    FP_DECIMAL_DIGIT        ; 312C  cda830
L312F:
        DEC     C                       ; 312F  0d
        JP      p,L3126                 ; 3130  f22631
; ---- Verworfene Folgeziffer >=5: Betrag dezimal aufrunden, Uebertrag ueber 9er-Kette.
        LD      A,(ARG)                 ; 3133  3ae742
        LD      B,A                     ; 3136  47
        LD      HL,(42F8H)              ; 3137  2af842
        LD      A,(HL)                  ; 313A  7e
        DEC     HL                      ; 313B  2b
        DEC     B                       ; 313C  05
        AND     15                      ; 313D  e60f
        CP      5                       ; 313F  fe05
        JR      c,L3158                 ; 3141  3815
FP_DECIMAL_ROUND_CARRY:
        LD      A,(HL)                  ; 3143  7e
        INC     A                       ; 3144  3c
        AND     3FH                     ; 3145  e63f
        LD      (HL),A                  ; 3147  77
        CP      3AH                     ; 3148  fe3a
        JR      nz,L3158                ; 314A  200c
        LD      (HL),30H                ; 314C  3630
        DEC     HL                      ; 314E  2b
        DJNZ    FP_DECIMAL_ROUND_CARRY  ; 314F  10f2
        INC     HL                      ; 3151  23
        LD      (HL),31H                ; 3152  3631
        LD      HL,42F3H                ; 3154  21f342
        INC     (HL)                    ; 3157  34
L3158:
        LD      BC,(42FBH)              ; 3158  ed4bfb42
        LD      HL,(42F6H)              ; 315C  2af642
        SCF                             ; 315F  37
        LD      A,L                     ; 3160  7d
        ADC     A,B                     ; 3161  88
        LD      L,A                     ; 3162  6f
        JR      nc,L3166                ; 3163  3001
        INC     H                       ; 3165  24
L3166:
        LD      (HL),3                  ; 3166  3603
        BIT     7,C                     ; 3168  cb79
        JP      nz,L31F5                ; 316A  c2f531
        EX      DE,HL                   ; 316D  eb
        LD      HL,42F3H                ; 316E  21f342
        BIT     7,(HL)                  ; 3171  cb7e
        JR      nz,L3193                ; 3173  201e
        LD      A,C                     ; 3175  79
        OR      A                       ; 3176  b7
        JR      z,L317A                 ; 3177  2801
        SCF                             ; 3179  37
L317A:
        ADC     A,(HL)                  ; 317A  8e
        SUB     B                       ; 317B  90
        JP      p,L31E3                 ; 317C  f2e331
        LD      A,(HL)                  ; 317F  7e
        ADD     A,C                     ; 3180  81
        LD      L,0E7H                  ; 3181  2ee7
        SUB     (HL)                    ; 3183  96
        JP      m,L3193                 ; 3184  fa9331
        INC     A                       ; 3187  3c
        LD      B,A                     ; 3188  47
        LD      HL,(42F8H)              ; 3189  2af842
L318C:
        LD      (HL),30H                ; 318C  3630
        INC     HL                      ; 318E  23
        DJNZ    L318C                   ; 318F  10fb
        JR      L3196                   ; 3191  1803
L3193:
        LD      HL,(42F8H)              ; 3193  2af842
L3196:
        DEC     HL                      ; 3196  2b
        EX      DE,HL                   ; 3197  eb
        DEC     HL                      ; 3198  2b
        LD      A,C                     ; 3199  79
        OR      A                       ; 319A  b7
        LD      B,0                     ; 319B  0600
        JR      z,L31A6                 ; 319D  2807
        EX      DE,HL                   ; 319F  eb
        LDDR                            ; 31A0  edb8
        EX      DE,HL                   ; 31A2  eb
        LD      (HL),2EH                ; 31A3  362e
        DEC     HL                      ; 31A5  2b
L31A6:
        LD      A,(42F3H)               ; 31A6  3af342
        OR      A                       ; 31A9  b7
        JP      p,L31B2                 ; 31AA  f2b231
        LD      (HL),30H                ; 31AD  3630
        DEC     HL                      ; 31AF  2b
        JR      L31BA                   ; 31B0  1808
L31B2:
        JR      nz,L31B5                ; 31B2  2001
        INC     A                       ; 31B4  3c
L31B5:
        LD      C,A                     ; 31B5  4f
        EX      DE,HL                   ; 31B6  eb
        LDDR                            ; 31B7  edb8
        EX      DE,HL                   ; 31B9  eb
L31BA:
        LD      A,(42F1H)               ; 31BA  3af142
        OR      A                       ; 31BD  b7
        JP      p,L31C4                 ; 31BE  f2c431
        LD      (HL),2DH                ; 31C1  362d
        DEC     HL                      ; 31C3  2b
L31C4:
        LD      D,H                     ; 31C4  54
        LD      E,L                     ; 31C5  5d
        LD      BC,(42F6H)              ; 31C6  ed4bf642
        SBC     HL,BC                   ; 31CA  ed42
        JR      z,L31D7                 ; 31CC  2809
        LD      B,L                     ; 31CE  45
        EX      DE,HL                   ; 31CF  eb
L31D0:
        LD      (HL),20H                ; 31D0  3620
        DEC     HL                      ; 31D2  2b
        DJNZ    L31D0                   ; 31D3  10fb
        JR      L31D8                   ; 31D5  1801
L31D7:
        EX      DE,HL                   ; 31D7  eb
L31D8:
        LD      A,(42FCH)               ; 31D8  3afc42
        LD      B,A                     ; 31DB  47
        LD      HL,0                    ; 31DC  210000
        LD      (42FBH),HL              ; 31DF  22fb42
        RET                             ; 31E2  c9
L31E3:
        LD      A,(ARG)                 ; 31E3  3ae742
        DEC     A                       ; 31E6  3d
        LD      C,A                     ; 31E7  4f
        LD      HL,(42F6H)              ; 31E8  2af642
        ADD     A,8                     ; 31EB  c608
        LD      (42FCH),A               ; 31ED  32fc42
        ADD     A,L                     ; 31F0  85
        LD      L,A                     ; 31F1  6f
        JR      nc,L31F5                ; 31F2  3001
        INC     H                       ; 31F4  24
; ---- Exponentialausgabe: E, explizites Vorzeichen und zwei Dezimalziffern des Exponenten.
L31F5:
        DEC     HL                      ; 31F5  2b
        LD      A,(42F3H)               ; 31F6  3af342
        LD      B,0FFH                  ; 31F9  06ff
        OR      A                       ; 31FB  b7
        JP      p,L3201                 ; 31FC  f20132
        NEG                             ; 31FF  ed44
L3201:
        RES     7,C                     ; 3201  cbb9
L3203:
        INC     B                       ; 3203  04
        SUB     10                      ; 3204  d60a
        JR      nc,L3203                ; 3206  30fb
        ADD     A,3AH                   ; 3208  c63a
        LD      (HL),A                  ; 320A  77
        DEC     HL                      ; 320B  2b
        LD      A,B                     ; 320C  78
        OR      30H                     ; 320D  f630
        LD      (HL),A                  ; 320F  77
        DEC     HL                      ; 3210  2b
        LD      A,(42F3H)               ; 3211  3af342
        OR      A                       ; 3214  b7
        LD      A,2BH                   ; 3215  3e2b
        JP      p,L321C                 ; 3217  f21c32
        LD      A,2DH                   ; 321A  3e2d
L321C:
        LD      (HL),A                  ; 321C  77
        DEC     HL                      ; 321D  2b
        LD      (HL),45H                ; 321E  3645
        LD      A,0C5H                  ; 3220  3ec5
        EX      DE,HL                   ; 3222  eb
        LD      (42F3H),A               ; 3223  32f342
        JP      L3193                   ; 3226  c39331
UINT16_TO_HEX:
        LD      A,H                     ; 3229  7c
        CALL    L322E                   ; 322A  cd2e32
        LD      A,L                     ; 322D  7d
L322E:
        PUSH    AF                      ; 322E  f5
        RRA                             ; 322F  1f
        RRA                             ; 3230  1f
        RRA                             ; 3231  1f
        RRA                             ; 3232  1f
        CALL    L3237                   ; 3233  cd3732
        POP     AF                      ; 3236  f1
L3237:
        AND     15                      ; 3237  e60f
        ADD     A,30H                   ; 3239  c630
        CP      3AH                     ; 323B  fe3a
        JR      c,L3241                 ; 323D  3802
        ADD     A,7                     ; 323F  c607
L3241:
        LD      (DE),A                  ; 3241  12
        INC     DE                      ; 3242  13
        RET                             ; 3243  c9
NUMBER_SET_FORMAT:
        LD      A,D                     ; 3244  7a
        CP      1EH                     ; 3245  fe1e
        JR      c,L324B                 ; 3247  3802
        LD      A,1EH                   ; 3249  3e1e
L324B:
        LD      H,A                     ; 324B  67
        LD      A,E                     ; 324C  7b
        AND     15                      ; 324D  e60f
        JR      z,L326D                 ; 324F  281c
        CP      9                       ; 3251  fe09
        JR      c,L3257                 ; 3253  3802
L3255:
        LD      A,9                     ; 3255  3e09
L3257:
        LD      L,A                     ; 3257  6f
        BIT     7,E                     ; 3258  cb7b
        JR      z,L3260                 ; 325A  2804
        SET     7,L                     ; 325C  cbfd
        ADD     A,4                     ; 325E  c604
L3260:
        INC     A                       ; 3260  3c
L3261:
        INC     A                       ; 3261  3c
        SUB     H                       ; 3262  94
        JR      c,L3269                 ; 3263  3804
        LD      H,10H                   ; 3265  2610
        LD      L,88H                   ; 3267  2e88
L3269:
        LD      (42FBH),HL              ; 3269  22fb42
        RET                             ; 326C  c9
L326D:
        BIT     7,E                     ; 326D  cb7b
        JR      nz,L3255                ; 326F  20e4
        LD      L,A                     ; 3271  6f
        JR      L3261                   ; 3272  18ed
; ---- Signed-16-Bit-Integer in FAC auf 32 Bit vorzeichenerweitern und exakt nach FP wandeln.
INT16_TO_FP:
        LD      HL,0                    ; 3274  210000
        LD      A,(42E3H)               ; 3277  3ae342
        RLA                             ; 327A  17
        JR      nc,L327E                ; 327B  3001
        DEC     HL                      ; 327D  2b
L327E:
        LD      (42E4H),HL              ; 327E  22e442
; ---- Signed-32-Bit-Wert nach FP: Typ=2, e=31, ggf. Betrag bilden und normalisieren.
INT32_TO_FP:
        LD      A,2                     ; 3281  3e02
        LD      (FAC_TYPE),A            ; 3283  32e142
        LD      A,1FH                   ; 3286  3e1f
        LD      (FAC_EXP),A             ; 3288  32e642
        LD      HL,(42E4H)              ; 328B  2ae442
        LD      DE,(FAC)                ; 328E  ed5be242
        BIT     7,H                     ; 3292  cb7c
        JP      z,FP_NORMALIZE          ; 3294  ca5e28
        CALL    FP_NEGATE_MAGNITUDE     ; 3297  cd9428
        SCF                             ; 329A  37
        BIT     7,H                     ; 329B  cb7c
        JP      z,FP_STORE_RESULT       ; 329D  ca7c27
        RR      H                       ; 32A0  cb1c
        RR      L                       ; 32A2  cb1d
        RR      D                       ; 32A4  cb1a
        RR      E                       ; 32A6  cb1b
        LD      A,(FAC_EXP)             ; 32A8  3ae642
        INC     A                       ; 32AB  3c
        LD      (FAC_EXP),A             ; 32AC  32e642
        LD      (42E4H),HL              ; 32AF  22e442
        LD      (FAC),DE                ; 32B2  ed53e242
        RET                             ; 32B6  c9

;=====================================================================
; GLEITKOMMA NACH 16-BIT-INTEGER: SEPARATE RUNDUNG
; Typ=1; Null oder e<0 -> 0. e>15 -> Bereichsfehler 31.
; Oberes Mantissenwort rechts schieben; letztes verlorenes Bit rundet
; den Betrag auf, danach Vorzeichen anwenden (halbe Werte weg von null).
; Niedrige Mantissenbits werden vorher verworfen; Grenzfaelle sind
; daher NICHT ideal mathematisch gerundet: 32767.5 -> 32767.
; Auch -32768 wird wegen e=16 abgewiesen. Keine Codekorrektur vorgenommen.
;=====================================================================
FP_TO_INT16:
        LD      A,1                     ; 32B7  3e01
        LD      (FAC_TYPE),A            ; 32B9  32e142
        LD      HL,(FAC_SIGN_MSB)       ; 32BC  2ae542
        LD      A,L                     ; 32BF  7d
        AND     A                       ; 32C0  a7
        JR      z,L32C7                 ; 32C1  2804
        BIT     7,H                     ; 32C3  cb7c
        JR      z,L32CC                 ; 32C5  2805
L32C7:
        LD      HL,0                    ; 32C7  210000
        JR      L32F3                   ; 32CA  1827
L32CC:
        LD      A,15                    ; 32CC  3e0f
        SUB     H                       ; 32CE  94
        LD      B,A                     ; 32CF  47
        LD      A,1FH                   ; 32D0  3e1f
        JP      c,ERROR                 ; 32D2  da5933
        PUSH    HL                      ; 32D5  e5
        LD      HL,(42E4H)              ; 32D6  2ae442
        RES     7,H                     ; 32D9  cbbc
        JR      z,L32E7                 ; 32DB  280a
L32DD:
        AND     A                       ; 32DD  a7
        RR      H                       ; 32DE  cb1c
        RR      L                       ; 32E0  cb1d
        DJNZ    L32DD                   ; 32E2  10f9
        JR      nc,L32E7                ; 32E4  3001
        INC     HL                      ; 32E6  23
L32E7:
        POP     DE                      ; 32E7  d1
        BIT     7,E                     ; 32E8  cb7b
        JR      z,L32F3                 ; 32EA  2807
        EX      DE,HL                   ; 32EC  eb
        LD      HL,0                    ; 32ED  210000
        AND     A                       ; 32F0  a7
        SBC     HL,DE                   ; 32F1  ed52
L32F3:
        LD      (FAC),HL                ; 32F3  22e242
        RET                             ; 32F6  c9
        DB      0EDH,5BH,9AH,41H        ; 32F7 .[.A
L32FB:
        EX      DE,HL                   ; 32FB  eb
        LD      A,(HL)                  ; 32FC  7e
        LD      (DE),A                  ; 32FD  12
        LD      (HL),E                  ; 32FE  73
        INC     HL                      ; 32FF  23
        LD      A,(HL)                  ; 3300  7e
        LD      (HL),D                  ; 3301  72
        INC     DE                      ; 3302  13
        LD      (DE),A                  ; 3303  12
        DEC     DE                      ; 3304  1b
        DEC     HL                      ; 3305  2b
        EX      DE,HL                   ; 3306  eb
        RET                             ; 3307  c9
L3308:
        LD      DE,(419AH)              ; 3308  ed5b9a41
L330C:
        LD      H,D                     ; 330C  62
        LD      L,E                     ; 330D  6b
        LD      A,(HL)                  ; 330E  7e
        INC     HL                      ; 330F  23
        LD      H,(HL)                  ; 3310  66
        LD      L,A                     ; 3311  6f
        OR      H                       ; 3312  b4
        SCF                             ; 3313  37
        RET     z                       ; 3314  c8
        LD      A,(HL)                  ; 3315  7e
        LD      (DE),A                  ; 3316  12
        INC     HL                      ; 3317  23
        INC     DE                      ; 3318  13
        LD      A,(HL)                  ; 3319  7e
        LD      (DE),A                  ; 331A  12
        DEC     DE                      ; 331B  1b
        DEC     HL                      ; 331C  2b
        AND     A                       ; 331D  a7
        RET                             ; 331E  c9

;=====================================================================
; PROGRAMMZEILEN-VERWALTUNG
; Zeilen bilden eine verkettete Liste; 419AH = aktuelle Zeile.
; LINE_NEXT: zur folgenden Zeile weiterschalten.
;=====================================================================
LINE_NEXT:
        LD      HL,(419AH)              ; 331F  2a9a41
        LD      A,(HL)                  ; 3322  7e
        INC     HL                      ; 3323  23
        LD      H,(HL)                  ; 3324  66
        LD      L,A                     ; 3325  6f
; ---- LINE_SET: HL als aktuelle Zeile setzen, Zeilennummer nach DE
LINE_SET:
        LD      (419AH),HL              ; 3326  229a41
        LD      E,(HL)                  ; 3329  5e
        INC     HL                      ; 332A  23
        LD      D,(HL)                  ; 332B  56
        DEC     HL                      ; 332C  2b
        LD      A,D                     ; 332D  7a
        OR      E                       ; 332E  b3
        EX      DE,HL                   ; 332F  eb
        RET                             ; 3330  c9
L3331:
        LD      DE,(419AH)              ; 3331  ed5b9a41
; ---- LINE_FIND: Zeile mit Nummer DE suchen
LINE_FIND:
        LD      C,A                     ; 3335  4f
        PUSH    HL                      ; 3336  e5
        EX      DE,HL                   ; 3337  eb
        CALL    LINE_SET                ; 3338  cd2633
        JR      z,L3350                 ; 333B  2813
L333D:
        LD      B,H                     ; 333D  44
        INC     HL                      ; 333E  23
        INC     HL                      ; 333F  23
        LD      E,(HL)                  ; 3340  5e
        INC     HL                      ; 3341  23
        LD      D,(HL)                  ; 3342  56
        POP     HL                      ; 3343  e1
        LD      A,C                     ; 3344  79
        CALL    L25CA                   ; 3345  cdca25
        JR      nz,L3353                ; 3348  2009
        PUSH    HL                      ; 334A  e5
        CALL    LINE_NEXT               ; 334B  cd1f33
        JR      nz,L333D                ; 334E  20ed
L3350:
        POP     HL                      ; 3350  e1
        XOR     A                       ; 3351  af
        RET                             ; 3352  c9
L3353:
        LD      HL,(419AH)              ; 3353  2a9a41
        LD      C,(HL)                  ; 3356  4e
        EX      DE,HL                   ; 3357  eb
        RET                             ; 3358  c9

;=====================================================================
; FEHLERBEHANDLUNG (ERROR)
; Ein: A = Fehlernummer, Bit7=1: Warnung statt Fehler.
; Merkt Nummer (41E3H, fuer ERRN) und Zeile (41E1H, fuer ERLN),
; gibt "ERROR"/"WARNING" + Nummer + " AT LINE:" aus.
; Bei Fehler Ruecksprung in WARMSTART, bei Warnung weiter.
;=====================================================================
ERROR:
        BIT     7,A                     ; 3359  cb7f
        RES     7,A                     ; 335B  cbbf
        PUSH    AF                      ; 335D  f5
        LD      (41E3H),A               ; 335E  32e341
        LD      HL,(41DAH)              ; 3361  2ada41
        LD      (41E1H),HL              ; 3364  22e141
        LD      HL,MSG_ERROR            ; 3367  218f34
        JR      z,L336F                 ; 336A  2803
        LD      HL,MSG_WARNING          ; 336C  219534
L336F:
        CALL    CH_NEWLINE              ; 336F  cdc335
        CALL    PRINT_STR               ; 3372  cde735
        POP     AF                      ; 3375  f1
        PUSH    AF                      ; 3376  f5
        CALL    L2553                   ; 3377  cd5325
        CALL    L257E                   ; 337A  cd7e25
        CALL    L259C                   ; 337D  cd9c25
        CALL    CH_CRLF                 ; 3380  cdce35
        LD      HL,41C1H                ; 3383  21c141
        BIT     0,(HL)                  ; 3386  cb46
        CALL    nz,L3390                ; 3388  c49033
        POP     AF                      ; 338B  f1
        RET     nz                      ; 338C  c0
        JP      WARMSTART               ; 338D  c34802
L3390:
        LD      A,(41E3H)               ; 3390  3ae341
        AND     7FH                     ; 3393  e67f
        CP      64H                     ; 3395  fe64
        RET     nc                      ; 3397  d0
        LD      HL,(4088H)              ; 3398  2a8840
        PUSH    HL                      ; 339B  e5
        DEC     HL                      ; 339C  2b
        LD      A,(HL)                  ; 339D  7e
        JR      L33A3                   ; 339E  1803
L33A0:
        CALL    L11F8                   ; 33A0  cdf811
L33A3:
        CP      1EH                     ; 33A3  fe1e
        JR      nz,L33A0                ; 33A5  20f9
        POP     HL                      ; 33A7  e1
        LD      DE,408AH                ; 33A8  118a40
        AND     A                       ; 33AB  a7
        SBC     HL,DE                   ; 33AC  ed52
        LD      B,L                     ; 33AE  45
        EX      DE,HL                   ; 33AF  eb
        CALL    CH_CRLF                 ; 33B0  cdce35
L33B3:
        LD      A,(HL)                  ; 33B3  7e
        CP      1EH                     ; 33B4  fe1e
        JR      z,L33BE                 ; 33B6  2806
        INC     HL                      ; 33B8  23
        CALL    OUTCH                   ; 33B9  cdd435
        DJNZ    L33B3                   ; 33BC  10f5
L33BE:
        DEC     HL                      ; 33BE  2b
        SET     7,(HL)                  ; 33BF  cbfe
        INC     HL                      ; 33C1  23
        CALL    CH_SPACE                ; 33C2  cdd235
        LD      A,3FH                   ; 33C5  3e3f
        CALL    OUTCH                   ; 33C7  cdd435
        CALL    CH_SPACE                ; 33CA  cdd235
        CALL    L35DB                   ; 33CD  cddb35
        LD      HL,41C2H                ; 33D0  21c241
        SET     0,(HL)                  ; 33D3  cbc6
        LD      HL,408AH                ; 33D5  218a40
        LD      DE,4003H                ; 33D8  110340
        LD      BC,7EH                  ; 33DB  017e00
        LDIR                            ; 33DE  edb0
        CALL    CON_CR                  ; 33E0  cd2f36
        LD      HL,4003H                ; 33E3  210340
        LD      B,7EH                   ; 33E6  067e
L33E8:
        LD      A,(HL)                  ; 33E8  7e
        INC     HL                      ; 33E9  23
        CP      1EH                     ; 33EA  fe1e
        JR      z,L33F3                 ; 33EC  2805
        CALL    CH_OUT                  ; 33EE  cddb34
        DJNZ    L33E8                   ; 33F1  10f5
L33F3:
        LD      HL,41A6H                ; 33F3  21a641
        CALL    L3402                   ; 33F6  cd0234
        LD      HL,41A8H                ; 33F9  21a841
        CALL    L3402                   ; 33FC  cd0234
        LD      HL,41AAH                ; 33FF  21aa41
L3402:
        CALL    LINE_SET                ; 3402  cd2633
        RET     z                       ; 3405  c8
L3406:
        LD      BC,6                    ; 3406  010600
        ADD     HL,BC                   ; 3409  09
        LD      A,(HL)                  ; 340A  7e
        INC     HL                      ; 340B  23
        AND     (HL)                    ; 340C  a6
        INC     A                       ; 340D  3c
        LD      C,8                     ; 340E  0e08
        CALL    z,L204B                 ; 3410  cc4b20
        CALL    LINE_NEXT               ; 3413  cd1f33
        JR      nz,L3406                ; 3416  20ee
        RET                             ; 3418  c9
; ---- Meldungstexte (Laengenbyte + Text)
MSG_WELCOME:
        DB      3DH,57H,45H,4CH,43H,4FH,4DH,45H ; 3419 =WELCOME
        DB      20H,54H,4FH,20H,47H,52H,41H,50H ; 3421  TO GRAP
        DB      48H,49H,4BH,2DH,42H,41H,53H,49H ; 3429 HIK-BASI
        DB      43H,1EH,1EH,56H,45H,52H,53H,49H ; 3431 C..VERSI
        DB      4FH,4EH,20H,33H,2EH,31H,20H,20H ; 3439 ON 3.1
        DB      56H,4FH,4DH,20H,30H,33H,2EH,30H ; 3441 VOM 03.0
        DB      33H,2EH,38H,36H,1EH,52H,2EH,48H ; 3449 3.86.R.H
        DB      45H,59H,4EH,45H,1EH,1EH ; 3451 EYNE..
MSG_NOSRC:
        DB      53H,4FH,55H,52H,43H,45H,20H,4EH ; 3457 SOURCE N
        DB      4FH,54H,20H,53H,54H,4FH,52H,41H ; 345F OT STORA
        DB      47H,45H,44H,1EH         ; 3467 GED.
MSG_RESTART:
        DB      52H,45H,53H,54H,41H,52H,54H,20H ; 346B RESTART
        DB      42H,41H,53H,49H,43H,1EH,05H ; 3473 BASIC..
MSG_BREAK:
        DB      42H,52H,45H,41H,4BH,09H ; 347A BREAK.
MSG_ATLINE:
        DB      20H,41H,54H,20H,4CH,49H,4EH,45H ; 3480  AT LINE
        DB      3AH,52H,45H,41H,44H,59H,1EH ; 3488 :READY.
MSG_ERROR:
        DB      05H,45H,52H,52H,4FH,52H ; 348F .ERROR
MSG_WARNING:
        DB      07H,57H,41H,52H,4EH,49H,4EH,47H ; 3495 .WARNING
        DB      45H,4EH,44H,1EH,01H,00H,89H,00H ; 349D END.....
        DB      0A1H,34H,83H,00H,02H,40H,00H,43H ; 34A5 .4...@.C
        DB      0B5H,34H,0FFH,0FFH,00H,00H,00H,00H ; 34AD .4......
        DB      0A7H,0C9H               ; 34B5 ..
L34B7:
        CALL    L356D                   ; 34B7  cd6d35
        CP      57H                     ; 34BA  fe57
        JR      z,L34D3                 ; 34BC  2815
        CP      42H                     ; 34BE  fe42
        LD      (41E4H),A               ; 34C0  32e441
        RET     nz                      ; 34C3  c0
        CALL    CH_NEWLINE              ; 34C4  cdc335
        LD      HL,3479H                ; 34C7  217934
        CALL    PRINT_STR               ; 34CA  cde735
        CALL    L257E                   ; 34CD  cd7e25
        JP      WARMSTART               ; 34D0  c34802
L34D3:
        CALL    L356D                   ; 34D3  cd6d35
        CP      43H                     ; 34D6  fe43
        JR      nz,L34D3                ; 34D8  20f9
        RET                             ; 34DA  c9

;=====================================================================
; ZEICHEN-EIN/AUSGABE UEBER KANALBLOECKE
; IY zeigt auf einen Kanalblock (Konsole, Drucker, Datei ...):
; (IY+0) Flags, (IY+1/2) Adresse der Treiberroutine.
; CH_OUT: Zeichen A auf Kanal IY ausgeben.
;=====================================================================
CH_OUT:
        PUSH    HL                      ; 34DB  e5
        PUSH    DE                      ; 34DC  d5
        PUSH    BC                      ; 34DD  c5
        PUSH    AF                      ; 34DE  f5
        LD      H,(IY+2)                ; 34DF  fd6602
        LD      L,(IY+1)                ; 34E2  fd6e01
        LD      B,A                     ; 34E5  47
        LD      A,(IY)                  ; 34E6  fd7e00
        RRCA                            ; 34E9  0f
        CALL    nc,L353C                ; 34EA  d43c35
        RRCA                            ; 34ED  0f
        JR      nc,L3544                ; 34EE  3054
        LD      A,B                     ; 34F0  78
        CP      10                      ; 34F1  fe0a
        JR      z,L3531                 ; 34F3  283c
        CP      1EH                     ; 34F5  fe1e
        JR      z,L352A                 ; 34F7  2831
        CP      13                      ; 34F9  fe0d
        JR      z,L352A                 ; 34FB  282d
        CP      9                       ; 34FD  fe09
        JR      nz,L350F                ; 34FF  200e
        LD      A,(IY+4)                ; 3501  fd7e04
L3504:
        SUB     8                       ; 3504  d608
        JR      c,L3519                 ; 3506  3811
        CP      (IY+3)                  ; 3508  fdbe03
        JR      nc,L3504                ; 350B  30f7
        JR      L3513                   ; 350D  1804
L350F:
        LD      A,(IY+3)                ; 350F  fd7e03
        DEC     A                       ; 3512  3d
L3513:
        LD      (IY+3),A                ; 3513  fd7703
        INC     A                       ; 3516  3c
        JR      nz,L3531                ; 3517  2018
L3519:
        BIT     5,(IY)                  ; 3519  fdcb006e
        JR      z,L352A                 ; 351D  280b
        LD      A,1EH                   ; 351F  3e1e
        PUSH    BC                      ; 3521  c5
        PUSH    HL                      ; 3522  e5
        CALL    L3570                   ; 3523  cd7035
        JR      c,L354D                 ; 3526  3825
        POP     HL                      ; 3528  e1
        POP     BC                      ; 3529  c1
L352A:
        LD      A,(IY+4)                ; 352A  fd7e04
        DEC     A                       ; 352D  3d
        LD      (IY+3),A                ; 352E  fd7703
L3531:
        LD      A,B                     ; 3531  78
        CALL    L3570                   ; 3532  cd7035
        JR      c,L354D                 ; 3535  3816
        POP     AF                      ; 3537  f1
        POP     BC                      ; 3538  c1
        POP     DE                      ; 3539  d1
        POP     HL                      ; 353A  e1
        RET                             ; 353B  c9
L353C:
        BIT     5,A                     ; 353C  cb6f
        JR      nz,L3583                ; 353E  2043
        LD      A,52H                   ; 3540  3e52
        JR      L354A                   ; 3542  1806
L3544:
        LD      A,53H                   ; 3544  3e53
        JR      L354A                   ; 3546  1802
L3548:
        LD      A,54H                   ; 3548  3e54
L354A:
        JP      ERROR                   ; 354A  c35933
L354D:
        LD      A,B                     ; 354D  78
        JR      L354A                   ; 354E  18fa
L3550:
        PUSH    HL                      ; 3550  e5
        PUSH    DE                      ; 3551  d5
        PUSH    BC                      ; 3552  c5
        LD      A,(IY)                  ; 3553  fd7e00
        RRCA                            ; 3556  0f
        CALL    nc,L353C                ; 3557  d43c35
        RRCA                            ; 355A  0f
        RRCA                            ; 355B  0f
        JR      nc,L3548                ; 355C  30ea
        LD      H,(IY+2)                ; 355E  fd6602
        LD      L,(IY+1)                ; 3561  fd6e01
        CALL    L3570                   ; 3564  cd7035
        JR      c,L354D                 ; 3567  38e4
        POP     BC                      ; 3569  c1
        POP     DE                      ; 356A  d1
        POP     HL                      ; 356B  e1
        RET                             ; 356C  c9
L356D:
        LD      HL,3764H                ; 356D  216437
L3570:
        PUSH    IX                      ; 3570  dde5
        PUSH    IY                      ; 3572  fde5
        LD      DE,357EH                ; 3574  117e35
        PUSH    DE                      ; 3577  d5
        LD      DE,9                    ; 3578  110900
        ADD     IY,DE                   ; 357B  fd19
        JP      (HL)                    ; 357D  e9
        DB      0FDH,0E1H,0DDH,0E1H,0C9H ; 357E .....
L3583:
        PUSH    AF                      ; 3583  f5
        SET     0,(IY)                  ; 3584  fdcb00c6
        BIT     5,(IY)                  ; 3588  fdcb006e
        JR      z,L3594                 ; 358C  2806
        LD      A,(IY+4)                ; 358E  fd7e04
        LD      (IY+3),A                ; 3591  fd7703
L3594:
        PUSH    HL                      ; 3594  e5
        LD      H,(IY+6)                ; 3595  fd6606
        LD      L,(IY+5)                ; 3598  fd6e05
L359B:
        LD      A,H                     ; 359B  7c
        OR      L                       ; 359C  b5
        JR      z,L35A8                 ; 359D  2809
        PUSH    DE                      ; 359F  d5
        PUSH    BC                      ; 35A0  c5
        CALL    L3570                   ; 35A1  cd7035
        JR      c,L354D                 ; 35A4  38a7
        POP     BC                      ; 35A6  c1
        POP     DE                      ; 35A7  d1
L35A8:
        POP     HL                      ; 35A8  e1
L35A9:
        POP     AF                      ; 35A9  f1
        RET                             ; 35AA  c9
L35AB:
        PUSH    AF                      ; 35AB  f5
        BIT     0,(IY)                  ; 35AC  fdcb0046
        JR      z,L35A9                 ; 35B0  28f7
        RES     0,(IY)                  ; 35B2  fdcb0086
        PUSH    HL                      ; 35B6  e5
        LD      H,(IY+8)                ; 35B7  fd6608
        LD      L,(IY+7)                ; 35BA  fd6e07
        JR      L359B                   ; 35BD  18dc
L35BF:
        LD      A,9                     ; 35BF  3e09
        JR      OUTCH                   ; 35C1  1811
CH_NEWLINE:
        LD      IY,(41F1H)              ; 35C3  fd2af141
        LD      A,(IY+4)                ; 35C7  fd7e04
        CP      (IY+3)                  ; 35CA  fdbe03
        RET     z                       ; 35CD  c8
CH_CRLF:
        LD      A,1EH                   ; 35CE  3e1e
        JR      OUTCH                   ; 35D0  1802
CH_SPACE:
        LD      A,20H                   ; 35D2  3e20
; ---- OUTCH: Zeichen A auf aktuellen Ausgabekanal (41F1H)
OUTCH:
        LD      IY,(41F1H)              ; 35D4  fd2af141
        JP      CH_OUT                  ; 35D8  c3db34
L35DB:
        LD      B,1EH                   ; 35DB  061e
L35DD:
        LD      A,(HL)                  ; 35DD  7e
        CALL    OUTCH                   ; 35DE  cdd435
        LD      A,(HL)                  ; 35E1  7e
        INC     HL                      ; 35E2  23
        CP      B                       ; 35E3  b8
        JR      nz,L35DD                ; 35E4  20f7
        RET                             ; 35E6  c9
; ---- PRINT_STR: Text mit Laengenbyte bei HL ausgeben
PRINT_STR:
        LD      B,(HL)                  ; 35E7  46
        INC     HL                      ; 35E8  23
PRINT_N:
        LD      A,(HL)                  ; 35E9  7e
        CALL    OUTCH                   ; 35EA  cdd435
        INC     HL                      ; 35ED  23
        DJNZ    PRINT_N                 ; 35EE  10f9
        RET                             ; 35F0  c9
X_SKIP:
        LD      A,1EH                   ; 35F1  3e1e
        JR      L35F7                   ; 35F3  1802
L35F5:
        LD      A,20H                   ; 35F5  3e20
L35F7:
        LD      IY,(41F3H)              ; 35F7  fd2af341
        JP      CH_OUT                  ; 35FB  c3db34
        DB      46H,23H,7EH,0CDH,0F7H,35H,23H,10H ; 35FE F#~..5#.
        DB      0F9H,0C9H,06H,1EH,7EH,0CDH,0F7H,35H ; 3606 ....~..5
        DB      7EH,23H,0B8H,20H,0F7H,0C9H ; 360E ~#. ..
L3614:
        LD      A,1EH                   ; 3614  3e1e
        JP      CH_OUT                  ; 3616  c3db34
L3619:
        LD      A,20H                   ; 3619  3e20
        JP      CH_OUT                  ; 361B  c3db34
        DB      46H,23H                 ; 361E F#
L3620:
        LD      A,(HL)                  ; 3620  7e
        CALL    CH_OUT                  ; 3621  cddb34
        INC     HL                      ; 3624  23
        DJNZ    L3620                   ; 3625  10f9
        RET                             ; 3627  c9
L3628:
        CALL    L356D                   ; 3628  cd6d35
        AND     A                       ; 362B  a7
        JR      nz,L3628                ; 362C  20fa
        RET                             ; 362E  c9
CON_CR:
        LD      IY,4204H                ; 362F  fd210442
        LD      A,13                    ; 3633  3e0d
        JP      CH_OUT                  ; 3635  c3db34
L3638:
        LD      (4083H),A               ; 3638  328340
        PUSH    HL                      ; 363B  e5
        LD      HL,(4088H)              ; 363C  2a8840
        DEC     HL                      ; 363F  2b
        LD      (4088H),HL              ; 3640  228840
        POP     HL                      ; 3643  e1
        RET                             ; 3644  c9
L3645:
        LD      A,(4083H)               ; 3645  3a8340
        AND     A                       ; 3648  a7
        JR      z,L3652                 ; 3649  2807
        PUSH    AF                      ; 364B  f5
        XOR     A                       ; 364C  af
        LD      (4083H),A               ; 364D  328340
        POP     AF                      ; 3650  f1
        RET                             ; 3651  c9
L3652:
        PUSH    IY                      ; 3652  fde5
        LD      IY,(41F7H)              ; 3654  fd2af741
        LD      HL,41C1H                ; 3658  21c141
        BIT     5,(HL)                  ; 365B  cb6e
        JR      nz,L3667                ; 365D  2008
        BIT     1,(HL)                  ; 365F  cb4e
        JR      nz,L3667                ; 3661  2004
        LD      IY,(41F5H)              ; 3663  fd2af541
L3667:
        CALL    L3550                   ; 3667  cd5035
        POP     IY                      ; 366A  fde1
        RET                             ; 366C  c9
        DB      00H,00H,00H,00H,00H,00H,00H,00H ; 366D ........
        DB      00H,00H,00H,00H,00H,00H,00H,00H ; 3675 ........
        DB      00H,00H,00H,00H,00H,00H,00H,00H ; 367D ........
        DB      00H,00H,00H,00H,00H,00H,00H,00H ; 3685 ........
        DB      00H,00H,00H,00H,00H,00H,00H,00H ; 368D ........
        DB      00H,00H,00H,00H,00H,00H,00H,00H ; 3695 ........
        DB      00H,00H,00H,00H,00H,00H,00H,00H ; 369D ........
        DB      00H,00H,00H,00H,00H,00H,00H,00H ; 36A5 ........
        DB      00H,00H,00H,00H,00H,00H,00H,00H ; 36AD ........
        DB      00H,0FEH,1EH,20H,07H,3EH,0DH,0CDH ; 36B5 ... .>..
        DB      0C1H,36H,3EH,0AH,0C5H,0D5H,0E5H,0F5H ; 36BD .6>.....
        DB      5FH,0EH,05H,0CDH,05H,00H,0F1H,0B7H ; 36C5 _.......
        DB      18H,17H,3EH,0CH,0FEH,1EH,28H,22H ; 36CD ..>...("
        DB      0B7H,18H,10H            ; 36D5 ...
L36D8:
        PUSH    BC                      ; 36D8  c5
        PUSH    DE                      ; 36D9  d5
        PUSH    HL                      ; 36DA  e5
L36DB:
        LD      E,0FFH                  ; 36DB  1eff
        LD      C,6                     ; 36DD  0e06
        CALL    BDOS                    ; 36DF  cd0500
        CP      0                       ; 36E2  fe00
        JR      z,L36DB                 ; 36E4  28f5
        JR      L36F3                   ; 36E6  180b

;=====================================================================
; CP/M-ANSCHLUSS (BDOS)
; CONOUT: Zeichen A ueber BDOS 2 ausgeben, alle Register erhalten.
;=====================================================================
CONOUT:
        PUSH    BC                      ; 36E8  c5
        PUSH    DE                      ; 36E9  d5
        PUSH    HL                      ; 36EA  e5
        PUSH    AF                      ; 36EB  f5
        LD      E,A                     ; 36EC  5f
        LD      C,2                     ; 36ED  0e02
        CALL    BDOS                    ; 36EF  cd0500
        POP     AF                      ; 36F2  f1
L36F3:
        POP     HL                      ; 36F3  e1
        POP     DE                      ; 36F4  d1
        POP     BC                      ; 36F5  c1
        RET                             ; 36F6  c9
        DB      3EH,0DH,0CDH,0E8H,36H,3EH,0AH,18H ; 36F7 >...6>..
        DB      0E8H                    ; 36FF .

;=====================================================================
; DRVTAB: PATCHBARE TREIBERTABELLE
; Erweiterungspunkte fuer Geraetetreiber. 3703H ist nur RET; dorthin
; zeigen PLOT und die meisten Grafik-Unterfunktionen.
;=====================================================================
DRVTAB:
        DB      00H,00H,00H             ; 3700 ...
DRV_DUMMY:
        DB      0C9H,44H,0AFH,37H,00H,00H,00H,00H ; 3703 .D.7....
        DB      00H,00H,42H,0DBH,37H,00H,00H,00H ; 370B ..B.7...
        DB      00H,00H,00H,42H,0D1H,36H,0FFH,0FFH ; 3713 ...B.6..
        DB      0CFH,36H,00H,00H,42H,03H,37H,01H ; 371B .6..B.7.
        DB      00H,00H,00H,00H,00H,44H,03H,37H ; 3723 .....D.7
        DB      00H,00H,00H,00H,00H,00H,62H,0B6H ; 372B ......b.
        DB      36H,50H,00H,00H,00H,00H,00H,54H ; 3733 6P.....T
        DB      7CH,37H,00H,00H,2FH,3AH,49H,3AH ; 373B |7../:I:
        DB      52H,6CH,37H,0FFH,0FFH,0A5H,39H,0C5H ; 3743 Rl7...9.
        DB      39H,54H,4BH,3AH,0FFH,0FFH,2FH,3AH ; 374B 9TK:../:
        DB      49H,3AH,52H,0DFH,39H,0FFH,0FFH,0A5H ; 3753 I:R.9...
        DB      39H,0C5H,39H            ; 375B 9.9
        LD      C,0                     ; 375E  0e00
        CALL    BDOS                    ; 3760  cd0500
        RET                             ; 3763  c9
        LD      E,0FFH                  ; 3764  1eff
        LD      C,6                     ; 3766  0e06
        CALL    BDOS                    ; 3768  cd0500
        RET                             ; 376B  c9
        CP      1EH                     ; 376C  fe1e
        JP      nz,L39DF                ; 376E  c2df39
        LD      A,13                    ; 3771  3e0d
        CALL    L39DF                   ; 3773  cddf39
        RET     c                       ; 3776  d8
        LD      A,10                    ; 3777  3e0a
        JP      L39DF                   ; 3779  c3df39
L377C:
        CALL    L3A4B                   ; 377C  cd4b3a
        RET     c                       ; 377F  d8
        CP      10                      ; 3780  fe0a
        JR      z,L377C                 ; 3782  28f8
        CP      13                      ; 3784  fe0d
        JR      nz,L378A                ; 3786  2002
        LD      A,1EH                   ; 3788  3e1e
L378A:
        OR      A                       ; 378A  b7
        RET                             ; 378B  c9
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ; 378C ........
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ; 3794 ........
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ; 379C ........
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ; 37A4 ........
        DB      0FFH,0FFH,0FFH          ; 37AC ...
        LD      HL,(4088H)              ; 37AF  2a8840
        LD      A,H                     ; 37B2  7c
        OR      L                       ; 37B3  b5
        JR      nz,L37D8                ; 37B4  2022
        LD      HL,408AH                ; 37B6  218a40
        LD      DE,7FH                  ; 37B9  117f00
        CALL    L3802                   ; 37BC  cd0238
        LD      B,64H                   ; 37BF  0664
        RET     c                       ; 37C1  d8
        LD      A,20H                   ; 37C2  3e20
        LD      HL,4109H                ; 37C4  210941
        LD      B,80H                   ; 37C7  0680
L37C9:
        DEC     HL                      ; 37C9  2b
        CP      (HL)                    ; 37CA  be
        JR      nz,L37CF                ; 37CB  2002
        DJNZ    L37C9                   ; 37CD  10fa
L37CF:
        INC     HL                      ; 37CF  23
        LD      (HL),1EH                ; 37D0  361e
        LD      HL,408AH                ; 37D2  218a40
        LD      (4088H),HL              ; 37D5  228840
L37D8:
        LD      A,(HL)                  ; 37D8  7e
        AND     A                       ; 37D9  a7
        RET                             ; 37DA  c9
        CP      1EH                     ; 37DB  fe1e
        RET     z                       ; 37DD  c8
        CP      13                      ; 37DE  fe0d
        JR      nz,L37F9                ; 37E0  2017
        LD      HL,0                    ; 37E2  210000
        LD      (4088H),HL              ; 37E5  228840
        LD      HL,408AH                ; 37E8  218a40
        LD      (4086H),HL              ; 37EB  228640
        LD      B,7FH                   ; 37EE  067f
        LD      C,20H                   ; 37F0  0e20
L37F2:
        LD      (HL),C                  ; 37F2  71
        INC     HL                      ; 37F3  23
        DJNZ    L37F2                   ; 37F4  10fc
        LD      (HL),1EH                ; 37F6  361e
        RET                             ; 37F8  c9
L37F9:
        LD      HL,(4086H)              ; 37F9  2a8640
        LD      (HL),A                  ; 37FC  77
        INC     HL                      ; 37FD  23
        LD      (4086H),HL              ; 37FE  228640
        RET                             ; 3801  c9
L3802:
        LD      BC,(4086H)              ; 3802  ed4b8640
        PUSH    AF                      ; 3806  f5
        PUSH    BC                      ; 3807  c5
        PUSH    DE                      ; 3808  d5
        PUSH    HL                      ; 3809  e5
        PUSH    HL                      ; 380A  e5
        AND     A                       ; 380B  a7
        SBC     HL,BC                   ; 380C  ed42
        LD      D,L                     ; 380E  55
        POP     HL                      ; 380F  e1
        LD      B,0                     ; 3810  0600
        LD      C,E                     ; 3812  4b
        DEC     C                       ; 3813  0d
        INC     D                       ; 3814  14
        DEC     D                       ; 3815  15
        JR      nz,L381E                ; 3816  2006
        DEC     C                       ; 3818  0d
        DEC     C                       ; 3819  0d
        DEC     C                       ; 381A  0d
        DEC     C                       ; 381B  0d
        JR      L383F                   ; 381C  1821
L381E:
        AND     A                       ; 381E  a7
L381F:
        BIT     7,(HL)                  ; 381F  cb7e
        JR      z,L3827                 ; 3821  2804
        RES     7,(HL)                  ; 3823  cbbe
        LD      E,D                     ; 3825  5a
        SCF                             ; 3826  37
L3827:
        LD      A,(HL)                  ; 3827  7e
        CALL    CONOUT                  ; 3828  cde836
        INC     HL                      ; 382B  23
        INC     B                       ; 382C  04
        DEC     C                       ; 382D  0d
        INC     D                       ; 382E  14
        JR      nz,L381F                ; 382F  20ee
        JR      nc,L383F                ; 3831  300c
        LD      A,8                     ; 3833  3e08
L3835:
        CALL    CONOUT                  ; 3835  cde836
        DEC     HL                      ; 3838  2b
        DEC     B                       ; 3839  05
        INC     C                       ; 383A  0c
        INC     D                       ; 383B  14
        INC     E                       ; 383C  1c
        JR      nz,L3835                ; 383D  20f6
L383F:
        CALL    L36D8                   ; 383F  cdd836
        CP      80H                     ; 3842  fe80
        JR      nc,L385C                ; 3844  3016
        CP      20H                     ; 3846  fe20
        JR      c,L385C                 ; 3848  3812
L384A:
        INC     C                       ; 384A  0c
        DEC     C                       ; 384B  0d
        JR      z,L383F                 ; 384C  28f1
        LD      (HL),A                  ; 384E  77
        CALL    CONOUT                  ; 384F  cde836
        INC     HL                      ; 3852  23
        INC     B                       ; 3853  04
        DEC     C                       ; 3854  0d
        INC     D                       ; 3855  14
        DEC     D                       ; 3856  15
        JR      z,L383F                 ; 3857  28e6
        DEC     D                       ; 3859  15
        JR      L383F                   ; 385A  18e3
L385C:
        CP      4                       ; 385C  fe04
        JR      nz,L3863                ; 385E  2003
        LD      A,(HL)                  ; 3860  7e
        JR      L384A                   ; 3861  18e7
L3863:
        CP      8                       ; 3863  fe08
        JR      nz,L3876                ; 3865  200f
        INC     B                       ; 3867  04
        DEC     B                       ; 3868  05
        JR      z,L383F                 ; 3869  28d4
        LD      A,8                     ; 386B  3e08
        CALL    CONOUT                  ; 386D  cde836
        DEC     HL                      ; 3870  2b
        DEC     B                       ; 3871  05
        INC     C                       ; 3872  0c
        INC     D                       ; 3873  14
        JR      L383F                   ; 3874  18c9
L3876:
        CP      5                       ; 3876  fe05
        JR      nz,L38A5                ; 3878  202b
        INC     D                       ; 387A  14
        DEC     D                       ; 387B  15
        JR      z,L383F                 ; 387C  28c1
        LD      A,C                     ; 387E  79
        PUSH    BC                      ; 387F  c5
        PUSH    DE                      ; 3880  d5
        LD      B,0                     ; 3881  0600
        ADD     HL,BC                   ; 3883  09
        LD      D,H                     ; 3884  54
        LD      E,L                     ; 3885  5d
        DEC     HL                      ; 3886  2b
        LDDR                            ; 3887  edb8
        INC     HL                      ; 3889  23
        LD      (HL),20H                ; 388A  3620
        POP     DE                      ; 388C  d1
        CP      D                       ; 388D  ba
        JR      z,L3891                 ; 388E  2801
        INC     D                       ; 3890  14
L3891:
        LD      B,D                     ; 3891  42
L3892:
        LD      A,(HL)                  ; 3892  7e
        CALL    CONOUT                  ; 3893  cde836
        INC     HL                      ; 3896  23
        DJNZ    L3892                   ; 3897  10f9
        LD      B,D                     ; 3899  42
        LD      A,8                     ; 389A  3e08
L389C:
        CALL    CONOUT                  ; 389C  cde836
        DEC     HL                      ; 389F  2b
        DJNZ    L389C                   ; 38A0  10fa
        POP     BC                      ; 38A2  c1
L38A3:
        JR      L383F                   ; 38A3  189a
L38A5:
        CP      18H                     ; 38A5  fe18
        JR      nz,L38D2                ; 38A7  2029
        INC     D                       ; 38A9  14
        DEC     D                       ; 38AA  15
        JR      z,L383F                 ; 38AB  2892
        PUSH    BC                      ; 38AD  c5
        PUSH    DE                      ; 38AE  d5
        PUSH    HL                      ; 38AF  e5
        LD      B,0                     ; 38B0  0600
        LD      D,H                     ; 38B2  54
        LD      E,L                     ; 38B3  5d
        INC     HL                      ; 38B4  23
        LDIR                            ; 38B5  edb0
        DEC     HL                      ; 38B7  2b
        DEC     HL                      ; 38B8  2b
        LD      (HL),20H                ; 38B9  3620
        POP     HL                      ; 38BB  e1
        POP     DE                      ; 38BC  d1
        LD      B,D                     ; 38BD  42
L38BE:
        LD      A,(HL)                  ; 38BE  7e
        CALL    CONOUT                  ; 38BF  cde836
        INC     HL                      ; 38C2  23
        DJNZ    L38BE                   ; 38C3  10f9
        LD      B,D                     ; 38C5  42
        LD      A,8                     ; 38C6  3e08
L38C8:
        CALL    CONOUT                  ; 38C8  cde836
        DEC     HL                      ; 38CB  2b
        DJNZ    L38C8                   ; 38CC  10fa
        DEC     D                       ; 38CE  15
        POP     BC                      ; 38CF  c1
        JR      L38A3                   ; 38D0  18d1
L38D2:
        CP      1                       ; 38D2  fe01
        JR      nz,L38EA                ; 38D4  2014
        INC     B                       ; 38D6  04
        DEC     B                       ; 38D7  05
        JR      z,L38A3                 ; 38D8  28c9
        LD      A,8                     ; 38DA  3e08
        PUSH    BC                      ; 38DC  c5
L38DD:
        CALL    CONOUT                  ; 38DD  cde836
        DJNZ    L38DD                   ; 38E0  10fb
        POP     BC                      ; 38E2  c1
L38E3:
        DEC     HL                      ; 38E3  2b
        INC     D                       ; 38E4  14
        INC     C                       ; 38E5  0c
        DJNZ    L38E3                   ; 38E6  10fb
        JR      L38A3                   ; 38E8  18b9
L38EA:
        CP      6                       ; 38EA  fe06
        JR      nz,L3904                ; 38EC  2016
        INC     D                       ; 38EE  14
        DEC     D                       ; 38EF  15
        JR      z,L38A3                 ; 38F0  28b1
        PUSH    BC                      ; 38F2  c5
        LD      B,D                     ; 38F3  42
        LD      A,15H                   ; 38F4  3e15
L38F6:
        CALL    CONOUT                  ; 38F6  cde836
        DJNZ    L38F6                   ; 38F9  10fb
        POP     BC                      ; 38FB  c1
L38FC:
        INC     HL                      ; 38FC  23
        INC     B                       ; 38FD  04
        DEC     C                       ; 38FE  0d
        DEC     D                       ; 38FF  15
        JR      nz,L38FC                ; 3900  20fa
L3902:
        JR      L38A3                   ; 3902  189f
L3904:
        CP      13                      ; 3904  fe0d
        JR      nz,L3936                ; 3906  202e
        LD      E,D                     ; 3908  5a
        LD      D,0                     ; 3909  1600
        ADD     HL,DE                   ; 390B  19
        LD      D,E                     ; 390C  53
L390D:
        LD      (HL),1EH                ; 390D  361e
        LD      A,8                     ; 390F  3e08
        INC     B                       ; 3911  04
        DEC     B                       ; 3912  05
        JR      z,L391C                 ; 3913  2807
        PUSH    BC                      ; 3915  c5
L3916:
        CALL    CONOUT                  ; 3916  cde836
        DJNZ    L3916                   ; 3919  10fb
        POP     BC                      ; 391B  c1
L391C:
        LD      A,B                     ; 391C  78
        ADD     A,D                     ; 391D  82
        JR      z,L3931                 ; 391E  2811
        LD      B,A                     ; 3920  47
        LD      A,20H                   ; 3921  3e20
        PUSH    BC                      ; 3923  c5
L3924:
        CALL    CONOUT                  ; 3924  cde836
        DJNZ    L3924                   ; 3927  10fb
        LD      A,8                     ; 3929  3e08
        POP     BC                      ; 392B  c1
L392C:
        CALL    CONOUT                  ; 392C  cde836
        DJNZ    L392C                   ; 392F  10fb
L3931:
        POP     HL                      ; 3931  e1
        POP     DE                      ; 3932  d1
        POP     BC                      ; 3933  c1
        POP     AF                      ; 3934  f1
        RET                             ; 3935  c9
L3936:
        CP      3                       ; 3936  fe03
        JR      nz,L393C                ; 3938  2002
        JR      L390D                   ; 393A  18d1
L393C:
        CP      12H                     ; 393C  fe12
        JR      nz,L3950                ; 393E  2010
        PUSH    BC                      ; 3940  c5
        INC     B                       ; 3941  04
        DEC     B                       ; 3942  05
        JR      z,L3948                 ; 3943  2803
L3945:
        DEC     HL                      ; 3945  2b
        DJNZ    L3945                   ; 3946  10fd
L3948:
        LD      B,5                     ; 3948  0605
L394A:
        INC     HL                      ; 394A  23
        DJNZ    L394A                   ; 394B  10fd
        POP     BC                      ; 394D  c1
        JR      L390D                   ; 394E  18bd
L3950:
        CP      0                       ; 3950  fe00
        JR      L3902                   ; 3952  18ae
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ; 3954 ........
        DB      0FFH,0FFH,0FFH,0FFH     ; 395C ....

;=====================================================================
; DATEI-EIN/AUSGABE (LOAD, SAVE, OPEN, CLOSE, GET, PUT)
; FCB-Verwaltung und BDOS-Aufrufe 14H-16H, 0FH, 10H, 13H.
;=====================================================================
L3960:
        PUSH    IY                      ; 3960  fde5
        POP     HL                      ; 3962  e1
        CALL    L399A                   ; 3963  cd9a39
        EX      DE,HL                   ; 3966  eb
        LD      (HL),0                  ; 3967  3600
        INC     HL                      ; 3969  23
        LD      B,6                     ; 396A  0606
L396C:
        LD      A,(DE)                  ; 396C  1a
        LD      (HL),A                  ; 396D  77
        INC     DE                      ; 396E  13
        INC     HL                      ; 396F  23
        DJNZ    L396C                   ; 3970  10fa
        LD      (HL),20H                ; 3972  3620
        INC     HL                      ; 3974  23
        LD      (HL),20H                ; 3975  3620
        INC     HL                      ; 3977  23
        LD      (HL),47H                ; 3978  3647
        INC     HL                      ; 397A  23
        LD      (HL),42H                ; 397B  3642
        INC     HL                      ; 397D  23
        LD      (HL),41H                ; 397E  3641
        LD      B,18H                   ; 3980  0618
L3982:
        INC     HL                      ; 3982  23
        LD      (HL),0                  ; 3983  3600
        DJNZ    L3982                   ; 3985  10fb
        PUSH    IY                      ; 3987  fde5
        POP     HL                      ; 3989  e1
        LD      B,30H                   ; 398A  0630
L398C:
        INC     HL                      ; 398C  23
        DJNZ    L398C                   ; 398D  10fd
        LD      (IY+7),L                ; 398F  fd7507
        LD      (IY+8),H                ; 3992  fd7408
        LD      (IY+6),0                ; 3995  fd360600
        RET                             ; 3999  c9
L399A:
        PUSH    IY                      ; 399A  fde5
        POP     DE                      ; 399C  d1
        PUSH    BC                      ; 399D  c5
        LD      B,12                    ; 399E  060c
L39A0:
        INC     DE                      ; 39A0  13
        DJNZ    L39A0                   ; 39A1  10fd
        POP     BC                      ; 39A3  c1
        RET                             ; 39A4  c9
        CALL    L3960                   ; 39A5  cd6039
        CALL    L399A                   ; 39A8  cd9a39
        PUSH    IY                      ; 39AB  fde5
        PUSH    DE                      ; 39AD  d5
        LD      C,13H                   ; 39AE  0e13
        CALL    BDOS                    ; 39B0  cd0500  BDOS 19: Datei loeschen
        POP     DE                      ; 39B3  d1
        LD      C,16H                   ; 39B4  0e16
        CALL    BDOS                    ; 39B6  cd0500  BDOS 22: Datei anlegen
        CP      0FFH                    ; 39B9  feff
        POP     IY                      ; 39BB  fde1
        JR      z,L39C1                 ; 39BD  2802
        XOR     A                       ; 39BF  af
        RET                             ; 39C0  c9
L39C1:
        LD      B,6FH                   ; 39C1  066f
        SCF                             ; 39C3  37
        RET                             ; 39C4  c9
        XOR     A                       ; 39C5  af
        CP      (IY+6)                  ; 39C6  fdbe06
        CALL    nz,L39F7                ; 39C9  c4f739
        RET     c                       ; 39CC  d8
        PUSH    IY                      ; 39CD  fde5
        CALL    L399A                   ; 39CF  cd9a39
        LD      C,10H                   ; 39D2  0e10
        CALL    BDOS                    ; 39D4  cd0500  BDOS 16: Datei schliessen
        POP     IY                      ; 39D7  fde1
        AND     0FCH                    ; 39D9  e6fc
        JR      nz,L39C1                ; 39DB  20e4
        XOR     A                       ; 39DD  af
        RET                             ; 39DE  c9
L39DF:
        LD      L,(IY+7)                ; 39DF  fd6e07
        LD      H,(IY+8)                ; 39E2  fd6608
        LD      (HL),A                  ; 39E5  77
        INC     HL                      ; 39E6  23
        LD      (IY+7),L                ; 39E7  fd7507
        LD      (IY+8),H                ; 39EA  fd7408
        INC     (IY+6)                  ; 39ED  fd3406
        LD      A,80H                   ; 39F0  3e80
        CP      (IY+6)                  ; 39F2  fdbe06
        JR      nz,L3A2D                ; 39F5  2036
L39F7:
        PUSH    IY                      ; 39F7  fde5
        POP     HL                      ; 39F9  e1
        LD      B,30H                   ; 39FA  0630
L39FC:
        INC     HL                      ; 39FC  23
        DJNZ    L39FC                   ; 39FD  10fd
        LD      DE,80H                  ; 39FF  118000
        LD      BC,80H                  ; 3A02  018000
        LDIR                            ; 3A05  edb0
        CALL    L399A                   ; 3A07  cd9a39
        PUSH    IY                      ; 3A0A  fde5
        LD      C,15H                   ; 3A0C  0e15
        CALL    BDOS                    ; 3A0E  cd0500  BDOS 21: Satz schreiben
        POP     IY                      ; 3A11  fde1
        CP      0                       ; 3A13  fe00
        JR      z,L3A1B                 ; 3A15  2804
        LD      B,6FH                   ; 3A17  066f
        SCF                             ; 3A19  37
        RET                             ; 3A1A  c9
L3A1B:
        PUSH    IY                      ; 3A1B  fde5
        POP     HL                      ; 3A1D  e1
        LD      B,30H                   ; 3A1E  0630
L3A20:
        INC     HL                      ; 3A20  23
        DJNZ    L3A20                   ; 3A21  10fd
        LD      (IY+7),L                ; 3A23  fd7507
        LD      (IY+8),H                ; 3A26  fd7408
        LD      (IY+6),0                ; 3A29  fd360600
L3A2D:
        XOR     A                       ; 3A2D  af
        RET                             ; 3A2E  c9
        CALL    L3960                   ; 3A2F  cd6039
        CALL    L399A                   ; 3A32  cd9a39
        PUSH    IY                      ; 3A35  fde5
        PUSH    DE                      ; 3A37  d5
        LD      C,15                    ; 3A38  0e0f
        CALL    BDOS                    ; 3A3A  cd0500
        POP     DE                      ; 3A3D  d1
        POP     IY                      ; 3A3E  fde1
        INC     A                       ; 3A40  3c
        JR      nz,L3A47                ; 3A41  2004
        LD      B,71H                   ; 3A43  0671
        SCF                             ; 3A45  37
        RET                             ; 3A46  c9
L3A47:
        XOR     A                       ; 3A47  af
        RET                             ; 3A48  c9
        XOR     A                       ; 3A49  af
        RET                             ; 3A4A  c9
L3A4B:
        LD      A,(IY+6)                ; 3A4B  fd7e06
        OR      A                       ; 3A4E  b7
        JR      nz,L3A81                ; 3A4F  2030
        CALL    L399A                   ; 3A51  cd9a39
        PUSH    DE                      ; 3A54  d5
        PUSH    IY                      ; 3A55  fde5
        LD      C,14H                   ; 3A57  0e14
        CALL    BDOS                    ; 3A59  cd0500  BDOS 20: Satz lesen
        POP     IY                      ; 3A5C  fde1
        POP     DE                      ; 3A5E  d1
        OR      A                       ; 3A5F  b7
        JR      z,L3A66                 ; 3A60  2804
        LD      B,70H                   ; 3A62  0670
        SCF                             ; 3A64  37
        RET                             ; 3A65  c9
L3A66:
        PUSH    IY                      ; 3A66  fde5
        POP     HL                      ; 3A68  e1
        LD      B,30H                   ; 3A69  0630
L3A6B:
        INC     HL                      ; 3A6B  23
        DJNZ    L3A6B                   ; 3A6C  10fd
        LD      (IY+7),L                ; 3A6E  fd7507
        LD      (IY+8),H                ; 3A71  fd7408
        LD      (IY+6),80H              ; 3A74  fd360680
        LD      BC,80H                  ; 3A78  018000
        LD      DE,80H                  ; 3A7B  118000
        EX      DE,HL                   ; 3A7E  eb
        LDIR                            ; 3A7F  edb0
L3A81:
        DEC     (IY+6)                  ; 3A81  fd3506
        LD      L,(IY+7)                ; 3A84  fd6e07
        LD      H,(IY+8)                ; 3A87  fd6608
        XOR     A                       ; 3A8A  af
        LD      A,(HL)                  ; 3A8B  7e
        INC     HL                      ; 3A8C  23
        LD      (IY+7),L                ; 3A8D  fd7507
        LD      (IY+8),H                ; 3A90  fd7408
        RET                             ; 3A93  c9
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ; 3A94 ........
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ; 3A9C ........
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ; 3AA4 ........
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ; 3AAC ........
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ; 3AB4 ........
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ; 3ABC ........
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ; 3AC4 ........
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ; 3ACC ........
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ; 3AD4 ........
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ; 3ADC ........
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ; 3AE4 ........
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ; 3AEC ........
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ; 3AF4 ........
        DB      0FFH,0FFH,0FFH,0FFH     ; 3AFC ....

;=====================================================================
; GRAFIKMODUL (1986 hinzugefuegt)
; 256 x 128 Punkte, 1 Bit/Punkt, Bildspeicher 9000H-9FFFH,
; 32 Byte pro Zeile, Ursprung unten links, Bit7 = linker Punkt.
; Der Video-RAM liegt im Adressraum des normalen RAM und wird ueber
; Port 08H eingeblendet (Bit7=0) und wieder ausgeblendet (Bit7=1).
; Variablen: X1,Y1,X2,Y2 (je 16 Bit, genutzt wird Low-Byte)
;=====================================================================
GX1:
        DB      00H,00H                 ; 3B00 ..
GY1:
        DB      00H,00H                 ; 3B02 ..
GX2:
        DB      00H,00H                 ; 3B04 ..
GY2:
        DB      00H,00H,41H,00H,60H,13H,00H,00H ; 3B06 ..A.`...
        DB      00H,00H,00H,00H,00H,00H,00H,00H ; 3B0E ........
        DB      00H,00H,00H,00H,00H,00H,00H,00H ; 3B16 ........
        DB      00H,00H                 ; 3B1E ..
; ---- DOT: B=1 setzen
G_DOT:
        LD      B,1                     ; 3B20  0601
        JR      G_PIXEL                 ; 3B22  1802
; ---- CDOT: B=0 loeschen
G_CDOT:
        LD      B,0                     ; 3B24  0600
; ---- Adresse = 9000H + (127-y)*32 + x/8, Maske = 80H>>(x AND 7)
G_PIXEL:
        LD      HL,9000H                ; 3B26  210090
        LD      A,(GY1)                 ; 3B29  3a023b
        CPL                             ; 3B2C  2f
        RES     7,A                     ; 3B2D  cbbf
        LD      D,0                     ; 3B2F  1600
        LD      E,A                     ; 3B31  5f
        SLA     E                       ; 3B32  cb23
        SLA     E                       ; 3B34  cb23
        JR      nc,L3B39                ; 3B36  3001
        INC     D                       ; 3B38  14
L3B39:
        SLA     D                       ; 3B39  cb22
        SLA     E                       ; 3B3B  cb23
        JR      nc,L3B40                ; 3B3D  3001
        INC     D                       ; 3B3F  14
L3B40:
        SLA     D                       ; 3B40  cb22
        SLA     E                       ; 3B42  cb23
        JR      nc,L3B47                ; 3B44  3001
        INC     D                       ; 3B46  14
L3B47:
        SLA     D                       ; 3B47  cb22
        SLA     E                       ; 3B49  cb23
        JR      nc,L3B4E                ; 3B4B  3001
        INC     D                       ; 3B4D  14
L3B4E:
        ADD     HL,DE                   ; 3B4E  19
        LD      A,(GX1)                 ; 3B4F  3a003b
        LD      D,0                     ; 3B52  1600
        LD      E,A                     ; 3B54  5f
        SRL     E                       ; 3B55  cb3b
        SRL     E                       ; 3B57  cb3b
        SRL     E                       ; 3B59  cb3b
        ADD     HL,DE                   ; 3B5B  19
        AND     7                       ; 3B5C  e607
        ADD     A,0                     ; 3B5E  c600
        LD      E,A                     ; 3B60  5f
        LD      A,80H                   ; 3B61  3e80
        JR      z,G_VRAM_ON             ; 3B63  2804
L3B65:
        RRCA                            ; 3B65  0f
        DEC     E                       ; 3B66  1d
        JR      nz,L3B65                ; 3B67  20fc
; ---- Video-RAM einblenden: OUT (08H),00H, Interrupts gesperrt
G_VRAM_ON:
        BIT     0,B                     ; 3B69  cb40
        DI                              ; 3B6B  f3
        EX      AF,AF'                  ; 3B6C  08
        XOR     A                       ; 3B6D  af
        OUT     (GPORT),A               ; 3B6E  d308  Bildspeicher umschalten
        EX      AF,AF'                  ; 3B70  08
        JR      z,L3B7E                 ; 3B71  280b
        OR      (HL)                    ; 3B73  b6
L3B74:
        LD      (HL),A                  ; 3B74  77
        EX      AF,AF'                  ; 3B75  08
; ---- Video-RAM ausblenden: OUT (08H),80H
G_VRAM_OFF:
        LD      A,80H                   ; 3B76  3e80
        OUT     (GPORT),A               ; 3B78  d308  Bildspeicher umschalten
        EX      AF,AF'                  ; 3B7A  08
        EI                              ; 3B7B  fb
        XOR     A                       ; 3B7C  af
        RET                             ; 3B7D  c9
L3B7E:
        CPL                             ; 3B7E  2f
        AND     (HL)                    ; 3B7F  a6
        JR      L3B74                   ; 3B80  18f2
; ---- TEST: Bit des Punktes nach Carry holen
G_TEST:
        LD      HL,9000H                ; 3B82  210090
        LD      A,(GY1)                 ; 3B85  3a023b
        CPL                             ; 3B88  2f
        RES     7,A                     ; 3B89  cbbf
        LD      D,0                     ; 3B8B  1600
        LD      E,A                     ; 3B8D  5f
        SLA     E                       ; 3B8E  cb23
        SLA     E                       ; 3B90  cb23
        JR      nc,L3B95                ; 3B92  3001
        INC     D                       ; 3B94  14
L3B95:
        SLA     D                       ; 3B95  cb22
        SLA     E                       ; 3B97  cb23
        JR      nc,L3B9C                ; 3B99  3001
        INC     D                       ; 3B9B  14
L3B9C:
        SLA     D                       ; 3B9C  cb22
        SLA     E                       ; 3B9E  cb23
        JR      nc,L3BA3                ; 3BA0  3001
        INC     D                       ; 3BA2  14
L3BA3:
        SLA     D                       ; 3BA3  cb22
        SLA     E                       ; 3BA5  cb23
        JR      nc,L3BAA                ; 3BA7  3001
        INC     D                       ; 3BA9  14
L3BAA:
        ADD     HL,DE                   ; 3BAA  19
        LD      A,(GX1)                 ; 3BAB  3a003b
        LD      D,0                     ; 3BAE  1600
        LD      E,A                     ; 3BB0  5f
        SRL     E                       ; 3BB1  cb3b
        SRL     E                       ; 3BB3  cb3b
        SRL     E                       ; 3BB5  cb3b
        ADD     HL,DE                   ; 3BB7  19
        AND     7                       ; 3BB8  e607
        LD      E,A                     ; 3BBA  5f
        LD      E,A                     ; 3BBB  5f
        INC     E                       ; 3BBC  1c
        DI                              ; 3BBD  f3
        EX      AF,AF'                  ; 3BBE  08
        XOR     A                       ; 3BBF  af
        OUT     (GPORT),A               ; 3BC0  d308  Bildspeicher umschalten
        EX      AF,AF'                  ; 3BC2  08
        LD      A,(HL)                  ; 3BC3  7e
        EX      AF,AF'                  ; 3BC4  08
        LD      A,80H                   ; 3BC5  3e80
        OUT     (GPORT),A               ; 3BC7  d308  Bildspeicher umschalten
        EX      AF,AF'                  ; 3BC9  08
        EI                              ; 3BCA  fb
L3BCB:
        RLC     A                       ; 3BCB  cb07
        DEC     E                       ; 3BCD  1d
        JR      nz,L3BCB                ; 3BCE  20fb
        RET                             ; 3BD0  c9
; ---- FILL: Rechteck zeilenweise mit Byte-Masken fuellen (C=1 setzen)
G_FILL:
        LD      C,1                     ; 3BD1  0e01
        JR      L3BD7                   ; 3BD3  1802
; ---- CFILL (kein Schluesselwort): C=0 loeschen
G_CFILL:
        LD      C,0                     ; 3BD5  0e00
L3BD7:
        PUSH    BC                      ; 3BD7  c5
        LD      A,(GY1)                 ; 3BD8  3a023b
        RES     7,A                     ; 3BDB  cbbf
        LD      L,A                     ; 3BDD  6f
        LD      A,(GY2)                 ; 3BDE  3a063b
        RES     7,A                     ; 3BE1  cbbf
        LD      H,A                     ; 3BE3  67
        SUB     L                       ; 3BE4  95
        LD      E,H                     ; 3BE5  5c
        JR      nc,L3BEB                ; 3BE6  3003
        LD      E,L                     ; 3BE8  5d
        NEG                             ; 3BE9  ed44
L3BEB:
        LD      C,A                     ; 3BEB  4f
        INC     C                       ; 3BEC  0c
        LD      A,(GX1)                 ; 3BED  3a003b
        LD      L,A                     ; 3BF0  6f
        LD      A,(GX2)                 ; 3BF1  3a043b
        LD      H,A                     ; 3BF4  67
        SUB     L                       ; 3BF5  95
        LD      D,L                     ; 3BF6  55
        JR      nc,L3BFC                ; 3BF7  3003
        LD      D,H                     ; 3BF9  54
        NEG                             ; 3BFA  ed44
L3BFC:
        LD      B,A                     ; 3BFC  47
        INC     B                       ; 3BFD  04
        JR      nz,L3C08                ; 3BFE  2008
        LD      H,0FFH                  ; 3C00  26ff
        LD      B,1EH                   ; 3C02  061e
        LD      L,0FFH                  ; 3C04  2eff
        JR      L3C47                   ; 3C06  183f
L3C08:
        LD      A,D                     ; 3C08  7a
        AND     7                       ; 3C09  e607
        LD      H,0FFH                  ; 3C0B  26ff
        JR      z,L3C14                 ; 3C0D  2805
L3C0F:
        SRL     H                       ; 3C0F  cb3c
        DEC     A                       ; 3C11  3d
        JR      nz,L3C0F                ; 3C12  20fb
L3C14:
        LD      A,D                     ; 3C14  7a
        OR      0F8H                    ; 3C15  f6f8
        NEG                             ; 3C17  ed44
        LD      L,A                     ; 3C19  6f
        LD      A,B                     ; 3C1A  78
        SUB     L                       ; 3C1B  95
        JR      nc,L3C30                ; 3C1C  3012
        NEG                             ; 3C1E  ed44
        LD      B,A                     ; 3C20  47
        LD      A,0FFH                  ; 3C21  3eff
L3C23:
        SLA     A                       ; 3C23  cb27
        DEC     B                       ; 3C25  05
        JR      nz,L3C23                ; 3C26  20fb
        AND     H                       ; 3C28  a4
        LD      H,A                     ; 3C29  67
        LD      B,0                     ; 3C2A  0600
        LD      L,0                     ; 3C2C  2e00
        JR      L3C47                   ; 3C2E  1817
L3C30:
        LD      L,A                     ; 3C30  6f
        SRL     A                       ; 3C31  cb3f
        SRL     A                       ; 3C33  cb3f
        SRL     A                       ; 3C35  cb3f
        LD      B,A                     ; 3C37  47
        LD      A,L                     ; 3C38  7d
        AND     7                       ; 3C39  e607
        LD      L,A                     ; 3C3B  6f
        LD      A,0FFH                  ; 3C3C  3eff
        JR      z,L3C45                 ; 3C3E  2805
L3C40:
        SRL     A                       ; 3C40  cb3f
        DEC     L                       ; 3C42  2d
        JR      nz,L3C40                ; 3C43  20fb
L3C45:
        CPL                             ; 3C45  2f
        LD      L,A                     ; 3C46  6f
L3C47:
        PUSH    BC                      ; 3C47  c5
        PUSH    HL                      ; 3C48  e5
        LD      HL,9000H                ; 3C49  210090
        LD      A,E                     ; 3C4C  7b
        CPL                             ; 3C4D  2f
        RES     7,A                     ; 3C4E  cbbf
        LD      B,0                     ; 3C50  0600
        LD      C,A                     ; 3C52  4f
        SLA     C                       ; 3C53  cb21
        SLA     C                       ; 3C55  cb21
        JR      nc,L3C5A                ; 3C57  3001
        INC     B                       ; 3C59  04
L3C5A:
        SLA     B                       ; 3C5A  cb20
        SLA     C                       ; 3C5C  cb21
        JR      nc,L3C61                ; 3C5E  3001
        INC     B                       ; 3C60  04
L3C61:
        SLA     B                       ; 3C61  cb20
        SLA     C                       ; 3C63  cb21
        JR      nc,L3C68                ; 3C65  3001
        INC     B                       ; 3C67  04
L3C68:
        SLA     B                       ; 3C68  cb20
        SLA     C                       ; 3C6A  cb21
        JR      nc,L3C6F                ; 3C6C  3001
        INC     B                       ; 3C6E  04
L3C6F:
        ADD     HL,BC                   ; 3C6F  09
        LD      B,0                     ; 3C70  0600
        LD      C,D                     ; 3C72  4a
        SRL     C                       ; 3C73  cb39
        SRL     C                       ; 3C75  cb39
        SRL     C                       ; 3C77  cb39
        ADD     HL,BC                   ; 3C79  09
        POP     DE                      ; 3C7A  d1
        POP     BC                      ; 3C7B  c1
        POP     AF                      ; 3C7C  f1
        PUSH    HL                      ; 3C7D  e5
        JR      nc,L3CAD                ; 3C7E  302d
L3C80:
        DI                              ; 3C80  f3
        EX      AF,AF'                  ; 3C81  08
        XOR     A                       ; 3C82  af
        OUT     (GPORT),A               ; 3C83  d308  Bildspeicher umschalten
        EX      AF,AF'                  ; 3C85  08
        LD      A,(HL)                  ; 3C86  7e
        OR      D                       ; 3C87  b2
        LD      (HL),A                  ; 3C88  77
        LD      A,B                     ; 3C89  78
        ADD     A,0                     ; 3C8A  c600
        JR      z,L3C94                 ; 3C8C  2806
L3C8E:
        INC     HL                      ; 3C8E  23
        LD      (HL),0FFH               ; 3C8F  36ff
        DEC     A                       ; 3C91  3d
        JR      nz,L3C8E                ; 3C92  20fa
L3C94:
        INC     HL                      ; 3C94  23
        LD      A,(HL)                  ; 3C95  7e
        OR      E                       ; 3C96  b3
        LD      (HL),A                  ; 3C97  77
        EX      AF,AF'                  ; 3C98  08
        LD      A,80H                   ; 3C99  3e80
        OUT     (GPORT),A               ; 3C9B  d308  Bildspeicher umschalten
        EX      AF,AF'                  ; 3C9D  08
        EI                              ; 3C9E  fb
        POP     HL                      ; 3C9F  e1
        LD      A,L                     ; 3CA0  7d
        ADD     A,20H                   ; 3CA1  c620
        LD      L,A                     ; 3CA3  6f
        JR      nc,L3CA7                ; 3CA4  3001
        INC     H                       ; 3CA6  24
L3CA7:
        PUSH    HL                      ; 3CA7  e5
        DEC     C                       ; 3CA8  0d
        JR      nz,L3C80                ; 3CA9  20d5
        JR      L3CDF                   ; 3CAB  1832
L3CAD:
        LD      A,D                     ; 3CAD  7a
        CPL                             ; 3CAE  2f
        LD      D,A                     ; 3CAF  57
        LD      A,E                     ; 3CB0  7b
        CPL                             ; 3CB1  2f
        LD      E,A                     ; 3CB2  5f
L3CB3:
        DI                              ; 3CB3  f3
        EX      AF,AF'                  ; 3CB4  08
        XOR     A                       ; 3CB5  af
        OUT     (GPORT),A               ; 3CB6  d308  Bildspeicher umschalten
        EX      AF,AF'                  ; 3CB8  08
        LD      A,(HL)                  ; 3CB9  7e
        AND     D                       ; 3CBA  a2
        LD      (HL),A                  ; 3CBB  77
        LD      A,B                     ; 3CBC  78
        ADD     A,0                     ; 3CBD  c600
        JR      z,L3CC8                 ; 3CBF  2807
L3CC1:
        INC     HL                      ; 3CC1  23
        LD      (HL),0                  ; 3CC2  3600
        DEC     A                       ; 3CC4  3d
        JR      nz,L3CC1                ; 3CC5  20fa
        DEC     A                       ; 3CC7  3d
L3CC8:
        INC     HL                      ; 3CC8  23
        LD      A,(HL)                  ; 3CC9  7e
        AND     E                       ; 3CCA  a3
        LD      (HL),A                  ; 3CCB  77
        EX      AF,AF'                  ; 3CCC  08
        LD      A,80H                   ; 3CCD  3e80
        OUT     (GPORT),A               ; 3CCF  d308  Bildspeicher umschalten
        EX      AF,AF'                  ; 3CD1  08
        EI                              ; 3CD2  fb
        POP     HL                      ; 3CD3  e1
        LD      A,L                     ; 3CD4  7d
        ADD     A,20H                   ; 3CD5  c620
        LD      L,A                     ; 3CD7  6f
        JR      nc,L3CDB                ; 3CD8  3001
        INC     H                       ; 3CDA  24
L3CDB:
        PUSH    HL                      ; 3CDB  e5
        DEC     C                       ; 3CDC  0d
        JR      nz,L3CB3                ; 3CDD  20d4
L3CDF:
        POP     HL                      ; 3CDF  e1
        XOR     A                       ; 3CE0  af
        RET                             ; 3CE1  c9
; ---- LINE: B=1 setzen
G_LINE:
        LD      B,1                     ; 3CE2  0601
        JR      G_DDA                   ; 3CE4  1802
; ---- CLINE: B=0 loeschen
G_CLINE:
        LD      B,0                     ; 3CE6  0600

;=====================================================================
; DDA-Algorithmus: Steigung als 8.8-Festkomma durch fortgesetzte
; Subtraktion; gelaufen wird entlang der laengeren Achse.
;=====================================================================
G_DDA:
        LD      A,(GX1)                 ; 3CE8  3a003b
        LD      E,A                     ; 3CEB  5f
        LD      A,(GY1)                 ; 3CEC  3a023b
        LD      D,A                     ; 3CEF  57
        LD      A,(GX2)                 ; 3CF0  3a043b
        LD      L,A                     ; 3CF3  6f
        LD      A,(GY2)                 ; 3CF4  3a063b
        LD      H,A                     ; 3CF7  67
        RES     7,D                     ; 3CF8  cbba
        RES     7,H                     ; 3CFA  cbbc
        LD      A,E                     ; 3CFC  7b
        SUB     L                       ; 3CFD  95
        JR      c,L3D01                 ; 3CFE  3801
        EX      DE,HL                   ; 3D00  eb
L3D01:
        LD      A,D                     ; 3D01  7a
        SUB     H                       ; 3D02  94
        JR      nc,L3D09                ; 3D03  3004
        SET     1,B                     ; 3D05  cbc8
        NEG                             ; 3D07  ed44
L3D09:
        INC     A                       ; 3D09  3c
        LD      C,A                     ; 3D0A  4f
        LD      A,L                     ; 3D0B  7d
        SUB     E                       ; 3D0C  93
        INC     A                       ; 3D0D  3c
        JR      z,L3D18                 ; 3D0E  2808
        CP      C                       ; 3D10  b9
        JR      nc,L3D18                ; 3D11  3005
        SET     2,B                     ; 3D13  cbd0
        LD      H,A                     ; 3D15  67
        LD      A,C                     ; 3D16  79
        LD      C,H                     ; 3D17  4c
L3D18:
        PUSH    DE                      ; 3D18  d5
        PUSH    BC                      ; 3D19  c5
        LD      B,0                     ; 3D1A  0600
        LD      D,0                     ; 3D1C  1600
        LD      L,0                     ; 3D1E  2e00
        LD      E,0FFH                  ; 3D20  1eff
        SUB     C                       ; 3D22  91
L3D23:
        SUB     C                       ; 3D23  91
        INC     D                       ; 3D24  14
        JR      nc,L3D23                ; 3D25  30fc
        ADD     A,C                     ; 3D27  81
        LD      H,A                     ; 3D28  67
        ADD     A,0                     ; 3D29  c600
L3D2B:
        SBC     HL,BC                   ; 3D2B  ed42
        INC     E                       ; 3D2D  1c
        JR      nc,L3D2B                ; 3D2E  30fb
        LD      H,D                     ; 3D30  62
        LD      L,E                     ; 3D31  6b
        POP     BC                      ; 3D32  c1
        EXX                             ; 3D33  d9
        POP     BC                      ; 3D34  c1
        EXX                             ; 3D35  d9
        LD      A,80H                   ; 3D36  3e80
        ADD     A,L                     ; 3D38  85
        LD      L,A                     ; 3D39  6f
        JR      nc,L3D3D                ; 3D3A  3001
        INC     H                       ; 3D3C  24
L3D3D:
        BIT     1,B                     ; 3D3D  cb48
        JR      z,L3D6B                 ; 3D3F  282a
        BIT     2,B                     ; 3D41  cb50
        JR      nz,L3D5D                ; 3D43  2018
        JR      L3D4B                   ; 3D45  1804
L3D47:
        ADD     HL,DE                   ; 3D47  19
        EXX                             ; 3D48  d9
        INC     B                       ; 3D49  04
        EXX                             ; 3D4A  d9
L3D4B:
        EXX                             ; 3D4B  d9
        CALL    G_PIXEL_EXX             ; 3D4C  cd953d
        INC     C                       ; 3D4F  0c
        EXX                             ; 3D50  d9
        DEC     H                       ; 3D51  25
        JR      nz,L3D4B                ; 3D52  20f7
        DEC     C                       ; 3D54  0d
        JR      nz,L3D47                ; 3D55  20f0
        JR      L3D94                   ; 3D57  183b
L3D59:
        ADD     HL,DE                   ; 3D59  19
        EXX                             ; 3D5A  d9
        INC     C                       ; 3D5B  0c
        EXX                             ; 3D5C  d9
L3D5D:
        EXX                             ; 3D5D  d9
        CALL    G_PIXEL_EXX             ; 3D5E  cd953d
        INC     B                       ; 3D61  04
        EXX                             ; 3D62  d9
        DEC     H                       ; 3D63  25
        JR      nz,L3D5D                ; 3D64  20f7
        DEC     C                       ; 3D66  0d
        JR      nz,L3D59                ; 3D67  20f0
        JR      L3D94                   ; 3D69  1829
L3D6B:
        BIT     2,B                     ; 3D6B  cb50
        JR      nz,L3D87                ; 3D6D  2018
        JR      L3D75                   ; 3D6F  1804
L3D71:
        ADD     HL,DE                   ; 3D71  19
        EXX                             ; 3D72  d9
        DEC     B                       ; 3D73  05
        EXX                             ; 3D74  d9
L3D75:
        EXX                             ; 3D75  d9
        CALL    G_PIXEL_EXX             ; 3D76  cd953d
        INC     C                       ; 3D79  0c
        EXX                             ; 3D7A  d9
        DEC     H                       ; 3D7B  25
        JR      nz,L3D75                ; 3D7C  20f7
        DEC     C                       ; 3D7E  0d
        JR      nz,L3D71                ; 3D7F  20f0
        JR      L3D94                   ; 3D81  1811
L3D83:
        ADD     HL,DE                   ; 3D83  19
        EXX                             ; 3D84  d9
        INC     C                       ; 3D85  0c
        EXX                             ; 3D86  d9
L3D87:
        EXX                             ; 3D87  d9
        CALL    G_PIXEL_EXX             ; 3D88  cd953d
        DEC     B                       ; 3D8B  05
        EXX                             ; 3D8C  d9
        DEC     H                       ; 3D8D  25
        JR      nz,L3D87                ; 3D8E  20f7
        DEC     C                       ; 3D90  0d
        JR      nz,L3D83                ; 3D91  20f0
        XOR     A                       ; 3D93  af
L3D94:
        RET                             ; 3D94  c9
; ---- Einzelpunkt fuer LINE (x in C', y in B')
G_PIXEL_EXX:
        LD      HL,9000H                ; 3D95  210090
        LD      A,B                     ; 3D98  78
        CPL                             ; 3D99  2f
        RES     7,A                     ; 3D9A  cbbf
        LD      D,0                     ; 3D9C  1600
        LD      E,A                     ; 3D9E  5f
        SLA     E                       ; 3D9F  cb23
        SLA     E                       ; 3DA1  cb23
        JR      nc,L3DA6                ; 3DA3  3001
        INC     D                       ; 3DA5  14
L3DA6:
        SLA     D                       ; 3DA6  cb22
        SLA     E                       ; 3DA8  cb23
        JR      nc,L3DAD                ; 3DAA  3001
        INC     D                       ; 3DAC  14
L3DAD:
        SLA     D                       ; 3DAD  cb22
        SLA     E                       ; 3DAF  cb23
        JR      nc,L3DB4                ; 3DB1  3001
        INC     D                       ; 3DB3  14
L3DB4:
        SLA     D                       ; 3DB4  cb22
        SLA     E                       ; 3DB6  cb23
        JR      nc,L3DBB                ; 3DB8  3001
        INC     D                       ; 3DBA  14
L3DBB:
        ADD     HL,DE                   ; 3DBB  19
        LD      D,0                     ; 3DBC  1600
        LD      E,C                     ; 3DBE  59
        SRL     E                       ; 3DBF  cb3b
        SRL     E                       ; 3DC1  cb3b
        SRL     E                       ; 3DC3  cb3b
        ADD     HL,DE                   ; 3DC5  19
        LD      A,C                     ; 3DC6  79
        AND     7                       ; 3DC7  e607
        ADD     A,0                     ; 3DC9  c600
        LD      E,A                     ; 3DCB  5f
        LD      A,80H                   ; 3DCC  3e80
        JR      z,L3DD4                 ; 3DCE  2804
L3DD0:
        RRCA                            ; 3DD0  0f
        DEC     E                       ; 3DD1  1d
        JR      nz,L3DD0                ; 3DD2  20fc
L3DD4:
        EXX                             ; 3DD4  d9
        BIT     0,B                     ; 3DD5  cb40
        EXX                             ; 3DD7  d9
        DI                              ; 3DD8  f3
        EX      AF,AF'                  ; 3DD9  08
        XOR     A                       ; 3DDA  af
        OUT     (GPORT),A               ; 3DDB  d308  Bildspeicher umschalten
        EX      AF,AF'                  ; 3DDD  08
        JR      z,L3DE4                 ; 3DDE  2804
        OR      (HL)                    ; 3DE0  b6
        LD      (HL),A                  ; 3DE1  77
        JR      L3DE7                   ; 3DE2  1803
L3DE4:
        CPL                             ; 3DE4  2f
        AND     (HL)                    ; 3DE5  a6
        LD      (HL),A                  ; 3DE6  77
L3DE7:
        EX      AF,AF'                  ; 3DE7  08
        LD      A,80H                   ; 3DE8  3e80
        OUT     (GPORT),A               ; 3DEA  d308  Bildspeicher umschalten
        EX      AF,AF'                  ; 3DEC  08
        EI                              ; 3DED  fb
        RET                             ; 3DEE  c9
; ---- OFF (Unterfunktion 2): 9000H-9FFFH=0, 8000H-81FFH=0, 8200H-83FFH=27H
G_CLEAR:
        LD      D,0                     ; 3DEF  1600
        LD      BC,1000H                ; 3DF1  010010
        LD      HL,9000H                ; 3DF4  210090
        DI                              ; 3DF7  f3
        EX      AF,AF'                  ; 3DF8  08
        XOR     A                       ; 3DF9  af
        OUT     (GPORT),A               ; 3DFA  d308  Bildspeicher umschalten
        EX      AF,AF'                  ; 3DFC  08
L3DFD:
        LD      (HL),D                  ; 3DFD  72
        INC     HL                      ; 3DFE  23
        DEC     BC                      ; 3DFF  0b
        LD      A,B                     ; 3E00  78
        OR      C                       ; 3E01  b1
        JR      nz,L3DFD                ; 3E02  20f9
        LD      HL,8000H                ; 3E04  210080
        LD      D,0                     ; 3E07  1600
        LD      BC,0200H                ; 3E09  010002
L3E0C:
        LD      (HL),D                  ; 3E0C  72
        INC     HL                      ; 3E0D  23
        DEC     BC                      ; 3E0E  0b
        LD      A,B                     ; 3E0F  78
        OR      C                       ; 3E10  b1
        JR      nz,L3E0C                ; 3E11  20f9
        LD      D,27H                   ; 3E13  1627
        LD      BC,0200H                ; 3E15  010002
L3E18:
        LD      (HL),D                  ; 3E18  72
        INC     HL                      ; 3E19  23
        DEC     BC                      ; 3E1A  0b
        LD      A,B                     ; 3E1B  78
        OR      C                       ; 3E1C  b1
        JR      nz,L3E18                ; 3E1D  20f9
        EX      AF,AF'                  ; 3E1F  08
        LD      A,80H                   ; 3E20  3e80
        OUT     (GPORT),A               ; 3E22  d308  Bildspeicher umschalten
        EX      AF,AF'                  ; 3E24  08
        EI                              ; 3E25  fb
        XOR     A                       ; 3E26  af
        RET                             ; 3E27  c9

;=====================================================================
; ENDE DES CODES
; Ab 4000H folgt das mitgespeicherte Abbild des Arbeitsspeichers
; (Variablen, Puffer, Kanalbloecke). Es wird beim Start ueberschrieben.
;=====================================================================
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ; 3E28 ........
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ; 3E30 ........
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ; 3E38 ........
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ; 3E40 ........
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ; 3E48 ........
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ; 3E50 ........
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ; 3E58 ........
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ; 3E60 ........
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ; 3E68 ........
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ; 3E70 ........
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ; 3E78 ........
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ; 3E80 ........
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ; 3E88 ........
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ; 3E90 ........
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ; 3E98 ........
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ; 3EA0 ........
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ; 3EA8 ........
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ; 3EB0 ........
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ; 3EB8 ........
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ; 3EC0 ........
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ; 3EC8 ........
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ; 3ED0 ........
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ; 3ED8 ........
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ; 3EE0 ........
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ; 3EE8 ........
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ; 3EF0 ........
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ; 3EF8 ........
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ; 3F00 ........
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ; 3F08 ........
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ; 3F10 ........
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ; 3F18 ........
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ; 3F20 ........
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ; 3F28 ........
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ; 3F30 ........
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ; 3F38 ........
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ; 3F40 ........
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ; 3F48 ........
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ; 3F50 ........
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ; 3F58 ........
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ; 3F60 ........
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ; 3F68 ........
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ; 3F70 ........
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ; 3F78 ........
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ; 3F80 ........
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ; 3F88 ........
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ; 3F90 ........
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ; 3F98 ........
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ; 3FA0 ........
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ; 3FA8 ........
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ; 3FB0 ........
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ; 3FB8 ........
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ; 3FC0 ........
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ; 3FC8 ........
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ; 3FD0 ........
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ; 3FD8 ........
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ; 3FE0 ........
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ; 3FE8 ........
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ; 3FF0 ........
        DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ; 3FF8 ........
        DB      00H,00H,00H,1EH,59H,45H,00H,00H ; 4000 ....YE..
        DB      23H,23H,23H,23H,23H,23H,23H,23H ; 4008 ########
        DB      23H,23H,23H,23H,23H,23H,23H,23H ; 4010 ########
        DB      23H,23H,23H,23H,23H,23H,23H,23H ; 4018 ########
        DB      23H,23H,23H,23H,23H,23H,23H,23H ; 4020 ########
        DB      23H,23H,23H,23H,23H,23H,23H,23H ; 4028 ########
        DB      23H,23H,23H,23H,23H,23H,23H,23H ; 4030 ########
        DB      23H,23H,23H,23H,23H,23H,23H,23H ; 4038 ########
        DB      23H,23H,23H,23H,23H,23H,23H,23H ; 4040 ########
        DB      23H,23H,23H,23H,23H,23H,23H,23H ; 4048 ########
        DB      23H,23H,23H,23H,23H,23H,23H,23H ; 4050 ########
        DB      23H,23H,23H,23H,23H,23H,23H,23H ; 4058 ########
        DB      23H,23H,23H,23H,23H,23H,23H,23H ; 4060 ########
        DB      23H,23H,23H,23H,23H,23H,23H,23H ; 4068 ########
        DB      23H,23H,23H,23H,23H,23H,23H,23H ; 4070 ########
        DB      23H,23H,23H,1EH,00H,00H,00H,00H ; 4078 ###.....
        DB      00H,00H,00H,00H,8AH,40H,8AH,40H ; 4080 .....@.@
        DB      8EH,40H,42H,59H,45H,1EH,1EH,20H ; 4088 .@BYE..
        DB      20H,20H,20H,20H,20H,20H,20H,20H ; 4090
        DB      20H,20H,20H,20H,20H,20H,20H,20H ; 4098
        DB      20H,20H,20H,20H,20H,20H,20H,20H ; 40A0
        DB      20H,20H,20H,20H,20H,20H,20H,20H ; 40A8
        DB      20H,20H,20H,20H,20H,20H,20H,20H ; 40B0
        DB      20H,20H,20H,20H,20H,20H,20H,20H ; 40B8
        DB      20H,20H,20H,20H,20H,20H,20H,20H ; 40C0
        DB      20H,20H,20H,20H,20H,20H,20H,20H ; 40C8
        DB      20H,20H,20H,20H,20H,20H,20H,20H ; 40D0
        DB      20H,20H,20H,20H,20H,20H,20H,20H ; 40D8
        DB      20H,20H,20H,20H,20H,20H,20H,20H ; 40E0
        DB      20H,20H,20H,20H,20H,20H,20H,20H ; 40E8
        DB      20H,20H,20H,20H,20H,20H,20H,20H ; 40F0
        DB      20H,20H,20H,20H,20H,20H,20H,20H ; 40F8
        DB      20H,20H,20H,20H,20H,20H,20H,20H ; 4100
        DB      20H,1EH,00H,01H,90H,0F5H,4DH,9EH ; 4108  .....M.
        DB      0C0H,43H,00H,73H,44H,0FFH,94H,0F3H ; 4110 .C.sD...
        DB      41H,0DH,42H,0FFH,46H,00H,1FH,46H ; 4118 A.B.F..F
        DB      62H,64H,0EFH,4FH,6EH,10H,02H,1EH ; 4120 bd.On...
        DB      2AH,46H,04H,95H,4BH,62H,64H,0F5H ; 4128 *F..Kbd.
        DB      4FH,6EH,10H,09H,1EH,95H,4BH,62H ; 4130 On....Kb
        DB      6EH,10H,00H,1EH,0C6H,4DH,62H,6EH ; 4138 n....Mbn
        DB      10H,00H,1EH,0CCH,4DH,62H,68H,8EH ; 4140 ....Mbh.
        DB      46H,00H,1FH,46H,04H,1FH,46H,20H ; 4148 F..F..F
        DB      58H,4EH,60H,6CH,4EH,0E4H,4DH,88H ; 4150 XN`lN.M.
        DB      72H,4EH,1EH,0BBH,49H,00H,47H,46H ; 4158 rN..I.GF
        DB      00H,1FH,46H,04H,1FH,46H,20H,58H ; 4160 ..F..F X
        DB      4EH,60H,0EAH,4DH,0E4H,4DH,88H,7AH ; 4168 N`.M.M.z
        DB      4EH,00H,00H,00H,00H,00H,00H,00H ; 4170 N.......
        DB      00H,00H,00H,00H,00H,00H,00H,00H ; 4178 ........
        DB      00H,00H,00H,00H,00H,00H,00H,00H ; 4180 ........
        DB      00H,00H,00H,00H,00H,00H,00H,00H ; 4188 ........
        DB      0BH,41H,00H,00H,00H,00H,00H,00H ; 4190 .A......
        DB      00H,00H,32H,4DH,7CH,50H,00H,00H ; 4198 ..2M|P..
        DB      00H,00H,00H,00H,5DH,46H,00H,00H ; 41A0 ....]F..
        DB      0DEH,4FH,0F3H,48H,0EBH,4BH,0BAH,43H ; 41A8 .O.H.K.C
        DB      9CH,44H,0CAH,45H,01H,14H,14H,03H ; 41B0 .D.E....
        DB      0C5H,00H,00H,00H,00H,00H,00H,00H ; 41B8 ........
        DB      00H,00H,00H,0ADH,00H,0A4H,41H,22H ; 41C0 ......A"
        DB      0B2H,00H,00H,20H,20H,20H,35H,30H ; 41C8 ...   50
        DB      0FFH,00H,00H,00H,00H,00H,00H,00H ; 41D0 ........
        DB      00H,00H,8AH,41H,12H,00H,00H,00H ; 41D8 ...A....
        DB      00H,00H,00H,00H,00H,00H,00H,00H ; 41E0 ........
        DB      00H,00H,00H,00H,00H,00H,00H,00H ; 41E8 ........
        DB      00H,0DH,42H,0DH,42H,0FBH,41H,0FBH ; 41F0 ..B.B.A.
        DB      41H,00H,00H,45H,0AFH,37H,00H,00H ; 41F8 A..E.7..
        DB      00H,00H,00H,00H,43H,0DBH,37H,0FFH ; 4200 ....C.7.
        DB      00H,00H,00H,00H,00H,43H,0D1H,36H ; 4208 .....C.6
        DB      0FEH,0FFH,0CFH,36H,00H,00H,42H,03H ; 4210 ...6..B.
        DB      37H,01H,00H,00H,00H,00H,00H,44H ; 4218 7......D
        DB      03H,37H,00H,00H,00H,00H,00H,00H ; 4220 .7......
        DB      62H,0B6H,36H,50H,00H,00H,00H,00H ; 4228 b.6P....
        DB      00H,54H,00H,00H,00H,00H,00H,00H ; 4230 .T......
        DB      00H,00H,00H,00H,00H,00H,00H,00H ; 4238 ........
        DB      00H,00H,00H,00H,00H,00H,00H,00H ; 4240 ........
        DB      00H,00H,00H,00H,00H,00H,00H,00H ; 4248 ........
        DB      00H,00H,00H,00H,00H,00H,00H,00H ; 4250 ........
        DB      00H,00H,00H,00H,00H,00H,00H,00H ; 4258 ........
        DB      00H,00H,00H,00H,00H,00H,00H,00H ; 4260 ........
        DB      00H,00H,00H,00H,00H,00H,00H,00H ; 4268 ........
        DB      00H,00H,00H,00H,00H,00H,00H,00H ; 4270 ........
        DB      00H,00H,00H,00H,00H,00H,00H,00H ; 4278 ........
        DB      00H,00H,00H,00H,00H,00H,00H,00H ; 4280 ........
        DB      00H,00H,00H,00H,00H,00H,00H,00H ; 4288 ........
        DB      00H,00H,00H,00H,00H,00H,00H,00H ; 4290 ........
        DB      00H,00H,00H,00H,00H,00H,00H,00H ; 4298 ........
        DB      00H,00H,00H,00H,00H,00H,00H,00H ; 42A0 ........
        DB      00H,00H,00H,00H,00H,00H,00H,00H ; 42A8 ........
        DB      00H,00H,00H,00H,00H,00H,00H,00H ; 42B0 ........
        DB      00H,00H,00H,00H,00H,00H,00H,00H ; 42B8 ........
        DB      00H,00H,00H,00H,00H,00H,00H,00H ; 42C0 ........
        DB      00H,00H,00H,00H,00H,00H,00H,00H ; 42C8 ........
        DB      00H,00H,00H,00H,00H,00H,00H,00H ; 42D0 ........
        DB      00H,00H,00H,00H,00H,00H,00H,00H ; 42D8 ........
        DB      00H                     ; 42E0 .
FAC_TYPE:
        DB      01H                     ; 42E1 .
FAC:
        DB      02H,01H,00H             ; 42E2 ...
FAC_SIGN_MSB:
        DB      00H                     ; 42E5 .
FAC_EXP:
        DB      00H                     ; 42E6 .
ARG:
        DB      00H,00H,00H             ; 42E7 ...
ARG_SIGN_MSB:
        DB      00H                     ; 42EA .
ARG_EXP:
        DB      00H,00H,00H,00H,00H,00H,01H,00H ; 42EB ........
        DB      00H,00H,0AH,05H,40H,00H,00H,00H ; 42F3 ....@...
        DB      00H,00H,00H,00H,00H,00H,00H,00H ; 42FB ........
        DB      00H,00H,00H,00H,00H,00H,00H,00H ; 4303 ........
        DB      00H,00H,00H,00H,00H,00H,00H,00H ; 430B ........
        DB      00H,00H,00H,00H,00H,00H,00H,00H ; 4313 ........
        DB      00H,00H,00H,00H,00H,00H,00H,00H ; 431B ........
        DB      00H,00H,00H,00H,00H,00H,00H,00H ; 4323 ........
        DB      00H,00H,00H,00H,00H,00H,00H,00H ; 432B ........
        DB      00H,00H,00H,00H,00H,00H,00H,00H ; 4333 ........
        DB      00H,00H,00H,00H,00H,00H,00H,00H ; 433B ........
        DB      00H,00H,00H,00H,00H,00H,00H,00H ; 4343 ........
        DB      00H,00H,00H,00H,00H,00H,00H,00H ; 434B ........
        DB      00H,00H,00H,00H,00H,00H,00H,00H ; 4353 ........
        DB      00H,00H,3BH,33H,05H,00H,3BH,33H ; 435B ..;3..;3
        DB      06H,00H,3BH,33H,04H,00H,54H,5DH ; 4363 ..;3..T]
        DB      29H,33H,4EH,33H,06H,00H,44H,00H ; 436B )3N3..D.
        DB      44H,00H,80H,0D2H,0F2H,36H,00H,08H ; 4373 D....6..
        DB      8DH,40H,00H,00H,77H,01H,2FH,39H ; 437B .@..w./9
        DB      8AH,40H,7FH,00H,8AH,40H,44H,00H ; 4383 .@...@D.
        DB      0BFH,37H,0F2H,36H,0F2H,36H,4AH,0AH ; 438B .7.6.6J.
        DB      0D1H,36H,09H,00H,38H,1EH,7EH,35H ; 4393 .6..8.~5
        DB      0DH,42H,0CH,41H,35H,35H,1AH,1EH ; 439B .B.A55..
        DB      38H,1EH,48H,00H,8DH,40H,63H,37H ; 43A3 8.H..@c7
        DB      00H,02H,06H,4CH,4FH,54H,54H,4FH ; 43AB ...LOTTO
        DB      46H,8AH,44H,8BH,00H,0ADH,43H,0C0H ; 43B3 F.D...C.
        DB      43H,89H,00H,61H,46H,7EH,44H,89H ; 43BB C..aF~D.
        DB      00H,65H,46H,00H,00H,0ADH,00H,56H ; 43C3 .eF....V
        DB      44H,00H,00H,00H,00H,4CH,4FH,54H ; 43CB D....LOT
        DB      54H,4FH,46H,20H,20H,47H,42H,41H ; 43D3 TOF  GBA
        DB      00H,00H,80H,15H,02H,00H,03H,00H ; 43DB ........
        DB      00H,00H,00H,00H,00H,00H,00H,00H ; 43E3 ........
        DB      00H,00H,00H,00H,15H,00H,00H,00H ; 43EB ........
        DB      23H,23H,23H,23H,23H,23H,23H,23H ; 43F3 ########
        DB      23H,23H,23H,23H,23H,23H,23H,23H ; 43FB ########
        DB      23H,23H,23H,23H,23H,23H,23H,23H ; 4403 ########
        DB      23H,23H,23H,23H,23H,23H,23H,23H ; 440B ########
        DB      23H,23H,23H,23H,23H,23H,23H,23H ; 4413 ########
        DB      23H,23H,23H,23H,23H,23H,23H,23H ; 441B ########
        DB      23H,23H,23H,23H,23H,23H,23H,23H ; 4423 ########
        DB      23H,23H,23H,23H,23H,23H,23H,23H ; 442B ########
        DB      23H,23H,23H,23H,23H,23H,23H,23H ; 4433 ########
        DB      23H,23H,23H,23H,23H,23H,23H,23H ; 443B ########
        DB      23H,23H,23H,23H,23H,23H,23H,23H ; 4443 ########
        DB      23H,23H,23H,23H,23H,23H,1EH,45H ; 444B ######.E
        DB      4EH,44H,1EH,35H,30H,20H,23H,23H ; 4453 ND.50 ##
        DB      23H,23H,23H,23H,23H,23H,23H,23H ; 445B ########
        DB      23H,23H,23H,23H,23H,23H,23H,23H ; 4463 ########
        DB      23H,23H,23H,23H,23H,23H,23H,23H ; 446B ########
        DB      00H,00H,22H,0B2H,00H,00H,00H,00H ; 4473 ..".....
        DB      0C0H,47H,09H,0A9H,44H,8AH,00H,79H ; 447B .G..D..y
        DB      44H,8CH,4CH,63H,80H,00H,00H,0FDH ; 4483 D.Lc....
        DB      46H,8BH,00H,00H,00H,0BH,1EH,7EH ; 448B F......~
        DB      44H,20H,73H,44H,60H,8AH,44H,84H ; 4493 D sD`.D.
        DB      44H,0C2H,45H,01H,00H,00H,00H,90H ; 449B D.E.....
        DB      44H,00H,00H,00H,50H,04H,0B4H,44H ; 44A3 D...P..D
        DB      8AH,00H,0A4H,44H,00H,00H,00H,4AH ; 44AB ...D...J
        DB      06H,0BFH,44H,8AH,00H,0AFH,44H,00H ; 44B3 ..D...D.
        DB      00H,00H,58H,04H,0CAH,44H,8AH,00H ; 44BB ..X..D..
        DB      0BAH,44H,00H,00H,00H,40H,02H,0D5H ; 44C3 .D...@..
        DB      44H,8AH,00H,0C5H,44H,00H,00H,00H ; 44CB D...D...
        DB      4CH,05H,0E0H,44H,8AH,00H,0D0H,44H ; 44D3 L..D...D
        DB      00H,00H,00H,6CH,05H,0EBH,44H,8AH ; 44DB ...l..D.
        DB      00H,0DBH,44H,00H,00H,00H,68H,05H ; 44E3 ..D...h.
        DB      0F6H,44H,8AH,00H,0E6H,44H,00H,00H ; 44EB .D...D..
        DB      00H,48H,06H,01H,45H,8AH,00H,0F1H ; 44F3 .H..E...
        DB      44H,00H,00H,00H,76H,06H,0CH,45H ; 44FB D...v..E
        DB      8AH,00H,0FCH,44H,00H,00H,00H,64H ; 4503 ...D...d
        DB      06H,17H,45H,8AH,00H,07H,45H,00H ; 450B ..E...E.
        DB      00H,00H,4EH,06H,22H,45H,8AH,00H ; 4513 ..N."E..
        DB      12H,45H,00H,00H,00H,6CH,06H,2DH ; 451B .E...l.-
        DB      45H,8AH,00H,1DH,45H,00H,00H,00H ; 4523 E...E...
        DB      68H,06H,38H,45H,8AH,00H,28H,45H ; 452B h.8E..(E
        DB      00H,00H,00H,72H,06H,43H,45H,8AH ; 4533 ...r.CE.
        DB      00H,33H,45H,00H,00H,00H,56H,06H ; 453B .3E...V.
        DB      4EH,45H,8AH,00H,3EH,45H,00H,00H ; 4543 NE..>E..
        DB      00H,52H,06H,59H,45H,8AH,00H,49H ; 454B .R.YE..I
        DB      45H,00H,00H,00H,5CH,06H,64H,45H ; 4553 E.....dE
        DB      8AH,00H,54H,45H,00H,00H,00H,70H ; 455B ..TE...p
        DB      04H,6FH,45H,8AH,00H,5FH,45H,00H ; 4563 .oE.._E.
        DB      00H,00H,50H,06H,7AH,45H,8AH,00H ; 456B ..P.zE..
        DB      6AH,45H,00H,00H,00H,46H,06H,85H ; 4573 jE...F..
        DB      45H,8AH,00H,75H,45H,00H,00H,00H ; 457B E..uE...
        DB      60H,06H,90H,45H,8AH,00H,80H,45H ; 4583 `..E...E
        DB      00H,00H,00H,5AH,06H,9BH,45H,8AH ; 458B ...Z..E.
        DB      00H,8BH,45H,00H,00H,00H,6EH,06H ; 4593 ..E...n.
        DB      0A6H,45H,8AH,00H,96H,45H,00H,00H ; 459B .E...E..
        DB      00H,44H,05H,0B1H,45H,8AH,00H,0A1H ; 45A3 .D..E...
        DB      45H,00H,00H,00H,62H,06H,0BCH,45H ; 45AB E...b..E
        DB      8AH,00H,0ACH,45H,00H,00H,00H,4CH ; 45B3 ...E...L
        DB      06H,2AH,46H,8AH,00H,0B7H,45H,3FH ; 45BB .*F...E?
        DB      46H,02H,00H,00H,00H,00H,00H,00H ; 45C3 F.......
        DB      00H,02H,00H,28H,0A9H,44H,0B4H,44H ; 45CB ...(.D.D
        DB      0BFH,44H,0CAH,44H,0D5H,44H,0E0H,44H ; 45D3 .D.D.D.D
        DB      0EBH,44H,0E0H,44H,0CAH,44H,0F6H,44H ; 45DB .D.D.D.D
        DB      01H,45H,0CAH,44H,0CH,45H,17H,45H ; 45E3 .E.D.E.E
        DB      22H,45H,17H,45H,2DH,45H,0CAH,44H ; 45EB "E.E-E.D
        DB      38H,45H,17H,45H,43H,45H,4EH,45H ; 45F3 8E.ECENE
        DB      17H,45H,59H,45H,64H,45H,0CAH,44H ; 45FB .EYEdE.D
        DB      6FH,45H,2DH,45H,7AH,45H,85H,45H ; 4603 oE-EzE.E
        DB      90H,45H,6FH,45H,9BH,45H,2DH,45H ; 460B .EoE.E-E
        DB      22H,45H,0A6H,45H,0B1H,45H,0BCH,45H ; 4613 "E.E.E.E
        DB      17H,45H,2DH,45H,0C6H,4DH,22H,81H ; 461B .E-E.M".
        DB      00H,00H,00H,00H,00H,40H,01H,6EH ; 4623 .....@.n
        DB      46H,8AH,00H,25H,46H,0EH,80H,1FH ; 462B F..%F...
        DB      46H,0AH,00H,44H,0BFH,1EH,2AH,46H ; 4633 F..D..*F
        DB      0FFH,1EH,6FH,45H,0ACH,46H,03H,00H ; 463B ..oE.F..
        DB      00H,00H,30H,46H,0BBH,49H,22H,80H ; 4643 ..0F.I".
        DB      00H,00H,01H,20H,00H,00H,01H,8EH ; 464B ... ....
        DB      02H,00H,01H,5AH,00H,2AH,03H,20H ; 4653 ...Z.*.
        DB      20H,3DH,0C6H,43H,04H,00H,00H,01H ; 465B  =.C....
        DB      30H,30H,02H,01H,30H,32H,00H,00H ; 4663 00..02..
        DB      00H,7CH,05H,79H,46H,8AH,00H,69H ; 466B .|.yF..i
        DB      46H,00H,00H,00H,78H,05H,0E1H,47H ; 4673 F...x..G
        DB      8AH,00H,74H,46H,2CH,96H,47H,46H ; 467B ..tF,.GF
        DB      1EH,1FH,46H,0EH,6EH,46H,3AH,0EH ; 4683 ..F.nF:.
        DB      1FH,46H,0EH,47H,46H,0CH,73H,44H ; 468B .F.GF.sD
        DB      32H,20H,73H,44H,1EH,47H,46H,0CH ; 4693 2 sD.GF.
        DB      79H,46H,20H,47H,46H,5EH,84H,44H ; 469B yF GF^.D
        DB      1EH,47H,46H,56H,60H,0A5H,34H,84H ; 46A3 .GFV`.4.
        DB      44H,0BAH,46H,04H,00H,00H,00H,7FH ; 46AB D.F.....
        DB      46H,05H,82H,1FH,46H,00H,00H,0C2H ; 46B3 F...F...
        DB      46H,05H,00H,00H,00H,0B4H,46H,0CAH ; 46BB F.....F.
        DB      46H,06H,00H,00H,00H,00H,00H,0D2H ; 46C3 F.......
        DB      46H,07H,00H,00H,00H,00H,00H,0DAH ; 46CB F.......
        DB      46H,08H,00H,00H,00H,00H,00H,10H ; 46D3 F.......
        DB      47H,09H,00H,00H,00H,00H,00H,58H ; 46DB G......X
        DB      4EH,0A3H,80H,00H,00H,14H,55H,4EH ; 46E3 N.....UN
        DB      47H,55H,45H,4CH,54H,49H,47H,45H ; 46EB GUELTIGE
        DB      20H,45H,49H,4EH,47H,41H,42H,45H ; 46F3  EINGABE
        DB      20H,21H,67H,47H,8BH,00H,0E8H,46H ; 46FB  !gG...F
        DB      0CH,68H,68H,94H,0F7H,41H,0FBH,41H ; 4703 .hh..A.A
        DB      60H,0FDH,46H,0E2H,46H,72H,47H,0AH ; 470B `.F.FrG.
        DB      00H,00H,00H,03H,47H,4EH,57H,41H ; 4713 ....GNWA
        DB      48H,52H,53H,43H,48H,45H,49H,4EH ; 471B HRSCHEIN
        DB      4CH,49H,43H,48H,4BH,45H,49H,54H ; 4723 LICHKEIT
        DB      53H,42H,45H,52H,45H,43H,48H,4EH ; 472B SBERECHN
        DB      55H,4EH,47H,45H,4EH,20H,5AH,55H ; 4733 UNGEN ZU
        DB      52H,20H,4CH,4FH,54H,54H,4FH,2DH ; 473B R LOTTO-
        DB      53H,50H,49H,45H,4CH,41H,52H,54H ; 4743 SPIELART
        DB      20H,41H,20H,41H,55H,53H,20H,42H ; 474B  A AUS B
        DB      20H,28H,46H,45H,53H,54H,4BH,4FH ; 4753  (FESTKO
        DB      4DH,4DH,41H,2DH,41H,55H,53H,47H ; 475B MMA-AUSG
        DB      41H,42H,45H,29H,0C9H,47H,8BH,00H ; 4763 ABE).G..
        DB      18H,47H,04H,64H,67H,47H,68H,0D4H ; 476B .G.dgGh.
        DB      47H,0BH,00H,00H,00H,6DH,47H,4EH ; 4773 G....mGN
        DB      7EH,7EH,7EH,7EH,7EH,7EH,7EH,7EH ; 477B ~~~~~~~~
        DB      7EH,7EH,7EH,7EH,7EH,7EH,7EH,7EH ; 4783 ~~~~~~~~
        DB      7EH,7EH,7EH,7EH,7EH,7EH,7EH,7EH ; 478B ~~~~~~~~
        DB      7EH,7EH,7EH,7EH,7EH,7EH,7EH,7EH ; 4793 ~~~~~~~~
        DB      7EH,7EH,7EH,7EH,7EH,7EH,7EH,7EH ; 479B ~~~~~~~~
        DB      7EH,7EH,7EH,7EH,7EH,7EH,7EH,7EH ; 47A3 ~~~~~~~~
        DB      7EH,7EH,7EH,7EH,7EH,7EH,7EH,7EH ; 47AB ~~~~~~~~
        DB      7EH,7EH,7EH,7EH,7EH,7EH,7EH,7EH ; 47B3 ~~~~~~~~
        DB      7EH,7EH,7EH,7EH,7EH,7EH,7EH,7EH ; 47BB ~~~~~~~~
        DB      7EH,7EH,7EH,7EH,7EH,7EH,4EH,48H ; 47C3 ~~~~~~NH
        DB      8BH,00H,7AH,47H,04H,64H,0C9H,47H ; 47CB ..zG.d.G
        DB      68H,0F6H,47H,0CH,00H,00H,00H,0CFH ; 47D3 h.G.....
        DB      47H,00H,48H,41H,4DH,14H,74H,49H ; 47DB G.HAM.tI
        DB      8AH,00H,0DCH,47H,0EH,64H,84H,44H ; 47E3 ...G.d.D
        DB      68H,68H,1EH,73H,44H,00H,0E1H,47H ; 47EB hh.sD..G
        DB      20H,73H,44H,59H,48H,0DH,00H,00H ; 47F3  sDYH...
        DB      00H,0E7H,47H,4FH,45H,53H,20H,57H ; 47FB ..GOES W
        DB      49H,52H,44H,20H,44H,49H,45H,20H ; 4803 IRD DIE
        DB      57H,41H,48H,52H,53H,43H,48H,45H ; 480B WAHRSCHE
        DB      49H,4EH,4CH,49H,43H,48H,4BH,45H ; 4813 INLICHKE
        DB      49H,54H,2CH,20H,44H,49H,45H,20H ; 481B IT, DIE
        DB      28H,41H,55H,46H,20H,44H,45H,4EH ; 4823 (AUF DEN
        DB      20H,48H,41H,55H,50H,54H,47H,45H ; 482B  HAUPTGE
        DB      57H,49H,4EH,4EH,29H,20H,4EH,4FH ; 4833 WINN) NO
        DB      52H,4DH,49H,45H,52H,54H,45H,20H ; 483B RMIERTE
        DB      57H,41H,48H,52H,53H,43H,48H,45H ; 4843 WAHRSCHE
        DB      49H,4EH,2DH,0B1H,48H,8BH,00H,0FEH ; 484B IN-.H...
        DB      47H,04H,64H,4EH,48H,68H,0BCH,48H ; 4853 G.dNHh.H
        DB      0EH,00H,00H,00H,54H,48H,4FH,4CH ; 485B ....THOL
        DB      49H,43H,48H,4BH,45H,49H,54H,20H ; 4863 ICHKEIT
        DB      53H,4FH,57H,49H,45H,20H,42H,45H ; 486B SOWIE BE
        DB      49H,20H,57H,41H,45H,48H,4CH,42H ; 4873 I WAEHLB
        DB      41H,52H,45H,52H,20H,54H,49H,50H ; 487B ARER TIP
        DB      41H,4EH,5AH,41H,48H,4CH,20H,44H ; 4883 ANZAHL D
        DB      49H,45H,20H,57H,41H,48H,52H,53H ; 488B IE WAHRS
        DB      43H,48H,45H,49H,4EH,4CH,49H,43H ; 4893 CHEINLIC
        DB      48H,53H,54H,45H,20H,41H,4EH,5AH ; 489B HSTE ANZ
        DB      41H,48H,4CH,20H,46H,55H,45H,52H ; 48A3 AHL FUER
        DB      20H,4AH,45H,44H,45H,4EH,0DFH,48H ; 48AB  JEDEN.H
        DB      8BH,00H,61H,48H,04H,64H,0B1H,48H ; 48B3 ..aH.d.H
        DB      68H,0EBH,48H,0FH,00H,00H,00H,0B7H ; 48BB h.H.....
        DB      48H,1AH,4DH,4FH,45H,47H,4CH,49H ; 48C3 H.MOEGLI
        DB      43H,48H,45H,4EH,20H,52H,41H,4EH ; 48CB CHEN RAN
        DB      47H,20H,42H,45H,52H,45H,43H,48H ; 48D3 G BERECH
        DB      4EH,45H,54H,2EH,0BH,49H,8BH,00H ; 48DB NET..I..
        DB      0C4H,48H,05H,64H,0DFH,48H,68H,68H ; 48E3 .H.d.Hhh
        DB      20H,49H,10H,00H,00H,00H,0E5H,48H ; 48EB  I.....H
        DB      9DH,49H,0A4H,45H,11H,00H,00H,00H ; 48F3 .I.E....
        DB      0FH,45H,49H,4EH,47H,41H,42H,45H ; 48FB .EINGABE
        DB      20H,56H,4FH,4EH,20H,41H,3AH,20H ; 4903  VON A:
        DB      0B5H,49H,8BH,00H,0FBH,48H,0EH,64H ; 490B .I...H.d
        DB      0BH,49H,76H,47H,46H,6EH,03H,00H ; 4913 .IvGFn..
        DB      1EH,47H,46H,62H,68H,44H,49H,11H ; 491B .GFbhDI.
        DB      00H,00H,00H,11H,49H,00H,00H,12H ; 4923 ....I...
        DB      00H,0A4H,45H,00H,00H,13H,8AH,05H ; 492B ..E.....
        DB      00H,1EH,47H,46H,32H,00H,47H,46H ; 4933 ..GF2.GF
        DB      0FFH,64H,0E2H,46H,68H,86H,28H,49H ; 493B .d.Fh.(I
        DB      0FFH,67H,49H,12H,00H,00H,00H,30H ; 4943 .gI....0
        DB      49H,28H,49H,13H,00H,0A4H,45H,00H ; 494B I(I...E.
        DB      00H,12H,8AH,04H,00H,1EH,2AH,46H ; 4953 ......*F
        DB      00H,47H,46H,0FFH,64H,0E2H,46H,68H ; 495B .GF.d.Fh
        DB      86H,4CH,49H,0FFH,95H,49H,13H,00H ; 4963 .LI..I..
        DB      00H,00H,54H,49H,00H,00H,00H,63H ; 496B ..TI...c
        DB      07H,80H,4CH,8AH,00H,6FH,49H,4CH ; 4973 ..L..oIL
        DB      49H,14H,00H,0A4H,45H,00H,00H,12H ; 497B I...E...
        DB      8AH,01H,00H,1EH,74H,49H,00H,47H ; 4983 ....tI.G
        DB      46H,0FFH,64H,0E2H,46H,68H,86H,7AH ; 498B F.d.Fh.z
        DB      49H,0FFH,0D0H,49H,14H,00H,00H,00H ; 4993 I..I....
        DB      82H,49H,65H,4AH,0A4H,49H,15H,00H ; 499B .IeJ.I..
        DB      00H,00H,0FH,45H,49H,4EH,47H,41H ; 49A3 ...EINGA
        DB      42H,45H,20H,56H,4FH,4EH,20H,42H ; 49AB BE VON B
        DB      3AH,20H,9AH,4AH,8BH,00H,0A5H,49H ; 49B3 : .J...I
        DB      84H,44H,42H,80H,00H,00H,0EH,64H ; 49BB .DB....d
        DB      0B5H,49H,76H,0BBH,49H,6EH,03H,00H ; 49C3 .Iv.In..
        DB      1EH,0BBH,49H,62H,68H,0F4H,49H,15H ; 49CB ..Ibh.I.
        DB      00H,00H,00H,0C1H,49H,7AH,49H,16H ; 49D3 ....IzI.
        DB      00H,0A4H,49H,00H,00H,13H,8AH,05H ; 49DB ..I.....
        DB      00H,1EH,0BBH,49H,32H,00H,0BBH,49H ; 49E3 ...I2..I
        DB      0FFH,64H,0E2H,46H,68H,86H,0D8H,49H ; 49EB .d.Fh..I
        DB      0FFH,17H,4AH,16H,00H,00H,00H,0E0H ; 49F3 ..J.....
        DB      49H,0D8H,49H,17H,00H,0A4H,49H,00H ; 49FB I.I...I.
        DB      00H,12H,8AH,04H,00H,1EH,2AH,46H ; 4A03 ......*F
        DB      00H,0BBH,49H,0FFH,64H,0E2H,46H,68H ; 4A0B ..I.d.Fh
        DB      86H,0FCH,49H,0FFH,3AH,4AH,17H,00H ; 4A13 ..I.:J..
        DB      00H,00H,04H,4AH,0FCH,49H,18H,00H ; 4A1B ...J.I..
        DB      0A4H,49H,00H,00H,12H,8AH,01H,00H ; 4A23 .I......
        DB      1EH,74H,49H,00H,0BBH,49H,0FFH,64H ; 4A2B .tI..I.d
        DB      0E2H,46H,68H,86H,1FH,4AH,0FFH,5DH ; 4A33 .Fh..J.]
        DB      4AH,18H,00H,00H,00H,27H,4AH,1FH ; 4A3B J....'J.
        DB      4AH,19H,00H,0A4H,49H,00H,00H,12H ; 4A43 J...I...
        DB      8AH,06H,00H,1EH,47H,46H,00H,0BBH ; 4A4B ....GF..
        DB      49H,0FFH,64H,0E2H,46H,68H,86H,42H ; 4A53 I.d.Fh.B
        DB      4AH,0FFH,0B5H,4AH,19H,00H,00H,00H ; 4A5B J..J....
        DB      4AH,4AH,25H,4DH,0A4H,4DH,1AH,00H ; 4A63 JJ%M.M..
        DB      00H,00H,2CH,41H,4EH,5AH,41H,48H ; 4A6B ..,ANZAH
        DB      4CH,20H,44H,45H,52H,20H,41H,4EH ; 4A73 L DER AN
        DB      20H,44H,45H,52H,20H,5AH,49H,45H ; 4A7B  DER ZIE
        DB      48H,55H,4EH,47H,20H,42H,45H,54H ; 4A83 HUNG BET
        DB      45H,49H,4CH,49H,47H,54H,45H,4EH ; 4A8B EILIGTEN
        DB      20H,54H,49H,50H,53H,3AH,20H,0EBH ; 4A93  TIPS: .
        DB      4AH,8BH,00H,6DH,4AH,95H,4BH,82H ; 4A9B J..mJ.K.
        DB      82H,00H,00H,0EH,64H,9AH,4AH,76H ; 4AA3 ....d.Jv
        DB      0A0H,4AH,6EH,10H,00H,1EH,0A0H,4AH ; 4AAB .Jn....J
        DB      62H,68H,0D9H,4AH,1AH,00H,00H,00H ; 4AB3 bh.J....
        DB      0A6H,4AH,42H,4AH,1BH,00H,0A4H,4DH ; 4ABB .JBJ...M
        DB      00H,00H,13H,8AH,05H,00H,1EH,0A0H ; 4AC3 ........
        DB      4AH,32H,00H,0A0H,4AH,0FFH,64H,0E2H ; 4ACB J2..J.d.
        DB      46H,68H,86H,0BDH,4AH,0FFH,31H,4BH ; 4AD3 Fh..J.1K
        DB      1BH,00H,00H,00H,0C5H,4AH,09H,53H ; 4ADB .....J.S
        DB      50H,49H,45H,4CH,41H,52H,54H,3AH ; 4AE3 PIELART:
        DB      0F6H,4AH,8BH,00H,0E1H,4AH,04H,20H ; 4AEB .J...J.
        DB      41H,55H,53H,09H,4BH,8BH,00H,0F1H ; 4AF3 AUS.K...
        DB      4AH,0CH,20H,20H,54H,49H,50H,41H ; 4AFB J.  TIPA
        DB      4EH,5AH,41H,48H,4CH,3AH,89H,4BH ; 4B03 NZAHL:.K
        DB      8BH,00H,0FCH,4AH,21H,68H,68H,64H ; 4B0B ...J!hhd
        DB      0EBH,4AH,6EH,03H,00H,1EH,47H,46H ; 4B13 .Jn...GF
        DB      62H,64H,0F6H,4AH,6EH,03H,00H,1EH ; 4B1B bd.Jn...
        DB      0BBH,49H,62H,64H,09H,4BH,6EH,10H ; 4B23 .Ibd.Kn.
        DB      00H,1EH,0A0H,4AH,62H,68H,0ACH,4BH ; 4B2B ...Jbh.K
        DB      1CH,00H,00H,00H,0FH,4BH,4FH,3DH ; 4B33 .....KO=
        DB      3DH,3DH,3DH,3DH,3DH,3DH,3DH,3DH ; 4B3B ========
        DB      3DH,3DH,3DH,3DH,3DH,3DH,3DH,3DH ; 4B43 ========
        DB      3DH,3DH,3DH,3DH,3DH,3DH,3DH,3DH ; 4B4B ========
        DB      3DH,3DH,3DH,3DH,3DH,3DH,3DH,3DH ; 4B53 ========
        DB      3DH,3DH,3DH,3DH,3DH,3DH,3DH,3DH ; 4B5B ========
        DB      3DH,3DH,3DH,3DH,3DH,3DH,3DH,3DH ; 4B63 ========
        DB      3DH,3DH,3DH,3DH,3DH,3DH,3DH,3DH ; 4B6B ========
        DB      3DH,3DH,3DH,3DH,3DH,3DH,3DH,3DH ; 4B73 ========
        DB      3DH,3DH,3DH,3DH,3DH,3DH,3DH,3DH ; 4B7B ========
        DB      3DH,3DH,3DH,3DH,3DH,3DH,66H,4CH ; 4B83 ======fL
        DB      8BH,00H,39H,4BH,0D2H,4DH,22H,44H ; 4B8B ..9K.M"D
        DB      00H,00H,0E4H,4DH,0E2H,82H,00H,00H ; 4B93 ...M....
        DB      10H,64H,89H,4BH,68H,1EH,47H,46H ; 4B9B .d.Kh.GF
        DB      20H,8FH,4BH,1EH,2AH,46H,20H,95H ; 4BA3  .K.*F .
        DB      4BH,0CCH,4BH,1DH,00H,00H,00H,9BH ; 4BAB K.K.....
        DB      4BH,17H,8AH,01H,00H,1EH,0BBH,49H ; 4BB3 K......I
        DB      00H,47H,46H,00H,47H,46H,0FFH,1EH ; 4BBB .GF.GF..
        DB      0BBH,49H,00H,47H,46H,20H,47H,46H ; 4BC3 .I.GF GF
        DB      0FFH,0E3H,4BH,1EH,00H,00H,00H,0B4H ; 4BCB ..K.....
        DB      4BH,0EH,80H,1FH,46H,0AH,00H,49H ; 4BD3 K...F..I
        DB      00H,1EH,2AH,46H,0FFH,1EH,47H,46H ; 4BDB ..*F..GF
        DB      0AH,4CH,1FH,00H,00H,00H,0D4H,4BH ; 4BE3 .L.....K
        DB      5EH,4EH,8CH,00H,00H,00H,18H,1EH ; 4BEB ^N......
        DB      95H,4BH,0EH,1FH,46H,20H,0EBH,4BH ; 4BF3 .K..F .K
        DB      1EH,0BBH,49H,0CH,2AH,46H,00H,1FH ; 4BFB ..I.*F..
        DB      46H,06H,0EBH,4BH,20H,95H,4BH,18H ; 4C03 F..K .K.
        DB      4CH,20H,00H,00H,00H,0F1H,4BH,05H ; 4C0B L ....K.
        DB      82H,1FH,46H,00H,00H,73H,4CH,21H ; 4C13 ..F..sL!
        DB      00H,00H,00H,12H,4CH,45H,54H,41H ; 4C1B ....LETA
        DB      42H,45H,4CH,4CH,45H,20H,31H,20H ; 4C23 BELLE 1
        DB      28H,47H,49H,4CH,54H,20H,42H,45H ; 4C2B (GILT BE
        DB      49H,20H,4EH,49H,43H,48H,54H,5AH ; 4C33 I NICHTZ
        DB      49H,45H,48H,55H,4EH,47H,20H,4FH ; 4C3B IEHUNG O
        DB      44H,45H,52H,20H,4EH,49H,43H,48H ; 4C43 DER NICH
        DB      54H,41H,55H,53H,57H,45H,52H,54H ; 4C4B TAUSWERT
        DB      55H,4EH,47H,20H,44H,45H,52H,20H ; 4C53 UNG DER
        DB      5AH,55H,53H,41H,54H,5AH,5AH,41H ; 4C5B ZUSATZZA
        DB      48H,4CH,29H,0F0H,4CH,8BH,00H,20H ; 4C63 HL).L..
        DB      4CH,06H,68H,68H,64H,66H,4CH,68H ; 4C6B L.hhdfLh
        DB      0B9H,4CH,22H,00H,00H,00H,6CH,4CH ; 4C73 .L"...lL
        DB      00H,50H,00H,44H,13H,32H,4DH,8AH ; 4C7B .P.D.2M.
        DB      00H,7BH,4CH,0D8H,4DH,0E2H,46H,00H ; 4C83 .{L.M.F.
        DB      00H,0E2H,46H,0A2H,80H,00H,00H,0BDH ; 4C8B ..F.....
        DB      4AH,23H,00H,0A4H,51H,00H,00H,1EH ; 4C93 J#..Q...
        DB      1EH,73H,44H,0CH,80H,4CH,20H,73H ; 4C9B .sD..L s
        DB      44H,1EH,8FH,4BH,20H,47H,46H,1EH ; 4CA3 D..K GF.
        DB      95H,4BH,20H,86H,4CH,1EH,2AH,46H ; 4CAB .K .L.*F
        DB      20H,8CH,4CH,88H,92H,4CH,0FDH,4CH ; 4CB3  .L..L.L
        DB      23H,00H,00H,00H,9AH,4CH,2EH,54H ; 4CBB #....L.T
        DB      41H,42H,45H,4CH,4CH,45H,20H,32H ; 4CC3 ABELLE 2
        DB      20H,28H,47H,49H,4CH,54H,20H,42H ; 4CCB  (GILT B
        DB      45H,49H,20H,41H,55H,53H,57H,45H ; 4CD3 EI AUSWE
        DB      52H,54H,55H,4EH,47H,20H,44H,45H ; 4CDB RTUNG DE
        DB      52H,20H,5AH,55H,53H,41H,54H,5AH ; 4CE3 R ZUSATZ
        DB      5AH,41H,48H,4CH,29H,4BH,4DH,8BH ; 4CEB ZAHL)KM.
        DB      00H,0C1H,4CH,06H,68H,68H,64H,0F0H ; 4CF3 ..L.hhd.
        DB      4CH,68H,1DH,4DH,24H,00H,00H,00H ; 4CFB Lh.M$...
        DB      0F6H,4CH,92H,4CH,25H,00H,0A4H,51H ; 4D03 .L.L%..Q
        DB      00H,00H,0FH,1EH,0CAH,44H,20H,8CH ; 4D0B .....D .
        DB      4CH,88H,05H,4DH,94H,0F3H,41H,0DH ; 4D13 L..M..A.
        DB      42H,90H,87H,4DH,25H,00H,00H,00H ; 4D1B B..M%...
        DB      0DH,4DH,48H,4FH,0A4H,51H,26H,00H ; 4D23 .MHO.Q&.
        DB      00H,00H,00H,00H,00H,50H,05H,0F5H ; 4D2B .....P..
        DB      4DH,8AH,00H,2DH,4DH,12H,57H,41H ; 4D33 M..-M.WA
        DB      48H,52H,53H,43H,48H,45H,49H,4EH ; 4D3B HRSCHEIN
        DB      4CH,49H,43H,48H,4BH,45H,49H,54H ; 4D43 LICHKEIT
        DB      6DH,4DH,8BH,00H,38H,4DH,1BH,4EH ; 4D4B mM..8M.N
        DB      4FH,52H,4DH,49H,45H,52H,54H,45H ; 4D53 ORMIERTE
        DB      20H,57H,41H,48H,52H,2DH,20H,57H ; 4D5B  WAHR- W
        DB      41H,48H,52H,53H,43H,48H,45H,49H ; 4D63 AHRSCHEI
        DB      4EH,2DH,0AEH,4DH,8BH,00H,51H,4DH ; 4D6B N-.M..QM
        DB      13H,68H,1EH,32H,4DH,6CH,64H,4BH ; 4D73 .h.2MldK
        DB      4DH,20H,0EBH,4BH,1EH,0BFH,44H,6CH ; 4D7B M .K..Dl
        DB      64H,6DH,4DH,68H,0BEH,4DH,26H,00H ; 4D83 dmMh.M&.
        DB      00H,00H,73H,4DH,1EH,53H,43H,48H ; 4D8B ..sM.SCH
        DB      45H,49H,4EH,4CH,49H,43H,48H,4BH ; 4D93 EINLICHK
        DB      45H,49H,54H,20H,20H,4CH,49H,43H ; 4D9B EIT  LIC
        DB      48H,53H,54H,45H,20H,41H,4EH,5AH ; 4DA3 HSTE ANZ
        DB      41H,48H,4CH,0EAH,4DH,8BH,00H,8FH ; 4DAB AHL.M...
        DB      4DH,09H,1EH,0B1H,45H,6CH,64H,0AEH ; 4DB3 M...Eld.
        DB      4DH,68H,68H,39H,4EH,27H,00H,00H ; 4DBB Mhh9N'..
        DB      00H,0B4H,4DH,0CCH,4DH,0C2H,81H,00H ; 4DC3 ..M.M...
        DB      00H,0A0H,4AH,02H,82H,00H,00H,86H ; 4DCB ..J.....
        DB      4CH,62H,46H,00H,00H,0DEH,4DH,62H ; 4DD3 LbF...Mb
        DB      4AH,00H,00H,47H,46H,62H,4EH,00H ; 4DDB J..GFbN.
        DB      00H,73H,44H,43H,83H,00H,00H,6CH ; 4DE3 .sDC...l
        DB      4EH,8BH,00H,4DH,46H,00H,00H,00H ; 4DEB N..MF...
        DB      00H,00H,4DH,50H,8AH,00H,0F0H,4DH ; 4DF3 ..MP...M
        DB      05H,4DH,28H,00H,0A4H,59H,00H,00H ; 4DFB .M(..Y..
        DB      35H,1EH,86H,4CH,20H,95H,4BH,1EH ; 4E03 5..L .K.
        DB      2AH,46H,20H,0C6H,4DH,1EH,0A0H,4AH ; 4E0B *F .M..J
        DB      0EH,95H,4BH,20H,0CCH,4DH,1EH,95H ; 4E13 ..K .M..
        DB      4BH,20H,0D2H,4DH,1EH,0C6H,4DH,20H ; 4E1B K .M..M
        DB      0D8H,4DH,1EH,0CCH,4DH,20H,0DEH,4DH ; 4E23 .M..M .M
        DB      60H,0EAH,4DH,0E4H,4DH,1EH,0F5H,4DH ; 4E2B `.M.M..M
        DB      20H,1FH,46H,88H,0FBH,4DH,50H,4EH ; 4E33  .F..MPN
        DB      28H,00H,00H,00H,03H,4EH,0EH,80H ; 4E3B (....N..
        DB      1FH,46H,0AH,00H,4BH,1EH,1EH,2AH ; 4E43 .F..K..*
        DB      46H,0FFH,1EH,47H,46H,0E8H,4EH,29H ; 4E4B F..GF.N)
        DB      00H,00H,00H,41H,4EH,1FH,46H,0C2H ; 4E53 ...AN.F.
        DB      80H,00H,00H,8FH,4BH,0ACH,00H,00H ; 4E5B ....K...
        DB      00H,0FBH,4DH,2AH,00H,0A4H,55H,00H ; 4E63 ..M*..U.
        DB      00H,1EH,4FH,8BH,00H,55H,46H,64H ; 4E6B ..O..UFd
        DB      4EH,2AH,00H,0A4H,55H,00H,00H,72H ; 4E73 N*..U..r
        DB      4EH,2AH,00H,0A4H,55H,00H,00H,65H ; 4E7B N*..U..e
        DB      8AH,02H,36H,1EH,2AH,46H,00H,8CH ; 4E83 ..6.*F..
        DB      4CH,0FFH,1EH,0BBH,49H,00H,47H,46H ; 4E8B L...I.GF
        DB      0CH,2AH,46H,00H,1FH,46H,20H,5EH ; 4E93 .*F..F ^
        DB      4EH,1EH,47H,46H,0CH,2AH,46H,00H ; 4E9B N.GF.*F.
        DB      1FH,46H,0EH,5EH,4EH,04H,1FH,46H ; 4EA3 .F.^N..F
        DB      04H,1FH,46H,20H,58H,4EH,60H,0EAH ; 4EAB ..F XN`.
        DB      4DH,0E4H,4DH,88H,64H,4EH,0FFH,1EH ; 4EB3 M.M.dN..
        DB      47H,46H,0CH,2AH,46H,00H,1FH,46H ; 4EBB GF.*F..F
        DB      04H,1FH,46H,20H,58H,4EH,60H,6CH ; 4EC3 ..F XN`l
        DB      4EH,0E4H,4DH,88H,72H,4EH,1EH,0BBH ; 4ECB N.M.rN..
        DB      49H,00H,47H,46H,00H,1FH,46H,04H ; 4ED3 I.GF..F.
        DB      1FH,46H,20H,58H,4EH,60H,0EAH,4DH ; 4EDB .F XN`.M
        DB      0E4H,4DH,88H,7AH,4EH,0F6H,4EH,2AH ; 4EE3 .M.zN.N*
        DB      00H,00H,00H,82H,4EH,05H,82H,1FH ; 4EEB ....N...
        DB      46H,00H,00H,40H,4FH,2BH,00H,00H ; 4EF3 F..@O+..
        DB      00H,0F0H,4EH,1FH,4BH,4FH,4EH,54H ; 4EFB ..N.KONT
        DB      52H,4FH,4CH,4CH,53H,55H,4DH,4DH ; 4F03 ROLLSUMM
        DB      45H,20H,20H,20H,20H,20H,20H,20H ; 4F0B E
        DB      20H,20H,20H,20H,20H,20H,20H,20H ; 4F13
        DB      20H,20H,20H,72H,4FH,8BH,00H,0FEH ; 4F1B    rO...
        DB      4EH,1BH,68H,64H,1EH,4FH,6EH,10H ; 4F23 N.hd.On.
        DB      09H,1EH,0D2H,4DH,62H,6EH,10H,00H ; 4F2B ...Mbn..
        DB      1EH,0D8H,4DH,62H,6EH,10H,00H,1EH ; 4F33 ..Mbn...
        DB      0DEH,4DH,62H,68H,8EH,8FH,4FH,2CH ; 4F3B .Mbh..O,
        DB      00H,00H,00H,24H,4FH,0D6H,4FH,0A4H ; 4F43 ...$O.O.
        DB      55H,2DH,00H,00H,00H,21H,57H,45H ; 4F4B U-...!WE
        DB      49H,54H,45H,52H,45H,20H,52H,41H ; 4F53 ITERE RA
        DB      45H,4EH,47H,45H,20H,45H,58H,49H ; 4F5B ENGE EXI
        DB      53H,54H,49H,45H,52H,45H,4EH,20H ; 4F63 STIEREN
        DB      4EH,49H,43H,48H,54H,20H,21H,0EFH ; 4F6B NICHT !.
        DB      4FH,8BH,00H,50H,4FH,16H,8AH,02H ; 4F73 O..PO...
        DB      00H,1EH,0F5H,4DH,00H,58H,4EH,0FFH ; 4F7B ...M.XN.
        DB      64H,72H,4FH,68H,1EH,47H,46H,20H ; 4F83 drOh.GF
        DB      1FH,46H,8EH,0FFH,0CEH,4FH,2DH,00H ; 4F8B .F...O-.
        DB      00H,00H,78H,4FH,36H,1EH,95H,4BH ; 4F93 ..xO6..K
        DB      0EH,58H,4EH,20H,95H,4BH,1EH,0C6H ; 4F9B .XN .K..
        DB      4DH,0EH,58H,4EH,20H,0C6H,4DH,1EH ; 4FA3 M.XN .M.
        DB      0CCH,4DH,0EH,58H,4EH,20H,0CCH,4DH ; 4FAB .M.XN .M
        DB      1EH,0D2H,4DH,0CH,95H,4BH,20H,0D2H ; 4FB3 ..M..K .
        DB      4DH,1EH,0D8H,4DH,0CH,0C6H,4DH,20H ; 4FBB M..M..M
        DB      0D8H,4DH,1EH,0DEH,4DH,0CH,0CCH,4DH ; 4FC3 .M..M..M
        DB      20H,0DEH,4DH,38H,50H,2EH,00H,00H ; 4FCB  .M8P...
        DB      00H,97H,4FH,40H,50H,0A4H,59H,2FH ; 4FD3 ..O@P.Y/
        DB      00H,00H,00H,7AH,4EH,2FH,00H,0A4H ; 4FDB ...zN/..
        DB      5DH,00H,00H,08H,2DH,45H,52H,20H ; 4FE3 ]...-ER
        DB      20H,31H,20H,3AH,0F5H,4FH,8BH,00H ; 4FEB  1 :.O..
        DB      0E6H,4FH,00H,00H,8BH,00H,59H,46H ; 4FF3 .O....YF
        DB      3CH,94H,0F3H,41H,0ACH,34H,88H,0DEH ; 4FFB <..A.4..
        DB      4FH,64H,0E4H,4DH,6EH,03H,00H,1EH ; 5003 Od.Mn...
        DB      47H,46H,00H,1FH,46H,62H,64H,0EFH ; 500B GF..Fbd.
        DB      4FH,6EH,10H,02H,1EH,2AH,46H,04H ; 5013 On...*F.
        DB      95H,4BH,62H,64H,0F5H,4FH,6EH,10H ; 501B .Kbd.On.
        DB      09H,1EH,95H,4BH,62H,6EH,10H,00H ; 5023 ...Kbn..
        DB      1EH,0C6H,4DH,62H,6EH,10H,00H,1EH ; 502B ..Mbn...
        DB      0CCH,4DH,62H,68H,8EH,64H,50H,2FH ; 5033 .Mbh.dP/
        DB      00H,00H,00H,0FBH,4FH,00H,00H,0A4H ; 503B ....O...
        DB      5DH,30H,00H,00H,00H,00H,0F0H,79H ; 5043 ]0.....y
        DB      46H,14H,0B4H,43H,8AH,00H,48H,50H ; 504B F..C..HP
        DB      10H,8AH,02H,00H,1EH,4DH,50H,00H ; 5053 .....MP.
        DB      73H,44H,0FFH,94H,0F3H,41H,0DH,42H ; 505B sD...A.B
        DB      0FFH,6CH,50H,30H,00H,00H,00H,53H ; 5063 .lP0...S
        DB      50H,74H,50H,31H,00H,00H,00H,51H ; 506B PtP1...Q
        DB      46H,00H,00H,32H,00H,00H,00H,00H ; 5073 F..2....
        DB      00H,00H,00H,00H,00H,00H,00H,00H ; 507B ........
        DB      00H,00H,00H,00H,00H,00H,00H,00H ; 5083 ........
        DB      00H,00H,00H,00H,00H,00H,00H,00H ; 508B ........
        DB      00H,00H,00H,00H,00H,00H,00H,00H ; 5093 ........
        DB      00H,00H,00H,00H,00H,00H,00H,00H ; 509B ........
        DB      00H,00H,00H,00H,00H,00H,00H,00H ; 50A3 ........
        DB      00H,00H,00H,00H,00H,00H,00H,00H ; 50AB ........
        DB      00H,00H,00H,00H,00H,00H,00H,00H ; 50B3 ........
        DB      00H,00H,00H,00H,00H,00H,00H,00H ; 50BB ........
        DB      00H,00H,00H,00H,00H,00H,00H,00H ; 50C3 ........
        DB      00H,00H,00H,00H,00H,00H,00H,00H ; 50CB ........
        DB      00H,00H,00H,00H,00H,00H,00H,00H ; 50D3 ........
        DB      00H,00H,00H,00H,00H,00H,00H,00H ; 50DB ........
        DB      00H,00H,00H,00H,00H,00H,00H,00H ; 50E3 ........
        DB      00H,00H,00H,00H,00H,00H,00H,00H ; 50EB ........
        DB      00H,00H,00H,00H,00H,00H,00H,00H ; 50F3 ........
        DB      00H,00H,00H,00H,00H     ; 50FB .....
        END
