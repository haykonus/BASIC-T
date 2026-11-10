; core_lines.inc - Zeilenverwaltung, Fehlerbehandlung, Meldungen
; Teil von basict.asm (per INCLUDE), nicht einzeln assemblierbar.

;=====================================================================
; PROGRAMMZEILEN-VERWALTUNG
; Zeilen bilden eine verkettete Liste; 419AH = aktuelle Zeile.
; LINE_NEXT: zur folgenden Zeile weiterschalten.
;=====================================================================
LINE_NEXT:
        LD      HL,(V_419A)             ; 331F  2a9a41
        LD      A,(HL)                  ; 3322  7e
        INC     HL                      ; 3323  23
        LD      H,(HL)                  ; 3324  66
        LD      L,A                     ; 3325  6f
; ---- LINE_SET: HL als aktuelle Zeile setzen, Zeilennummer nach DE
LINE_SET:
        LD      (V_419A),HL             ; 3326  229a41
        LD      E,(HL)                  ; 3329  5e
        INC     HL                      ; 332A  23
        LD      D,(HL)                  ; 332B  56
        DEC     HL                      ; 332C  2b
        LD      A,D                     ; 332D  7a
        OR      E                       ; 332E  b3
        EX      DE,HL                   ; 332F  eb
        RET                             ; 3330  c9
L3331:
        LD      DE,(V_419A)             ; 3331  ed5b9a41
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
        LD      HL,(V_419A)             ; 3353  2a9a41
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
        LD      (V_41E3),A              ; 335E  32e341
        LD      HL,(V_41DA)             ; 3361  2ada41
        LD      (V_41E1),HL             ; 3364  22e141
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
        LD      HL,V_41C1               ; 3383  21c141
        BIT     0,(HL)                  ; 3386  cb46
        CALL    nz,L3390                ; 3388  c49033
        POP     AF                      ; 338B  f1
        RET     nz                      ; 338C  c0
        JP      WARMSTART               ; 338D  c34802
L3390:
        LD      A,(V_41E3)              ; 3390  3ae341
        AND     7FH                     ; 3393  e67f
        CP      64H                     ; 3395  fe64
        RET     nc                      ; 3397  d0
        LD      HL,(ED_RPTR)            ; 3398  2a8840
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
        LD      DE,ED_BUF               ; 33A8  118a40
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
        LD      HL,V_41C2               ; 33D0  21c241
        SET     0,(HL)                  ; 33D3  cbc6
        LD      HL,ED_BUF               ; 33D5  218a40
        LD      DE,V_4003               ; 33D8  110340
        LD      BC,7EH                  ; 33DB  017e00
        LDIR                            ; 33DE  edb0
        CALL    CON_CR                  ; 33E0  cd2f36
        LD      HL,V_4003               ; 33E3  210340
        LD      B,7EH                   ; 33E6  067e
L33E8:
        LD      A,(HL)                  ; 33E8  7e
        INC     HL                      ; 33E9  23
        CP      1EH                     ; 33EA  fe1e
        JR      z,L33F3                 ; 33EC  2805
        CALL    CH_OUT                  ; 33EE  cddb34
        DJNZ    L33E8                   ; 33F1  10f5
L33F3:
        LD      HL,V_41A6               ; 33F3  21a641
        CALL    L3402                   ; 33F6  cd0234
        LD      HL,V_41A8               ; 33F9  21a841
        CALL    L3402                   ; 33FC  cd0234
        LD      HL,V_41AA               ; 33FF  21aa41
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
        DB      42H,41H,53H,49H,43H,1EH ; 3473 BASIC.
D3479:
        DB      05H                     ; 3479 .
MSG_BREAK:
        DB      42H,52H,45H,41H,4BH     ; 347A BREAK
D347F:
        DB      09H                     ; 347F .
MSG_ATLINE:
        DB      20H,41H,54H,20H,4CH,49H,4EH,45H ; 3480  AT LINE
        DB      3AH                     ; 3488 :
D3489:
        DB      52H,45H,41H,44H,59H,1EH ; 3489 READY.
MSG_ERROR:
        DB      05H,45H,52H,52H,4FH,52H ; 348F .ERROR
MSG_WARNING:
        DB      07H,57H,41H,52H,4EH,49H,4EH,47H ; 3495 .WARNING
D349D:
        DB      45H,4EH,44H,1EH         ; 349D END.
D34A1:
        DB      01H,00H,89H,00H         ; 34A1 ....
D34A5:
        DW      D34A1                   ; 34A5  a134
        DB      83H,00H,02H,40H,00H     ; 34A7 ...@.
D34AC:
        DB      43H                     ; 34AC C
        DW      D34B5                   ; 34AD  b534
        DB      0FFH,0FFH,00H,00H,00H,00H ; 34AF ......
D34B5:
        DB      0A7H,0C9H               ; 34B5 ..
L34B7:
        CALL    KEY_CHECK               ; 34B7  cd6d35
        CP      57H                     ; 34BA  fe57
        JR      z,L34D3                 ; 34BC  2815
        CP      42H                     ; 34BE  fe42
        LD      (V_41E4),A              ; 34C0  32e441
        RET     nz                      ; 34C3  c0
        CALL    CH_NEWLINE              ; 34C4  cdc335
        LD      HL,D3479                ; 34C7  217934
        CALL    PRINT_STR               ; 34CA  cde735
        CALL    L257E                   ; 34CD  cd7e25
        JP      WARMSTART               ; 34D0  c34802
L34D3:
        CALL    KEY_CHECK               ; 34D3  cd6d35
        CP      43H                     ; 34D6  fe43
        JR      nz,L34D3                ; 34D8  20f9
        RET                             ; 34DA  c9
