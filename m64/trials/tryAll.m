% FILE:     tryAll.m
% PURPOSE:  call all xcom trials (lots of output)
%
% OVERVIEW:
%   There are many tests in the m/tests directory.  This function calls
%   them all.  It is a final check that all is well after a change.
%   The tests take quite a bit of time: be patient or go get coffee.
%
% EXAMPLE:  
%   tryAll()

% COPYRIGHT W.M.McKeeman 2006.  You may do anything you like with 
% this file except remove or modify this copyright.

function tryAll()
  format compact;
  datestr(now)
  disp '-----enter unit trials -----------'
  tryEnum();
  tryCfg();
  tryLexer();
  tryParser();
  tryTree();
  trySymbols();
  tryAsmX86();
  tryEmitX86();
  tryGenerator();
  tryXcom();
  tryGem;
  disp '-----leave unit trials -----------'

  disp '-----start tryErr (correct behavior is an error per trial)----------'
  tryErr();
  disp '-----finish tryErr ----------'
end

