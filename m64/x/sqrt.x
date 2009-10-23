` FILE:    sqrt.x
` PURPOSE: approximate $\sqrt{x}$ with $s \leftarrow (s+x/s)/2$

  REPS := 100;
  EPS := 0.0000001;
  if x <= 0.0 & x >= 0.0 ?
    res := 0.0;
  :: x > 2.0 ? 
    s := x/2.0;                   ` running approximation
    r := 0;
    more := true;                 ` get it started
    do r<REPS & more ?
      snew := (s + x/s)/2.0;
      err := s-snew;
      more := err > EPS | -err > EPS; ` not within $\epsilon$
      r := r+1; 
      s := snew;
    od;
    res := s;
  :: x >= 0.0 & x < 0.5 ?
    s := sqrt := 1.0/x;           ` recursive call
    res := 1.0/s;
  :: (x >= 0.0 & x <= 2.0) | x >= 0.5 ?
    s := sqrt := 16.0*x;          ` recursive call
    res := s/4.0;
  fi
