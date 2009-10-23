` FILE:    caller35.x
` PURPOSE: subprogram test for xcom
` METHOD:  xcom x/called35.x x/caller35.x

x,y,z := 1,2,3; ` for types
x,y,z := called35 := 11,12,13,14,15;

` correct answer assertions (don't fiddle with called35)
if x = 81 ? fi;  ` called35 adds 16 to the sum of the inputs
if y = 21 ? fi;  ` called35 just returns 21 for second output
if z = 31 ? fi;  ` called35 just returns 31 for third output

