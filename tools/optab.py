# Liest die Opcode-Sprungtabelle der Laufzeit (OPTAB, 1271H) aus.
import json
b=open('BASICT.COM','rb').read();ORG=0x100
W=lambda a:b[a-ORG]|b[a-ORG+1]<<8
t=[]
for op in range(0,256,2):
    w=W(0x1271+op)
    if not(0x100<=w<0x3E28): break
    t.append(w)
json.dump(t,open('optab.json','w'))
