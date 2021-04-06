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

### Podejście 2
1. zrobic metody getc, putc. Zwracaja nowy znak? Używają bufora. Potrzebny statyczny counter ilosci rzeczy w buforze.
2. przerobic zapisywanie labelek jako kopiowanie calosci stringa, trzeba okreslic maksymalna dlugosc etykiety
3. dodac wrapper w stylu copy_str_to_file który uzywa putc
4. przerobic replace_labels zeby uzywal bufora do przechowywania aktualnego slowa zamiast wskaznikow
5. przerobic replace_labels zeby uzywaly getc, putc
6. tyle? wtedy potrzebujemy tylko 1 bufora
7. dynamiczna alokacja dla labelek
