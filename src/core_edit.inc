; core_edit.inc - Zeileneditor, nur ueber CONIN/CONOUT (systemunabhaengig)
; Teil von basict.asm (per INCLUDE), nicht einzeln assemblierbar.

;=====================================================================
; ED_LINE: ZEILENEDITOR
; Ein: HL = Puffer, E = Laenge. Vorhandener Text wird angezeigt,
; Bit7 eines Zeichens markiert die Cursorposition (Fehlerstelle).
; Tasten ueber CONIN: 04H ^D Cursor rechts, 08H ^H links, 18H ^X
; Zeichen loeschen, weitere Steuertasten siehe Sprachbeschreibung.
;=====================================================================
ED_LINE:
        LD      BC,(ED_WPTR)            ; 3802  ed4b8640
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
        CALL    CONIN                   ; 383F  cdd836
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
