` FILE:    timeRealInc.x
` PURPOSE: time code to increment a real variable
` USAGE:   see directory times

reps := 100.0;
rep  := 0.0;
lim  := 1000000.0;

do rep < reps ?
  ctr := 0.0;
  do ctr<lim ?      ` 100,000,000 times
    ctr := ctr + 1.0; 
    ctr := ctr + 1.0; 
    ctr := ctr + 1.0; 
    ctr := ctr + 1.0; 
    ctr := ctr + 1.0; 

    ctr := ctr + 1.0; 
    ctr := ctr + 1.0; 
    ctr := ctr + 1.0; 
    ctr := ctr + 1.0; 
    ctr := ctr + 1.0; 
  od;
  rep := rep + 1.0;
od;


