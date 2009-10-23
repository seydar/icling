` FILE:    testdo.x
` PURPOSE: make sure a loop works

x:=1.0;
do x<3.0? x:=x+1.0; od;
yshouldbe:=3.0;
y:=x;