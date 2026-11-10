; core_io.inc - Logische E/A ueber Kanalbloecke (systemunabhaengig)
; Teil von basict.asm (per INCLUDE), nicht einzeln assemblierbar.

;=====================================================================
; LOGISCHE EIN/AUSGABE UEBER KANALBLOECKE (nach RFE 3/1984)
; Jedes Geraet ist ein 9-Byte-Kanalblock (Tabelle ab DEV_KBD), IY zeigt darauf:
;   +0     Flags: Bit0 offen, Bit1 Ausgabe erlaubt, Bit2 Eingabe erlaubt,
;          Bit4 Dateikanal, Bit5 automatischer Zeilenumbruch,
;          Bit6 beim ersten Zugriff selbst oeffnen
;   +1/+2  E/A-Routine (Pflicht): Ausgabe Zeichen in A, Eingabe liefert A
;   +3     verbleibende Spalten der Zeile, +4 Zeilenbreite (Neuladewert)
;   +5/+6  OPEN-Routine (0 = keine), +7/+8 CLOSE-Routine (0 = keine)
; Treiber werden ueber DRV_CALL mit IY = Block+9 gerufen; ab dort liegt
; der Arbeitsbereich des Treibers (bei Dateien Zaehler, Zeiger, FCB, Puffer).
; Treiber duerfen alle Register aendern; CY=1 meldet Fehler, B = Fehlernummer.
; Zeilenende ist intern 1EH; die Treiber wandeln es bei Bedarf in CR/LF.
; CH_OUT: Zeichen A auf Kanal IY ausgeben (Spalten, TAB, Umbruch).
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
        CALL    nc,CH_AUTOOPEN          ; 34EA  d43c35
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
        CALL    DRV_CALL                ; 3523  cd7035
        JR      c,L354D                 ; 3526  3825
        POP     HL                      ; 3528  e1
        POP     BC                      ; 3529  c1
L352A:
        LD      A,(IY+4)                ; 352A  fd7e04
        DEC     A                       ; 352D  3d
        LD      (IY+3),A                ; 352E  fd7703
L3531:
        LD      A,B                     ; 3531  78
        CALL    DRV_CALL                ; 3532  cd7035
        JR      c,L354D                 ; 3535  3816
        POP     AF                      ; 3537  f1
        POP     BC                      ; 3538  c1
        POP     DE                      ; 3539  d1
        POP     HL                      ; 353A  e1
        RET                             ; 353B  c9
; ---- Kanal nicht offen: bei Flag Bit6 automatisch oeffnen, sonst Fehler 52H
CH_AUTOOPEN:
        BIT     5,A                     ; 353C  cb6f
        JR      nz,CH_OPEN              ; 353E  2043
        LD      A,52H                   ; 3540  3e52
        JR      L354A                   ; 3542  1806
; ---- Fehler 53H: Kanal kann nicht ausgeben
L3544:
        LD      A,53H                   ; 3544  3e53
        JR      L354A                   ; 3546  1802
; ---- Fehler 54H: Kanal kann nicht lesen
L3548:
        LD      A,54H                   ; 3548  3e54
L354A:
        JP      ERROR                   ; 354A  c35933
; ---- Treiber meldete CY=1: Fehlernummer aus B
L354D:
        LD      A,B                     ; 354D  78
        JR      L354A                   ; 354E  18fa

;=====================================================================
; CH_IN: ein Zeichen von Kanal IY lesen
; Prueft offen/Eingabe erlaubt, ruft die E/A-Routine; Aus: A = Zeichen.
;=====================================================================
CH_IN:
        PUSH    HL                      ; 3550  e5
        PUSH    DE                      ; 3551  d5
        PUSH    BC                      ; 3552  c5
        LD      A,(IY)                  ; 3553  fd7e00
        RRCA                            ; 3556  0f
        CALL    nc,CH_AUTOOPEN          ; 3557  d43c35
        RRCA                            ; 355A  0f
        RRCA                            ; 355B  0f
        JR      nc,L3548                ; 355C  30ea
        LD      H,(IY+2)                ; 355E  fd6602
        LD      L,(IY+1)                ; 3561  fd6e01
        CALL    DRV_CALL                ; 3564  cd7035
        JR      c,L354D                 ; 3567  38e4
        POP     BC                      ; 3569  c1
        POP     DE                      ; 356A  d1
        POP     HL                      ; 356B  e1
        RET                             ; 356C  c9
; ---- KEY_CHECK: Taste ohne Warten abfragen (A=0: keine), fuer B/W/C-Abbruch
KEY_CHECK:
        LD      HL,KEY_POLL             ; 356D  216437

;=====================================================================
; DRV_CALL: Treiberroutine HL aufrufen
; Rettet IX/IY, setzt IY auf Block+9 (Treiber-Arbeitsbereich).
;=====================================================================
DRV_CALL:
        PUSH    IX                      ; 3570  dde5
        PUSH    IY                      ; 3572  fde5
        LD      DE,L357E                ; 3574  117e35
        PUSH    DE                      ; 3577  d5
        LD      DE,9                    ; 3578  110900
        ADD     IY,DE                   ; 357B  fd19
        JP      (HL)                    ; 357D  e9
L357E:
        POP     IY                      ; 357E  fde1
        POP     IX                      ; 3580  dde1
        RET                             ; 3582  c9
; ---- CH_OPEN: Flag Bit0 setzen, Spalten zuruecksetzen, OPEN-Routine (+5) rufen
CH_OPEN:
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
        CALL    DRV_CALL                ; 35A1  cd7035
        JR      c,L354D                 ; 35A4  38a7
        POP     BC                      ; 35A6  c1
        POP     DE                      ; 35A7  d1
L35A8:
        POP     HL                      ; 35A8  e1
L35A9:
        POP     AF                      ; 35A9  f1
        RET                             ; 35AA  c9
; ---- CH_CLOSE: falls offen Bit0 loeschen und CLOSE-Routine (+7) rufen
CH_CLOSE:
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
        LD      IY,(V_41F1)             ; 35C3  fd2af141
        LD      A,(IY+4)                ; 35C7  fd7e04
        CP      (IY+3)                  ; 35CA  fdbe03
        RET     z                       ; 35CD  c8
CH_CRLF:
        LD      A,1EH                   ; 35CE  3e1e
        JR      OUTCH                   ; 35D0  1802
CH_SPACE:
        LD      A,20H                   ; 35D2  3e20
OUTCH:
        LD      IY,(V_41F1)             ; 35D4  fd2af141
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
        LD      IY,(V_41F3)             ; 35F7  fd2af341
        JP      CH_OUT                  ; 35FB  c3db34
        LD      B,(HL)                  ; 35FE  46
        INC     HL                      ; 35FF  23
L3600:
        LD      A,(HL)                  ; 3600  7e
        CALL    L35F7                   ; 3601  cdf735
        INC     HL                      ; 3604  23
        DJNZ    L3600                   ; 3605  10f9
        RET                             ; 3607  c9
L3608:
        LD      B,1EH                   ; 3608  061e
L360A:
        LD      A,(HL)                  ; 360A  7e
        CALL    L35F7                   ; 360B  cdf735
        LD      A,(HL)                  ; 360E  7e
        INC     HL                      ; 360F  23
        CP      B                       ; 3610  b8
        JR      nz,L360A                ; 3611  20f7
        RET                             ; 3613  c9
L3614:
        LD      A,1EH                   ; 3614  3e1e
        JP      CH_OUT                  ; 3616  c3db34
L3619:
        LD      A,20H                   ; 3619  3e20
        JP      CH_OUT                  ; 361B  c3db34
        LD      B,(HL)                  ; 361E  46
        INC     HL                      ; 361F  23
L3620:
        LD      A,(HL)                  ; 3620  7e
        CALL    CH_OUT                  ; 3621  cddb34
        INC     HL                      ; 3624  23
        DJNZ    L3620                   ; 3625  10f9
        RET                             ; 3627  c9
; ---- KEY_FLUSH: Tastaturpuffer leeren (bis KEY_CHECK keine Taste meldet)
KEY_FLUSH:
        CALL    KEY_CHECK               ; 3628  cd6d35
        AND     A                       ; 362B  a7
        JR      nz,KEY_FLUSH            ; 362C  20fa
        RET                             ; 362E  c9
CON_CR:
        LD      IY,V_4204               ; 362F  fd210442
        LD      A,13                    ; 3633  3e0d
        JP      CH_OUT                  ; 3635  c3db34
L3638:
        LD      (V_4083),A              ; 3638  328340
        PUSH    HL                      ; 363B  e5
        LD      HL,(ED_RPTR)            ; 363C  2a8840
        DEC     HL                      ; 363F  2b
        LD      (ED_RPTR),HL            ; 3640  228840
        POP     HL                      ; 3643  e1
        RET                             ; 3644  c9
L3645:
        LD      A,(V_4083)              ; 3645  3a8340
        AND     A                       ; 3648  a7
        JR      z,L3652                 ; 3649  2807
        PUSH    AF                      ; 364B  f5
        XOR     A                       ; 364C  af
        LD      (V_4083),A              ; 364D  328340
        POP     AF                      ; 3650  f1
        RET                             ; 3651  c9
L3652:
        PUSH    IY                      ; 3652  fde5
        LD      IY,(V_41F7)             ; 3654  fd2af741
        LD      HL,V_41C1               ; 3658  21c141
        BIT     5,(HL)                  ; 365B  cb6e
        JR      nz,L3667                ; 365D  2008
        BIT     1,(HL)                  ; 365F  cb4e
        JR      nz,L3667                ; 3661  2004
        LD      IY,(V_41F5)             ; 3663  fd2af541
L3667:
        CALL    CH_IN                   ; 3667  cd5035
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
        DB      00H                     ; 36B5 .
