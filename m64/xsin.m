% FILE:     xsin.m
% PURPOSE:  compute sin(x) by Taylor series
%           compare results with sin.x
% EXAMPLE:
%  s = xsin(0.123)

% COPYRIGHT W.M.McKeeman 2007.  You may do anything you like with 
% this file except remove or modify this copyright.


function s = xsin(x)
  s = 0;
  sg = 1;
  for i=1:2:inf
    t = x^i/factorial(i);
    %if sg == -1; sgtxt = '-'; else sgtxt = ''; end
    %fprintf(['t = ' sgtxt 'x^' num2str(i) '/' num2str(i) '!\n'])
    s = s + sg*t;
    sg = -sg;
    if t < eps; break; end
  end
end
