` FILE:    checkquadratic.x
` PURPOSE: check on quadratic equation solver ax^2+bx+c=0
` USAGE:   xcom x/sqrt.x x/quadratic.x x/checkquadratic.x

a := 1.0;
b := 3.0;
c := 1.0;

res1, res2 := quadratic := a, b, c;

shouldbezero1 := a*res1*res1 + b*res1 + c;
shouldbezero2 := a*res2*res2 + b*res2 + c;
