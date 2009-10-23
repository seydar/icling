% FILE:     testGenerator.m
% PURPOSE:  test generation of executable code
% OVERVIEW:
%   Generator is the central module in mxcom.   It requires a tree and a
%   emitter.  The tree contains all of the accumulated front-end
%   information and the emitter contains the means to turn that
%   information into an executable and run it.
% USAGE:
%   testGenerator(t,t,t...)  % for test t t t
% EXAMPLE:
%   testGenerator()  % for all tests

% COPYRIGHT W.M.McKeeman 2007.  You may do anything you like with 
% this file except remove or modify this copyright.

function testGenerator(varargin)   
  tn = [varargin{:}];                            % cell to vector
  load(fullfile(mxcomRoot, 'cfg.mat'), 'cfg');   % use saved cfg object
  pass = 0;                                      % none yet

  pos = {
    'x:=1;'
    'if 1 < 2 ? x := 3; fi'
    };

  for i=1:numel(pos)
    if isempty(tn) || any(tn == i)
      positive(i);
    end
  end
  
  fprintf('Generator: passed %d unit tests\n', pass);

  return;

  %----------------- nested functions -------------------
  function positive(t)
    toks = Lexer(cfg, pos{t});                   % lex it
    p = Parser(toks);                            % parse it
    tree = Tree(p);                              % tree it
    sym = Symbols(tree);                         % symbols
    env = xenv({''});
    fr = env.getSizesAddress();
    ex = env.getEntriesAddress();
    cc = Generator(1, {sym}, 0, ex, fr);          % do it
    frame = zeros(1,1, 'int32');                 % plenty
    cc.go(frame);
    test(true);
  end

  function res = test(expr)
    pass = pass+1;
    res = expr;
  end

end
