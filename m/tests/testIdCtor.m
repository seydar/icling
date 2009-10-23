% FILE:     testIdCtor.m
% PURPOSE:  test renaming arbitrary string to id
% METHOD:   try many random strings, all should pass isvarname(str)
% EXAMPLE:
%  testIdCtor()

% COPYRIGHT W.M.McKeeman 2007.  You may do anything you like with 
% this file except remove or modify this copyright.

function testIdCtor()
  makeId = idCtor();
  
  td = 'abcABC123_~!@#$%^&*()+`-={}|[]\:";''<>?,./';
  len = numel(td);
  pass = 0;                                      % none yet
  
  for testno=1:10000
    lft = floor(rand*numel(td)+1);
    rgt = lft+floor(rand*(numel(td)-lft));
    data = td(randperm(len));
    id = makeId.str2id(data(lft:rgt));
    if test(~isvarname(id))
      error('tidCtor: test %d str2i(%s) failed', testno, id); 
    end
  end
  fprintf('idCtor: passed %d unit tests\n', pass);
  
  return;

  function res = test(expr)
    pass = pass+1;
    res = expr;
  end
end