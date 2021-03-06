` FILE:    sin.x
` PURPOSE: approximate sin(x) with x - x^3/6 + x^5/120 - ...
` USAGE:   xcom x/sin.x    (from command line)
`          xout := sin := xin  (in X source)

  ` -------- normalize argument x -------------------
  if xin < 0.0 ? xa := -xin; :: xin >= 0.0 ? xa := xin; fi; 

  pi2 := 2.0*3.141592653589793;
  cut := 7.0;
  if xa > cut ?      ` get x into reasonable range
     red := r2i(xa/pi2)-1;
     xa  := xa - i2r(red)*pi2;
  :: xa <= cut ?     ` do nothing
  fi;
  xi := xa;          ` x^i
  x2 := xi*xi;       ` x^2

  ` --------- setup iteration ----------------
  i   := 0.0;        ` i
  sum := 0.0;        ` running sum
  fac := 1.0;        ` i!
  del := 1.0;        ` get started
  sg  := 1.0;        ` sign

  ` ---------- sum series -------------------
  do del > 0.0000001 ?
    del := xi/fac;    ` non-negative increment
    sum := sum + sg*del;
    sg  := -sg;      ` alternate sign
    i   := i+2.0;    ` step 2
    fac := fac*i*(i+1.0);
    xi  := xi*x2;    ` mul by x^2
  od;

  ` ------ normalize result: sin(-x) = -sin(x) ---------
  if xin < 0.0 ? xout := -sum; :: xin >= 0.0 ? xout := sum; fi
