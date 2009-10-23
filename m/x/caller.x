` FILE:    caller.x
` PURPOSE: minimal subprogram test for xcom
` METHOD:  xcom x/called.x x/caller.x

x := 1;
x := called := 100;
` assert called returns 17
if x = 100+17 ? fi;



