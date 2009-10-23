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

` test multiple assign, int /
i14, i15, i16, i17 := 1/2, i1/3, 4/i1, i1/i1;
if i14=0  & i15=4 & i16=0 & i17=1 ? fi;
pass := pass + 4;

` test multiple assign, int //
i18, i19, i20, i21 := 1//2, i1//3, 4//i1, i1//i1;
if i18=1  & i19=1 & i20=4 & i21=0 ? fi;
pass := pass + 4;

` conversion to ints
i22, i23 := r2i 17.0, b2i true;
if i22=17  & i23=1 ? fi;
pass := pass + 2;

` negation
i24, i25 := -1, -i1;
if i24= -1 & i25= -13 ? fi;
pass := pass + 2;

` parens
i26, i27 := ((((((((13)))))))), (-(-(-(-7))));
if i26=13 & i27=7 ? fi;
pass := pass + 2;

` precedence
i28 := 1+2*3/4//5-1+2*3/4//5;
if i28=2 ? fi;
pass := pass + 1;

passedints := pass;
