### Podejście nr 1 (całość do szerokiego bufora, osobny bufor na output)
Przy pliku input.txt:
```
value a
value bbb
a:
value a
bbb: a + 6
bbb + c * a
c:
d:
ff:
ff
test abc:
test abc
ddd:
a bbb c d ff ddd
ddd ddd
newlabel: test
newlabel2: newlabel
newlabel3: newlabel3
```

Statystyki: 
Total: 11900
ALU: 4091 (34%)
Jump: 1559 (13%)
Branch: 2368 (20%)
Memory: 2323 (20%)
Other: 1559 (13%)

### Podejście 2 (czytanie do małego bufora)
Przy takim samym pliku input.txt:

Statystyki: 
Total: 17140
ALU: 6859 (40%)
Jump: 1900 (12%)
Branch: 2374 (13%)
Memory: 4746 (28%)
Other: 1261 (7%)
