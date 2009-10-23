% FILE:    testRuleSyms.m
% PURPOSE: exercise M version of rule naming 
% METHOD:  each character has an identifier,
%          each symbol is the catenation of the names of its characters
% EXAMPLE: 
%   testRuleSyms()

% COPYRIGHT W.M.McKeeman 2008.  You may do anything you like with 
% this file except remove or modify this copyright.

function testRuleSyms()
  disp 'testRuleSyms: start test................'
  names = NameSyms(ruleNames());                 % from the X language
  fprintf('names.program1=%d\n', names.program1);% spot tests
  fprintf('names.assignment1=%d\n', names.assignment1);
  fprintf('names.factor1=%d\n', names.factor1);
  fprintf('names.factor2=%d\n', names.factor2);
  
  fields(names)                                  % all the names
  disp 'testRuleSyms: end   test................'
end %  of testRuleSyms

