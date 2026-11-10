; core_fp.inc - Gleitkomma-Arithmetik, Funktionen, Zahlenwandlung
; Teil von basict.asm (per INCLUDE), nicht einzeln assemblierbar.

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
        LD      DE,(V_42E4)             ; 2734  ed5be442
        LD      HL,(FAC)                ; 2738  2ae242
        LD      BC,(ARG)                ; 273B  ed4be742
        XOR     D                       ; 273F  aa
        LD      A,D                     ; 2740  7a
        RES     7,D                     ; 2741  cbba
        JP      m,FP_SUB_MANTISSAS      ; 2743  fa6e27
        ADD     HL,BC                   ; 2746  09
        EX      DE,HL                   ; 2747  eb
        LD      BC,(V_42E9)             ; 2748  ed4be942
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
        LD      BC,(V_42E9)             ; 2771  ed4be942
        RES     7,B                     ; 2775  cbb8
        SBC     HL,BC                   ; 2777  ed42
        CALL    m,FP_NEGATE_MAGNITUDE   ; 2779  fc9428
; ---- Vorzeichen in HLDE einsetzen, nach FAC schreiben, anschliessend normalisieren.
FP_STORE_RESULT:
        AND     80H                     ; 277C  e680
        ADD     A,H                     ; 277E  84
        LD      H,A                     ; 277F  67
        LD      (V_42E4),HL             ; 2780  22e442
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
        LD      HL,(V_42E4)             ; 27C8  2ae442
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
        LD      DE,(V_42E4)             ; 27F5  ed5be442
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
        LD      BC,(V_42E9)             ; 2823  ed4be942
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
        LD      BC,(V_42E9)             ; 284D  ed4be942
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
        LD      BC,(V_42E4)             ; 285E  ed4be442
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
        LD      A,7FH                   ; 28A6  3e7f
        JR      L28AC                   ; 28A8  1802
        LD      A,0FFH                  ; 28AA  3eff
L28AC:
        LD      HL,FAC_EXP              ; 28AC  21e642
        LD      (HL),7FH                ; 28AF  367f
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
        LD      (V_42EC),HL             ; 28DB  22ec42
        LD      A,H                     ; 28DE  7c
        OR      L                       ; 28DF  b5
        LD      HL,(V_42E4)             ; 28E0  2ae442
        OR      H                       ; 28E3  b4
        OR      L                       ; 28E4  b5
        RET     z                       ; 28E5  c8
        BIT     7,H                     ; 28E6  cb7c
        JP      nz,FP_FUNCTION_ERROR    ; 28E8  c2c62c
        LD      (V_42EE),HL             ; 28EB  22ee42
        LD      A,(FAC_EXP)             ; 28EE  3ae642
        LD      (V_42F0),A              ; 28F1  32f042
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
        LD      DE,V_42F1               ; 2910  11f142
        LDIR                            ; 2913  edb0
        LD      BC,5                    ; 2915  010500
        LD      HL,V_42EC               ; 2918  21ec42
        LD      DE,FAC                  ; 291B  11e242
        LDIR                            ; 291E  edb0
        LD      BC,5                    ; 2920  010500
        LD      HL,V_42F1               ; 2923  21f142
        LD      DE,ARG                  ; 2926  11e742
        LDIR                            ; 2929  edb0
        CALL    FP_DIV_ARG              ; 292B  cdef27
        LD      BC,5                    ; 292E  010500
        LD      HL,V_42F1               ; 2931  21f142
        LD      DE,ARG                  ; 2934  11e742
        LDIR                            ; 2937  edb0
        CALL    FP_ADD_ARG              ; 2939  cdc326
        LD      HL,FAC_EXP              ; 293C  21e642
        DEC     (HL)                    ; 293F  35
        RET                             ; 2940  c9
        LD      HL,FAC_SIGN_MSB         ; 2941  21e542
        RES     7,(HL)                  ; 2944  cbbe
        RET                             ; 2946  c9
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
        LD      DE,ARG                  ; 299D  11e742
        LD      HL,FAC                  ; 29A0  21e242
        LD      BC,5                    ; 29A3  010500
        LDIR                            ; 29A6  edb0
        CALL    FP_FLOOR                ; 29A8  cd5729
        CALL    FP_NEG                  ; 29AB  cd4729
        JP      FP_ADD_ARG              ; 29AE  c3c326
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
        LD      DE,V_42EC               ; 29E3  11ec42
        CALL    FAC_STORE               ; 29E6  cdae26
        LD      DE,K_SQRT_HALF          ; 29E9  11632d
        CALL    FP_ADD                  ; 29EC  cdc026
        LD      DE,V_42F1               ; 29EF  11f142
        CALL    FAC_STORE               ; 29F2  cdae26
        LD      DE,V_42EC               ; 29F5  11ec42
        CALL    FAC_LOAD                ; 29F8  cd9f26
        LD      DE,K_SQRT_HALF          ; 29FB  11632d
        CALL    FP_SUB                  ; 29FE  cdb326
        LD      DE,V_42F1               ; 2A01  11f142
        CALL    FP_DIV                  ; 2A04  cdec27
        LD      DE,V_42F1               ; 2A07  11f142
        CALL    FAC_STORE               ; 2A0A  cdae26
        CALL    FP_SQUARE               ; 2A0D  cdc728
        LD      DE,V_42EC               ; 2A10  11ec42
        CALL    FAC_STORE               ; 2A13  cdae26
        LD      DE,K_LOG_C5             ; 2A16  11d32c
        CALL    FP_MUL                  ; 2A19  cd8a27
        LD      DE,K_LOG_C3             ; 2A1C  116d2d
        CALL    FP_ADD                  ; 2A1F  cdc026
        LD      DE,V_42EC               ; 2A22  11ec42
        CALL    FP_MUL                  ; 2A25  cd8a27
        LD      DE,K_LOG_C1             ; 2A28  11682d
        CALL    FP_ADD                  ; 2A2B  cdc026
        LD      DE,V_42F1               ; 2A2E  11f142
        CALL    FP_MUL                  ; 2A31  cd8a27
        LD      DE,K_FP_HALF            ; 2A34  11132d
        CALL    FP_SUB                  ; 2A37  cdb326
        LD      DE,V_42EC               ; 2A3A  11ec42
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
        LD      DE,V_42EC               ; 2A4F  11ec42
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
        LD      DE,V_42EC               ; 2A7B  11ec42
        CALL    FAC_STORE               ; 2A7E  cdae26
        LD      DE,K_FP_SIX             ; 2A81  11f52c
        CALL    FP_DIV                  ; 2A84  cdec27
        LD      DE,K_FP_ONE             ; 2A87  11dc2c
        CALL    FP_ADD                  ; 2A8A  cdc026
        LD      DE,V_42EC               ; 2A8D  11ec42
        CALL    FP_MUL                  ; 2A90  cd8a27
        LD      DE,K_FP_FIVE            ; 2A93  11f02c
        CALL    FP_DIV                  ; 2A96  cdec27
        LD      DE,K_FP_ONE             ; 2A99  11dc2c
        CALL    FP_ADD                  ; 2A9C  cdc026
        LD      DE,V_42EC               ; 2A9F  11ec42
        CALL    FP_MUL                  ; 2AA2  cd8a27
        LD      DE,K_FP_FOUR            ; 2AA5  11eb2c
        CALL    FP_DIV                  ; 2AA8  cdec27
        LD      DE,K_FP_ONE             ; 2AAB  11dc2c
        CALL    FP_ADD                  ; 2AAE  cdc026
        LD      DE,V_42EC               ; 2AB1  11ec42
        CALL    FP_MUL                  ; 2AB4  cd8a27
        LD      DE,K_FP_THREE           ; 2AB7  11e62c
        CALL    FP_DIV                  ; 2ABA  cdec27
        LD      DE,K_FP_ONE             ; 2ABD  11dc2c
        CALL    FP_ADD                  ; 2AC0  cdc026
        LD      DE,V_42EC               ; 2AC3  11ec42
        CALL    FP_MUL                  ; 2AC6  cd8a27
        LD      DE,K_FP_HALF            ; 2AC9  11132d
        CALL    FP_MUL                  ; 2ACC  cd8a27
        LD      DE,K_FP_ONE             ; 2ACF  11dc2c
        CALL    FP_ADD                  ; 2AD2  cdc026
        LD      DE,V_42EC               ; 2AD5  11ec42
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
        LD      DE,V_42EC               ; 2B18  11ec42
        CALL    FAC_STORE               ; 2B1B  cdae26
        LD      DE,K_PI_TWO             ; 2B1E  11222d
        CALL    FP_DIV                  ; 2B21  cdec27
        CALL    FP_FLOOR                ; 2B24  cd5729
        LD      DE,K_PI_TWO             ; 2B27  11222d
        CALL    FP_MUL                  ; 2B2A  cd8a27
        LD      DE,V_42EC               ; 2B2D  11ec42
        CALL    FP_SUB                  ; 2B30  cdb326
        CALL    FP_NEG                  ; 2B33  cd4729
L2B36:
        LD      DE,V_42EC               ; 2B36  11ec42
        CALL    FAC_STORE               ; 2B39  cdae26
        LD      DE,K_FP_TENTH           ; 2B3C  11092d
        CALL    FP_SUB                  ; 2B3F  cdb326
        LD      A,(FAC_SIGN_MSB)        ; 2B42  3ae542
        RLA                             ; 2B45  17
        JR      c,L2B59                 ; 2B46  3811
        POP     AF                      ; 2B48  f1
        INC     A                       ; 2B49  3c
        PUSH    AF                      ; 2B4A  f5
        LD      DE,V_42EC               ; 2B4B  11ec42
        CALL    FAC_LOAD                ; 2B4E  cd9f26
        LD      DE,K_FP_THREE           ; 2B51  11e62c
        CALL    FP_DIV                  ; 2B54  cdec27
        JR      L2B36                   ; 2B57  18dd
L2B59:
        LD      DE,V_42EC               ; 2B59  11ec42
        CALL    FAC_LOAD                ; 2B5C  cd9f26
        CALL    FP_SQUARE               ; 2B5F  cdc728
        LD      DE,K_FP_HALF            ; 2B62  11132d
        CALL    FP_MUL                  ; 2B65  cd8a27
        LD      DE,V_42F1               ; 2B68  11f142
        CALL    FAC_STORE               ; 2B6B  cdae26
        LD      DE,K_FP_HALF            ; 2B6E  11132d
        CALL    FP_MUL                  ; 2B71  cd8a27
        LD      DE,K_FP_FIVE            ; 2B74  11f02c
        CALL    FP_DIV                  ; 2B77  cdec27
        LD      DE,K_FP_ONE             ; 2B7A  11dc2c
        CALL    FP_SUB                  ; 2B7D  cdb326
        LD      DE,V_42F1               ; 2B80  11f142
        CALL    FP_MUL                  ; 2B83  cd8a27
        LD      DE,K_FP_THREE           ; 2B86  11e62c
        CALL    FP_DIV                  ; 2B89  cdec27
        LD      DE,K_FP_ONE             ; 2B8C  11dc2c
        CALL    FP_ADD                  ; 2B8F  cdc026
        LD      DE,V_42EC               ; 2B92  11ec42
        CALL    FP_MUL                  ; 2B95  cd8a27
        POP     AF                      ; 2B98  f1
        JR      z,L2BBE                 ; 2B99  2823
        LD      B,A                     ; 2B9B  47
; ---- Dreifachwinkelformel: s <- -(4*s*s-3)*s; Schleife je vorheriger Drittelung.
FP_SIN_TRIPLE:
        PUSH    BC                      ; 2B9C  c5
        LD      DE,V_42F1               ; 2B9D  11f142
        CALL    FAC_STORE               ; 2BA0  cdae26
        CALL    FP_SQUARE               ; 2BA3  cdc728
        LD      DE,K_FP_FOUR            ; 2BA6  11eb2c
        CALL    FP_MUL                  ; 2BA9  cd8a27
        LD      DE,K_FP_THREE           ; 2BAC  11e62c
        CALL    FP_SUB                  ; 2BAF  cdb326
        LD      DE,V_42F1               ; 2BB2  11f142
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
        LD      DE,V_42F6               ; 2BEA  11f642
        CALL    FAC_STORE               ; 2BED  cdae26
        CALL    FP_SQUARE               ; 2BF0  cdc728
        LD      DE,V_42F1               ; 2BF3  11f142
        CALL    FAC_STORE               ; 2BF6  cdae26
        LD      DE,K_ATN_A3             ; 2BF9  114f2d
        CALL    FP_ADD                  ; 2BFC  cdc026
        CALL    FP_RECIPROCAL           ; 2BFF  cdb629
        LD      DE,K_ATN_B2             ; 2C02  115e2d
        CALL    FP_MUL                  ; 2C05  cd8a27
        LD      DE,K_ATN_A2             ; 2C08  114a2d
        CALL    FP_ADD                  ; 2C0B  cdc026
        LD      DE,V_42F1               ; 2C0E  11f142
        CALL    FP_ADD                  ; 2C11  cdc026
        CALL    FP_RECIPROCAL           ; 2C14  cdb629
        LD      DE,K_ATN_B1             ; 2C17  11592d
        CALL    FP_MUL                  ; 2C1A  cd8a27
        LD      DE,K_ATN_A1             ; 2C1D  11452d
        CALL    FP_ADD                  ; 2C20  cdc026
        LD      DE,V_42F1               ; 2C23  11f142
        CALL    FP_ADD                  ; 2C26  cdc026
        CALL    FP_RECIPROCAL           ; 2C29  cdb629
        LD      DE,K_ATN_B0             ; 2C2C  11542d
        CALL    FP_MUL                  ; 2C2F  cd8a27
        LD      DE,K_ATN_A0             ; 2C32  11402d
        CALL    FP_ADD                  ; 2C35  cdc026
        LD      DE,V_42F6               ; 2C38  11f642
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
        LD      HL,(V_42E9)             ; 2C68  2ae942
        PUSH    HL                      ; 2C6B  e5
        LD      A,(ARG_EXP)             ; 2C6C  3aeb42
        PUSH    AF                      ; 2C6F  f5
        CALL    X_LOG                   ; 2C70  cdd029
        POP     AF                      ; 2C73  f1
        LD      (ARG_EXP),A             ; 2C74  32eb42
        POP     HL                      ; 2C77  e1
        LD      (V_42E9),HL             ; 2C78  22e942
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
        LD      DE,V_41D5               ; 2C8A  11d541
        CALL    FAC_LOAD                ; 2C8D  cd9f26
        LD      DE,K_RND_FACTOR         ; 2C90  11722d
        CALL    FP_MUL                  ; 2C93  cd8a27
        LD      DE,K_RND_INCREMENT      ; 2C96  11772d
        CALL    FP_ADD                  ; 2C99  cdc026
        LD      DE,V_42F1               ; 2C9C  11f142
        CALL    FAC_STORE               ; 2C9F  cdae26
        LD      DE,K_RND_MODULUS        ; 2CA2  117c2d
        CALL    FP_DIV                  ; 2CA5  cdec27
        CALL    FP_FLOOR                ; 2CA8  cd5729
        LD      DE,K_RND_MODULUS        ; 2CAB  117c2d
        CALL    FP_MUL                  ; 2CAE  cd8a27
        LD      DE,V_42F1               ; 2CB1  11f142
        CALL    FP_SUB                  ; 2CB4  cdb326
        CALL    FP_NEG                  ; 2CB7  cd4729
        LD      DE,V_41D5               ; 2CBA  11d541
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
        DB      00H                     ; 2D81 .
L2D82:
        LD      DE,V_4004               ; 2D82  110440
        LD      HL,0                    ; 2D85  210000
        LD      B,11H                   ; 2D88  0611
L2D8A:
        LD      A,(DE)                  ; 2D8A  1a
        INC     DE                      ; 2D8B  13
        SUB     30H                     ; 2D8C  d630
        JR      z,L2D93                 ; 2D8E  2803
        DEC     A                       ; 2D90  3d
        RET     nz                      ; 2D91  c0
        SCF                             ; 2D92  37
L2D93:
        ADC     HL,HL                   ; 2D93  ed6a
        DJNZ    L2D8A                   ; 2D95  10f3
        JR      L2DAE                   ; 2D97  1815
L2D99:
        LD      DE,V_4004               ; 2D99  110440
        LD      HL,0                    ; 2D9C  210000
        PUSH    HL                      ; 2D9F  e5
        ADD     HL,SP                   ; 2DA0  39
L2DA1:
        CALL    L2DB5                   ; 2DA1  cdb52d
        JR      c,L2DB3                 ; 2DA4  380d
        RLD                             ; 2DA6  ed6f
        INC     HL                      ; 2DA8  23
        RLD                             ; 2DA9  ed6f
        DEC     HL                      ; 2DAB  2b
        JR      z,L2DA1                 ; 2DAC  28f3
L2DAE:
        LD      A,1FH                   ; 2DAE  3e1f
        JP      ERROR                   ; 2DB0  c35933
L2DB3:
        POP     HL                      ; 2DB3  e1
        RET                             ; 2DB4  c9
L2DB5:
        LD      A,(DE)                  ; 2DB5  1a
        INC     DE                      ; 2DB6  13
        SUB     30H                     ; 2DB7  d630
        RET     c                       ; 2DB9  d8
        CP      10H                     ; 2DBA  fe10
        CCF                             ; 2DBC  3f
        RET     nc                      ; 2DBD  d0
        SUB     7                       ; 2DBE  d607
        CP      10                      ; 2DC0  fe0a
        RET     c                       ; 2DC2  d8
        CP      10H                     ; 2DC3  fe10
        CCF                             ; 2DC5  3f
        RET                             ; 2DC6  c9
L2DC7:
        LD      DE,V_4003               ; 2DC7  110340
        LD      HL,0                    ; 2DCA  210000
L2DCD:
        LD      A,(DE)                  ; 2DCD  1a
        CP      30H                     ; 2DCE  fe30
        CCF                             ; 2DD0  3f
        RET     nc                      ; 2DD1  d0
        CP      3AH                     ; 2DD2  fe3a
        RET     nc                      ; 2DD4  d0
        LD      A,0F0H                  ; 2DD5  3ef0
        AND     H                       ; 2DD7  a4
        SCF                             ; 2DD8  37
        RET     nz                      ; 2DD9  c0
        LD      B,H                     ; 2DDA  44
        LD      C,L                     ; 2DDB  4d
        ADD     HL,HL                   ; 2DDC  29
        ADD     HL,HL                   ; 2DDD  29
        ADD     HL,BC                   ; 2DDE  09
        ADD     HL,HL                   ; 2DDF  29
        LD      A,(DE)                  ; 2DE0  1a
        INC     DE                      ; 2DE1  13
        AND     15                      ; 2DE2  e60f
        ADD     A,L                     ; 2DE4  85
        LD      L,A                     ; 2DE5  6f
        LD      A,0                     ; 2DE6  3e00
        ADC     A,H                     ; 2DE8  8c
        LD      H,A                     ; 2DE9  67
        SCF                             ; 2DEA  37
        RET     m                       ; 2DEB  f8
        JR      L2DCD                   ; 2DEC  18df
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
        LD      (V_42F6),HL             ; 2E1C  22f642
        LD      HL,V_42F5               ; 2E1F  21f542
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
        LD      HL,V_42F1               ; 2E30  21f142
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
        LD      H,FAC>>8                ; 2E54  2642
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
        LD      HL,V_42F1               ; 2E8D  21f142
        BIT     2,(HL)                  ; 2E90  cb56
        JR      nz,L2EE6                ; 2E92  2052
        SET     2,(HL)                  ; 2E94  cbd6
        JR      L2E2B                   ; 2E96  1893
L2E98:
        INC     A                       ; 2E98  3c
        JR      nz,L2EA2                ; 2E99  2007
        LD      A,80H                   ; 2E9B  3e80
L2E9D:
        LD      (V_42F4),A              ; 2E9D  32f442
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
        LD      (V_42F3),A              ; 2EC8  32f342
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
        LD      A,(V_42F1)              ; 2EDF  3af142
        RRA                             ; 2EE2  1f
        JP      nc,L2E2B                ; 2EE3  d22b2e
L2EE6:
        LD      HL,V_42F1               ; 2EE6  21f142
        BIT     0,(HL)                  ; 2EE9  cb46
        JR      nz,L2EFE                ; 2EEB  2011
        LD      A,(V_42F3)              ; 2EED  3af342
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
        LD      HL,V_42F3               ; 2F0C  21f342
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
        LD      A,(V_42F2)              ; 2F35  3af242
        AND     A                       ; 2F38  a7
        JP      m,L2F41                 ; 2F39  fa412f
        CALL    FP_MUL_ARG              ; 2F3C  cd8d27
        JR      L2F50                   ; 2F3F  180f
L2F41:
        CALL    FP_DIV_ARG              ; 2F41  cdef27
        JR      L2F50                   ; 2F44  180a
L2F46:
        LD      A,(V_42F2)              ; 2F46  3af242
        AND     A                       ; 2F49  a7
        JP      m,L2EFB                 ; 2F4A  fafb2e
L2F4D:
        JP      FP_OVERFLOW             ; 2F4D  c3ca2c
L2F50:
        LD      A,(V_42F4)              ; 2F50  3af442
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
        LD      A,(V_42EC)              ; 2F80  3aec42
        RRA                             ; 2F83  1f
        LD      (V_42EC),A              ; 2F84  32ec42
        RET                             ; 2F87  c9
; ---- Textzeichen holen; ASCII 0..9 als Ziffer liefern, andere Zeichen mit Carry markieren.
FP_READ_DIGIT:
        LD      HL,(V_42F6)             ; 2F88  2af642
        LD      A,(HL)                  ; 2F8B  7e
        INC     HL                      ; 2F8C  23
        LD      (V_42F6),HL             ; 2F8D  22f642
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
        LD      HL,(V_42FB)             ; 2FB3  2afb42
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
        LD      HL,(V_42FB)             ; 2FD8  2afb42
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
        LD      HL,(V_42FB)             ; 3006  2afb42
        LD      BC,0700H                ; 3009  010007
        POP     AF                      ; 300C  f1
        JR      z,L3012                 ; 300D  2803
        LD      BC,1088H                ; 300F  018810
L3012:
        LD      A,H                     ; 3012  7c
        OR      L                       ; 3013  b5
        JR      nz,L301A                ; 3014  2004
        LD      (V_42FB),BC             ; 3016  ed43fb42
L301A:
        POP     HL                      ; 301A  e1
        LD      (V_42F6),HL             ; 301B  22f642
        LD      (V_42F8),HL             ; 301E  22f842
        LD      HL,(FAC_SIGN_MSB)       ; 3021  2ae542
        LD      (V_42F1),HL             ; 3024  22f142
        RES     7,L                     ; 3027  cbbd
        LD      (FAC_SIGN_MSB),HL       ; 3029  22e542
        XOR     A                       ; 302C  af
L302D:
        LD      (V_42F3),A              ; 302D  32f342
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
        LD      (V_42F2),A              ; 30B8  32f242
        CALL    L2F9A                   ; 30BB  cd9a2f
        RES     7,(HL)                  ; 30BE  cbbe
        LD      A,(V_42F2)              ; 30C0  3af242
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
        LD      DE,(V_42FB)             ; 30D6  ed5bfb42
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
        LD      HL,(V_42F8)             ; 311D  2af842
        INC     HL                      ; 3120  23
        LD      (HL),A                  ; 3121  77
        LD      (V_42F8),HL             ; 3122  22f842
        RET                             ; 3125  c9
L3126:
        LD      A,(V_42F2)              ; 3126  3af242
        CALL    L311D                   ; 3129  cd1d31
        CALL    FP_DECIMAL_DIGIT        ; 312C  cda830
L312F:
        DEC     C                       ; 312F  0d
        JP      p,L3126                 ; 3130  f22631
; ---- Verworfene Folgeziffer >=5: Betrag dezimal aufrunden, Uebertrag ueber 9er-Kette.
        LD      A,(ARG)                 ; 3133  3ae742
        LD      B,A                     ; 3136  47
        LD      HL,(V_42F8)             ; 3137  2af842
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
        LD      HL,V_42F3               ; 3154  21f342
        INC     (HL)                    ; 3157  34
L3158:
        LD      BC,(V_42FB)             ; 3158  ed4bfb42
        LD      HL,(V_42F6)             ; 315C  2af642
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
        LD      HL,V_42F3               ; 316E  21f342
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
        LD      HL,(V_42F8)             ; 3189  2af842
L318C:
        LD      (HL),30H                ; 318C  3630
        INC     HL                      ; 318E  23
        DJNZ    L318C                   ; 318F  10fb
        JR      L3196                   ; 3191  1803
L3193:
        LD      HL,(V_42F8)             ; 3193  2af842
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
        LD      A,(V_42F3)              ; 31A6  3af342
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
        LD      A,(V_42F1)              ; 31BA  3af142
        OR      A                       ; 31BD  b7
        JP      p,L31C4                 ; 31BE  f2c431
        LD      (HL),2DH                ; 31C1  362d
        DEC     HL                      ; 31C3  2b
L31C4:
        LD      D,H                     ; 31C4  54
        LD      E,L                     ; 31C5  5d
        LD      BC,(V_42F6)             ; 31C6  ed4bf642
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
        LD      A,(V_42FC)              ; 31D8  3afc42
        LD      B,A                     ; 31DB  47
        LD      HL,0                    ; 31DC  210000
        LD      (V_42FB),HL             ; 31DF  22fb42
        RET                             ; 31E2  c9
L31E3:
        LD      A,(ARG)                 ; 31E3  3ae742
        DEC     A                       ; 31E6  3d
        LD      C,A                     ; 31E7  4f
        LD      HL,(V_42F6)             ; 31E8  2af642
        ADD     A,8                     ; 31EB  c608
        LD      (V_42FC),A              ; 31ED  32fc42
        ADD     A,L                     ; 31F0  85
        LD      L,A                     ; 31F1  6f
        JR      nc,L31F5                ; 31F2  3001
        INC     H                       ; 31F4  24
; ---- Exponentialausgabe: E, explizites Vorzeichen und zwei Dezimalziffern des Exponenten.
L31F5:
        DEC     HL                      ; 31F5  2b
        LD      A,(V_42F3)              ; 31F6  3af342
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
        LD      A,(V_42F3)              ; 3211  3af342
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
        LD      (V_42F3),A              ; 3223  32f342
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
        LD      (V_42FB),HL             ; 3269  22fb42
        RET                             ; 326C  c9
L326D:
        BIT     7,E                     ; 326D  cb7b
        JR      nz,L3255                ; 326F  20e4
        LD      L,A                     ; 3271  6f
        JR      L3261                   ; 3272  18ed
; ---- Signed-16-Bit-Integer in FAC auf 32 Bit vorzeichenerweitern und exakt nach FP wandeln.
INT16_TO_FP:
        LD      HL,0                    ; 3274  210000
        LD      A,(V_42E3)              ; 3277  3ae342
        RLA                             ; 327A  17
        JR      nc,L327E                ; 327B  3001
        DEC     HL                      ; 327D  2b
L327E:
        LD      (V_42E4),HL             ; 327E  22e442
; ---- Signed-32-Bit-Wert nach FP: Typ=2, e=31, ggf. Betrag bilden und normalisieren.
INT32_TO_FP:
        LD      A,2                     ; 3281  3e02
        LD      (FAC_TYPE),A            ; 3283  32e142
        LD      A,1FH                   ; 3286  3e1f
        LD      (FAC_EXP),A             ; 3288  32e642
        LD      HL,(V_42E4)             ; 328B  2ae442
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
        LD      (V_42E4),HL             ; 32AF  22e442
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
        LD      HL,(V_42E4)             ; 32D6  2ae442
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
        LD      DE,(V_419A)             ; 32F7  ed5b9a41
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
        LD      DE,(V_419A)             ; 3308  ed5b9a41
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
