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
Total: 18959
ALU: 7473 (39%)
Jump: 2284 (13%)
Branch: 2588 (13%)
Memory: 5210 (28%)
Other: 1404 (7%)

7. dynamiczna alokacja dla labelek
