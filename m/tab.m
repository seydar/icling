% FILE:    tab.m
% PURPOSE: Basic utility to control trace indentation
% METHOD:  tab.val() is the current tab
%          tab.in() increases the tab
%          tab.out() decreases the tab
%          tab.reset() sets the indentation level to 0
% EXAMPLE:
%  tabobj = tab();
%  tabobj.in();
%  tabobj.in();
%  fprintf('[%s]\n', tabobj.val());

% COPYRIGHT W.M.McKeeman 2007.  You may do anything you like with 
% this file except remove or modify this copyright.


function obj = tab()
  tabval = '';
  obj = public();
  %---------------------
  
  function r = val()
    r = tabval;
  end

  function in()
    tabval = [tabval ' '];
  end

  function out()
    tabval = tabval(1:end-1);
  end

  function reset()
    tabval = '';
  end

  function o = public()
    o = struct;
    o.val   = @val;
    o.in    = @in;
    o.out   = @out;
    o.reset = @reset;
  end
end



