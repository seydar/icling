% FILE:    xarith.m
% PURPOSE: Basic utility to provide 2's complement int arithmetic
%          instead of saturated int arithmetic.
%          This is necessary for X semantics and address computations.
%          ops: add, sub, neg, mul, div, and, or, xor, not
% METHOD:  convert to double, do operation, convert back
% EXAMPLE: 
%  obj = xarith();                        % constructor
%  x = int32(17);  y = int32(19);
%  res = obj.add(x, y)                   % signed 32-bit  x+y
%
% SEE ALSO: u2s.m, s2u.m

% COPYRIGHT W.M.McKeeman 2006.  You may do anything you like with 
% this file except remove or modify this copyright.

function ops = xarith()                           % constructor
  ops = public();
  return
  
  %-------------methods-------------------
  function c = add(a,b)                          % a+b
    c = d2i(double(a)+double(b));                % correct value
  end

  function c = sub(a,b)                          % a-b
    c = d2i(double(a)-double(b));
  end

  function c = neg(a)                            % -a
    c = d2i(-double(a));
  end

  function c = mul(a,b)                          % a*b
    c = d2i(double(a)*double(b));
  end

  function c = div(a,b)                          % a/b
    c = d2i(double(a)/double(b));
  end

  function c = rem(a,b)                          % a%b
    c = d2i(mod(double(a),double(b)));
  end

  function c = and(a,b)                          % a&b
    a1 = s2u(a);
    b1 = s2u(b);
    c = u2s(bitand(a1,b1));
  end

  function c = or(a,b)                           % a|b
    a1 = s2u(a);
    b1 = s2u(b);
    c = u2s(bitor(a1,b1));
  end

  function c = xor(a,b)                          % a^b
    a1 = s2u(a);
    b1 = s2u(b);
    c = u2s(bitxor(a1,b1));
  end

  function c = not(a)                            % ~a
    a1 = s2u(a);
    c = u2s(bitcmp(a1));
  end

  function i = d2i(d)                            % avoid saturation
    assert(isa(d, 'double'));
    im0 = floor(abs(d));                         % int magnitude
    im1 = mod(im0, 2^32);                        % 0 <= im1 < 2^32
    if d >= 0
      im2 = uint32(im1);
      i = typecast(im2, 'int32');                % int32 result
    else
      if im1==0
        im2 = -2^31;                             % max neg value
      else
        im2 = -im1;                              % other neg values
      end
      i = int32(im2);                            % int32 result
    end
  end

  function o = public()                          % public interface
    o = struct;
    o.add = @add;
    o.sub = @sub;
    o.neg = @neg;
    o.mul = @mul;
    o.div = @div;
    o.rem = @rem;
    o.and = @and;
    o.or  = @or;
    o.xor = @xor;
    o.not = @not;
  end
    
end