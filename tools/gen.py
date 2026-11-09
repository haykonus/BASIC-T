# Erzeugt src/basict.asm (AS-Syntax, nur Leerzeichen, feste Spalten).
import json,re
exec(open('cmt.py').read()); exec(open('names.py').read())
from fp import FP_COMMENTS, FP_NAMES, FP_CONSTANTS
C.update(FP_COMMENTS); N.update(FP_NAMES)
b=open('BASICT.COM','rb').read(); ORG=0x100; END=ORG+len(b)
ins={int(k):v for k,v in json.load(open('ins.json')).items()}
G=json.load(open('gram.json')); nodes={int(k):v for k,v in G['nodes'].items()}
optab=json.load(open('optab.json'))
SC=json.load(open('scan.json')); sents={int(k):v for k,v in SC['ents'].items()}
names=dict(N)
BDOSF={0:'Warmstart',1:'Konsole lesen',2:'Konsole schreiben',6:'Konsole direkt',
 9:'Text ausgeben',10:'Zeile lesen',11:'Konsolstatus',13:'Disk-Reset',14:'Laufwerk waehlen',
 15:'Datei oeffnen',16:'Datei schliessen',17:'Suche erste',19:'Datei loeschen',
 20:'Satz lesen',21:'Satz schreiben',22:'Datei anlegen',23:'Umbenennen',26:'DMA setzen'}
# Schluesselwort -> Syntaxaktion S_xxx; Opcode der Aktion -> Laufzeitroutine X_xxx
def ident(k): return re.sub(r'[^A-Z0-9]','_',k.upper())
opkw={}
for a in sorted(nodes):
    n=nodes[a]; act=n['act']
    if not(n['kw'] and act) or not n['kw'][0].isalpha(): continue
    nm='S_'+ident(n['kw'])
    if act not in names and nm not in names.values(): names[act]=nm
    t=ins.get(act,('',0))[0]
    m=re.match(r'LD (L|A),0x([0-9a-f]{2})$',t)
    if m:
        op=int(m.group(2),16)
        if op%2==0 and op//2<len(optab): opkw.setdefault(op,[]).append(n['kw'])
for op,kws in opkw.items():
    tg=optab[op//2]; nm='X_'+ident(kws[0])
    if tg not in names and nm not in names.values(): names[tg]=nm
targets=set()
for a,(t,n) in ins.items():
    m=t.split()[0]
    if m in('JP','JR','CALL','DJNZ'):
        x=re.findall(r'0x([0-9a-f]+)',t)
        if x and '(' not in t: targets.add(int(x[-1],16))
for n in nodes.values():
    if n['act']: targets.add(n['act'])
targets|=set(optab)|set(SC['actions'])
lab={a:names.get(a,'L%04X'%a) for a in targets if a in ins}
lab.update(names)
# --- Feste Adressen symbolisch machen (Voraussetzung fuer ein anderes ORG) ---
# Befehle, deren 16-Bit-Wert eine Zahl und keine Adresse ist (Adresse des Befehls):
NUMS={0x0F31,0x0F38,0x0F3F,0x0F48,   # Formatangaben FIX/BIN/HEX/FLO
      0x2DF3,0x2DF9,                 # 10000, 1000 (Dezimalwandlung)
      0x3009,0x300F,                 # Zahlenformat-Konstanten
      0x3DF1,0x3E09,0x3E15}          # Laengen beim Loeschen des Bildspeichers
WTAB={0x0307:31,0x1D84:12,0x1028:11} # Adresstabellen RULETAB, GSUBTAB, Zustandstabelle 1028H
DWAT={0x34A5,0x34AD}                 # einzelne Zeiger in Vorlagen hinter den Meldungen
DRVBLK=range(0x3704,0x375E,9)        # Kanalbloecke: Flag, 4 Worte
inner=set()                          # Bytes mitten in Befehl/Knoten/Konstante
for a,(t,n) in ins.items(): inner|=set(range(a+1,a+n))
for a,nd in nodes.items(): inner|=set(range(a+1,nd['end']))
for a,e in sents.items(): inner|=set(range(a+1,e['end']))
for a in FP_CONSTANTS: inner|=set(range(a+1,a+(4 if a==0x2CD8 else 5)))
def isaddr(v): return 0x100<=v<0x3E28
RAM_LO,RAM_TOP=0x4000,0x43AD          # Arbeitsspeicher bis Stack-Obergrenze
def isram(v): return RAM_LO<=v<=RAM_TOP
RAMREF={0x0113:'RAM_BASE-1'}          # Speichertest beginnt unter RAM_BASE
ramcells={v for v in names if isram(v)}
for a0,(t,n) in ins.items():
    if a0 in NUMS or a0 in RAMREF: continue
    for x in re.findall(r'0x([0-9a-f]{3,4})',t):
        if isram(int(x,16)): ramcells.add(int(x,16))
def ramname(v): return names.get(v,'V_%04X'%v)
refs=set()
for a,(t,n) in ins.items():
    if a in NUMS or t.split()[0] in('JP','JR','CALL','DJNZ'): continue
    for x in re.findall(r'0x([0-9a-f]+)',t):
        if isaddr(int(x,16)) and len(x)>2: refs.add(int(x,16))
for t0,cnt in WTAB.items():
    for i in range(cnt): refs.add(b[t0-ORG+2*i]|b[t0-ORG+2*i+1]<<8)
W16=lambda a:b[a-ORG]|b[a-ORG+1]<<8
for t0 in DWAT: refs.add(W16(t0))
for t0 in DRVBLK:
    for k in (1,3,5,7):
        v=W16(t0+k)
        if isaddr(v): refs.add(v)
for i in range(31): lab.setdefault(W16(0x307+2*i),'RULE%02X'%(2*i))
for v in refs:
    if v in inner: raise SystemExit('Adresse %04X liegt mitten in einem Befehl'%v)
    if v not in lab: lab[v]=('L%04X' if v in ins else 'D%04X')%v
def sym(v): return lab[v]
def hx(v,w=2):
    s=('%0'+str(w)+'X')%v
    return ('0' if s[0] in 'ABCDEF' else '')+s+'H'
def conv(a,t):
    m=t.split()[0]; ops=t[len(m):].strip()
    ops=ops.replace('IXH','IXU').replace('IYH','IYU')
    def rep(mo):
        v=int(mo.group(1),16)
        if m=='CALL' and v==5: return 'BDOS'
        if m in('JP','JR','CALL','DJNZ') and v in lab: return lab[v]
        if v in names and v>=0x100 and not ops.startswith('(C)'):
            if not re.search(r'\(0x'+mo.group(1)+r'\)',ops) or m=='LD': return names[v]
        if a in RAMREF and v==0x3FFF: return RAMREF[a]
        if a not in NUMS and isram(v) and len(mo.group(1))>2: return ramname(v)
        if a not in NUMS and isaddr(v) and len(mo.group(1))>2: return sym(v)
        if m in('IN','OUT'): return 'GPORT' if v==8 else hx(v)
        return hx(v,4 if v>255 or len(mo.group(1))>2 else 2)
    ops=re.sub(r'0x([0-9a-f]+)',rep,ops)
    return m,ops
def line(lb='',mn='',op='',cm=''):
    s=lb
    if mn: s=(s+' ').ljust(8)+mn
    if op: s=(s+' ').ljust(16)+op
    if cm: s=(s+' ').ljust(40)+'; '+cm
    return s.rstrip()
out=[l.replace('\t',' ') for l in open('header.inc').read().rstrip('\n').split('\n')]
used=set()
def comment(a):
    used.add(a); t=C[a]
    if '\n' in t:
        out.append(''); out.append(';'+'='*69)
        for z in t.split('\n'): out.append('; '+z)
        out.append(';'+'='*69)
    else: out.append('; ---- '+t)
lastC=None
def flush():
    global pend
    while pend:
        ch=pend[:8]; pend=pend[8:]
        asc=''.join(chr(c) if 32<=c<127 and c!=92 else '.' for _,c in ch)
        out.append(line('','DB',','.join(hx(c) for _,c in ch),f'{ch[0][0]:04X} {asc}'))
a=ORG; pend=[]; OPT=set(range(0x1271,0x1271+2*len(optab)))
while a<0x4000:
    if a==0x3E28:
        flush(); out.append('')
        out.append('; Ende des Programms.')
        out.append(line('','IF','$>RAM_BASE'))
        out.append(line('','ERROR','"Code reicht in den Arbeitsspeicher"'))
        out.append(line('','ENDIF'))
        out.append('; Fuellbytes bis RAM_BASE, nur damit die Datei bei 0100H dem')
        out.append('; Original (0100H-3FFFH) entspricht.')
        out.append(line('','IF','CODE_ORG=0100H'))
    if a in lab or a in nodes or a in sents or a in C: flush()
    if a in C: comment(a)
    if a in lab and a<0x3E28: out.append(lab[a]+':')
    if a in FP_CONSTANTS:
        flush()
        # K_FP_ZERO ist hier nur vier Byte lang: 2CDCH beginnt schon K_FP_ONE.
        count=4 if a==0x2CD8 else 5
        bs=b[a-ORG:a-ORG+count]
        out.append(line('','DB',','.join(hx(c) for c in bs),
                        f'{a:04X} '+FP_CONSTANTS[a][1]))
        a+=count; continue
    if a in DWAT or any(t0<=a<t0+2*c for t0,c in WTAB.items()):
        flush(); v=W16(a)
        out.append(line('','DW',sym(v),f'{a:04X}  '+b[a-ORG:a-ORG+2].hex()))
        a+=2; continue
    if a in DRVBLK:
        flush()
        out.append(line('','DB',hx(b[a-ORG]),f'{a:04X} Kanalblock: Flag'))
        for k in (1,3,5,7):
            v=W16(a+k)
            out.append(line('','DW',sym(v) if isaddr(v) else hx(v,4),f'{a+k:04X}  '+b[a+k-ORG:a+k+2-ORG].hex()))
        a+=9; continue
    if a in OPT:
        flush()
        op=a-0x1271; tg=b[a-ORG]|b[a-ORG+1]<<8
        kw=','.join(opkw.get(op,[]))
        out.append(line('','DW',lab.get(tg,hx(tg,4)),f'{a:04X} Opcode {op:02X}H'+(' '+kw if kw else '')))
        a+=2; continue
    if a in sents:
        flush(); e=sents[a]; bs=b[a-ORG:e['end']-ORG]
        d=['SCAN']
        if e['ch'] is not None:
            ch=e['ch']&0x7F; d.append(repr(chr(ch)) if 32<=ch<127 else '%02XH'%e['ch'])
        else: d.append('jedes')
        if e['val'] is not None: d.append('=%02X'%e['val'])
        if e['act']: d.append('-> '+lab.get(e['act'],'%04X'%e['act']))
        if e['off']: d.append(('ende ' if e['c']&32 else 'weiter ')+'%04X'%e['off'])
        elif e['c']&32: d.append('ende')
        if e['c']&128: d.append('last')
        out.append(line('','DB',','.join(hx(c) for c in bs),f'{a:04X} '+' '.join(d)))
        a=e['end']; continue
    if a in nodes:
        n=nodes[a]; e=n['end']; bs=b[a-ORG:e-ORG]
        typ={0:'EPS',8:'KW',16:'TOK',24:'RULE'}[n['t']]
        d=[typ+(' "'+n['kw']+'"' if n['kw'] else '')+(' %02X'%n['arg'] if n['arg'] is not None else '')]
        if n['act']: d.append('-> '+lab.get(n['act'],'%04X'%n['act']))
        if n['lnk']: d.append('next %04X'%n['lnk'])
        if n['c']&0x80: d.append('last')
        out.append(line('','DB',','.join(hx(c) for c in bs),f'{a:04X} '+' '.join(d)))
        a=e; continue
    if a in ins:
        flush(); t,n=ins[a]; mn,op=conv(a,t); cm=f'{a:04X}  '+b[a-ORG:a-ORG+n].hex()
        if mn=='CALL' and op=='BDOS':
            p=ins.get(a-2,('',0))[0]; mm=re.match(r'LD C,0x([0-9a-f]+)$',p)
            if mm: cm+='  BDOS '+str(int(mm.group(1),16))+': '+BDOSF.get(int(mm.group(1),16),'?')
        if mn=='OUT' and 'GPORT' in op: cm+='  Bildspeicher umschalten'
        out.append(line('',mn,op,cm))
        a+=n; continue
    pend.append((a,b[a-ORG]))
    if len(pend)>=8: flush()
    a+=1
flush(); out.append(line('','ENDIF'))
cells=sorted(ramcells)
out.append(''); out.append(';'+'='*69)
out.append('; ARBEITSSPEICHER ab RAM_BASE (nur reserviert, nicht in der Datei)')
out.append('; Darueber bis zum BDOS liegt der BASIC-Programmspeicher;')
out.append('; der Stack waechst von STACK_TOP nach unten.')
out.append(';'+'='*69)
out.append(line('','ORG','RAM_BASE'))
for k,v in enumerate(cells):
    if v==RAM_TOP: out.append(line(ramname(v)+':','','','%04XH  (RAM_BASE+%03XH)'%(v,v-RAM_LO))); continue
    nx=cells[k+1]
    out.append(line(ramname(v)+':','DS',str(nx-v),'%04XH  (RAM_BASE+%03XH)'%(v,v-RAM_LO)))
out.append(line('','END'))
for k in set(C)-used: print('WARNUNG: Kommentar nicht platziert: %04X'%k)
open('src/basict.asm','w').write('\n'.join(out)+'\n')
