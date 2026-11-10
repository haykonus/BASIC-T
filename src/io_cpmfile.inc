; io_cpmfile.inc - CP/M-Datei-E/A (FCB, LOAD/SAVE): bei Portierung anpassen
; Teil von basict.asm (per INCLUDE), nicht einzeln assemblierbar.

;=====================================================================
; DATEI-EIN/AUSGABE UEBER CP/M (LOAD, SAVE, OPEN, CLOSE, GET, PUT)
; Arbeitsbereich ab IY (= Kanalblock+9): +0..5 Name, +6 Bytezaehler,
; +7/+8 Pufferzeiger, ab +12 FCB (36 Byte), ab +48 Satzpuffer (128 Byte).
; Satzweise Uebertragung ueber den CP/M-DMA-Puffer 0080H.
; FCB_INIT: FCB mit Laufwerk 0, 6-Zeichen-Name und Typ "GBA" fuellen.
;=====================================================================
FCB_INIT:
        PUSH    IY                      ; 3960  fde5
        POP     HL                      ; 3962  e1
        CALL    FCB_ADDR                ; 3963  cd9a39
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
; ---- FCB_ADDR: DE = IY+12 (FCB-Adresse fuer BDOS)
FCB_ADDR:
        PUSH    IY                      ; 399A  fde5
        POP     DE                      ; 399C  d1
        PUSH    BC                      ; 399D  c5
        LD      B,12                    ; 399E  060c
L39A0:
        INC     DE                      ; 39A0  13
        DJNZ    L39A0                   ; 39A1  10fd
        POP     BC                      ; 39A3  c1
        RET                             ; 39A4  c9
; ---- F_CREATE: OPEN zum Schreiben: alte Datei loeschen, neu anlegen
F_CREATE:
        CALL    FCB_INIT                ; 39A5  cd6039
        CALL    FCB_ADDR                ; 39A8  cd9a39
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
; ---- Fehler 6FH: Diskette/Verzeichnis voll oder Schreibfehler
L39C1:
        LD      B,6FH                   ; 39C1  066f
        SCF                             ; 39C3  37
        RET                             ; 39C4  c9
; ---- F_CLOSE: Rest des Puffers schreiben, Datei schliessen
F_CLOSE:
        XOR     A                       ; 39C5  af
        CP      (IY+6)                  ; 39C6  fdbe06
        CALL    nz,F_FLUSH              ; 39C9  c4f739
        RET     c                       ; 39CC  d8
        PUSH    IY                      ; 39CD  fde5
        CALL    FCB_ADDR                ; 39CF  cd9a39
        LD      C,10H                   ; 39D2  0e10
        CALL    BDOS                    ; 39D4  cd0500  BDOS 16: Datei schliessen
        POP     IY                      ; 39D7  fde1
        AND     0FCH                    ; 39D9  e6fc
        JR      nz,L39C1                ; 39DB  20e4
        XOR     A                       ; 39DD  af
        RET                             ; 39DE  c9
; ---- F_PUTB: Byte A in Satzpuffer, bei 128 Byte F_FLUSH
F_PUTB:
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
; ---- F_FLUSH: Satzpuffer nach 0080H kopieren und schreiben
F_FLUSH:
        PUSH    IY                      ; 39F7  fde5
        POP     HL                      ; 39F9  e1
        LD      B,30H                   ; 39FA  0630
L39FC:
        INC     HL                      ; 39FC  23
        DJNZ    L39FC                   ; 39FD  10fd
        LD      DE,80H                  ; 39FF  118000
        LD      BC,80H                  ; 3A02  018000
        LDIR                            ; 3A05  edb0
        CALL    FCB_ADDR                ; 3A07  cd9a39
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
; ---- F_OPEN: OPEN zum Lesen (BDOS 15), Fehler 71H wenn nicht vorhanden
F_OPEN:
        CALL    FCB_INIT                ; 3A2F  cd6039
        CALL    FCB_ADDR                ; 3A32  cd9a39
        PUSH    IY                      ; 3A35  fde5
        PUSH    DE                      ; 3A37  d5
        LD      C,15                    ; 3A38  0e0f
        CALL    BDOS                    ; 3A3A  cd0500  BDOS 15: Datei oeffnen
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
; ---- F_NOP: CLOSE fuer Lesekanaele, nichts zu tun
F_NOP:
        XOR     A                       ; 3A49  af
        RET                             ; 3A4A  c9
; ---- F_GETB: Byte aus Satzpuffer, bei leerem Puffer Satz lesen (Fehler 70H am Ende)
F_GETB:
        LD      A,(IY+6)                ; 3A4B  fd7e06
        OR      A                       ; 3A4E  b7
        JR      nz,L3A81                ; 3A4F  2030
        CALL    FCB_ADDR                ; 3A51  cd9a39
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
