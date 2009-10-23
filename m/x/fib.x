` FILE:    fib.x
` PURPOSE: minimal subprogram test for xcom
` METHOD:  Recursive

if n = 0 ? res := 1;
:: n = 1 ? res := 1;
:: n > 1 ? r1 := fib := n-1;  r2 := fib := n-2;  res := r1+r2;
fi
