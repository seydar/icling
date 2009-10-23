% FILE:    tryTree.m
% PURPOSE: exercise syntax tree generation and use
% EXAMPLE:
%  tryTree()  % for all tests

% COPYRIGHT W.M.McKeeman 2006.  You may do anything you like with 
% this file except remove or modify this copyright.

function tryTree(varargin)

  tn = [varargin{:}];                           % cell to vector
  load(fullfile(mxcomRoot, 'cfg.mat'), 'cfg');   % use saved cfg object
  
  EOL = 10;
  pos = {
    'x:=1.0'                           % 1
    'x,y,z := foo := 1,2,3'            % 2
    'xyz := 1+2*3/4; i := i2r xyz;'    % 3
    ['if true ?'   EOL ...             % 4
     '  k := 3.0;' EOL ...
     ':: false ?'  EOL ...
     '  k := 4.;'  EOL ...
     'fi'              ...
    ]
  };
  
  for i=1:numel(pos)
    if isempty(tn) || any(tn == i)
      a = positive(i);
      a.dump();
    end
  end
  return;                                        % end executable

  %------------------ nested functions -------------------------
  function res = positive(t)
    aLexer = Lexer(cfg, pos{t});
    aParser = Parser(aLexer);
    res = Tree(aParser);
    fprintf('tryTree: AST positive trial %d, input:\n', t);
    fprintf('%s\n', pos{t});
    aParser = Parser(aLexer, {'-noAST'});
    res = Tree(aParser);
    fprintf('tryTree: syntax tree positive trial %d, input:\n', t);
    fprintf('%s\n', pos{t});
  end

end