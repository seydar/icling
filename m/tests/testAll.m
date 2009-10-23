% FILE:     testAll.m
% PURPOSE:  call all xcom tests
%
% OVERVIEW:
%   There are many tests in the m/tests directory.  This function calls
%   them all.  It is a final check that all is well after a change.
%   The tests take quite a bit of time: be patient or go get coffee.
%
% EXAMPLE:  
%   testAll()

% COPYRIGHT W.M.McKeeman 2006.  You may do anything you like with 
% this file except remove or modify this copyright.

function testAll(flag)
  disp '-----enter xcom unit tests -----------'
  datestr(now)
  
  if nargin == 0; flag = ''; end
  
  testIdCtor();
  testEnum();
  testArith();
  testTransitiveClosure();
  if strcmp(flag, '-noLR')
    testCfg(1:9);
  else
    testCfg()
  end;
  testLexer();
  testParser();
  testTree();
  
  testErr();
  
  res = evalc('testSymbols()');  % supress extraneous output
  idx = findstr(res, 10);
  disp(res(idx(end-1)+1:end-1))
  
  testAsmX86();
  testEmitX86();
  
  testGenerator();
  testXcom();
  testEmulateX86();
  
  disp '-----leave xcom unit tests -----------'

  disp '-----start testErr---------'
  res = evalc('testErr()');  % supress extraneous output
  fprintf('testErr: passed %d tests\n', numel(strfind(res, 'Error using')))
  disp '-----finish testErr ----------'
  
  disp '-----start gem tests-----------'
  testGem();
  testGem2();
  disp '-----finish gem tests-------------'
end

