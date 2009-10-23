% FILE:    testSymbols.m
% PURPOSE: test symbol table generation and use
% EXAMPLE:
%   testSymbols()

% COPYRIGHT W.M.McKeeman 2007.  You may do anything you like with 
% this file except remove or modify this copyright.

function testSymbols()

  load(fullfile(mxcomRoot, 'cfg.mat'), 'cfg');   % use saved cfg object
  pass = 0;                                      % none yet
  
  pos = {
    'w := true'
    'x := 1'
    'y := 1.1'
    'x, output1 := 2,3; output2 := x+input;'
    'a,b,c := foo := 13, 6.0, true; output := a+b+c+0'
    'if x ? y := 3; fi `x is boolean'

    % operators 7-30
    'x := true | false'                          % logical
    'x := true & false'
    'x := ~false'
    
    'x := 13<3'                                  % integer relationals
    'x := 14<=4'
    'x := 15=5' 
    'x := 16~=6' 
    'x := 17>=7'
    'x := 18>8'
    'x := 13.0<3.0'                              % real relationals
    'x := 14.0<=4.0'
    'x := 17.0>=7.0'
    'x := 18.0>8.0'
    
    'x := 13+3'                                  % +
    'x := 11.0+1.0'
    'x := 10-12'                                 % -
    'x := -3.0'
    'x := -12'                                   % unary -
    'x := 9.0-3.0'
    'x := 8*11'                                  % *
    'x := 7.0*4.0'
    'x := 7/11'                                  % /
    'x := 6.0/4.0'
    'x := 13//3'                                 % //
  };

  res = {
    @(s) s.size()==1 && s.lookup('w')==1 && s.getType(1)==s.boolTYPE;
    @(s) s.size()==1 && s.lookup('x')==1 && s.getType(1)==s.intTYPE;
    @(s) s.size()==1 && s.lookup('y')==1 && s.getType(1)==s.realTYPE;
    @(s) s.getUse(s.lookup('output1'))==s.onLEFT...
    &&   s.getUse(s.lookup('output2'))==s.onLEFT...
    &&   s.getUse(s.lookup('input'))==s.onRIGHT;
    @(s) s.getUse(s.lookup('output'))==s.onLEFT...
    &&   s.getType(s.lookup('a'))==s.intTYPE;
    @(s) s.getType(s.lookup('x'))==s.boolTYPE;

    @(s) s.getType(s.lookup('x'))==s.boolTYPE;  %7
    @(s) s.getType(s.lookup('x'))==s.boolTYPE;
    @(s) s.getType(s.lookup('x'))==s.boolTYPE;
    @(s) s.getType(s.lookup('x'))==s.boolTYPE;
    @(s) s.getType(s.lookup('x'))==s.boolTYPE;
    @(s) s.getType(s.lookup('x'))==s.boolTYPE;
    @(s) s.getType(s.lookup('x'))==s.boolTYPE;
    @(s) s.getType(s.lookup('x'))==s.boolTYPE;
    @(s) s.getType(s.lookup('x'))==s.boolTYPE;
    @(s) s.getType(s.lookup('x'))==s.boolTYPE;
    @(s) s.getType(s.lookup('x'))==s.boolTYPE;
    @(s) s.getType(s.lookup('x'))==s.boolTYPE;
    @(s) s.getType(s.lookup('x'))==s.boolTYPE; %19
  
    @(s) s.getType(s.lookup('x'))==s.intTYPE;  %20
    @(s) s.getType(s.lookup('x'))==s.realTYPE;
    @(s) s.getType(s.lookup('x'))==s.intTYPE;
    @(s) s.getType(s.lookup('x'))==s.realTYPE;
    @(s) s.getType(s.lookup('x'))==s.intTYPE;
    @(s) s.getType(s.lookup('x'))==s.realTYPE;
    @(s) s.getType(s.lookup('x'))==s.intTYPE;
    @(s) s.getType(s.lookup('x'))==s.realTYPE;
    @(s) s.getType(s.lookup('x'))==s.intTYPE;
    @(s) s.getType(s.lookup('x'))==s.realTYPE;
    @(s) s.getType(s.lookup('x'))==s.intTYPE;
  };

  for i=1:numel(pos)
    positive(i);
  end

  neg = {
    'x := y'                                     % undef types
    'x := 1+2.0'                                 % type conflicts
    'x := 1+true'
    'x := true+2.0'
    'x := true+1'
    'x := true+true'
    'x := 2.0+1'
    'x := 2.0+false'
    'x := 1; y := 3.14; output := x+y'
    'x := 1*2.0';                                % operators
    'x := 1/2.0';
    'x := 1//2.0';
    'x := 3.0//2.0';
    };
  
  for i=1:numel(neg)
    negative(i);
  end

  fprintf('Symbols: passed %d unit tests\n', pass);

  return;                                        % end of code
  
  % ---- nested functions ----
  function positive(testno)
    toks = Lexer(cfg, pos{testno});              % lex it
    p = Parser(toks);                            % parse it
    t = Tree(p);                                 % tree it
    s = Symbols(t, 1, {});                        % type it
    t = res{testno};
    if test(~t(s)) 
      error('testSymbols: bad symbol test %d', testno); 
    end
  end

  function negative(testno)
    toks = Lexer(cfg, neg{testno});              % lex it
    p = Parser(toks);                            % parse it
    t = Tree(p);                                 % tree it

    try
      Symbols(t, 1, {});                         % don't see failures
      fprintf('testSymbols: negative test %d FAILED\n', testno);
    catch                                        %#ok report the error
      test(true);
    end
  end

  function res = test(expr)
    pass = pass+1;
    res = expr;
  end

end
