` FILE:    caller12.x
` PURPOSE: minimal subprogram test for xcom
` METHOD:  xcom x/called12.x x/caller12.x

x := 1;
x := called12 := 99+1, 200;

` assert called12 returns sum of args+17
if x = 100+200+17 ? fi;



