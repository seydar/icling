` FILE:    callabsi.x
` PURPOSE: test call of absi.x

shouldbe7, shouldbe101, shouldbe6, shouldbe0 := 1,1,1,1;

shouldbe7   := absi := -7;
shouldbe101 := absi := -101;
shouldbe6   := absi := 6;
shouldbe0   := absi := 0;

