% FILE:    piQE.m
% PURPOSE: compute pi to n terms (compare with pi.x)
% METHOD:  4*(1 - 1/3 + 1/5 - 1/7 + 1/9...)
%          Number of terms is input
%          It takes a LOT of terms to get any accuracy at all
%          Exact analog of pi.x
% EXAMPLE:
%   xcom x/pi.x    ` set input to 10
%   piQE(10)

function piQE(nterms)
  p2 = single(0.0);
  i = int32(1);
  better = 0.0;
  while i<4*nterms 
    t  = single(1.0)/single(i); 
    p1 = p2 + t;               % too high
    i  = i + 2;
    t  = single(1.0)/single(i);
    p2 = p1 - t;               % too low
    i  = i + 2;
  end

  pi = 4.0*p2;
  delta = single(1.0)/single(nterms);
  fprintf('pi := %g\ndelta := %g\n', pi, delta);

end


