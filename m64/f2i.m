% FILE:    f2i.m
% PURPOSE: pun single into int32
% METHOD:  use typecast
% EXAMPLE: 
%
%   i32 = f2i(single(3.1))
%   f32 = i2f(i32)
%
% SEE ALSO i2f.m

% COPYRIGHT W.M.McKeeman 2006.  You may do anything you like with 
% this file except remove or modify this copyright.

function i = f2i(f)
  assert(isa(f, 'single'));
  assert(numel(f)==1);
  i = typecast(f, 'int32');
end

