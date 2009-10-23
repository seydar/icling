% FILE:    testTree.m
% PURPOSE: test syntax tree generation and use
% EXAMPLE:
%  testTree()

% COPYRIGHT W.M.McKeeman 2006.  You may do anything you like with 
% this file except remove or modify this copyright.

function testTree(varargin)

  tn = [varargin{:}];                            % cell to vector
  load(fullfile(mxcomRoot, 'cfg.mat'), 'cfg');   % use saved cfg object
  pass = 0;                                      % none yet
  
  EOL = 10;
  pos = {                                        % positive tests
    'x:=1.0'
    'x,y,z := foo := 1,2,3'
    'xyz := 1+2*3/4; i := i2r xyz;'
    ['if true ?'   EOL ...
     '  k := 3.0;' EOL ...
     ':: false ?'  EOL ...
     '  k := 4.;'  EOL ...
     'fi'              ...
    ]
  };

  for i=1:numel(pos)
    if isempty(tn) || any(tn == i)
      a = positive(i);
      r = a.getRoot();
      assert(a.getRule(r) == 1);
      pass = pass + 1;
    end
  end
  
  % negative tests needed
  
  fprintf('Tree: passed %d unit tests\n', pass);
  return;                                        % end executable

  %------------------ nested functions -------------------------
  function res = positive(t)
    aLexer = Lexer(cfg, pos{t});
    aParser = Parser(aLexer);
    res = Tree(aParser);
  end
end