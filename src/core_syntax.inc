; core_syntax.inc - Start, Hauptschleife, Syntaxmaschine, Grammatik, Syntaxaktionen
; Teil von basict.asm (per INCLUDE), nicht einzeln assemblierbar.

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
        LD      SP,STACK_TOP            ; 0106  31ad43
        LD      HL,(0006H)              ; 0109  2a0600
        LD      DE,V_4001               ; 010C  110140
        XOR     A                       ; 010F  af
        SBC     HL,DE                   ; 0110  ed52
        EX      DE,HL                   ; 0112  eb
        LD      HL,RAM_START-1          ; 0113  21ff3f
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
        LD      (RAMTOP),HL             ; 0127  22b741
        LD      (SP_INIT),SP            ; 012A  ed739c41
        LD      HL,DEV_KBD              ; 012E  210437
        LD      DE,CHANTAB              ; 0131  11fb41
        LD      BC,37H                  ; 0134  013700
        LDIR                            ; 0137  edb0
        LD      HL,V_420D               ; 0139  210d42
        LD      (V_41F1),HL             ; 013C  22f141
        LD      (V_41F3),HL             ; 013F  22f341
        LD      HL,CHANTAB              ; 0142  21fb41
        LD      (V_41F5),HL             ; 0145  22f541
        LD      (V_41F7),HL             ; 0148  22f741
        LD      A,0FFH                  ; 014B  3eff
        LD      (V_41B4),A              ; 014D  32b441
; ---- Treiber-Initialisierung (DRVTAB: leer, nur RET)
        CALL    DRVTAB                  ; 0150  cd0037
        LD      HL,MSG_WELCOME          ; 0153  211934
        CALL    PRINT_STR               ; 0156  cde735
L0159:
        LD      SP,STACK_TOP            ; 0159  31ad43
        LD      IX,V_410C               ; 015C  dd210c41
        LD      (IX-1),1                ; 0160  dd36ff01
        LD      (IX),90H                ; 0164  dd360090
        LD      HL,V_41C1               ; 0168  21c141
        SET     0,(HL)                  ; 016B  cbc6
        RES     7,(HL)                  ; 016D  cbbe
        LD      HL,ED_BUF               ; 016F  218a40
        LD      (V_4084),HL             ; 0172  228440
        XOR     A                       ; 0175  af
        LD      H,A                     ; 0176  67
        LD      L,H                     ; 0177  6c
        LD      (ED_RPTR),HL            ; 0178  228840
        LD      (V_4083),A              ; 017B  328340
        LD      (V_418C),HL             ; 017E  228c41
        LD      (V_41B5),HL             ; 0181  22b541
        LD      (V_4192),HL             ; 0184  229241
        LD      (V_4194),HL             ; 0187  229441
        LD      (V_419E),HL             ; 018A  229e41
        LD      (V_4198),HL             ; 018D  229841
        LD      (V_4196),HL             ; 0190  229641
        LD      (V_41A2),HL             ; 0193  22a241
        LD      HL,V_41C2               ; 0196  21c241
        BIT     0,(HL)                  ; 0199  cb46
        RES     0,(HL)                  ; 019B  cb86
        JR      nz,L01D4                ; 019D  2035
        CALL    CON_CR                  ; 019F  cd2f36
        BIT     2,(HL)                  ; 01A2  cb56
        RES     2,(HL)                  ; 01A4  cb96
        JR      z,L01C1                 ; 01A6  2819
        LD      HL,(V_41B9)             ; 01A8  2ab941
        LD      (V_41BB),HL             ; 01AB  22bb41
        PUSH    HL                      ; 01AE  e5
        CALL    L1343                   ; 01AF  cd4313
        POP     HL                      ; 01B2  e1
        LD      (V_418C),HL             ; 01B3  228c41
        CALL    L2272                   ; 01B6  cd7222
        LD      HL,0                    ; 01B9  210000
        LD      (V_418C),HL             ; 01BC  228c41
        JR      L01D4                   ; 01BF  1813
L01C1:
        LD      HL,(V_41BD)             ; 01C1  2abd41
        LD      A,H                     ; 01C4  7c
        OR      L                       ; 01C5  b5
        JR      z,L01D4                 ; 01C6  280c
        LD      IY,V_4204               ; 01C8  fd210442
        CALL    L255D                   ; 01CC  cd5d25
        LD      A,0A0H                  ; 01CF  3ea0
        CALL    CH_OUT                  ; 01D1  cddb34
L01D4:
        CALL    KEY_FLUSH               ; 01D4  cd2836
        CALL    L026B                   ; 01D7  cd6b02
        LD      A,11                    ; 01DA  3e0b
        JP      nz,ERROR                ; 01DC  c25933
        LD      HL,V_41C1               ; 01DF  21c141
        RES     0,(HL)                  ; 01E2  cb86
        LD      HL,(V_418C)             ; 01E4  2a8c41
        LD      A,H                     ; 01E7  7c
        OR      L                       ; 01E8  b5
        LD      IY,(V_41F1)             ; 01E9  fd2af141
        CALL    nz,L255D                ; 01ED  c45d25
        LD      HL,(V_4084)             ; 01F0  2a8440
        CALL    L35DB                   ; 01F3  cddb35
        LD      HL,(V_41B5)             ; 01F6  2ab541
        LD      A,H                     ; 01F9  7c
        OR      L                       ; 01FA  b5
        JR      z,L0202                 ; 01FB  2805
        CALL    L026A                   ; 01FD  cd6a02
        JR      L022C                   ; 0200  182a
L0202:
        LD      HL,(V_418C)             ; 0202  2a8c41
        LD      A,H                     ; 0205  7c
        OR      L                       ; 0206  b5
        JR      nz,L0221                ; 0207  2018
        LD      A,(V_41C1)              ; 0209  3ac141
        BIT     7,A                     ; 020C  cb7f
        LD      A,14                    ; 020E  3e0e
        JP      nz,ERROR                ; 0210  c25933
        LD      HL,V_410B               ; 0213  210b41
        LD      (V_4190),HL             ; 0216  229041
        LD      BC,V_418A               ; 0219  018a41
        CALL    L143A                   ; 021C  cd3a14
        JR      L022C                   ; 021F  180b
L0221:
        LD      HL,(V_41BD)             ; 0221  2abd41
        LD      DE,(V_41BF)             ; 0224  ed5bbf41
        ADD     HL,DE                   ; 0228  19
        LD      (V_41BD),HL             ; 0229  22bd41
L022C:
        CALL    L34B7                   ; 022C  cdb734
        JP      L0159                   ; 022F  c35901
        LD      SP,STACK_TOP            ; 0232  31ad43
        CALL    CH_CRLF                 ; 0235  cdce35
        LD      HL,MSG_RESTART          ; 0238  216b34
        CALL    L35DB                   ; 023B  cddb35
        XOR     A                       ; 023E  af
        LD      (V_41C1),A              ; 023F  32c141
        LD      (V_41C2),A              ; 0242  32c241
        JP      L0159                   ; 0245  c35901

;=====================================================================
; WARMSTART / HAUPTSCHLEIFE (Direktmodus)
; Setzt Flags (41C1H) zurueck, Ausgabekanal auf Konsole (41FBH)
; und wartet auf eine Eingabezeile. ERROR kehrt hierher zurueck.
;=====================================================================
WARMSTART:
        LD      A,(V_41C1)              ; 0248  3ac141
        AND     4                       ; 024B  e604
        LD      (V_41C1),A              ; 024D  32c141
        LD      HL,CHANTAB              ; 0250  21fb41
        LD      (V_41F5),HL             ; 0253  22f541
        JR      L0261                   ; 0256  1809
L0258:
        CALL    CH_NEWLINE              ; 0258  cdc335
        LD      HL,D3489                ; 025B  218934
        CALL    L35DB                   ; 025E  cddb35
L0261:
        LD      HL,0                    ; 0261  210000
        CALL    L2272                   ; 0264  cd7222
        JP      L0159                   ; 0267  c35901
L026A:
        JP      (HL)                    ; 026A  e9
L026B:
        LD      HL,RULE00               ; 026B  214503
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
        LD      A,(V_4000)              ; 0272  3a0040
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
        LD      A,(V_4000)              ; 028C  3a0040
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
        LD      A,(V_4002)              ; 029B  3a0240
        CP      B                       ; 029E  b8
        JR      nz,L02AF                ; 029F  200e
        LD      DE,V_4003               ; 02A1  110340
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
        LD      (V_4000),A              ; 02EB  320040
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
        DW      RULE00                  ; 0307  4503
        DW      RULE02                  ; 0309  ce03
        DW      RULE04                  ; 030B  be04
        DW      RULE06                  ; 030D  0c06
        DW      RULE08                  ; 030F  1b06
        DW      RULE0A                  ; 0311  8707
        DW      RULE0C                  ; 0313  8b08
        DW      RULE0E                  ; 0315  ce0a
        DW      RULE10                  ; 0317  470b
        DW      RULE12                  ; 0319  920b
        DW      RULE14                  ; 031B  210c
        DW      RULE16                  ; 031D  a40c
        DW      RULE18                  ; 031F  e40c
        DW      RULE1A                  ; 0321  fa0c
        DW      RULE1C                  ; 0323  4e0d
        DW      RULE1E                  ; 0325  800d
        DW      RULE20                  ; 0327  f60c
        DW      RULE22                  ; 0329  890d
        DW      RULE24                  ; 032B  170e
        DW      RULE26                  ; 032D  280e
        DW      RULE28                  ; 032F  340e
        DW      RULE2A                  ; 0331  110e
        DW      RULE2C                  ; 0333  400e
        DW      RULE2E                  ; 0335  580e
        DW      RULE30                  ; 0337  d50e
        DW      RULE32                  ; 0339  3307
        DW      RULE34                  ; 033B  2607
        DW      RULE36                  ; 033D  800c
        DW      RULE38                  ; 033F  080d
        DW      RULE3A                  ; 0341  1e09
        DW      RULE3C                  ; 0343  fe09
RULE00:
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
        LD      HL,(ED_RPTR)            ; 037E  2a8840
        LD      A,(HL)                  ; 0381  7e
        CP      20H                     ; 0382  fe20
        JR      nz,L0387                ; 0384  2001
        INC     HL                      ; 0386  23
L0387:
        LD      (V_4084),HL             ; 0387  228440
        LD      HL,(V_4003)             ; 038A  2a0340
        LD      (V_418C),HL             ; 038D  228c41
        RET                             ; 0390  c9
L0391:
        LD      HL,(V_4003)             ; 0391  2a0340
        JP      L221E                   ; 0394  c31e22
L0397:
        LD      HL,V_41C1               ; 0397  21c141
        RES     2,(HL)                  ; 039A  cb96
        LD      HL,(V_4084)             ; 039C  2a8440
        LD      (HL),1EH                ; 039F  361e
        LD      HL,(V_418C)             ; 03A1  2a8c41
        LD      (V_41B9),HL             ; 03A4  22b941
        LD      A,H                     ; 03A7  7c
        OR      L                       ; 03A8  b5
        RET     z                       ; 03A9  c8
        LD      HL,V_41C2               ; 03AA  21c241
        SET     2,(HL)                  ; 03AD  cbd6
        RET                             ; 03AF  c9
L03B0:
        LD      HL,V_41C1               ; 03B0  21c141
        RES     2,(HL)                  ; 03B3  cb96
        LD      HL,(V_418C)             ; 03B5  2a8c41
        LD      DE,(V_41BD)             ; 03B8  ed5bbd41
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
RULE02:
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
        LD      HL,L159A                ; 0432  219a15
        JR      L0466                   ; 0435  182f
S_MEM:
        LD      A,1                     ; 0437  3e01
        JR      L043C                   ; 0439  1801
S_NOMEM:
        XOR     A                       ; 043B  af
L043C:
        LD      (V_41B4),A              ; 043C  32b441
        RET                             ; 043F  c9
S_DELETE:
        LD      HL,L1401                ; 0440  210114
        JR      L046A                   ; 0443  1825
S_BYE:
        LD      HL,L1414                ; 0445  211414
        JR      L046A                   ; 0448  1820
S_LIST:
        LD      HL,L1343                ; 044A  214313
        JR      L0466                   ; 044D  1817
S_NUMBER:
        LD      HL,L13E6                ; 044F  21e613
        JR      L0466                   ; 0452  1812
S_RENUMBER:
        LD      HL,L15C0                ; 0454  21c015
        JR      L046A                   ; 0457  1811
S_RUN:
        LD      HL,L1417                ; 0459  211714
        JR      L046A                   ; 045C  180c
S_LOAD:
        LD      HL,L13D3                ; 045E  21d313
        JR      L046A                   ; 0461  1807
S_SAVE:
        LD      HL,L13B6                ; 0463  21b613
L0466:
        LD      (V_41B5),HL             ; 0466  22b541
        RET                             ; 0469  c9
L046A:
        LD      (V_41B5),HL             ; 046A  22b541
L046D:
        LD      HL,0                    ; 046D  210000
        LD      (V_41BD),HL             ; 0470  22bd41
        LD      (V_41BF),HL             ; 0473  22bf41
        RET                             ; 0476  c9
L0477:
        LD      HL,(V_4003)             ; 0477  2a0340
        JR      L047F                   ; 047A  1803
L047C:
        CALL    L0483                   ; 047C  cd8304
L047F:
        LD      (V_41B9),HL             ; 047F  22b941
        RET                             ; 0482  c9
L0483:
        LD      HL,0                    ; 0483  210000
        JR      L048B                   ; 0486  1803
L0488:
        LD      HL,(V_4003)             ; 0488  2a0340
L048B:
        LD      (V_41BB),HL             ; 048B  22bb41
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
        LD      HL,(V_4003)             ; 04AB  2a0340
        CALL    L221E                   ; 04AE  cd1e22
        LD      A,3CH                   ; 04B1  3e3c
        JP      EMIT_BYTE               ; 04B3  c3bc23
L04B6:
        JP      L23EE                   ; 04B6  c3ee23
L04B9:
        LD      A,3EH                   ; 04B9  3e3e
        JP      EMIT_BYTE               ; 04BB  c3bc23
RULE04:
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
        LD      HL,V_41C1               ; 0556  21c141
        SET     3,(HL)                  ; 0559  cbde
        LD      HL,0                    ; 055B  210000
        JP      L23E0                   ; 055E  c3e023
L0561:
        LD      HL,V_410D               ; 0561  210d41
        INC     (HL)                    ; 0564  34
        JP      L23EE                   ; 0565  c3ee23
L0568:
        LD      IX,V_410C               ; 0568  dd210c41
        RET                             ; 056C  c9
L056D:
        LD      HL,V_41C2               ; 056D  21c241
        SET     5,(HL)                  ; 0570  cbee
        RET                             ; 0572  c9
S_FOR:
        LD      A,80H                   ; 0573  3e80
        CALL    EMIT_BYTE               ; 0575  cdbc23
        LD      (IX+3),0                ; 0578  dd360300
        LD      IX,V_4113               ; 057C  dd211341
        RET                             ; 0580  c9
S_TO:
        CALL    L254E                   ; 0581  cd4e25
        INC     A                       ; 0584  3c
        LD      (V_410F),A              ; 0585  320f41
S_THEN:
        LD      A,0FFH                  ; 0588  3eff
        JP      EMIT_BYTE               ; 058A  c3bc23
S_STEP:
        CALL    S_THEN                  ; 058D  cd8805
        CALL    L254E                   ; 0590  cd4e25
        LD      (V_4110),A              ; 0593  321041
        RET                             ; 0596  c9
L0597:
        CALL    S_THEN                  ; 0597  cd8805
L059A:
        CALL    L2430                   ; 059A  cd3024
        LD      (V_410D),HL             ; 059D  220d41
        JR      L05AD                   ; 05A0  180b
L05A2:
        LD      A,82H                   ; 05A2  3e82
        CALL    L23EB                   ; 05A4  cdeb23
        LD      HL,0                    ; 05A7  210000
        CALL    L23E0                   ; 05AA  cde023
L05AD:
        LD      HL,V_41C1               ; 05AD  21c141
        SET     7,(HL)                  ; 05B0  cbfe
        RET                             ; 05B2  c9
S_ON:
        LD      HL,84H                  ; 05B3  218400
        JP      L23E0                   ; 05B6  c3e023
L05B9:
        LD      HL,V_410D               ; 05B9  210d41
        INC     (HL)                    ; 05BC  34
        LD      HL,0FFFFH               ; 05BD  21ffff
        JP      L23E0                   ; 05C0  c3e023
L05C3:
        LD      A,8AH                   ; 05C3  3e8a
        JR      L05C9                   ; 05C5  1802
L05C7:
        LD      A,8CH                   ; 05C7  3e8c
L05C9:
        LD      (V_410C),A              ; 05C9  320c41
        RET                             ; 05CC  c9
S_IF:
        INC     IX                      ; 05CD  dd23
        INC     IX                      ; 05CF  dd23
        XOR     A                       ; 05D1  af
        JP      EMIT_BYTE               ; 05D2  c3bc23
L05D5:
        LD      A,(V_4001)              ; 05D5  3a0140
        JR      L05DC                   ; 05D8  1802
L05DA:
        LD      A,2                     ; 05DA  3e02
L05DC:
        LD      (V_410D),A              ; 05DC  320d41
        CALL    L05E4                   ; 05DF  cde405
        JR      S_THEN                  ; 05E2  18a4
L05E4:
        CALL    L0D6B                   ; 05E4  cd6b0d
        JP      L2430                   ; 05E7  c33024
L05EA:
        LD      A,(V_4001)              ; 05EA  3a0140
        JR      L05F1                   ; 05ED  1802
L05EF:
        LD      A,2                     ; 05EF  3e02
L05F1:
        LD      (V_410D),A              ; 05F1  320d41
L05F4:
        CALL    L2459                   ; 05F4  cd5924
        JP      L240A                   ; 05F7  c30a24
L05FA:
        LD      A,5                     ; 05FA  3e05
        LD      (V_410D),A              ; 05FC  320d41
        RET                             ; 05FF  c9
L0600:
        LD      A,0                     ; 0600  3e00
        JP      L23EB                   ; 0602  c3eb23
S_ELSE:
        CALL    L254E                   ; 0605  cd4e25
        LD      (V_410E),A              ; 0608  320e41
        RET                             ; 060B  c9
RULE06:
        DB      38H,08H,00H             ; 060C RULE 08
        DB      38H,0AH,00H             ; 060F RULE 0A
        DB      38H,0CH,00H             ; 0612 RULE 0C
        DB      38H,3AH,00H             ; 0615 RULE 3A
        DB      0B8H,3CH,00H            ; 0618 RULE 3C last
RULE08:
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
        LD      HL,V_41C2               ; 06D0  21c241
        RES     3,(HL)                  ; 06D3  cb9e
        RET                             ; 06D5  c9
S_EDIT:
        LD      HL,V_41C2               ; 06D6  21c241
        SET     3,(HL)                  ; 06D9  cbde
        RET                             ; 06DB  c9
L06DC:
        LD      A,76H                   ; 06DC  3e76
        LD      HL,V_41C2               ; 06DE  21c241
        BIT     3,(HL)                  ; 06E1  cb5e
        JR      z,L06C9                 ; 06E3  28e4
        LD      A,7AH                   ; 06E5  3e7a
        JR      L06C9                   ; 06E7  18e0
L06E9:
        LD      A,78H                   ; 06E9  3e78
        LD      HL,V_41C2               ; 06EB  21c241
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
RULE34:
        DB      78H,36H,33H,00H         ; 0726 RULE 36 -> L075B
        DB      0F0H,82H,02H,00H        ; 072A TOK 82 -> L072E last
L072E:
        LD      HL,(V_4003)             ; 072E  2a0340
        JR      L0773                   ; 0731  1840
RULE32:
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
        LD      HL,(V_4003)             ; 075B  2a0340
        CALL    L21FE                   ; 075E  cdfe21
        JR      L077C                   ; 0761  1819
L0763:
        LD      HL,(V_4003)             ; 0763  2a0340
        LD      (V_41C7),HL             ; 0766  22c741
        RET                             ; 0769  c9
L076A:
        JP      L0D28                   ; 076A  c3280d
L076D:
        CALL    L0782                   ; 076D  cd8207
        LD      HL,(V_41C7)             ; 0770  2ac741
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
RULE0A:
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
        LD      HL,V_41C1               ; 0834  21c141
        BIT     5,(HL)                  ; 0837  cb6e
        RES     5,(HL)                  ; 0839  cbae
        JR      z,S_STOP                ; 083B  2807
        LD      IY,(V_41F7)             ; 083D  fd2af741
        CALL    CH_CLOSE                ; 0841  cdab35
S_STOP:
        LD      A,90H                   ; 0844  3e90
        JP      EMIT_BYTE               ; 0846  c3bc23
S_RETURN:
        LD      A,8EH                   ; 0849  3e8e
        CALL    EMIT_BYTE               ; 084B  cdbc23
        JP      L05AD                   ; 084E  c3ad05
L0851:
        LD      HL,(V_4003)             ; 0851  2a0340
        CALL    L2143                   ; 0854  cd4321
        JP      L240A                   ; 0857  c30a24
L085A:
        LD      A,4EH                   ; 085A  3e4e
        JP      L23EB                   ; 085C  c3eb23
L085F:
        LD      HL,0                    ; 085F  210000
        LD      (V_41CE),HL             ; 0862  22ce41
        LD      HL,(V_4003)             ; 0865  2a0340
        LD      (V_41D0),HL             ; 0868  22d041
        LD      A,6                     ; 086B  3e06
        LD      (V_41CB),A              ; 086D  32cb41
        RET                             ; 0870  c9
L0871:
        LD      HL,(V_4003)             ; 0871  2a0340
        LD      (V_41CC),HL             ; 0874  22cc41
        RET                             ; 0877  c9
L0878:
        LD      HL,(V_4003)             ; 0878  2a0340
        LD      (V_41D2),HL             ; 087B  22d241
        LD      HL,V_41CB               ; 087E  21cb41
        LD      BC,9                    ; 0881  010900
        CALL    L20A1                   ; 0884  cda120
        EX      DE,HL                   ; 0887  eb
        JP      L23E0                   ; 0888  c3e023
RULE0C:
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
        LD      HL,(V_4003)             ; 08E2  2a0340
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
        LD      A,(V_4196)              ; 090F  3a9641
        JP      EMIT_BYTE               ; 0912  c3bc23
L0915:
        LD      A,(V_4196)              ; 0915  3a9641
        CALL    L23EB                   ; 0918  cdeb23
        JP      L24B9                   ; 091B  c3b924
RULE3A:
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
        LD      A,(V_4196)              ; 09CB  3a9641
        CALL    L23EB                   ; 09CE  cdeb23
L09D1:
        CALL    L23EE                   ; 09D1  cdee23
L09D4:
        CALL    L23EE                   ; 09D4  cdee23
L09D7:
        JP      L24B9                   ; 09D7  c3b924
L09DA:
        LD      A,(V_4196)              ; 09DA  3a9641
        CALL    L23EB                   ; 09DD  cdeb23
        JR      L09D7                   ; 09E0  18f5
L09E2:
        LD      A,(V_4196)              ; 09E2  3a9641
        CALL    L23EB                   ; 09E5  cdeb23
        JR      L09D4                   ; 09E8  18ea
L09EA:
        LD      A,(V_4196)              ; 09EA  3a9641
        CALL    L23EB                   ; 09ED  cdeb23
        CALL    L23EE                   ; 09F0  cdee23
        JR      L09D1                   ; 09F3  18dc
L09F5:
        LD      A,(V_4196)              ; 09F5  3a9641
        CALL    L23EB                   ; 09F8  cdeb23
        JP      L24B9                   ; 09FB  c3b924
RULE3C:
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
        LD      A,(V_4196)              ; 0AC2  3a9641
        CALL    L23EB                   ; 0AC5  cdeb23
        CALL    L23EE                   ; 0AC8  cdee23
        JP      L09D1                   ; 0ACB  c3d109
RULE0E:
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
        LD      (V_4198),HL             ; 0B06  229841
        CALL    L24A6                   ; 0B09  cda624
        JP      L248D                   ; 0B0C  c38d24
L0B0F:
        XOR     A                       ; 0B0F  af
        CALL    L0B1C                   ; 0B10  cd1c0b
        CALL    L2407                   ; 0B13  cd0724
        JP      L24B9                   ; 0B16  c3b924
L0B19:
        LD      A,(V_4001)              ; 0B19  3a0140
L0B1C:
        CALL    L23FB                   ; 0B1C  cdfb23
        LD      (V_4198),HL             ; 0B1F  229841
L0B22:
        LD      A,(V_4199)              ; 0B22  3a9941
        LD      B,A                     ; 0B25  47
        LD      A,(V_4197)              ; 0B26  3a9741
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
RULE10:
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
RULE12:
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
        LD      HL,(V_4003)             ; 0BDB  2a0340
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
        LD      A,(V_4196)              ; 0C15  3a9641
        CALL    EMIT_BYTE               ; 0C18  cdbc23
L0C1B:
        CALL    L24B9                   ; 0C1B  cdb924
        JP      L2407                   ; 0C1E  c30724
RULE14:
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
        LD      A,(V_4196)              ; 0C68  3a9641
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
RULE36:
        DB      70H,89H,1DH,00H         ; 0C80 TOK 89 -> L0C9F
        DB      0F0H,8EH,02H,00H        ; 0C84 TOK 8E -> L0C88 last
L0C88:
        LD      DE,V_4003               ; 0C88  110340
        CALL    FAC_LOAD                ; 0C8B  cd9f26
        CALL    FP_TO_INT16             ; 0C8E  cdb732
        LD      HL,(FAC)                ; 0C91  2ae242
        LD      (V_4003),HL             ; 0C94  220340
L0C97:
        BIT     7,H                     ; 0C97  cb7c
        RET     z                       ; 0C99  c8
        LD      A,1FH                   ; 0C9A  3e1f
        JP      ERROR                   ; 0C9C  c35933
L0C9F:
        LD      HL,(V_4003)             ; 0C9F  2a0340
        JR      L0C97                   ; 0CA2  18f3
RULE16:
        DB      70H,89H,0AH,00H         ; 0CA4 TOK 89 -> L0CB0
        DB      70H,8EH,1CH,00H         ; 0CA8 TOK 8E -> L0CC6
        DB      0F0H,8AH,18H,00H        ; 0CAC TOK 8A -> L0CC6 last
L0CB0:
        CALL    L0CDC                   ; 0CB0  cddc0c
        JR      z,L0CC2                 ; 0CB3  280d
        LD      DE,(V_4003)             ; 0CB5  ed5b0340
        LD      HL,0                    ; 0CB9  210000
        AND     A                       ; 0CBC  a7
        SBC     HL,DE                   ; 0CBD  ed52
        LD      (V_4003),HL             ; 0CBF  220340
L0CC2:
        LD      A,89H                   ; 0CC2  3e89
        JR      L0CD6                   ; 0CC4  1810
L0CC6:
        CALL    L0CDC                   ; 0CC6  cddc0c
        JR      z,L0CD4                 ; 0CC9  2809
        LD      HL,V_4006               ; 0CCB  210640
        BIT     6,(HL)                  ; 0CCE  cb76
        JR      z,L0CD4                 ; 0CD0  2802
        SET     7,(HL)                  ; 0CD2  cbfe
L0CD4:
        LD      A,8AH                   ; 0CD4  3e8a
L0CD6:
        CALL    L2185                   ; 0CD6  cd8521
        JP      L240A                   ; 0CD9  c30a24
L0CDC:
        LD      HL,V_41C2               ; 0CDC  21c241
        BIT     5,(HL)                  ; 0CDF  cb6e
        RES     5,(HL)                  ; 0CE1  cbae
        RET                             ; 0CE3  c9
RULE18:
        DB      70H,81H,06H,00H         ; 0CE4 TOK 81 -> L0CEC
        DB      0F0H,82H,02H,00H        ; 0CE8 TOK 82 -> L0CEC last
L0CEC:
        LD      HL,(V_4003)             ; 0CEC  2a0340
L0CEF:
        CALL    L2143                   ; 0CEF  cd4321
        EX      DE,HL                   ; 0CF2  eb
        JP      L240A                   ; 0CF3  c30a24
RULE20:
        DB      0F0H,83H,1FH,08H        ; 0CF6 TOK 83 -> L0D17 next 0D01 last
RULE1A:
        DB      70H,81H,1BH,04H         ; 0CFA TOK 81 -> L0D17 next 0D01
        DB      0D0H,82H,17H            ; 0CFE TOK 82 -> L0D17 last
        DB      70H,41H,1BH,04H         ; 0D01 TOK 41 -> L0D1E next 0D08
        DB      0E0H,22H,00H            ; 0D05 EPS -> L0D28 last
RULE38:
        DB      98H,0EH                 ; 0D08 RULE 0E last
        DB      70H,42H,24H,00H         ; 0D0A TOK 42 -> L0D30
        DB      0D0H,45H,1DH            ; 0D0E TOK 45 -> L0D2D last
        DB      98H,0EH                 ; 0D11 RULE 0E last
        DB      0F0H,42H,32H,00H        ; 0D13 TOK 42 -> L0D47 last
L0D17:
        LD      HL,(V_4003)             ; 0D17  2a0340
        LD      (V_41C7),HL             ; 0D1A  22c741
        RET                             ; 0D1D  c9
L0D1E:
        CALL    L0B03                   ; 0D1E  cd030b
        LD      HL,(V_41C7)             ; 0D21  2ac741
        SET     4,L                     ; 0D24  cbe5
        JR      L0CEF                   ; 0D26  18c7
L0D28:
        LD      HL,(V_41C7)             ; 0D28  2ac741
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
RULE1C:
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
        LD      HL,D34A5                ; 0D6B  21a534
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
RULE1E:
        DB      0F0H,8BH,02H,00H        ; 0D80 TOK 8B -> L0D84 last
L0D84:
        LD      A,8BH                   ; 0D84  3e8b
        JP      L0CD6                   ; 0D86  c3d60c
RULE22:
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
        LD      A,(V_4196)              ; 0DE5  3a9641
        CALL    L23EB                   ; 0DE8  cdeb23
L0DEB:
        CALL    L24B9                   ; 0DEB  cdb924
L0DEE:
        LD      HL,(V_4192)             ; 0DEE  2a9241
        LD      DE,D34A5                ; 0DF1  11a534
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
        LD      A,(V_4196)              ; 0E09  3a9641
        CALL    EMIT_BYTE               ; 0E0C  cdbc23
        JR      L0DEB                   ; 0E0F  18da
RULE2A:
        DB      38H,26H,00H             ; 0E11 RULE 26
        DB      38H,28H,00H             ; 0E14 RULE 28
RULE24:
        DB      0F0H,85H,02H,00H        ; 0E17 TOK 85 -> L0E1B last
L0E1B:
        LD      HL,(V_4003)             ; 0E1B  2a0340
        CALL    L2143                   ; 0E1E  cd4321
        LD      HL,4                    ; 0E21  210400
        ADD     HL,DE                   ; 0E24  19
        JP      L23E0                   ; 0E25  c3e023
RULE26:
        DB      6AH,44H,41H,49H,5AH,00H ; 0E28 KW "DAI" -> S_DAI
        DB      0EAH,43H,4FH,49H,59H,00H ; 0E2E KW "COI" -> S_COI last
RULE28:
        DB      6AH,44H,41H,4FH,58H,00H ; 0E34 KW "DAO" -> S_DAO
        DB      0EAH,43H,4FH,4FH,57H,00H ; 0E3A KW "COO" -> S_COO last
RULE2C:
        DB      6AH,52H,53H,49H,6FH,00H ; 0E40 KW "RSI" -> S_RSI
        DB      6AH,4DH,54H,52H,5BH,33H ; 0E46 KW "MTR" -> S_MTR next 0E7E
        DB      6AH,46H,44H,52H,4BH,2DH ; 0E4C KW "FDR" -> S_FDR next 0E7E
        DB      0EAH,4BH,45H,59H,59H,00H ; 0E52 KW "KEY" -> S_KEY last
RULE2E:
        DB      6AH,52H,53H,4FH,64H,00H ; 0E58 KW "RSO" -> S_RSO
        DB      6AH,4DH,54H,57H,48H,1BH ; 0E5E KW "MTW" -> S_MTW next 0E7E
        DB      6AH,46H,44H,57H,38H,15H ; 0E64 KW "FDW" -> S_FDW next 0E7E
        DB      6AH,4CH,50H,52H,56H,00H ; 0E6A KW "LPR" -> S_LPR
        DB      6CH,44H,55H,4DH,4DH,59H,41H,00H ; 0E70 KW "DUMMY" -> S_DUMMY
        DB      0EAH,53H,43H,52H,40H,00H ; 0E78 KW "SCR" -> S_SCR last
        DB      78H,1EH,52H,00H         ; 0E7E RULE 1E -> L0ED2
        DB      0F0H,83H,4BH,00H        ; 0E82 TOK 83 -> L0ECF last
S_DAI:
        LD      HL,V_41F7               ; 0E86  21f741
        JR      L0E98                   ; 0E89  180d
S_COI:
        LD      HL,V_41F5               ; 0E8B  21f541
        JR      L0E98                   ; 0E8E  1808
S_DAO:
        LD      HL,V_41F3               ; 0E90  21f341
        JR      L0E98                   ; 0E93  1803
S_COO:
        LD      HL,V_41F1               ; 0E95  21f141
L0E98:
        JP      L23E0                   ; 0E98  c3e023
S_FDR:
        LD      HL,DEV_FDR              ; 0E9B  214c37
        JR      L0ECC                   ; 0E9E  182c
S_FDW:
        LD      HL,DEV_FDW              ; 0EA0  215537
        JR      L0ECC                   ; 0EA3  1827
S_MTR:
        LD      HL,DEV_MTR              ; 0EA5  213a37
        JR      L0ECC                   ; 0EA8  1822
S_MTW:
        LD      HL,DEV_MTW              ; 0EAA  214337
        JR      L0ECC                   ; 0EAD  181d
S_KEY:
        LD      L,0                     ; 0EAF  2e00
        JR      L0EC6                   ; 0EB1  1813
S_RSI:
        LD      L,24H                   ; 0EB3  2e24
        JR      L0EC6                   ; 0EB5  180f
S_DUMMY:
        LD      HL,D34AC                ; 0EB7  21ac34
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
        LD      DE,CHANTAB              ; 0EC8  11fb41
        ADD     HL,DE                   ; 0ECB  19
L0ECC:
        JP      L23E0                   ; 0ECC  c3e023
L0ECF:
        CALL    L0CEC                   ; 0ECF  cdec0c
L0ED2:
        JP      L23EE                   ; 0ED2  c3ee23
RULE30:
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
        LD      (V_41C3),HL             ; 0F42  22c341
        JP      EMIT_BYTE               ; 0F45  c3bc23
L0F48:
        LD      HL,2001H                ; 0F48  210120
        JR      L0F50                   ; 0F4B  1803
L0F4D:
        LD      HL,(V_41C3)             ; 0F4D  2ac341
L0F50:
        LD      A,(V_4004)              ; 0F50  3a0440
        AND     A                       ; 0F53  a7
        JR      z,L0F5B                 ; 0F54  2805
L0F56:
        LD      A,27H                   ; 0F56  3e27
        JP      ERROR                   ; 0F58  c35933
L0F5B:
        LD      A,(V_4003)              ; 0F5B  3a0340
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
        LD      (V_4000),A              ; 0F71  320040
        LD      (V_4001),A              ; 0F74  320140
        LD      (V_4002),A              ; 0F77  320240
L0F7A:
        CALL    L11F8                   ; 0F7A  cdf811
        LD      (V_4003),A              ; 0F7D  320340
        LD      A,B                     ; 0F80  78
        OR      A                       ; 0F81  b7
        JR      z,L0F7A                 ; 0F82  28f6
        SUB     20H                     ; 0F84  d620
        JR      c,L0FE7                 ; 0F86  385f
        CP      10                      ; 0F88  fe0a
        JR      nc,L0F99                ; 0F8A  300d
        LD      HL,D101E                ; 0F8C  211e10
        ADD     A,L                     ; 0F8F  85
        LD      L,A                     ; 0F90  6f
        JR      nc,L0F94                ; 0F91  3001
        INC     H                       ; 0F93  24
L0F94:
        LD      A,(HL)                  ; 0F94  7e
        LD      (V_4000),A              ; 0F95  320040
        RET                             ; 0F98  c9
L0F99:
        SUB     20H                     ; 0F99  d620
        JR      c,L0FE7                 ; 0F9B  384a
        CP      11                      ; 0F9D  fe0b
        JR      nc,L0FE7                ; 0F9F  3046
        LD      HL,D1028                ; 0FA1  212810
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
        LD      A,(V_4003)              ; 0FAE  3a0340
        LD      IX,V_4003               ; 0FB1  dd210340
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
        LD      A,(V_4002)              ; 0FF3  3a0240
        INC     A                       ; 0FF6  3c
        LD      (V_4002),A              ; 0FF7  320240
L0FFA:
        LD      (IX),0                  ; 0FFA  dd360000
        RRC     C                       ; 0FFE  cb09
        JR      nc,L1007                ; 1000  3005
        LD      A,(HL)                  ; 1002  7e
        INC     HL                      ; 1003  23
        LD      (V_4001),A              ; 1004  320140
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
D101E:
        DB      47H,41H,42H,45H,46H,62H,43H,44H ; 101E GABEFbCD
        DB      48H,49H                 ; 1026 HI
D1028:
        DW      D103E                   ; 1028  3e10
        DW      D106F                   ; 102A  6f10
        DW      D1066                   ; 102C  6610
        DW      D1069                   ; 102E  6910
        DW      D109E                   ; 1030  9e10
        DW      D106C                   ; 1032  6c10
        DW      D10D5                   ; 1034  d510
        DW      D107F                   ; 1036  7f10
        DW      D1089                   ; 1038  8910
        DW      D1167                   ; 103A  6711
        DW      D1094                   ; 103C  9410
D103E:
        DB      02H                     ; 103E SCAN jedes
        DB      40H,0C0H,07H            ; 103F SCAN '@' weiter 1048
        DB      30H,0A0H,09H            ; 1042 SCAN ' ' -> L104D ende
        DB      0D6H,0EH,0F8H           ; 1045 SCAN jedes -> L1054 weiter 103F last
        DB      44H,0C0H,0F5H           ; 1048 SCAN '@' weiter 103F
        DB      0B3H,04H                ; 104B SCAN jedes -> L1050 ende last
L104D:
        JP      L0FE7                   ; 104D  c3e70f
L1050:
        LD      A,8BH                   ; 1050  3e8b
        JR      L109A                   ; 1052  1846
L1054:
        LD      A,(V_41C2)              ; 1054  3ac241
        BIT     4,A                     ; 1057  cb67
        RET     z                       ; 1059  c8
        LD      A,20H                   ; 105A  3e20
        LD      HL,(ED_RPTR)            ; 105C  2a8840
        DEC     HL                      ; 105F  2b
        ADD     A,(HL)                  ; 1060  86
        LD      (HL),A                  ; 1061  77
        LD      (IX-1),A                ; 1062  dd77ff
        RET                             ; 1065  c9
D1066:
        DB      0BEH,2CH,0EH            ; 1066 SCAN jedes =2C -> L1076 ende last
D1069:
        DB      0BEH,20H,0BH            ; 1069 SCAN jedes =20 -> L1076 ende last
D106C:
        DB      0BEH,44H,08H            ; 106C SCAN jedes =44 -> L1076 ende last
D106F:
        DB      1EH,4EH,05H             ; 106F SCAN jedes =4E -> L1076
        DB      2CH,2AH,68H             ; 1072 SCAN '*' =68 ende
        DB      0A3H                    ; 1075 SCAN jedes ende last
L1076:
        LD      A,1                     ; 1076  3e01
        LD      (V_4002),A              ; 1078  320240
        LD      A,61H                   ; 107B  3e61
        JR      L109A                   ; 107D  181b
D107F:
        DB      1AH,04H,0FH             ; 107F SCAN jedes =04 -> L1090
        DB      28H,3EH,05H             ; 1082 SCAN '>' =05 ende
        DB      28H,3DH,06H             ; 1085 SCAN '=' =06 ende
        DB      0A3H                    ; 1088 SCAN jedes ende last
D1089:
        DB      1AH,01H,05H             ; 1089 SCAN jedes =01 -> L1090
        DB      28H,3DH,03H             ; 108C SCAN '=' =03 ende
        DB      0A3H                    ; 108F SCAN jedes ende last
L1090:
        LD      A,63H                   ; 1090  3e63
        JR      L109A                   ; 1092  1806
D1094:
        DB      02H                     ; 1094 SCAN jedes
        DB      0B0H,21H,01H            ; 1095 SCAN '!' -> L1098 ende last
L1098:
        LD      A,64H                   ; 1098  3e64
L109A:
        LD      (V_4000),A              ; 109A  320040
        RET                             ; 109D  c9
D109E:
        DB      06H                     ; 109E SCAN jedes
        DB      40H,4EH,0FH             ; 109F SCAN 'N' weiter 10B0
        DB      48H,41H,90H,18H         ; 10A2 SCAN 'A' =90 weiter 10BD
        DB      48H,4FH,92H,1CH         ; 10A6 SCAN 'O' =92 weiter 10C5
        DB      40H,58H,16H             ; 10AA SCAN 'X' weiter 10C2
        DB      0C4H,0C6H,37H           ; 10AD SCAN 'F' weiter 10E6 last
        DB      48H,41H,94H,0AH         ; 10B0 SCAN 'A' =94 weiter 10BD
        DB      80H,4FH                 ; 10B4 SCAN 'O' last
        DB      40H,54H,12H             ; 10B6 SCAN 'T' weiter 10CA
        DB      0C8H,52H,96H,0BH        ; 10B9 SCAN 'R' =96 weiter 10C7 last
        DB      80H,4EH                 ; 10BD SCAN 'N' last
        DB      0C0H,44H,06H            ; 10BF SCAN 'D' weiter 10C7 last
        DB      88H,4FH,98H             ; 10C2 SCAN 'O' =98 last
        DB      80H,52H                 ; 10C5 SCAN 'R' last
        DB      0B0H,2EH,08H            ; 10C7 SCAN '.' -> L10D1 ende last
        DB      0B0H,2EH,01H            ; 10CA SCAN '.' -> L10CD ende last
L10CD:
        LD      A,65H                   ; 10CD  3e65
        JR      L109A                   ; 10CF  18c9
L10D1:
        LD      A,66H                   ; 10D1  3e66
        JR      L109A                   ; 10D3  18c5
D10D5:
        DB      06H                     ; 10D5 SCAN jedes
        DB      44H,0C6H,0FEH           ; 10D6 SCAN 'F' weiter 10D6
        DB      44H,2EH,09H             ; 10D9 SCAN '.' weiter 10E4
        DB      44H,45H,10H             ; 10DC SCAN 'E' weiter 10EE
        DB      34H,25H,19H             ; 10DF SCAN '%' -> L10FA ende
        DB      0B3H,22H                ; 10E2 SCAN jedes -> L1105 ende last
        DB      84H,0C6H                ; 10E4 SCAN 'F' last
        DB      44H,0C6H,0FEH           ; 10E6 SCAN 'F' weiter 10E6
        DB      44H,45H,03H             ; 10E9 SCAN 'E' weiter 10EE
        DB      0B3H,24H                ; 10EC SCAN jedes -> L1111 ende last
        DB      44H,2BH,03H             ; 10EE SCAN '+' weiter 10F3
        DB      04H,2DH                 ; 10F1 SCAN '-'
        DB      84H,0C6H                ; 10F3 SCAN 'F' last
        DB      34H,0C6H,1AH            ; 10F5 SCAN 'F' -> L1111 ende
        DB      0B3H,18H                ; 10F8 SCAN jedes -> L1111 ende last
L10FA:
        CALL    L2DC7                   ; 10FA  cdc72d
        JP      c,L0FE7                 ; 10FD  dae70f
        LD      A,89H                   ; 1100  3e89
        JP      L1158                   ; 1102  c35811
L1105:
        CALL    L111B                   ; 1105  cd1b11
        CALL    L2694                   ; 1108  cd9426
        JR      c,L1114                 ; 110B  3807
        LD      A,8EH                   ; 110D  3e8e
        JR      L1116                   ; 110F  1805
L1111:
        CALL    L111B                   ; 1111  cd1b11
L1114:
        LD      A,8AH                   ; 1114  3e8a
L1116:
        LD      C,5                     ; 1116  0e05
        JP      L115F                   ; 1118  c35f11
L111B:
        LD      DE,V_4003               ; 111B  110340
        CALL    FP_PARSE_DECIMAL        ; 111E  cd1b2e
        LD      DE,V_4003               ; 1121  110340
        JP      FAC_STORE               ; 1124  c3ae26
        DB      40H,27H,03H             ; 1127 SCAN "'" weiter 112C
        DB      0C3H,43H                ; 112A SCAN jedes weiter 116E last
        DB      44H,30H,0FEH            ; 112C SCAN '0' weiter 112C
        DB      44H,31H,0FBH            ; 112F SCAN '1' weiter 112C
        DB      0B3H,22H                ; 1132 SCAN jedes -> L1155 ende last
        DB      40H,27H,03H             ; 1134 SCAN "'" weiter 1139
        DB      0C3H,36H                ; 1137 SCAN jedes weiter 116E last
        DB      44H,0C6H,0FEH           ; 1139 SCAN 'F' weiter 1139
        DB      44H,41H,0FBH            ; 113C SCAN 'A' weiter 1139
        DB      44H,42H,0F8H            ; 113F SCAN 'B' weiter 1139
        DB      44H,43H,0F5H            ; 1142 SCAN 'C' weiter 1139
        DB      44H,44H,0F2H            ; 1145 SCAN 'D' weiter 1139
        DB      44H,45H,0EFH            ; 1148 SCAN 'E' weiter 1139
        DB      44H,46H,0ECH            ; 114B SCAN 'F' weiter 1139
        DB      0B3H,01H                ; 114E SCAN jedes -> L1150 ende last
L1150:
        CALL    L2D99                   ; 1150  cd992d
        JR      L1158                   ; 1153  1803
L1155:
        CALL    L2D82                   ; 1155  cd822d
L1158:
        LD      (V_4003),HL             ; 1158  220340
        LD      A,89H                   ; 115B  3e89
        LD      C,2                     ; 115D  0e02
L115F:
        LD      (V_4000),A              ; 115F  320040
        LD      A,C                     ; 1162  79
        LD      (V_4002),A              ; 1163  320240
        RET                             ; 1166  c9
D1167:
        DB      44H,48H,0CBH            ; 1167 SCAN 'H' weiter 1134
        DB      44H,42H,0BBH            ; 116A SCAN 'B' weiter 1127
        DB      86H                     ; 116D SCAN jedes last
        DB      44H,0C9H,0FEH           ; 116E SCAN 'I' weiter 116E
        DB      44H,0C6H,0FBH           ; 1171 SCAN 'F' weiter 116E
        DB      30H,25H,0CH             ; 1174 SCAN '%' -> L1182 ende
        DB      30H,24H,0DH             ; 1177 SCAN '$' -> L1186 ende
        DB      30H,26H,0EH             ; 117A SCAN '&' -> L118A ende
        DB      30H,3AH,0FH             ; 117D SCAN ':' -> L118E ende
        DB      0B3H,1AH                ; 1180 SCAN jedes -> L119B ende last
L1182:
        LD      B,81H                   ; 1182  0681
        JR      L1190                   ; 1184  180a
L1186:
        LD      B,83H                   ; 1186  0683
        JR      L1190                   ; 1188  1806
L118A:
        LD      B,85H                   ; 118A  0685
        JR      L1190                   ; 118C  1802
L118E:
        LD      B,84H                   ; 118E  0684
L1190:
        LD      A,(V_4002)              ; 1190  3a0240
        CP      3                       ; 1193  fe03
        LD      A,B                     ; 1195  78
        JR      c,L11EB                 ; 1196  3853
        JP      L0FE7                   ; 1198  c3e70f
L119B:
        LD      A,(V_4002)              ; 119B  3a0240
        CP      2                       ; 119E  fe02
        JR      c,L11D4                 ; 11A0  3832
        LD      DE,(V_4003)             ; 11A2  ed5b0340
        JR      nz,L11D8                ; 11A6  2030
        LD      HL,4649H                ; 11A8  214946
        SBC     HL,DE                   ; 11AB  ed52
        JR      z,L11CF                 ; 11AD  2820
        LD      HL,4E4FH                ; 11AF  214f4e
        AND     A                       ; 11B2  a7
        SBC     HL,DE                   ; 11B3  ed52
        JR      z,L11CF                 ; 11B5  2818
        LD      HL,4F54H                ; 11B7  21544f
        AND     A                       ; 11BA  a7
        SBC     HL,DE                   ; 11BB  ed52
        JR      z,L11CF                 ; 11BD  2810
        LD      HL,4E49H                ; 11BF  21494e
        AND     A                       ; 11C2  a7
        SBC     HL,DE                   ; 11C3  ed52
        JR      z,L11CF                 ; 11C5  2808
        LD      HL,5441H                ; 11C7  214154
        AND     A                       ; 11CA  a7
        SBC     HL,DE                   ; 11CB  ed52
        JR      nz,L11D4                ; 11CD  2005
L11CF:
        LD      A,20H                   ; 11CF  3e20
        JP      L109A                   ; 11D1  c39a10
L11D4:
        LD      A,82H                   ; 11D4  3e82
        JR      L11EB                   ; 11D6  1813
L11D8:
        CP      5                       ; 11D8  fe05
        JR      nc,L11CF                ; 11DA  30f3
        LD      HL,4E46H                ; 11DC  21464e
        AND     A                       ; 11DF  a7
        SBC     HL,DE                   ; 11E0  ed52
        JR      nz,L11CF                ; 11E2  20eb
        LD      A,86H                   ; 11E4  3e86
        LD      HL,(V_4005)             ; 11E6  2a0540
        JR      L11EE                   ; 11E9  1803
L11EB:
        LD      HL,(V_4003)             ; 11EB  2a0340
L11EE:
        LD      (V_4000),A              ; 11EE  320040
        CALL    L216F                   ; 11F1  cd6f21
        LD      (V_4003),HL             ; 11F4  220340
        RET                             ; 11F7  c9
L11F8:
        PUSH    HL                      ; 11F8  e5
        CALL    L3645                   ; 11F9  cd4536
        AND     7FH                     ; 11FC  e67f
        LD      HL,V_41C2               ; 11FE  21c241
        RES     4,(HL)                  ; 1201  cba6
        CP      61H                     ; 1203  fe61
        JR      c,L120F                 ; 1205  3808
        CP      7BH                     ; 1207  fe7b
        JR      nc,L120F                ; 1209  3004
        SET     4,(HL)                  ; 120B  cbe6
        SUB     20H                     ; 120D  d620
L120F:
        LD      HL,(ED_RPTR)            ; 120F  2a8840
        LD      C,A                     ; 1212  4f
        LD      A,H                     ; 1213  7c
        OR      L                       ; 1214  b5
        JR      nz,L121A                ; 1215  2003
        LD      HL,ED_BUF               ; 1217  218a40
L121A:
        LD      (HL),C                  ; 121A  71
        INC     HL                      ; 121B  23
        LD      (ED_RPTR),HL            ; 121C  228840
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
        LD      HL,D124B                ; 123B  214b12
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
D124B:
        DB      00H,4AH,40H,28H,03H,04H,05H,40H ; 124B .J@(...@
        DB      21H,22H,41H,42H,23H,43H,44H,45H ; 1253 !"AB#CDE
        DB      46H,46H,46H,46H,46H,46H,46H,46H ; 125B FFFFFFFF
        DB      46H,46H,29H,24H,47H,25H,48H,07H ; 1263 FF)$G%H.
        DB      08H,26H,09H,27H,0AH,0BH ; 126B .&.'..
