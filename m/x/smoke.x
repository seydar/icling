` FILE:    smoke.x
` PURPOSE: minimal test for xcom, one of everything
`          This is the first X program that ran
`          The term `smoke test' comes from electronics: did not catch fire

pass := 0;           ` none yet

a := true;
b := false;
c := a & b;
if ~c ? fi;
pass := pass + 1;    ` did not fail

i := 1;
j := 2+3;
k := i+j;
if k=6? fi;
pass := pass + 1;   ` did not fail

x := 1.0;
y := 2.0+3.0;
z := x+y;
if z <= 6.0 & 6.0 <= z ? fi;
pass := pass + 1;    ` did not fail

r := 1<2;
if r ? fi;
pass := pass + 1;

passedsmoke := pass;

` final comment
