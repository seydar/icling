% FILE:    testArith.m
% PURPOSE: exercise M version of C arithmetic
% METHOD:  try limit cases
% EXAMPLE:   
%    testArith()

% COPYRIGHT W.M.McKeeman 2006.  You may do anything you like with 
% this file except remove or modify this copyright.

function testArith()
  ops = xarith();        % ctor for xarith object
  mx = intmax('int32');  % limit value
  
  a = int32([]);
  for i=int32(-2):int32(2)
    a(end+1) = ops.add(mx, i); %#ok
  end
  
  s = int32([]);
  for i=int32(-2):int32(2)
    s(end+1) = ops.sub(mx, i); %#ok
  end

  n = int32([]);
  for i=int32(3):int32(-1):int32(-1)
    n(end+1) = ops.neg(i);     %#ok
  end
  for j=1:numel(a)
    assert(a(j)==s(end-j+1));
    assert(n(j)== j-4);
  end
  s = u2s(intmax('uint32'));
  u = s2u(s);
  assert(u == intmax('uint32'));
  assert(isa(s, 'int32'));
  assert(isa(u, 'uint32'));
  
  a1 = int32(2);
  m  = int32(1);
  for j=1:30
    m = ops.mul(m, a1);
  end
  assert(m==1073741824);   % 2^30
  m = ops.mul(m, a1);
  assert(m==-2^31);            % 2^31 == overflow == -2^31
  
end
    
    
  