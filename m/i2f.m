% FILE:    i2f.m
% PURPOSE: pun int32 into single
% METHOD:  use typecast
% EXAMPLE: 
%
%   f32 = i2f(int32(-311))
%   i32 = f2i(f32)
%
% SEE ALSO f2i.m
%
% COPYRIGHT W.M.McKeeman 2006.  You may do anything you like with 
% this file except remove or modify this copyright.

function f = i2f(i)
  assert(isa(i, 'int32'));
  assert(numel(i)==1);
  f = typecast(i, 'single');
end

