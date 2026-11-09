from z80dis import z80
import re,json
b=open('BASICT.COM','rb').read(); ORG=0x100; END=ORG+len(b)
def dec(a):
    i=a-ORG
    d=z80.decode(b[i:i+4],a); return z80.disasm(d),d.len
ins={}   # addr -> (text,len)
seeds=[0x100]+[int.from_bytes(b[a-ORG:a-ORG+2],'little') for a in range(0x1D84,0x1D9C,2)]
extra=set()
import json as J
G=J.load(open('gram.json'))
GB=set(G['g'])
seeds+=G['actions']
S=J.load(open('scan.json'))   # Zustandstabelle der Zeichen-Erkennung
seeds+=S['actions']
for k,v in S['ents'].items(): GB|=set(range(int(k),v['end']))
seeds+=J.load(open('optab.json'))
seeds+=[0x3B20,0x3B24,0x3B82,0x3BD1,0x3BD5,0x3CE2,0x3CE6,0x3DEF,0x375E,0x3764,0x376C,0x377C,0x37AF]
# Einspruenge, die nur ueber berechnete Spruenge, Vektoren oder Rueckkehradressen
# erreicht werden (von Hand geprueft; vorher als DB-Bytes stehen geblieben)
seeds+=[0x0232,0x13B6,0x13D3,0x13E6,0x1401,0x1414,0x1417,0x148F,0x159A,0x15C0,
        0x163A,0x1D29,0x216F,0x23F3,0x25C6,0x2694,0x28A6,0x28AA,0x2941,0x299D,
        0x2D82,0x2D99,0x2DC7,0x32F7,0x357E,0x35FE,0x3608,0x361E,0x36B6,0x36CF,
        0x36F7]
for a in range(0x3700,0x375E):
    w=b[a-ORG]|b[a-ORG+1]<<8
    if 0x375E<=w<0x3A94: seeds.append(w)
DATA=set(range(0x1271,0x1271+0xD2))|set(range(0x1D84,0x1D9C))|set(range(0x307,0x345))|set(range(0x3700,0x375E))|set(range(0x1028,0x103E))|set(range(0x3B00,0x3B20))
GB|=DATA
def inrange(x): return 0x100<=x<0x3E28 and not (0x378C<=x<0x37AF or 0x3A94<=x<0x3B00)
def trace(seeds):
    st=list(seeds)
    while st:
        a=st.pop()
        while inrange(a) and a not in ins and a not in GB:
            try: t,n=dec(a)
            except Exception: break
            if n<=0 or a+n>END: break
            # overlap check
            if any((a+k) in ins or (a+k) in GB for k in range(0,n)): break
            ins[a]=(t,n)
            m=t.split()[0]; ops=t[len(m):].strip()
            nxt=a+n
            tgt=re.findall(r'0x([0-9a-f]+)',ops)
            if m in('JP','JR','CALL','DJNZ') and tgt and '(' not in ops:
                st.append(int(tgt[-1],16))
            if m in('LD',) and re.match(r'(HL|DE|BC),0x',ops):
                v=int(tgt[0],16); extra.add((a,v))
            if m=='RET' and ops=='': break
            if m in('JP','JR') and ',' not in ops: break
            if m=='RETI' or m=='RETN' or m=='HALT': break
            a=nxt
trace(seeds)
# heuristic seeds: LD HL,nn followed by PUSH HL / JR to a PUSH HL / JP (HL)
for rnd in range(5):
    new=[]
    for a,v in list(extra):
        t,n=ins[a]
        if not t.startswith('LD HL') or not inrange(v) or v in ins: continue
        nx=a+n; t2=ins.get(nx,('',0))[0]
        ok=t2.startswith('PUSH HL') or t2.startswith('JP (HL)')
        if t2.startswith('JR') and ',' not in t2[3:]:
            tg=int(re.findall(r'0x([0-9a-f]+)',t2)[0],16)
            ok = ins.get(tg,('',0))[0].startswith('PUSH HL')
        if ok: new.append(v)
    if not new: break
    trace(new)
cov=sum(n for t,n in ins.values())
print(len(ins),cov,hex(len(b)))
json.dump({str(k):v for k,v in ins.items()},open('ins.json','w'))
