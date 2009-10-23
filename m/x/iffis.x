` FILE:    iffis.x
` PURPOSE: test combinations of if
` METHOD:  The X assert  if boolexp ? fi is used to check answers.

pass := 0;                  ` none yet
` test literal constant, store and fetch
b1, b2 := true, false;
if b1 & ~b2 ? fi;
pass := pass + 1;

x := 17;
if b1 ? x := 1; 
:: b2 ? x := 2;
fi;
if x = 1 ? fi;
pass := pass + 1;

x := 17;
if b2 ? x := 2; 
:: b1 ? x := 1;
fi;
if x = 1 ? fi;
pass := pass + 1;

x := 17;
if b1 ?
  if b1 ?
    x := 1;
  fi;
fi;
if x = 1 ? fi;
pass := pass + 1;

x := 17;
if b1 ?
  if b1 ?
    if b1 ?
      x := 1;
    fi;
  fi;
fi;
if x = 1 ? fi;
pass := pass + 1;

if b2 ?
:: b1 ?
  if b2 ?
  :: b1 ?
    if b2 ?
    :: b1 ?
      x := 1;
    fi;
  fi;
fi;
if x = 1 ? fi;
pass := pass + 1;


passediffis := pass;
