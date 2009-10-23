function res = xsqrt(x)
  REPS = 100;
  if x < 0.0
    error('cannot take negative sqrt');
  elseif x == 0.0
    res = 0.0;
  elseif x > 2.0 
   s = x/2.0;
   for i=1:REPS
     snew = (s + x/s)/2.0;
     if snew == s, break; else s = snew; end
   end
   res = s;
  elseif x < 0.5
   s = xsqrt(1.0/x);
   res = 1.0/s;
  else
   s = xsqrt(16.0*x)/4.0;
   res = s;
  end
end