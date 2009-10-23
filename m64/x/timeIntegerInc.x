` FILE:    timeIntegerInc.x
` PURPOSE: time code to increment an integer variable
` USAGE:   see directory times

reps := 100;
rep  := 0;
lim  := 1000000;

do rep < reps ?
  ctr := 0;
  do ctr<lim ?       ` 100,000,000 increments
    ctr := ctr + 1; 
    ctr := ctr + 1; 
    ctr := ctr + 1; 
    ctr := ctr + 1; 
    ctr := ctr + 1; 

    ctr := ctr + 1; 
    ctr := ctr + 1; 
    ctr := ctr + 1; 
    ctr := ctr + 1; 
    ctr := ctr + 1; 
  od;
  rep := rep + 1;
od;


