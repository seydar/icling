` FILE:    doods.x
` PURPOSE: test combinations of do-od
` METHOD:  The X assert  if boolexp ? fi is used to check answers.

pass := 0;
` test literal constant, store and fetch
b1, b2 := true, false;
if b1 & ~b2 ? fi;
pass := pass + 1;

x := 17;
do x>10 ? x := x - 1; 
od;
if x = 10 ? fi;
pass := pass + 1;

x := 311;
lim := 100;
do x//2=0 & lim>0 ? x := x/2; lim := lim - 1;
:: x//2=1 & lim>0 ? x := x+1; lim := lim - 1;
od;
if x = 2 ? fi;
pass := pass + 1;


passeddoods := pass;
