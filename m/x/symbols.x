` FILE:    symbols.x
` PURPOSE: check symbol analysis
` METHOD:  present hard-to-check cases
`          all variables should be type defined.
`          >> xcom -noExecute x/symbols.x to avoid lots of input requests

if b1 ? fi;        ` boolean inferences
b2 := b3 | true;
b4 := true | b5;
b6 := b7 & true;
b8 := true & b9;
b10 := ~b11;
b12 := i27 = 1;
b13 := r23 < 1.0;

i1 := i2 + 1;      ` integer inferences
i3 := 1 + i4;
i5 := i6 - 1;
i7 := 1 - i8;
i9 := i10 * 1;
i11 := 1 * i12;
i13 := i14 / 1;
i15 := 1 / i16;
i17 := i18 // 1;
i19 := 1 // i20;
i21 := -1;
i22 := -((((1))));
i23 := rand;
i24 := r2i r25;
i26 := b2i b14;

r1 := r2 + 1.0;    ` real inferences
r3 := 1.0 + r4;
r5 := r6 - 1.0;
r7 := 1.0 - r8;
r9 := r10 * 1.0;
r11 := 1.0 * r12;
r13 := r14 / 1.0;
r15 := 1.0 / r16;
r21 := -1.0;
r22 := -((((1.0))));
r24 := i2r i25;

x0 := x1;          ` a long chain
x1 := x2;
x2 := x3;
x3 := x4;
x4 := x5;
x5 := x6;
x6 := x7;
x7 := x8;
x8 := x9;
x9 := 10;

d1, d2 := (d3 + d4*d5/d6//d7), d8+d9 = d10-d11;
