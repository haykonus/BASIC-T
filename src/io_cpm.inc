; io_cpm.inc - CP/M-Treiber Konsole/Drucker, DRVTAB: bei Portierung anpassen
; Teil von basict.asm (per INCLUDE), nicht einzeln assemblierbar.

;=====================================================================
; PHYSISCHE TREIBER FUER CP/M (bei Portierung hier anpassen)
; PRNOUT: Drucker (DEV_PRN), 1EH wird zu CR+LF, Ausgabe ueber BDOS 5.
; Alle BDOS-Aufrufe: CALL 0005H, Funktion in C, Parameter in E bzw. DE.
;=====================================================================
PRNOUT:
        CP      1EH                     ; 36B6  fe1e
        JR      nz,PRN_CHAR             ; 36B8  2007
        LD      A,13                    ; 36BA  3e0d
        CALL    PRN_CHAR                ; 36BC  cdc136
        LD      A,10                    ; 36BF  3e0a
PRN_CHAR:
        PUSH    BC                      ; 36C1  c5
        PUSH    DE                      ; 36C2  d5
        PUSH    HL                      ; 36C3  e5
        PUSH    AF                      ; 36C4  f5
        LD      E,A                     ; 36C5  5f
        LD      C,5                     ; 36C6  0e05
        CALL    BDOS                    ; 36C8  cd0500  BDOS 5: Drucker
        POP     AF                      ; 36CB  f1
        OR      A                       ; 36CC  b7
        JR      L36E6                   ; 36CD  1817
; ---- CON_CLS: OPEN-Routine der Konsole, sendet 0CH (Bildschirm loeschen)
CON_CLS:
        LD      A,12                    ; 36CF  3e0c
; ---- CON_DRV: E/A-Routine der Konsole (DEV_CON): 1EH -> CR+LF, sonst CONOUT
CON_DRV:
        CP      1EH                     ; 36D1  fe1e
        JR      z,CON_CRLF              ; 36D3  2822
        OR      A                       ; 36D5  b7
        JR      CONOUT                  ; 36D6  1810

;=====================================================================
; CONIN: auf Taste warten, Zeichen in A (ohne Echo)
; BDOS 6 mit E=0FFH liest direkt; CP/M filtert so weder ^C noch ^S,
; und der eigene Zeileneditor (ED_LINE) kann alle Steuertasten nutzen.
;=====================================================================
CONIN:
        PUSH    BC                      ; 36D8  c5
        PUSH    DE                      ; 36D9  d5
        PUSH    HL                      ; 36DA  e5
L36DB:
        LD      E,0FFH                  ; 36DB  1eff
        LD      C,6                     ; 36DD  0e06
        CALL    BDOS                    ; 36DF  cd0500  BDOS 6: Konsole direkt
        CP      0                       ; 36E2  fe00
        JR      z,L36DB                 ; 36E4  28f5
L36E6:
        JR      L36F3                   ; 36E6  180b
; ---- CONOUT: Zeichen A ueber BDOS 2 ausgeben, alle Register erhalten
CONOUT:
        PUSH    BC                      ; 36E8  c5
        PUSH    DE                      ; 36E9  d5
        PUSH    HL                      ; 36EA  e5
        PUSH    AF                      ; 36EB  f5
        LD      E,A                     ; 36EC  5f
        LD      C,2                     ; 36ED  0e02
        CALL    BDOS                    ; 36EF  cd0500  BDOS 2: Konsole schreiben
        POP     AF                      ; 36F2  f1
L36F3:
        POP     HL                      ; 36F3  e1
        POP     DE                      ; 36F4  d1
        POP     BC                      ; 36F5  c1
        RET                             ; 36F6  c9
; ---- CON_CRLF: CR und LF auf die Konsole
CON_CRLF:
        LD      A,13                    ; 36F7  3e0d
        CALL    CONOUT                  ; 36F9  cde836
        LD      A,10                    ; 36FC  3e0a
        JR      CONOUT                  ; 36FE  18e8

;=====================================================================
; DRVTAB: TREIBER-HAKEN UND KANALBLOECKE
; 3700H-3702H frei, DRV_DUMMY ist nur RET (Leer-Treiber; PLOT und die
; meisten Grafik-Unterfunktionen zeigen dorthin). Danach die Kanalbloecke:
;   DEV_KBD  Tastatur ueber Zeileneditor   DEV_EDW  Vorgabe in Editorpuffer
;   DEV_CON  Bildschirm                    DEV_NULO/NULI  Leergeraete
;   DEV_PRN  Drucker, 80 Spalten           DEV_MTR/MTW  Textdatei lesen/schreiben
;   DEV_FDR/FDW  Datei binaer (GBA) lesen/schreiben
;=====================================================================
DRVTAB:
        DB      00H,00H,00H             ; 3700 ...
DRV_DUMMY:
        DB      0C9H                    ; 3703 .
DEV_KBD:
        DB      44H                     ; 3704 +0 Flags
        DW      KBD_GET                 ; 3705  af37  +1 E/A-Routine
        DW      0000H                   ; 3707  0000  +3 Restspalten, +4 Zeilenbreite
        DW      0000H                   ; 3709  0000  +5 OPEN-Routine
        DW      0000H                   ; 370B  0000  +7 CLOSE-Routine
DEV_EDW:
        DB      42H                     ; 370D +0 Flags
        DW      EDB_PUT                 ; 370E  db37  +1 E/A-Routine
        DW      0000H                   ; 3710  0000  +3 Restspalten, +4 Zeilenbreite
        DW      0000H                   ; 3712  0000  +5 OPEN-Routine
        DW      0000H                   ; 3714  0000  +7 CLOSE-Routine
DEV_CON:
        DB      42H                     ; 3716 +0 Flags
        DW      CON_DRV                 ; 3717  d136  +1 E/A-Routine
        DW      0FFFFH                  ; 3719  ffff  +3 Restspalten, +4 Zeilenbreite
        DW      CON_CLS                 ; 371B  cf36  +5 OPEN-Routine
        DW      0000H                   ; 371D  0000  +7 CLOSE-Routine
DEV_NULO:
        DB      42H                     ; 371F +0 Flags
        DW      DRV_DUMMY               ; 3720  0337  +1 E/A-Routine
        DW      0001H                   ; 3722  0100  +3 Restspalten, +4 Zeilenbreite
        DW      0000H                   ; 3724  0000  +5 OPEN-Routine
        DW      0000H                   ; 3726  0000  +7 CLOSE-Routine
DEV_NULI:
        DB      44H                     ; 3728 +0 Flags
        DW      DRV_DUMMY               ; 3729  0337  +1 E/A-Routine
        DW      0000H                   ; 372B  0000  +3 Restspalten, +4 Zeilenbreite
        DW      0000H                   ; 372D  0000  +5 OPEN-Routine
        DW      0000H                   ; 372F  0000  +7 CLOSE-Routine
DEV_PRN:
        DB      62H                     ; 3731 +0 Flags
        DW      PRNOUT                  ; 3732  b636  +1 E/A-Routine
        DW      0050H                   ; 3734  5000  +3 Restspalten, +4 Zeilenbreite
        DW      0000H                   ; 3736  0000  +5 OPEN-Routine
        DW      0000H                   ; 3738  0000  +7 CLOSE-Routine
DEV_MTR:
        DB      54H                     ; 373A +0 Flags
        DW      TXT_GET                 ; 373B  7c37  +1 E/A-Routine
        DW      0000H                   ; 373D  0000  +3 Restspalten, +4 Zeilenbreite
        DW      F_OPEN                  ; 373F  2f3a  +5 OPEN-Routine
        DW      F_NOP                   ; 3741  493a  +7 CLOSE-Routine
DEV_MTW:
        DB      52H                     ; 3743 +0 Flags
        DW      TXT_PUT                 ; 3744  6c37  +1 E/A-Routine
        DW      0FFFFH                  ; 3746  ffff  +3 Restspalten, +4 Zeilenbreite
        DW      F_CREATE                ; 3748  a539  +5 OPEN-Routine
        DW      F_CLOSE                 ; 374A  c539  +7 CLOSE-Routine
DEV_FDR:
        DB      54H                     ; 374C +0 Flags
        DW      F_GETB                  ; 374D  4b3a  +1 E/A-Routine
        DW      0FFFFH                  ; 374F  ffff  +3 Restspalten, +4 Zeilenbreite
        DW      F_OPEN                  ; 3751  2f3a  +5 OPEN-Routine
        DW      F_NOP                   ; 3753  493a  +7 CLOSE-Routine
DEV_FDW:
        DB      52H                     ; 3755 +0 Flags
        DW      F_PUTB                  ; 3756  df39  +1 E/A-Routine
        DW      0FFFFH                  ; 3758  ffff  +3 Restspalten, +4 Zeilenbreite
        DW      F_CREATE                ; 375A  a539  +5 OPEN-Routine
        DW      F_CLOSE                 ; 375C  c539  +7 CLOSE-Routine
; ---- CPM_EXIT: zurueck zu CP/M (BDOS 0, Warmstart), z.B. BYE
CPM_EXIT:
        LD      C,0                     ; 375E  0e00
        CALL    BDOS                    ; 3760  cd0500  BDOS 0: Warmstart
        RET                             ; 3763  c9
; ---- KEY_POLL: BDOS 6 mit E=0FFH ohne Warten, A=0 wenn keine Taste
KEY_POLL:
        LD      E,0FFH                  ; 3764  1eff
        LD      C,6                     ; 3766  0e06
        CALL    BDOS                    ; 3768  cd0500  BDOS 6: Konsole direkt
        RET                             ; 376B  c9
; ---- TXT_PUT: Textdatei schreiben, 1EH -> CR+LF, dann F_PUTB
TXT_PUT:
        CP      1EH                     ; 376C  fe1e
        JP      nz,F_PUTB               ; 376E  c2df39
        LD      A,13                    ; 3771  3e0d
        CALL    F_PUTB                  ; 3773  cddf39
        RET     c                       ; 3776  d8
        LD      A,10                    ; 3777  3e0a
        JP      F_PUTB                  ; 3779  c3df39
; ---- TXT_GET: Textdatei lesen, LF ueberspringen, CR -> 1EH
TXT_GET:
        CALL    F_GETB                  ; 377C  cd4b3a
        RET     c                       ; 377F  d8
        CP      10                      ; 3780  fe0a
        JR      z,TXT_GET               ; 3782  28f8
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

;=====================================================================
; KBD_GET: E/A-Routine von DEV_KBD
; Ist der Editorpuffer leer, Zeile mit ED_LINE holen (max. 127 Zeichen),
; Leerzeichen am Ende abschneiden, 1EH anhaengen; dann Zeichen fuer
; Zeichen aus ED_BUF liefern (ED_RPTR).
;=====================================================================
KBD_GET:
        LD      HL,(ED_RPTR)            ; 37AF  2a8840
        LD      A,H                     ; 37B2  7c
        OR      L                       ; 37B3  b5
        JR      nz,L37D8                ; 37B4  2022
        LD      HL,ED_BUF               ; 37B6  218a40
        LD      DE,7FH                  ; 37B9  117f00
        CALL    ED_LINE                 ; 37BC  cd0238
        LD      B,64H                   ; 37BF  0664
        RET     c                       ; 37C1  d8
        LD      A,20H                   ; 37C2  3e20
        LD      HL,V_4109               ; 37C4  210941
        LD      B,80H                   ; 37C7  0680
L37C9:
        DEC     HL                      ; 37C9  2b
        CP      (HL)                    ; 37CA  be
        JR      nz,L37CF                ; 37CB  2002
        DJNZ    L37C9                   ; 37CD  10fa
L37CF:
        INC     HL                      ; 37CF  23
        LD      (HL),1EH                ; 37D0  361e
        LD      HL,ED_BUF               ; 37D2  218a40
        LD      (ED_RPTR),HL            ; 37D5  228840
L37D8:
        LD      A,(HL)                  ; 37D8  7e
        AND     A                       ; 37D9  a7
        RET                             ; 37DA  c9
; ---- EDB_PUT: E/A-Routine von DEV_EDW, schreibt Vorgabetext nach ED_BUF
EDB_PUT:
        CP      1EH                     ; 37DB  fe1e
        RET     z                       ; 37DD  c8
        CP      13                      ; 37DE  fe0d
        JR      nz,L37F9                ; 37E0  2017
        LD      HL,0                    ; 37E2  210000
        LD      (ED_RPTR),HL            ; 37E5  228840
        LD      HL,ED_BUF               ; 37E8  218a40
        LD      (ED_WPTR),HL            ; 37EB  228640
        LD      B,7FH                   ; 37EE  067f
        LD      C,20H                   ; 37F0  0e20
L37F2:
        LD      (HL),C                  ; 37F2  71
        INC     HL                      ; 37F3  23
        DJNZ    L37F2                   ; 37F4  10fc
        LD      (HL),1EH                ; 37F6  361e
        RET                             ; 37F8  c9
L37F9:
        LD      HL,(ED_WPTR)            ; 37F9  2a8640
        LD      (HL),A                  ; 37FC  77
        INC     HL                      ; 37FD  23
        LD      (ED_WPTR),HL            ; 37FE  228640
        RET                             ; 3801  c9
