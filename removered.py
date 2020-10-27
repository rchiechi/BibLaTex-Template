#!/usr/bin/env python3

import sys,os

START=r'\red'

if sys.argv[1]:
    INFILE=sys.argv[1]
else:
    print("I need a input file.")
    os.exit()

OUTPUT=[]
TOSSED=0
with open(INFILE, 'rt') as fh:
    while True:
        _c = fh.read(1)
        if not _c:
            break
        else:
            OUTPUT.append(_c)
        if ''.join(OUTPUT[-1*len(START):]) == START:
            for i in range(0, len(START)):
                    OUTPUT.pop()
            _c = fh.read(1)
            if _c != '{':
                print("{ didn't follow start!")
                sys.exit()
            n = 0
            while True:
                _c = fh.read(1)
                if _c == '{':
                    n += 1
                elif _c == '}' and n > 0:
                    n -= 1
                elif _c == '}':
                    TOSSED+=1
                    break
                OUTPUT.append(_c)
os.rename(INFILE, INFILE+'.bak')
if os.path.exists(INFILE+'.bak'):
    with open(INFILE, 'wt') as fh:
        fh.write(''.join(OUTPUT))
print("Tossed %s instances of %s{...}" % (TOSSED, START))
