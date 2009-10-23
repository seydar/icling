% FILE:  obj.m
% PURPOSE: Example of using nested functions for classes
%
% The main function is the object "constructor".  It returns an instance.
% The nested function "public" collects the fields/methods of the object.
% The object can contain only things that are constant after construction;
% "constant" includes scalars, read-only arrays and function handles.
%
% Once instantiated via the "constructor", the "methods" can be used to
% access the persistent state of the object.  In this case there is an
% array x which can be updated and accessed via get and set. If the array
% itself were put in the obj struct, it would be copied at ctor time. It
% would, therefore, always have the initial null value. In this function,
% the access to x as a whole is put in a function getx which will copy the
% array at the time getx is called, therefore always giving the latest
% value held in the "object". 
%
% The constant C can be placed in the struct because it is never changed.
% This case is the equivalent to static fields in a class.
% EXAMPLE:
%  o = obj();
%  o.set(3,37);
%  res = o.get(3)

% COPYRIGHT W.M.McKeeman 2007.  You may do anything you like with 
% this file except remove or modify this copyright.

function o = obj()

  % variables in the persistent frame accessed by the handles
  x = zeros(1,0, 'int32');
  C = 2007;
  
  o = public();
  
  return;
  
  % ---- nested functions ----
  function set(i, v)
    x(i) = v;
  end

  function v = get(i)
    v = x(i);
  end

  function a = getx()
    a = x;
  end

  function res = public()
    res = struct;                % collect the public interface
    res.set = @set;              % function handles for "methods"
    res.get = @get;
    res.x   = @getx;             % res.x = x would not show changes in x
    res.C   = C;                 % OK because C does not change
  end
end
