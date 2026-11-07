import json
b=open('BASICT.COM','rb').read(); ORG=0x100
B=lambda a:b[a-ORG]
W=lambda a:B(a)|B(a+1)<<8
rules=[W(0x307+2*i) for i in range(31)]
nodes={}  # addr -> dict
actions=set(); gbytes=set()
st=list(rules)
while st:
    h=st.pop()
    if h in nodes or not(0x100<=h<0x3700): continue
    a=h; c=B(h); h+=1; t=c&0x18; kw=None; arg=None
    if t==0x08:
        n=(c&7)+1; kw=b[h-ORG:h-ORG+n].decode('latin1'); h+=n
    elif t in(0x10,0x18):
        arg=B(h); h+=1
        if t==0x18: st.append(rules[arg//2] if arg//2<31 else 0)
    act=lnk=None
    if c&0x40: act=h+B(h); actions.add(act); h+=1
    if c&0x20:
        v=B(h); v=v-256 if v>127 else v; lnk=h+v if v else 0; h+=1
        if v: st.append(lnk)
    for x in range(a,h): gbytes.add(x)
    nodes[a]=dict(c=c,t=t,kw=kw,arg=arg,act=act,lnk=lnk,end=h)
    if not(c&0x20) or not(c&0x80): st.append(h)
print(len(nodes),len(actions),len(gbytes))
json.dump(dict(nodes={str(k):v for k,v in nodes.items()},actions=sorted(actions),g=sorted(gbytes),rules=rules),open('gram.json','w'))
for k in sorted(nodes):
    n=nodes[k]
    if n['kw'] and n['act']: print(n['kw'],hex(n['act']),end='; ')
