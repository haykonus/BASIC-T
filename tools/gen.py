# Erzeugt src/basict.asm (AS-Syntax, nur Leerzeichen, feste Spalten).
import json,re
exec(open('cmt.py').read()); exec(open('names.py').read())
from fp import FP_COMMENTS, FP_NAMES, FP_CONSTANTS
C.update(FP_COMMENTS); N.update(FP_NAMES)
b=open('BASICT.COM','rb').read(); ORG=0x100; END=ORG+len(b)
ins={int(k):v for k,v in json.load(open('ins.json')).items()}
G=json.load(open('gram.json')); nodes={int(k):v for k,v in G['nodes'].items()}
optab=json.load(open('optab.json'))
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
targets|=set(optab)
lab={a:names.get(a,'L%04X'%a) for a in targets if a in ins}
lab.update(names)
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
while a<END:
    if a in lab or a in nodes or a in C: flush()
    if a in C: comment(a)
    if a in lab: out.append(lab[a]+':')
    if a in FP_CONSTANTS:
        flush()
        # K_FP_ZERO ist hier nur vier Byte lang: 2CDCH beginnt schon K_FP_ONE.
        count=4 if a==0x2CD8 else 5
        bs=b[a-ORG:a-ORG+count]
        out.append(line('','DB',','.join(hx(c) for c in bs),
                        f'{a:04X} '+FP_CONSTANTS[a][1]))
        a+=count; continue
    if a in OPT:
        flush()
        op=a-0x1271; tg=b[a-ORG]|b[a-ORG+1]<<8
        kw=','.join(opkw.get(op,[]))
        out.append(line('','DW',lab.get(tg,hx(tg,4)),f'{a:04X} Opcode {op:02X}H'+(' '+kw if kw else '')))
        a+=2; continue
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
flush(); out.append(line('','END'))
for k in set(C)-used: print('WARNUNG: Kommentar nicht platziert: %04X'%k)
open('src/basict.asm','w').write('\n'.join(out)+'\n')
