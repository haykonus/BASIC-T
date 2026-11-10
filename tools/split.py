# Teilt den von gen.py erzeugten Gesamtquelltext src/basict.asm in
# Module auf. Die Hauptdatei behaelt Kopf und Konfiguration und bindet
# die Module per INCLUDE ein; das Assemblat bleibt byte-identisch.
# Grenzen sind Abschnittsueberschriften (erste Titelzeile nach ;====).
MODS=[
 ('PROGRAMMSTART UND INITIALISIERUNG','core_syntax.inc',
  'Start, Hauptschleife, Syntaxmaschine, Grammatik, Syntaxaktionen'),
 ('OPTAB: SPRUNGTABELLE DER LAUFZEIT','core_run.inc',
  'OPTAB, Laufzeitschleife, Befehle/Funktionen, Zwischencode'),
 ('GLEITKOMMA: FORMAT UND SCHNITTSTELLEN','core_fp.inc',
  'Gleitkomma-Arithmetik, Funktionen, Zahlenwandlung'),
 ('PROGRAMMZEILEN-VERWALTUNG','core_lines.inc',
  'Zeilenverwaltung, Fehlerbehandlung, Meldungen'),
 ('LOGISCHE EIN/AUSGABE UEBER KANALBLOECKE','core_io.inc',
  'Logische E/A ueber Kanalbloecke (systemunabhaengig)'),
 ('PHYSISCHE TREIBER FUER CP/M','io_cpm.inc',
  'CP/M-Treiber Konsole/Drucker, DRVTAB: bei Portierung anpassen'),
 ('ED_LINE: ZEILENEDITOR','core_edit.inc',
  'Zeileneditor, nur ueber CONIN/CONOUT (systemunabhaengig)'),
 ('DATEI-EIN/AUSGABE UEBER CP/M','io_cpmfile.inc',
  'CP/M-Datei-E/A (FCB, LOAD/SAVE): bei Portierung anpassen'),
 ('GRAFIKMODUL (1986 hinzugefuegt)','gfx_tur.inc',
  'Grafikmodul fuer die TuR-Grafikhardware (Port 08H, 9000H)'),
 ('ARBEITSSPEICHER ab RAM_BASE','ram.inc',
  'Arbeitsspeicher als DS-Labels ab RAM_BASE'),
]
L=open('src/basict.asm').read().rstrip('\n').split('\n')
assert L[-1].strip()=='END'
L=L[:-1]
cut=[]
for title,_,_ in MODS:
    i=[k for k in range(1,len(L)) if L[k-1].startswith(';====') and L[k].startswith('; '+title)]
    assert len(i)==1,title
    cut.append(i[0]-1)
main=L[:cut[0]]
while main and main[-1]=='': main.pop()
main+=['',';'+'='*69,'; MODULE (Reihenfolge = Speicherreihenfolge, nicht umstellen)',';'+'='*69]
for n,(title,f,desc) in enumerate(MODS):
    a=cut[n]; b=cut[n+1] if n+1<len(cut) else len(L)
    body=L[a:b]
    while body and body[-1]=='': body.pop()
    hdr=['; '+f+' - '+desc,'; Teil von basict.asm (per INCLUDE), nicht einzeln assemblierbar.','']
    open('src/'+f,'w').write('\n'.join(hdr+body)+'\n')
    main.append('        INCLUDE "%s"%s; %s'%(f,' '*max(1,16-len(f)),desc))
main+=['','        END']
open('src/basict.asm','w').write('\n'.join(main)+'\n')
