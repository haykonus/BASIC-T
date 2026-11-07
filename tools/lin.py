from z80dis import z80
b=open('BASICT.COM','rb').read(); ORG=0x100
i=0
out=[]
while i<len(b):
    try:
        d=z80.decode(b[i:i+4],ORG+i); s=z80.disasm(d); n=d.len
    except Exception: s='??';n=1
    if n<=0: s='??';n=1
    out.append((ORG+i,b[i:i+n].hex(),s)); i+=n
open('lin.txt','w').write('\n'.join(f'{a:04X} {h:10} {s}' for a,h,s in out))
