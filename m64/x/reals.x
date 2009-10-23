` FILE:    reals.x
` PURPOSE: test all real operators
` METHOD:  The X assert  if boolexp ? fi is used to check answers.
` When a real result is known to be exact, the test
`     res <= ans & ans <= res
` can be used to check equality (= is forbidden to real)
` Numerical results are checked agains MATLAB which is pretty easy
` since an X assigment can be pasted into the MATLAB command line and,
` with minor edits, run by MATLAB.

pass := 0;
` test literal constant, store and fetch
r1 := 13.0;
if r1 <= 13.0 & 13.0 <= r1 ? fi;
pass := pass + 1;

` test multiple assign, real +
r2, r3, r4, r5 := 1.1+2.2, r1+3.3, 4.4+r1, r1+r1;
if r2<=3.30001 & r3<=16.3 & r4<=17.4 & r5<=26.0 ? fi;
pass := pass + 1;

` test multiple assign, real -
r6, r7, r8, r9 := 1.1-2.2, r1-3.3, 4.4-r1, r1-r1;
if r6<= -1.1 & r7<=9.7 & r8<= -8.6 & r9<=0.0 ? fi;
pass := pass + 1;

` test multiple assign, real *
r10, r11, r12, r13 := 1.1*2.2, r1*3.3, 4.4*r1, r1*r1;
if r10<=2.42  ? fi;
pass := pass + 1;
if r11<=42.9  ? fi;
pass := pass + 1;
if r12>=57.2  ? fi;
pass := pass + 1;
if r13<=169.0 ? fi;
pass := pass + 1;

` test multiple assign, real /
r14, r15, r16, r17 := 1.1/2.2, r1/3.3, 4.4/r1, r1/r1;
if r14<=0.5 & 0.5<=r14 ? fi;
pass := pass + 1;
if r15*3.3<=r1 ? fi;
pass := pass + 1;
if r16*r1<=4.4 ? fi;
pass := pass + 1;
if r17<=1.0 & 1.0<=r17 ? fi;      ` exact
pass := pass + 1;

` conversion to real
r22 := i2r 17;                    ` exact
if r22<=17.0 & 17.0<=r22 ? fi;
pass := pass + 1;

` negation
r24, r25 := -1.112, -r1;
if r24 <= -1.112 & -1.112 <= r24 ? fi;
pass := pass + 1;
if r25 <= -r1 & -r1 <= r25 ? fi;
pass := pass + 1;

` parens
r26, r27 := ((((((((13.0)))))))), (-(-(-(-(-7.1)))));
if r26 <= 13.0 & 13.0 <= r26 ? fi;
pass := pass + 1;
if r27 <= -7.1 & -7.1 <= r27 ? fi;
pass := pass + 1;

` precedence
r28 := 1.1+2.2*3.3/4.4-1.1+2.2*3.3/4.4;
if r28 <= 3.3 ? fi;
pass := pass + 1;

` rand
r29, r30, r31 := rand, rand, rand;
if 0.0<r29 & r29<1.0 ? fi;
pass := pass + 1;
if 0.0<r30 & r30<1.0 ? fi;
pass := pass + 1;
if 0.0<r31 & r31<1.0 ? fi;
pass := pass + 1;

i1 := r2i(1000000.0*r29);
i2 := r2i(1000000.0*r30);
i3 := r2i(1000000.0*r31);

` fails randomly 3 in a million times.  Try again
if i1~=i2 & i1~=i3 & i2~=i3 ? fi;
pass := pass + 1;

passedreals := pass;
