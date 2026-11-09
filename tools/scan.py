# Zustandstabelle der Zeichen-Erkennung (Tabelle D1028, Interpreter ab 0FBDH).
# Eintrag: [C][Zeichen, wenn Bit1=0][Bit3: Wert fuer 4001H][Bit4: Aktion]
#          [Bit6: Sprungweite]; Bit7 = letzter Eintrag des Zustands.
# Treffer: Bit2 Zeichen zaehlen, Bit5 fertig (RET), Bit6 relativer Sprung,
# sonst geht es mit dem naechsten Zeichen direkt hinter dem Eintrag weiter.
# Aktion = Adresse des Aktionsbytes + Byte (vorzeichenlos), Aufruf ueber SYN_ACTION.
import json
b=open('BASICT.COM','rb').read(); ORG=0x100
B=lambda a:b[a-ORG]
starts=[B(0x1028+2*i)|B(0x1029+2*i)<<8 for i in range(11)]
ents={}; acts=set(); st=list(starts); seen=set()
while st:
    s=st.pop()
    if s in seen: continue
    seen.add(s); a=s
    while True:
        if a in ents: break
        c=B(a); h=a+1; ch=val=act=off=None
        if not c&2: ch=B(h); h+=1
        if c&8: val=B(h); h+=1
        if c&16: act=h+B(h); acts.add(act); h+=1
        if c&64:
            o=B(h); o=o-256 if o>127 else o; off=h+o; h+=1
            if not c&32: st.append(off)
        elif not c&32: st.append(h)
        ents[a]=dict(c=c,ch=ch,val=val,act=act,off=off,end=h)
        if c&128: break
        a=h
print(len(ents),'Eintraege',len(acts),'Aktionen')
json.dump(dict(ents={str(k):v for k,v in ents.items()},actions=sorted(acts),starts=starts),open('scan.json','w'))
