% FILE:    testEquivalenceClass.m
% PURPOSE: exercise M equivalence classes
% EXAMPLE:   
%   testEquivalenceClass()

% COPYRIGHT W.M.McKeeman 2006.  You may do anything you like with 
% this file except remove or modify this copyright.


function testEquivalenceClass()
  c = EquivalenceClass();
  for i=1:10; c.insert(i); end
  c.andDatav(uint32(7));
  c.andDatav(uint32(8+1));
  c.getDatav()
  c.getSize()
end
