; gfx_tur.inc - Grafikmodul fuer die TuR-Grafikhardware (Port 08H, 9000H)
; Teil von basict.asm (per INCLUDE), nicht einzeln assemblierbar.

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

; Ende des Programms.
        IF      $>RAM_BASE
        ERROR   "Code reicht in den Arbeitsspeicher"
        ENDIF
; Fuellbytes bis RAM_BASE, nur damit die Datei bei 0100H dem
; Original (0100H-3FFFH) entspricht.
        IF      CODE_ORG=0100H
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
        ENDIF
