` FILE:    ints.x
` PURPOSE: test all integer operators
` METHOD:  The X assert  if boolexp ? fi is used to check answers.
` Numerical results are checked agains MATLAB which is pretty easy
` since an X assigment can be pasted into the MATLAB command line and,
` with minor edits, run by MATLAB.

pass := 0;                           ` none yet
` test literal constant, store and fetch
i1 := 13;
if i1 = 13 ? fi;
pass := pass + 1;

` test multiple assign, int +
i2, i3, i4, i5 := 1+2, i1+3, 4+i1, i1+i1;
if i2=3 & i3=16 & i4=17 & i5=26 ? fi;
pass := pass + 4;

` test multiple assign, int -
i6, i7, i8, i9 := 1-2, i1-3, 4-i1, i1-i1;
if i6= -1 & i7=10 & i8= -9 & i9=0 ? fi;
pass := pass + 4;

` test multiple assign, int *
i10, i11, i12, i13 := 1*2, i1*3, 4*i1, i1*i1;
if i10=2  & i11=39 & i12=52 & i13=169 ? fi;
pass := pass + 4;

passedints := pass;
