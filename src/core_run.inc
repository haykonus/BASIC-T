; core_run.inc - OPTAB, Laufzeitschleife, Befehle/Funktionen, Zwischencode
; Teil von basict.asm (per INCLUDE), nicht einzeln assemblierbar.

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
        LD      (V_41B9),A              ; 134B  32b941
        CALL    L226A                   ; 134E  cd6a22
        JR      nz,L1361                ; 1351  200e
L1353:
        LD      A,(V_41B9)              ; 1353  3ab941
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
        LD      A,(V_41B9)              ; 136E  3ab941
        AND     A                       ; 1371  a7
        CALL    nz,L35BF                ; 1372  c4bf35
        POP     HL                      ; 1375  e1
        LD      IY,(V_41F1)             ; 1376  fd2af141
        CALL    L255D                   ; 137A  cd5d25
        CALL    L34B7                   ; 137D  cdb734
        CALL    LINE_NEXT               ; 1380  cd1f33
        LD      A,1                     ; 1383  3e01
        JR      L134B                   ; 1385  18c4
L1387:
        EX      (SP),HL                 ; 1387  e3
        PUSH    HL                      ; 1388  e5
        CALL    L1353                   ; 1389  cd5313
        LD      HL,V_41C1               ; 138C  21c141
        BIT     5,(HL)                  ; 138F  cb6e
        JR      z,L1399                 ; 1391  2806
        LD      IY,(V_41F3)             ; 1393  fd2af341
        JR      L13A6                   ; 1397  180d
L1399:
        LD      HL,V_41C2               ; 1399  21c241
        BIT     2,(HL)                  ; 139C  cb56
        JR      z,L13A6                 ; 139E  2806
        RES     2,(HL)                  ; 13A0  cb96
        LD      IY,V_4204               ; 13A2  fd210442
L13A6:
        POP     HL                      ; 13A6  e1
        CALL    L255D                   ; 13A7  cd5d25
        POP     HL                      ; 13AA  e1
        CALL    L239E                   ; 13AB  cd9e23
        CALL    L34B7                   ; 13AE  cdb734
        CALL    LINE_NEXT               ; 13B1  cd1f33
        JR      L134A                   ; 13B4  1894
L13B6:
        LD      HL,V_41C1               ; 13B6  21c141
        SET     5,(HL)                  ; 13B9  cbee
        LD      IY,(V_41F3)             ; 13BB  fd2af341
        CALL    CH_OPEN                 ; 13BF  cd8335
        CALL    L1343                   ; 13C2  cd4313
        LD      HL,D349D                ; 13C5  219d34
        CALL    L3608                   ; 13C8  cd0836
        LD      HL,V_41C1               ; 13CB  21c141
        RES     5,(HL)                  ; 13CE  cbae
        JP      CH_CLOSE                ; 13D0  c3ab35
L13D3:
        LD      HL,V_41C1               ; 13D3  21c141
        SET     5,(HL)                  ; 13D6  cbee
        LD      IY,(V_41F7)             ; 13D8  fd2af741
        BIT     0,(IY)                  ; 13DC  fdcb0046
        CALL    z,CH_OPEN               ; 13E0  cc8335
        JP      L0159                   ; 13E3  c35901
L13E6:
        LD      HL,(V_41B9)             ; 13E6  2ab941
        LD      A,H                     ; 13E9  7c
        OR      L                       ; 13EA  b5
        JR      nz,L13F0                ; 13EB  2003
        LD      HL,64H                  ; 13ED  216400
L13F0:
        LD      (V_41BD),HL             ; 13F0  22bd41
        LD      HL,(V_41BB)             ; 13F3  2abb41
        LD      A,H                     ; 13F6  7c
        OR      L                       ; 13F7  b5
        JR      nz,L13FD                ; 13F8  2003
        LD      HL,10                   ; 13FA  210a00
L13FD:
        LD      (V_41BF),HL             ; 13FD  22bf41
        RET                             ; 1400  c9
L1401:
        CALL    L224D                   ; 1401  cd4d22
        CALL    L225F                   ; 1404  cd5f22
        RET     z                       ; 1407  c8
L1408:
        CALL    L226A                   ; 1408  cd6a22
        RET     z                       ; 140B  c8
        LD      (V_418C),HL             ; 140C  228c41
        CALL    L227E                   ; 140F  cd7e22
        JR      L1408                   ; 1412  18f4
L1414:
        JP      CPM_EXIT                ; 1414  c35e37
L1417:
        CALL    L224D                   ; 1417  cd4d22
        CALL    L148F                   ; 141A  cd8f14
        CALL    L225F                   ; 141D  cd5f22
        JP      z,X_STOP                ; 1420  ca7615
L1423:
        LD      A,7                     ; 1423  3e07
        CALL    L226C                   ; 1425  cd6c22
        JP      z,X_STOP                ; 1428  ca7615
        PUSH    AF                      ; 142B  f5
        CALL    L143A                   ; 142C  cd3a14
        POP     AF                      ; 142F  f1
        BIT     1,A                     ; 1430  cb4f
        JP      nz,X_STOP               ; 1432  c27615
        CALL    LINE_SET                ; 1435  cd2633
        JR      L1423                   ; 1438  18e9
L143A:
        LD      HL,6                    ; 143A  210600
        ADD     HL,BC                   ; 143D  09
        LD      E,(HL)                  ; 143E  5e
        INC     HL                      ; 143F  23
        LD      D,(HL)                  ; 1440  56
        LD      A,D                     ; 1441  7a
        OR      E                       ; 1442  b3
        LD      (V_41DA),BC             ; 1443  ed43da41
        JR      z,L145C                 ; 1447  2813
        PUSH    DE                      ; 1449  d5
        POP     IX                      ; 144A  dde1
        LD      A,E                     ; 144C  7b
        ADD     A,(IX)                  ; 144D  dd8600
        INC     IX                      ; 1450  dd23
        INC     A                       ; 1452  3c
        LD      (V_41DC),A              ; 1453  32dc41
        CALL    L34B7                   ; 1456  cdb734
        CALL    RUNLOOP                 ; 1459  cd6014
L145C:
        LD      HL,(V_41DA)             ; 145C  2ada41
        RET                             ; 145F  c9

;=====================================================================
; LAUFZEITSCHLEIFE (RUNLOOP)
; IX zeigt in den Zwischencode. Opcode holen, ueber OPTAB springen.
; Die Routinen X_xxx kehren mit RET hierher zurueck.
;=====================================================================
RUNLOOP:
        LD      A,(V_41DC)              ; 1460  3adc41
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
L148F:
        LD      BC,(V_41B2)             ; 148F  ed4bb241
        LD      A,B                     ; 1493  78
        OR      C                       ; 1494  b1
        CALL    nz,L172C                ; 1495  c42c17
        XOR     A                       ; 1498  af
        LD      (V_4002),A              ; 1499  320240
        LD      (V_41E4),A              ; 149C  32e441
        LD      HL,V_41C1               ; 149F  21c141
        SET     1,(HL)                  ; 14A2  cbce
        RES     4,(HL)                  ; 14A4  cba6
        BIT     2,(HL)                  ; 14A6  cb56
        RET     nz                      ; 14A8  c0
        LD      HL,V_41A6               ; 14A9  21a641
        CALL    L1545                   ; 14AC  cd4515
        JR      z,L14B9                 ; 14AF  2808
L14B1:
        LD      (HL),C                  ; 14B1  71
        INC     HL                      ; 14B2  23
        LD      (HL),B                  ; 14B3  70
        CALL    L1540                   ; 14B4  cd4015
        JR      nz,L14B1                ; 14B7  20f8
L14B9:
        LD      HL,V_41AA               ; 14B9  21aa41
        CALL    L1545                   ; 14BC  cd4515
        JR      z,L14C9                 ; 14BF  2808
L14C1:
        LD      (HL),C                  ; 14C1  71
        INC     HL                      ; 14C2  23
        LD      (HL),B                  ; 14C3  70
        CALL    L1540                   ; 14C4  cd4015
        JR      nz,L14C1                ; 14C7  20f8
L14C9:
        LD      HL,V_41A8               ; 14C9  21a841
        LD      DE,V_41AA               ; 14CC  11aa41
        CALL    L1548                   ; 14CF  cd4815
        JR      z,L14E3                 ; 14D2  280f
L14D4:
        EX      DE,HL                   ; 14D4  eb
        LD      HL,6                    ; 14D5  210600
        ADD     HL,BC                   ; 14D8  09
        LD      BC,2                    ; 14D9  010200
        LDIR                            ; 14DC  edb0
        CALL    L1540                   ; 14DE  cd4015
        JR      nz,L14D4                ; 14E1  20f1
L14E3:
        LD      HL,0                    ; 14E3  210000
        PUSH    HL                      ; 14E6  e5
        LD      HL,V_41B0               ; 14E7  21b041
        CALL    LINE_SET                ; 14EA  cd2633
L14ED:
        PUSH    HL                      ; 14ED  e5
        LD      (V_41DA),HL             ; 14EE  22da41
        LD      BC,6                    ; 14F1  010600
        ADD     HL,BC                   ; 14F4  09
        LD      A,(HL)                  ; 14F5  7e
        INC     HL                      ; 14F6  23
        LD      H,(HL)                  ; 14F7  66
        LD      L,A                     ; 14F8  6f
        INC     HL                      ; 14F9  23
        LD      A,(HL)                  ; 14FA  7e
        INC     HL                      ; 14FB  23
        LD      E,(HL)                  ; 14FC  5e
        INC     HL                      ; 14FD  23
        LD      D,(HL)                  ; 14FE  56
        CP      80H                     ; 14FF  fe80
        JR      nz,L1506                ; 1501  2003
        PUSH    DE                      ; 1503  d5
        JR      L152B                   ; 1504  1825
L1506:
        CP      82H                     ; 1506  fe82
        POP     HL                      ; 1508  e1
        JR      nz,L152B                ; 1509  2020
        EX      (SP),HL                 ; 150B  e3
        AND     A                       ; 150C  a7
        SBC     HL,DE                   ; 150D  ed52
        JR      nz,L1535                ; 150F  2024
        POP     DE                      ; 1511  d1
        POP     HL                      ; 1512  e1
        PUSH    HL                      ; 1513  e5
        ADD     HL,BC                   ; 1514  09
        LD      A,(HL)                  ; 1515  7e
        INC     HL                      ; 1516  23
        LD      H,(HL)                  ; 1517  66
        LD      L,A                     ; 1518  6f
        ADD     HL,BC                   ; 1519  09
        LD      (HL),E                  ; 151A  73
        INC     HL                      ; 151B  23
        LD      (HL),D                  ; 151C  72
        POP     HL                      ; 151D  e1
        EX      DE,HL                   ; 151E  eb
        ADD     HL,BC                   ; 151F  09
        LD      A,(HL)                  ; 1520  7e
        INC     HL                      ; 1521  23
        LD      H,(HL)                  ; 1522  66
        LD      L,A                     ; 1523  6f
        INC     HL                      ; 1524  23
        INC     HL                      ; 1525  23
        INC     HL                      ; 1526  23
        INC     HL                      ; 1527  23
        LD      (HL),E                  ; 1528  73
        INC     HL                      ; 1529  23
        LD      (HL),D                  ; 152A  72
L152B:
        CALL    LINE_NEXT               ; 152B  cd1f33
        JR      nz,L14ED                ; 152E  20bd
        POP     HL                      ; 1530  e1
        LD      A,H                     ; 1531  7c
        OR      L                       ; 1532  b5
        JR      z,L153A                 ; 1533  2805
L1535:
        LD      A,15H                   ; 1535  3e15
        JP      ERROR                   ; 1537  c35933
L153A:
        LD      HL,V_41C1               ; 153A  21c141
        SET     2,(HL)                  ; 153D  cbd6
        RET                             ; 153F  c9
L1540:
        CALL    LINE_NEXT               ; 1540  cd1f33
        JR      L154F                   ; 1543  180a
L1545:
        LD      DE,V_41B0               ; 1545  11b041
L1548:
        LD      (V_41C3),DE             ; 1548  ed53c341
        CALL    LINE_SET                ; 154C  cd2633
L154F:
        RET     z                       ; 154F  c8
        LD      (V_41DA),HL             ; 1550  22da41
        INC     HL                      ; 1553  23
        INC     HL                      ; 1554  23
        INC     HL                      ; 1555  23
        INC     HL                      ; 1556  23
        LD      C,(HL)                  ; 1557  4e
        INC     HL                      ; 1558  23
        LD      B,(HL)                  ; 1559  46
        INC     HL                      ; 155A  23
        PUSH    HL                      ; 155B  e5
        LD      HL,(V_419A)             ; 155C  2a9a41
        PUSH    HL                      ; 155F  e5
        LD      H,B                     ; 1560  60
        LD      L,C                     ; 1561  69
        LD      A,2                     ; 1562  3e02
        LD      DE,(V_41C3)             ; 1564  ed5bc341
        CALL    LINE_FIND               ; 1568  cd3533
        POP     HL                      ; 156B  e1
        LD      (V_419A),HL             ; 156C  229a41
        POP     HL                      ; 156F  e1
        RET     nz                      ; 1570  c0
        LD      A,14H                   ; 1571  3e14
        JP      ERROR                   ; 1573  c35933
X_STOP:
        LD      HL,V_41AC               ; 1576  21ac41
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
        LD      HL,V_41C1               ; 1592  21c141
        RES     1,(HL)                  ; 1595  cb8e
        JP      L0258                   ; 1597  c35802
L159A:
        LD      HL,V_419E               ; 159A  219e41
        LD      B,16H                   ; 159D  0616
L159F:
        LD      (HL),0                  ; 159F  3600
        INC     HL                      ; 15A1  23
        DJNZ    L159F                   ; 15A2  10fb
        LD      HL,STACK_TOP            ; 15A4  21ad43
        LD      (SP_INIT),HL            ; 15A7  229c41
        XOR     A                       ; 15AA  af
        LD      (V_41C1),A              ; 15AB  32c141
        LD      HL,V_420D               ; 15AE  210d42
        LD      (V_41F1),HL             ; 15B1  22f141
        LD      (V_41F3),HL             ; 15B4  22f341
        LD      HL,CHANTAB              ; 15B7  21fb41
        LD      (V_41F7),HL             ; 15BA  22f741
        JP      L046D                   ; 15BD  c36d04
L15C0:
        RET                             ; 15C0  c9

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
        LD      DE,L163A                ; 1633  113a16
        PUSH    IX                      ; 1636  dde5
        PUSH    DE                      ; 1638  d5
        JP      (HL)                    ; 1639  e9
L163A:
        POP     IX                      ; 163A  dde1
        RET                             ; 163C  c9
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
        LD      HL,(RAMTOP)             ; 1677  2ab741
        JR      L16C9                   ; 167A  184d
X_SIZE:
        LD      HL,(RAMTOP)             ; 167C  2ab741
        LD      DE,(SP_INIT)            ; 167F  ed5b9c41
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
        LD      IY,(V_41F7)             ; 16D4  fd2af741
        LD      A,IYL                   ; 16D8  fd7d
        SUB     0FBH                    ; 16DA  d6fb
        JR      z,L16E3                 ; 16DC  2805
        CALL    CH_IN                   ; 16DE  cd5035
        JR      L16F4                   ; 16E1  1811
L16E3:
        LD      A,(V_41E4)              ; 16E3  3ae441
        LD      L,A                     ; 16E6  6f
        XOR     A                       ; 16E7  af
        LD      (V_41E4),A              ; 16E8  32e441
        OR      L                       ; 16EB  b5
        JR      nz,L16C7                ; 16EC  20d9
L16EE:
        CALL    KEY_CHECK               ; 16EE  cd6d35
        AND     A                       ; 16F1  a7
        JR      z,L16EE                 ; 16F2  28fa
L16F4:
        LD      L,A                     ; 16F4  6f
        JR      L16C7                   ; 16F5  18d0
X_ERRN:
        LD      A,(V_41E3)              ; 16F7  3ae341
        JR      L16F4                   ; 16FA  18f8
X_ERLN:
        LD      HL,(V_41E1)             ; 16FC  2ae141
        JR      L16C9                   ; 16FF  18c8
X_RESTORE:
        CALL    FETCH_WORD              ; 1701  cd661e
        LD      A,H                     ; 1704  7c
        OR      L                       ; 1705  b5
        LD      BC,(V_41B2)             ; 1706  ed4bb241
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
        LD      DE,V_41B2               ; 171B  11b241
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
        LD      (V_41DE),HL             ; 1730  22de41
        LD      A,1                     ; 1733  3e01
        LD      (V_41E0),A              ; 1735  32e041
        RET                             ; 1738  c9
L1739:
        LD      HL,(V_41DE)             ; 1739  2ade41
        LD      A,H                     ; 173C  7c
        OR      L                       ; 173D  b5
        JR      z,L1754                 ; 173E  2814
        LD      A,(V_41E0)              ; 1740  3ae041
        DEC     A                       ; 1743  3d
        CP      (HL)                    ; 1744  be
        INC     A                       ; 1745  3c
        INC     A                       ; 1746  3c
        LD      (V_41E0),A              ; 1747  32e041
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
        LD      HL,V_41C1               ; 17BA  21c141
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
        LD      (V_41DA),HL             ; 17FE  22da41
        POP     DE                      ; 1801  d1
        RET                             ; 1802  c9
L1803:
        POP     DE                      ; 1803  d1
        RET                             ; 1804  c9
L1805:
        INC     IX                      ; 1805  dd23
        INC     IX                      ; 1807  dd23
        LD      HL,V_41C1               ; 1809  21c141
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
        LD      HL,V_41C2               ; 1849  21c241
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
        LD      HL,(V_4192)             ; 186C  2a9241
        LD      A,15                    ; 186F  3e0f
        AND     (HL)                    ; 1871  a6
        CP      3                       ; 1872  fe03
        DEC     IX                      ; 1874  dd2b
        DEC     IX                      ; 1876  dd2b
        JP      nz,L15D1                ; 1878  c2d115
        LD      HL,V_4002               ; 187B  210240
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
        LD      HL,V_41C2               ; 18B2  21c241
        SET     1,(HL)                  ; 18B5  cbce
X_GOSUB:
        LD      (V_41CD),IX             ; 18B7  dd22cd41
        LD      HL,(V_41DA)             ; 18BB  2ada41
        LD      (V_41CB),HL             ; 18BE  22cb41
        LD      HL,V_41CB               ; 18C1  21cb41
        LD      A,(V_41DC)              ; 18C4  3adc41
        LD      (V_41CF),A              ; 18C7  32cf41
        LD      BC,5                    ; 18CA  010500
        LD      DE,V_41A0               ; 18CD  11a041
        CALL    L2085                   ; 18D0  cd8520
X_GOTO:
        CALL    FETCH_WORD              ; 18D3  cd661e
        LD      DE,6                    ; 18D6  110600
        ADD     HL,DE                   ; 18D9  19
        LD      E,(HL)                  ; 18DA  5e
        INC     HL                      ; 18DB  23
        LD      D,(HL)                  ; 18DC  56
L18DD:
        LD      HL,V_41DB               ; 18DD  21db41
        LD      (HL),D                  ; 18E0  72
        DEC     HL                      ; 18E1  2b
        LD      (HL),E                  ; 18E2  73
        POP     DE                      ; 18E3  d1
        POP     DE                      ; 18E4  d1
        RET                             ; 18E5  c9
X_RETURN:
        LD      HL,V_41A0               ; 18E6  21a041
        LD      (V_419A),HL             ; 18E9  229a41
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
        LD      (V_41DC),A              ; 18FC  32dc41
        LD      (V_41DA),DE             ; 18FF  ed53da41
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
        LD      A,(V_4002)              ; 1916  3a0240
        PUSH    AF                      ; 1919  f5
        CALL    RUNLOOP                 ; 191A  cd6014
        POP     BC                      ; 191D  c1
        LD      C,B                     ; 191E  48
        LD      A,(V_4002)              ; 191F  3a0240
        SUB     C                       ; 1922  91
        LD      B,A                     ; 1923  47
        LD      DE,V_4003               ; 1924  110340
        LD      H,0                     ; 1927  2600
        LD      L,C                     ; 1929  69
        ADD     HL,DE                   ; 192A  19
        EX      DE,HL                   ; 192B  eb
        CALL    L1FE9                   ; 192C  cde91f
        XOR     A                       ; 192F  af
        LD      (V_4002),A              ; 1930  320240
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
        LD      DE,V_41F6               ; 1A78  11f641
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
        LD      HL,V_41F6               ; 1A92  21f641
        SBC     HL,DE                   ; 1A95  ed52
        LD      HL,V_4231               ; 1A97  213142
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
        LD      BC,V_41F5               ; 1ADC  01f541
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
        CALL    KEY_FLUSH               ; 1AFB  cd2836
        CALL    L0F6F                   ; 1AFE  cd6f0f
        LD      A,(V_4001)              ; 1B01  3a0140
        CP      20H                     ; 1B04  fe20
        PUSH    AF                      ; 1B06  f5
        JR      z,L1B0D                 ; 1B07  2804
        CP      2CH                     ; 1B09  fe2c
        JR      nz,L1B10                ; 1B0B  2003
L1B0D:
        CALL    L0F6F                   ; 1B0D  cd6f0f
L1B10:
        LD      A,(V_4000)              ; 1B10  3a0040
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
        LD      HL,CHANTAB              ; 1B26  21fb41
        LD      (V_41F7),HL             ; 1B29  22f741
        LD      HL,0                    ; 1B2C  210000
        LD      (ED_RPTR),HL            ; 1B2F  228840
        CALL    CON_CR                  ; 1B32  cd2f36
        POP     AF                      ; 1B35  f1
        JR      L1AFB                   ; 1B36  18c3
L1B38:
        INC     B                       ; 1B38  04
L1B39:
        LD      A,B                     ; 1B39  78
        LD      (FAC_TYPE),A            ; 1B3A  32e142
        LD      DE,V_4003               ; 1B3D  110340
        CALL    FAC_LOAD                ; 1B40  cd9f26
        CALL    L0F6F                   ; 1B43  cd6f0f
        LD      A,(V_4000)              ; 1B46  3a0040
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
        CALL    KEY_FLUSH               ; 1B65  cd2836
        LD      IY,(V_41F7)             ; 1B68  fd2af741
        LD      HL,V_4003               ; 1B6C  210340
        LD      B,0FFH                  ; 1B6F  06ff
L1B71:
        CALL    CH_IN                   ; 1B71  cd5035
        LD      (HL),A                  ; 1B74  77
        INC     HL                      ; 1B75  23
        LD      DE,(ED_RPTR)            ; 1B76  ed5b8840
        INC     DE                      ; 1B7A  13
        LD      (ED_RPTR),DE            ; 1B7B  ed538840
        CP      1EH                     ; 1B7F  fe1e
        JR      z,L1B86                 ; 1B81  2803
        DJNZ    L1B71                   ; 1B83  10ec
        INC     B                       ; 1B85  04
L1B86:
        LD      A,B                     ; 1B86  78
        CPL                             ; 1B87  2f
        LD      HL,V_4002               ; 1B88  210240
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
        LD      (V_4002),A              ; 1BC0  320240
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
        LD      (V_42FB),DE             ; 1BE0  ed53fb42
        RET                             ; 1BE4  c9
L1BE5:
        LD      IY,(V_41F3)             ; 1BE5  fd2af341
L1BE9:
        LD      DE,V_4003               ; 1BE9  110340
        CALL    NUMBER_FORMAT           ; 1BEC  cdb22f
        LD      HL,V_4004               ; 1BEF  210440
        JP      L3620                   ; 1BF2  c32036
L1BF5:
        LD      IY,(V_41F3)             ; 1BF5  fd2af341
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
        LD      IY,(V_41F3)             ; 1C19  fd2af341
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
        LD      IY,(V_41F9)             ; 1C35  fd2af941
        JP      CH_OPEN                 ; 1C39  c38335
X_CLOSE:
        CALL    X_GET                   ; 1C3C  cd461c
        LD      IY,(V_41F9)             ; 1C3F  fd2af941
        JP      CH_CLOSE                ; 1C43  c3ab35
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
        LD      (V_41F9),HL             ; 1C54  22f941
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
        LD      IY,(V_41F9)             ; 1C68  fd2af941
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
        LD      DE,D34AC                ; 1C7C  11ac34
L1C7F:
        INC     B                       ; 1C7F  04
        DEC     DE                      ; 1C80  1b
        LD      A,3                     ; 1C81  3e03
        JR      L1C68                   ; 1C83  18e3
L1C85:
        LD      IY,(V_41F9)             ; 1C85  fd2af941
        CALL    L1E97                   ; 1C89  cd971e
        LD      B,C                     ; 1C8C  41
        LD      C,A                     ; 1C8D  4f
        CALL    CH_IN                   ; 1C8E  cd5035
        CP      C                       ; 1C91  b9
L1C92:
        LD      A,25H                   ; 1C92  3e25
        JP      nz,ERROR                ; 1C94  c25933
L1C97:
        CALL    CH_IN                   ; 1C97  cd5035
        LD      (DE),A                  ; 1C9A  12
        INC     DE                      ; 1C9B  13
        DJNZ    L1C97                   ; 1C9C  10f9
        RET                             ; 1C9E  c9
L1C9F:
        LD      IY,(V_41F9)             ; 1C9F  fd2af941
        CALL    CH_IN                   ; 1CA3  cd5035
        CP      3                       ; 1CA6  fe03
        JR      nz,L1C92                ; 1CA8  20e8
        CALL    CH_IN                   ; 1CAA  cd5035
        LD      DE,V_4002               ; 1CAD  110240
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
        LD      DE,V_40EA               ; 1D12  11ea40
        PUSH    DE                      ; 1D15  d5
        CALL    NUMBER_FORMAT           ; 1D16  cdb22f
        POP     HL                      ; 1D19  e1
        INC     HL                      ; 1D1A  23
        JR      L1D2B                   ; 1D1B  180e
X_CHR:
        CALL    FAC_TO_INT              ; 1D1D  cd851f
        LD      A,L                     ; 1D20  7d
        LD      HL,V_42E3               ; 1D21  21e342
        LD      (HL),A                  ; 1D24  77
        LD      B,1                     ; 1D25  0601
        JR      L1D2B                   ; 1D27  1802
        LD      B,(HL)                  ; 1D29  46
        INC     HL                      ; 1D2A  23
L1D2B:
        EX      DE,HL                   ; 1D2B  eb
L1D2C:
        LD      HL,V_4002               ; 1D2C  210240
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
        LD      (V_4002),A              ; 1D47  320240
        RET                             ; 1D4A  c9
L1D4B:
        LD      A,22H                   ; 1D4B  3e22
        JP      ERROR                   ; 1D4D  c35933
L1D50:
        CALL    FAC_TO_INT              ; 1D50  cd851f
        PUSH    HL                      ; 1D53  e5
        LD      DE,(RAMTOP)             ; 1D54  ed5bb741
        AND     A                       ; 1D58  a7
        SBC     HL,DE                   ; 1D59  ed52
        EX      DE,HL                   ; 1D5B  eb
        POP     HL                      ; 1D5C  e1
        RET     z                       ; 1D5D  c8
        JP      nc,L2024                ; 1D5E  d22420
        LD      DE,(SP_INIT)            ; 1D61  ed5b9c41
        AND     A                       ; 1D65  a7
        SBC     HL,DE                   ; 1D66  ed52
        LD      A,4                     ; 1D68  3e04
        JP      c,ERROR                 ; 1D6A  da5933
        ADD     HL,DE                   ; 1D6D  19
        LD      (RAMTOP),HL             ; 1D6E  22b741
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
        DW      DRV_DUMMY               ; 1D84  0337
        DW      G_CLEAR                 ; 1D86  ef3d
        DW      DRV_DUMMY               ; 1D88  0337
        DW      DRV_DUMMY               ; 1D8A  0337
        DW      DRV_DUMMY               ; 1D8C  0337
        DW      DRV_DUMMY               ; 1D8E  0337
        DW      DRV_DUMMY               ; 1D90  0337
        DW      DRV_DUMMY               ; 1D92  0337
        DW      DRV_DUMMY               ; 1D94  0337
        DW      DRV_DUMMY               ; 1D96  0337
        DW      DRV_DUMMY               ; 1D98  0337
        DW      DRV_DUMMY               ; 1D9A  0337
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
        LD      (V_42E4),HL             ; 1F79  22e442
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
        LD      HL,(RAMTOP)             ; 2024  2ab741
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
        LD      (RAMTOP),HL             ; 2035  22b741
        RET                             ; 2038  c9
L2039:
        LD      A,83H                   ; 2039  3e83
        PUSH    HL                      ; 203B  e5
        CALL    ERROR                   ; 203C  cd5933
        POP     HL                      ; 203F  e1
        DEC     HL                      ; 2040  2b
        LD      (RAMTOP),HL             ; 2041  22b741
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
        LD      DE,(SP_INIT)            ; 2059  ed5b9c41
        AND     A                       ; 205D  a7
        SBC     HL,DE                   ; 205E  ed52
        POP     HL                      ; 2060  e1
        JR      nz,L2068                ; 2061  2005
        LD      (SP_INIT),HL            ; 2063  229c41
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
        LD      DE,V_41A4               ; 2072  11a441
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
        LD      DE,(V_419A)             ; 2081  ed5b9a41
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
        LD      HL,V_4002               ; 209A  210240
L209D:
        LD      C,(HL)                  ; 209D  4e
        INC     C                       ; 209E  0c
        LD      B,0                     ; 209F  0600
L20A1:
        LD      DE,(V_419A)             ; 20A1  ed5b9a41
        PUSH    DE                      ; 20A5  d5
        PUSH    HL                      ; 20A6  e5
        CALL    L20B5                   ; 20A7  cdb520
        EX      DE,HL                   ; 20AA  eb
        POP     HL                      ; 20AB  e1
        PUSH    DE                      ; 20AC  d5
        LDIR                            ; 20AD  edb0
        POP     DE                      ; 20AF  d1
        POP     HL                      ; 20B0  e1
        LD      (V_419A),HL             ; 20B1  229a41
        RET                             ; 20B4  c9
L20B5:
        LD      DE,V_41A4               ; 20B5  11a441
        LD      HL,0FFFFH               ; 20B8  21ffff
        LD      (V_41C3),HL             ; 20BB  22c341
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
        LD      HL,(V_41C3)             ; 20DC  2ac341
        SBC     HL,DE                   ; 20DF  ed52
        JR      c,L20F7                 ; 20E1  3814
        PUSH    DE                      ; 20E3  d5
        EX      DE,HL                   ; 20E4  eb
        LD      DE,4                    ; 20E5  110400
        SBC     HL,DE                   ; 20E8  ed52
        POP     DE                      ; 20EA  d1
        JR      c,L20F7                 ; 20EB  380a
        LD      HL,(V_419A)             ; 20ED  2a9a41
        LD      (V_41C5),HL             ; 20F0  22c541
        LD      (V_41C3),DE             ; 20F3  ed53c341
L20F7:
        CALL    LINE_NEXT               ; 20F7  cd1f33
        JR      L20C8                   ; 20FA  18cc
L20FC:
        POP     BC                      ; 20FC  c1
        LD      HL,(V_41C3)             ; 20FD  2ac341
        LD      A,H                     ; 2100  7c
        AND     L                       ; 2101  a5
        INC     A                       ; 2102  3c
        JR      nz,L212F                ; 2103  202a
        LD      HL,(RAMTOP)             ; 2105  2ab741
        LD      DE,(SP_INIT)            ; 2108  ed5b9c41
        SBC     HL,DE                   ; 210C  ed52
        SBC     HL,BC                   ; 210E  ed42
        LD      A,2                     ; 2110  3e02
        JP      c,ERROR                 ; 2112  da5933
        LD      H,B                     ; 2115  60
        LD      L,C                     ; 2116  69
        ADD     HL,DE                   ; 2117  19
        LD      (SP_INIT),HL            ; 2118  229c41
        PUSH    DE                      ; 211B  d5
        PUSH    BC                      ; 211C  c5
        EX      DE,HL                   ; 211D  eb
        LD      HL,(RAMTOP)             ; 211E  2ab741
        SBC     HL,DE                   ; 2121  ed52
        LD      DE,0C8H                 ; 2123  11c800
        SBC     HL,DE                   ; 2126  ed52
        LD      A,81H                   ; 2128  3e81
        CALL    c,ERROR                 ; 212A  dc5933
        JR      L2140                   ; 212D  1811
L212F:
        LD      DE,(V_41C5)             ; 212F  ed5bc541
        CALL    L330C                   ; 2133  cd0c33
        PUSH    HL                      ; 2136  e5
        PUSH    BC                      ; 2137  c5
        ADD     HL,BC                   ; 2138  09
        LD      BC,(V_41C3)             ; 2139  ed4bc341
        CALL    L2057                   ; 213D  cd5720
L2140:
        POP     BC                      ; 2140  c1
        POP     HL                      ; 2141  e1
        RET                             ; 2142  c9
L2143:
        LD      A,6                     ; 2143  3e06
        LD      DE,V_41AC               ; 2145  11ac41
        PUSH    HL                      ; 2148  e5
        CALL    LINE_FIND               ; 2149  cd3533
        POP     HL                      ; 214C  e1
        LD      D,B                     ; 214D  50
        LD      E,C                     ; 214E  59
        BIT     1,A                     ; 214F  cb4f
        RET     nz                      ; 2151  c0
        PUSH    HL                      ; 2152  e5
        LD      (V_41CB),HL             ; 2153  22cb41
        BIT     4,L                     ; 2156  cb65
        LD      HL,V_41D2               ; 2158  21d241
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
L216F:
        AND     1FH                     ; 216F  e61f
        LD      B,A                     ; 2171  47
        LD      A,L                     ; 2172  7d
        AND     1FH                     ; 2173  e61f
        RLA                             ; 2175  17
        RLA                             ; 2176  17
        RLA                             ; 2177  17
        LD      L,A                     ; 2178  6f
        LD      A,H                     ; 2179  7c
        SUB     20H                     ; 217A  d620
        AND     3FH                     ; 217C  e63f
        LD      H,A                     ; 217E  67
        ADD     HL,HL                   ; 217F  29
        ADD     HL,HL                   ; 2180  29
        LD      A,L                     ; 2181  7d
        OR      B                       ; 2182  b0
        LD      L,A                     ; 2183  6f
        RET                             ; 2184  c9
L2185:
        LD      H,0                     ; 2185  2600
        LD      L,A                     ; 2187  6f
        LD      DE,V_41AE               ; 2188  11ae41
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
        LD      HL,V_4002               ; 219E  210240
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
        LD      (V_4003),HL             ; 21BA  220340
        PUSH    BC                      ; 21BD  c5
        POP     HL                      ; 21BE  e1
        LD      (V_4005),HL             ; 21BF  220540
        RET                             ; 21C2  c9
L21C3:
        LD      HL,(V_419A)             ; 21C3  2a9a41
        EX      (SP),HL                 ; 21C6  e3
        PUSH    HL                      ; 21C7  e5
        LD      A,8BH                   ; 21C8  3e8b
        CP      L                       ; 21CA  bd
        LD      HL,V_4003               ; 21CB  210340
        LD      A,(V_4002)              ; 21CE  3a0240
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
        LD      (V_4003),HL             ; 21E4  220340
        LD      (V_4005),DE             ; 21E7  ed530540
        LD      HL,V_4003               ; 21EB  210340
        LD      BC,4                    ; 21EE  010400
        POP     DE                      ; 21F1  d1
        CALL    L2081                   ; 21F2  cd8120
        LD      (V_4005),HL             ; 21F5  220540
        RET                             ; 21F8  c9
L21F9:
        LD      DE,V_41A8               ; 21F9  11a841
        JR      L2201                   ; 21FC  1803
L21FE:
        LD      DE,V_41A6               ; 21FE  11a641
L2201:
        LD      (V_41CD),HL             ; 2201  22cd41
        LD      HL,(V_418C)             ; 2204  2a8c41
        LD      (V_41CB),HL             ; 2207  22cb41
L220A:
        LD      HL,0FFFFH               ; 220A  21ffff
        LD      (V_41CF),HL             ; 220D  22cf41
        LD      HL,V_41C1               ; 2210  21c141
        SET     7,(HL)                  ; 2213  cbfe
        LD      HL,V_41CB               ; 2215  21cb41
        LD      BC,6                    ; 2218  010600
        JP      L2085                   ; 221B  c38520
L221E:
        LD      DE,V_41AA               ; 221E  11aa41
        LD      (V_41CB),HL             ; 2221  22cb41
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
        LD      HL,(V_418C)             ; 2235  2a8c41
        AND     A                       ; 2238  a7
        SBC     HL,DE                   ; 2239  ed52
        LD      A,12                    ; 223B  3e0c
        JP      nz,ERROR                ; 223D  c25933
        POP     DE                      ; 2240  d1
L2241:
        LD      DE,(V_419A)             ; 2241  ed5b9a41
        LD      HL,(V_418C)             ; 2245  2a8c41
        LD      (V_41CD),HL             ; 2248  22cd41
        JR      L220A                   ; 224B  18bd
L224D:
        LD      HL,(V_41BB)             ; 224D  2abb41
        LD      A,H                     ; 2250  7c
        OR      L                       ; 2251  b5
        RET     nz                      ; 2252  c0
        LD      HL,(V_41B9)             ; 2253  2ab941
        LD      A,H                     ; 2256  7c
        OR      L                       ; 2257  b5
        JR      nz,L225B                ; 2258  2001
        DEC     HL                      ; 225A  2b
L225B:
        LD      (V_41BB),HL             ; 225B  22bb41
        RET                             ; 225E  c9
L225F:
        LD      DE,V_41B0               ; 225F  11b041
        LD      HL,(V_41B9)             ; 2262  2ab941
        LD      A,6                     ; 2265  3e06
        JP      LINE_FIND               ; 2267  c33533
L226A:
        LD      A,3                     ; 226A  3e03
L226C:
        LD      HL,(V_41BB)             ; 226C  2abb41
        JP      L3331                   ; 226F  c33133
L2272:
        LD      DE,V_41B0               ; 2272  11b041
        LD      A,6                     ; 2275  3e06
        CALL    LINE_FIND               ; 2277  cd3533
        BIT     1,A                     ; 227A  cb4f
        JR      z,L229C                 ; 227C  281e
L227E:
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
        LD      HL,(V_419A)             ; 229C  2a9a41
        PUSH    HL                      ; 229F  e5
        LD      DE,V_41A6               ; 22A0  11a641
        LD      A,1                     ; 22A3  3e01
L22A5:
        PUSH    AF                      ; 22A5  f5
L22A6:
        LD      HL,(V_418C)             ; 22A6  2a8c41
        LD      A,2                     ; 22A9  3e02
        CALL    LINE_FIND               ; 22AB  cd3533
        JR      z,L22B5                 ; 22AE  2805
        CALL    L22FD                   ; 22B0  cdfd22
        JR      L22A6                   ; 22B3  18f1
L22B5:
        LD      DE,V_41A8               ; 22B5  11a841
        POP     AF                      ; 22B8  f1
        DEC     A                       ; 22B9  3d
        JR      z,L22A5                 ; 22BA  28e9
        LD      HL,V_41AA               ; 22BC  21aa41
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
        LD      HL,(V_418C)             ; 22CE  2a8c41
        SBC     HL,DE                   ; 22D1  ed52
        JR      nz,L22D8                ; 22D3  2003
        CALL    L22FD                   ; 22D5  cdfd22
L22D8:
        CALL    LINE_NEXT               ; 22D8  cd1f33
        JR      nz,L22C4                ; 22DB  20e7
L22DD:
        LD      DE,V_41B2               ; 22DD  11b241
        LD      HL,(V_418C)             ; 22E0  2a8c41
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
        LD      (V_419A),HL             ; 22F9  229a41
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
        LD      (V_410B),A              ; 231A  320b41
        LD      HL,(V_418C)             ; 231D  2a8c41
        LD      A,H                     ; 2320  7c
        OR      L                       ; 2321  b5
        RET     z                       ; 2322  c8
        CALL    L2272                   ; 2323  cd7222
        CALL    L2374                   ; 2326  cd7423
        LD      DE,0                    ; 2329  110000
        LD      A,(V_41B4)              ; 232C  3ab441
        AND     A                       ; 232F  a7
        CALL    nz,L209A                ; 2330  c49a20
        LD      (V_418E),DE             ; 2333  ed538e41
        LD      DE,0                    ; 2337  110000
        LD      HL,V_410B               ; 233A  210b41
        LD      A,(HL)                  ; 233D  7e
        AND     A                       ; 233E  a7
        CALL    nz,L209D                ; 233F  c49d20
        LD      (V_4190),DE             ; 2342  ed539041
        LD      BC,6                    ; 2346  010600
        LD      HL,V_418C               ; 2349  218c41
        CALL    L2081                   ; 234C  cd8120
        LD      HL,V_41C1               ; 234F  21c141
        BIT     3,(HL)                  ; 2352  cb5e
        RET     z                       ; 2354  c8
        RES     3,(HL)                  ; 2355  cb9e
        LD      HL,(V_418C)             ; 2357  2a8c41
        LD      (V_410B),HL             ; 235A  220b41
        LD      DE,V_41B2               ; 235D  11b241
        LD      A,4                     ; 2360  3e04
        CALL    LINE_FIND               ; 2362  cd3533
        LD      HL,V_410B               ; 2365  210b41
        LD      A,(V_410D)              ; 2368  3a0d41
        ADD     A,A                     ; 236B  87
        ADD     A,3                     ; 236C  c603
        LD      B,0                     ; 236E  0600
        LD      C,A                     ; 2370  4f
        JP      L2081                   ; 2371  c38120
L2374:
        LD      DE,(V_4084)             ; 2374  ed5b8440
        DEC     DE                      ; 2378  1b
        LD      HL,V_4003               ; 2379  210340
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
        LD      (V_4002),A              ; 239A  320240
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
        LD      A,(V_41C1)              ; 23C4  3ac141
        RES     6,A                     ; 23C7  cbb7
        JR      nz,L23CD                ; 23C9  2002
        SET     6,A                     ; 23CB  cbf7
L23CD:
        LD      (V_41C1),A              ; 23CD  32c141
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
        LD      A,1EH                   ; 23F3  3e1e
        CALL    L23EB                   ; 23F5  cdeb23
        JP      L2530                   ; 23F8  c33025
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
        LD      DE,(V_4192)             ; 240A  ed5b9241
        LD      (V_4192),HL             ; 240E  229241
        LD      HL,(V_4194)             ; 2411  2a9441
        LD      (V_4194),DE             ; 2414  ed539441
        LD      A,H                     ; 2418  7c
        OR      L                       ; 2419  b5
        RET     z                       ; 241A  c8
        LD      A,H                     ; 241B  7c
        AND     L                       ; 241C  a5
        INC     A                       ; 241D  3c
        CALL    z,L2459                 ; 241E  cc5924
        LD      (V_41CB),HL             ; 2421  22cb41
        LD      HL,V_41CB               ; 2424  21cb41
        LD      DE,V_419E               ; 2427  119e41
        LD      BC,2                    ; 242A  010200
        JP      L2085                   ; 242D  c38520
L2430:
        PUSH    AF                      ; 2430  f5
        LD      DE,V_419E               ; 2431  119e41
        CALL    L330C                   ; 2434  cd0c33
        JR      c,L2440                 ; 2437  3807
        LD      BC,4                    ; 2439  010400
        CALL    L2057                   ; 243C  cd5720
        EX      DE,HL                   ; 243F  eb
L2440:
        LD      DE,(V_4194)             ; 2440  ed5b9441
        LD      (V_4194),HL             ; 2444  229441
        LD      HL,(V_4192)             ; 2447  2a9241
        LD      (V_4192),DE             ; 244A  ed539241
        POP     AF                      ; 244E  f1
        RET                             ; 244F  c9
L2450:
        LD      DE,(V_4192)             ; 2450  ed5b9241
        LD      (V_4192),HL             ; 2454  229241
        EX      DE,HL                   ; 2457  eb
        RET                             ; 2458  c9
L2459:
        LD      HL,V_41C1               ; 2459  21c141
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
        LD      HL,(V_4192)             ; 248D  2a9241
        LD      A,H                     ; 2490  7c
        AND     L                       ; 2491  a5
        INC     A                       ; 2492  3c
        CALL    z,L2459                 ; 2493  cc5924
        LD      (V_4192),HL             ; 2496  229241
        LD      HL,(V_4194)             ; 2499  2a9441
        LD      A,H                     ; 249C  7c
        AND     L                       ; 249D  a5
        INC     A                       ; 249E  3c
        CALL    z,L2459                 ; 249F  cc5924
        LD      (V_4194),HL             ; 24A2  229441
        RET                             ; 24A5  c9
L24A6:
        LD      DE,V_41A2               ; 24A6  11a241
        LD      BC,2                    ; 24A9  010200
        LD      HL,V_4196               ; 24AC  219641
        CALL    L2085                   ; 24AF  cd8520
        LD      HL,(V_4198)             ; 24B2  2a9841
        LD      (V_4196),HL             ; 24B5  229641
        RET                             ; 24B8  c9
L24B9:
        LD      DE,V_41A2               ; 24B9  11a241
        CALL    L330C                   ; 24BC  cd0c33
        JR      c,L24C8                 ; 24BF  3807
        LD      BC,4                    ; 24C1  010400
        CALL    L2057                   ; 24C4  cd5720
        EX      DE,HL                   ; 24C7  eb
L24C8:
        LD      (V_4196),HL             ; 24C8  229641
        RET                             ; 24CB  c9
L24CC:
        LD      A,(V_4197)              ; 24CC  3a9741
        CP      5                       ; 24CF  fe05
        JR      c,L24EF                 ; 24D1  381c
        LD      HL,(V_4192)             ; 24D3  2a9241
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
        LD      A,(V_4196)              ; 24E9  3a9641
        JP      EMIT_BYTE               ; 24EC  c3bc23
L24EF:
        LD      HL,(V_4194)             ; 24EF  2a9441
        LD      A,H                     ; 24F2  7c
        AND     L                       ; 24F3  a5
        INC     A                       ; 24F4  3c
        JR      z,L2524                 ; 24F5  282d
        LD      HL,(V_4192)             ; 24F7  2a9241
        LD      A,H                     ; 24FA  7c
        AND     L                       ; 24FB  a5
        INC     A                       ; 24FC  3c
        JR      nz,L2513                ; 24FD  2014
        LD      HL,(V_4194)             ; 24FF  2a9441
        LD      (V_4192),HL             ; 2502  229241
        LD      A,(V_4196)              ; 2505  3a9641
        CP      9                       ; 2508  fe09
        JR      nc,L251E                ; 250A  3012
        INC     A                       ; 250C  3c
        INC     A                       ; 250D  3c
        LD      (V_4196),A              ; 250E  329641
        JR      L251E                   ; 2511  180b
L2513:
        LD      HL,(V_4194)             ; 2513  2a9441
        CALL    L2530                   ; 2516  cd3025
        LD      A,1EH                   ; 2519  3e1e
        CALL    L23DD                   ; 251B  cddd23
L251E:
        LD      HL,0FFFFH               ; 251E  21ffff
        LD      (V_4194),HL             ; 2521  229441
L2524:
        CALL    L2430                   ; 2524  cd3024
        CALL    L2530                   ; 2527  cd3025
        LD      A,(V_4196)              ; 252A  3a9641
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
        LD      DE,V_41CB               ; 2553  11cb41
        CALL    UINT8_TO_DECIMAL        ; 2556  cdee2d
        LD      B,2                     ; 2559  0602
        JR      L2565                   ; 255B  1808
L255D:
        LD      DE,V_41CB               ; 255D  11cb41
        CALL    UINT16_TO_DECIMAL       ; 2560  cdf32d
        LD      B,4                     ; 2563  0604
L2565:
        LD      C,B                     ; 2565  48
        INC     C                       ; 2566  0c
        LD      HL,V_41CA               ; 2567  21ca41
        LD      A,30H                   ; 256A  3e30
L256C:
        INC     HL                      ; 256C  23
        CP      (HL)                    ; 256D  be
        JR      nz,L2574                ; 256E  2004
        LD      (HL),20H                ; 2570  3620
        DJNZ    L256C                   ; 2572  10f8
L2574:
        LD      HL,V_41CB               ; 2574  21cb41
        LD      B,C                     ; 2577  41
        CALL    L3620                   ; 2578  cd2036
        JP      L3619                   ; 257B  c31936
L257E:
        LD      HL,V_41C1               ; 257E  21c141
        BIT     1,(HL)                  ; 2581  cb4e
        RET     z                       ; 2583  c8
        LD      HL,D347F                ; 2584  217f34
        CALL    PRINT_STR               ; 2587  cde735
        LD      HL,(V_41DA)             ; 258A  2ada41
        INC     HL                      ; 258D  23
        INC     HL                      ; 258E  23
        LD      E,(HL)                  ; 258F  5e
        INC     HL                      ; 2590  23
        LD      D,(HL)                  ; 2591  56
        EX      DE,HL                   ; 2592  eb
        LD      (V_41B9),HL             ; 2593  22b941
        CALL    L255D                   ; 2596  cd5d25
        JP      CH_CRLF                 ; 2599  c3ce35
L259C:
        LD      HL,V_41C1               ; 259C  21c141
        BIT     1,(HL)                  ; 259F  cb4e
        RET     z                       ; 25A1  c8
        LD      HL,(V_41B9)             ; 25A2  2ab941
        LD      A,H                     ; 25A5  7c
        OR      L                       ; 25A6  b5
        RET     z                       ; 25A7  c8
        LD      DE,(V_41BB)             ; 25A8  ed5bbb41
        PUSH    DE                      ; 25AC  d5
        LD      (V_41BB),HL             ; 25AD  22bb41
        CALL    L1346                   ; 25B0  cd4613
        POP     HL                      ; 25B3  e1
        LD      (V_41BB),HL             ; 25B4  22bb41
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
        LD      HL,L25C6                ; 25C1  21c625
        EX      (SP),HL                 ; 25C4  e3
        JP      (HL)                    ; 25C5  e9
L25C6:
        POP     HL                      ; 25C6  e1
        POP     BC                      ; 25C7  c1
        INC     HL                      ; 25C8  23
        RET                             ; 25C9  c9
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
        LD      (V_42E4),DE             ; 2600  ed53e442
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
        LD      (V_42E4),HL             ; 2661  22e442
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
L2694:
        LD      A,(FAC_EXP)             ; 2694  3ae642
        AND     A                       ; 2697  a7
        BIT     7,A                     ; 2698  cb7f
        RET     nz                      ; 269A  c0
        CP      10H                     ; 269B  fe10
        CCF                             ; 269D  3f
        RET                             ; 269E  c9
