% FILE:     s2u.m 
% PURPOSE:  pun int32 to uint32
% METHOD:   use typecast
% EXAMPLE:
%   u = s2u(int32(-1))
% SEE ALSO: u2s.m, arith.m

% COPYRIGHT W.M.McKeeman 2006.  You may do anything you like with 
% this file except remove or modify this copyright.

function u = s2u(s)
  assert(numel(s)==1);
  u = typecast(s, 'uint32');
end


