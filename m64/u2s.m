% FILE:     u2s.m 
% PURPOSE:  pun uint32 to int32
% METHOD:   use typecast
% EXAMPLE:
%  s = u2s(uint32(2^32-1))
% SEE ALSO: s2u.m, arith.m

% COPYRIGHT W.M.McKeeman 2006.  You may do anything you like with 
% this file except remove or modify this copyright.

function s = u2s(u)
  assert(numel(u)==1);
  s = typecast(u, 'int32');
end


