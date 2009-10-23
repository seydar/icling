% FILE:    trySymbols.m
% PURPOSE: exercise symbol table generation and use
% EXAMPLE:
%  trySymbols()   % for all trials

% COPYRIGHT W.M.McKeeman 2007.  You may do anything you like with 
% this file except remove or modify this copyright.

function trySymbols()

  load(fullfile(mxcomRoot, 'cfg.mat'), 'cfg');   % use saved cfg object
  
  pos = {
    'w := true'
    'x := 1'
    'y := 1.1'
    'x, output1 := 2,3; output2 := x+input;'
    'a,b,c := foo := 13, 6.0, true; output := a+b+c+0'
    'if x ? y := 3; fi `x is boolean'
    'x := 1.0; y := 2.0; z := 3.0; i := 1; j := 2;'

    % operators
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

  disp 'trySymbols: ------------ begin positive trials -------'
  for i=1:numel(pos)
    positive(i);
  end
  disp 'trySymbols: ------------ end   positive trials -------'

  return;                                        % end of code
  
  % ---- nested functions ----
  function positive(test)
    fprintf('tSymbols: positive test %d: input:\n', test);
    fprintf('%s\n', pos{test});
    toks = Lexer(cfg, pos{test});                % lex it
    p = Parser(toks);                            % parse it
    t = Tree(p);                                 % tree it
    s = Symbols(t, 1, {});                       % type it
    s.dump();                                    % dump it
  end
    
end
