% FILE:     tryGenerator.m
% PURPOSE:  exercise generation of executable code
% OVERVIEW:
%   Generator is the central module in mxcom.   It requires a tree and a
%   emitter.  The tree contains all of the accumulated front-end
%   information and the emitter contains the means to turn that
%   information into an executable and run it.
% USAGE:
%   tryGenerator(t1,t2,t3...)             run trials t1,t2, t3
% EXAMPLE:
%   tryGenerator()  %                      run all trials
%

% COPYRIGHT W.M.McKeeman 2007.  You may do anything you like with 
% this file except remove or modify this copyright.

function tryGenerator(varargin)   
  tn = [varargin{:}];                  % cell to vector
  load(fullfile(mxcomRoot, 'cfg.mat'), 'cfg');   % use saved cfg object

  pos = {
    'x:=1;'
    'if 1 < 2 ? x := 3; fi'
    };

  for testno = 1:numel(pos)
    if isempty(tn) || any(tn == testno)
      positive(testno);
    end
  end
  return;

  %----------------- nested functions -------------------
  function positive(t)
    toks = Lexer(cfg, pos{t});                        % lex it
    fprintf('tryGenerator: positive test %d, test input:\n', t);
    fprintf('%s\n', pos{t});
    p = Parser(toks);                                 % parse it
    tree = Tree(p);                                   % tree it
    sym = Symbols(tree);                              % symbols
    env = xenv({''});                                 % no other files
    fr = env.getSizesAddress();
    ex = env.getEntriesAddress();
    cc = Generator(1, {sym}, 0, ex, fr);               % do it
    frame = zeros(1,1, 'int32');                      % plenty
    cc.go(frame);                                     % execute
  end
end
