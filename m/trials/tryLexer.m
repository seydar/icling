% FILE:     tryLexer.m
% PURPOSE:  exercise M version of lexer
% REQUIRES: Lexer.m
% METHOD:   a series of small trials of related constructs
% USAGE:    tryLexer(t1, t2...) for trials t1, t2
% EXAMPLE:
%   tryLexer() % for all trials

% COPYRIGHT W.M.McKeeman 2006.  You may do anything you like with 
% this file except remove or modify this copyright.

function tryLexer(varargin)            % empty means all trials

  tn    = [varargin{:}];               % cell to vector
  allt  = isempty(tn);                 % no arg at all
  EOL   = 10;                          % ASCII CTRL-J  
  load(fullfile(mxcomRoot, 'cfg.mat'), 'cfg');   % use saved cfg object

  disp 'start lex trials -------------------------------'
  
  if allt || any(tn == 1)              % smoke trial
    disp 'start lex trial 1 -- smoke trial -----------------'
    lexobj = Lexer(cfg, 'x  := 13333');
    lexobj.dump();
    disp 'end   lex trial 1 -------------------------------'
  end

  if allt || any(tn == 2)
    disp 'start lex trial 2 -- all ops --------------------'  
    src = [...
      'b,i,r := '                                       EOL...
      '1<2 & 2.0<=3.& ~3=4&4~=5 | ~5>=6 | ~6>7,'        EOL...
      'r2i i2r b2i(true),'                              EOL...
      '1+2-3*4/5//rand;'                                EOL...
    ];
    lexobj = Lexer(cfg, src);
    lexobj.dump();
    disp 'end   lex trial 2 -------------------------------'
  end

  if allt || any(tn == 3)
    disp 'start lex trial 3 -- runnable code --------------'
    src = [                                                    ...
      '` FILE:    fibbonacci.m'                            EOL ...
      '` PURPOSE: recursive Fibbonacci'                    EOL ... 
                                                           EOL ...
      'p := n;'                                            EOL ...
      'if p <= 1 ? fib := 1'                               EOL ...
      ':: p > 1  ? fib := fibbonacci(p-1)+fibbonacci(p-2)' EOL ...
      'fi'                                                     ...
      ];
    lexobj = Lexer(cfg, src);
    lexobj.dump();
    disp 'end   lex trial 3 -------------------------------'
  end
    
  if allt || any(tn == 4)              % fat reserved words
    disp 'start lex trial 4 -- names of special tokens ----'
    src = 'id  := integer + real';
    lexobj = Lexer(cfg, src);
    lexobj.dump();
    disp 'end   lex trial 4 -------------------------------'
  end

  if allt || any(tn == 5)              % op combos
    disp 'start lex trial 5 -- all op+sep dipthongs -------'
    cs = '!@#$%^&*(){}[]:;,.=+-_<>?/~';
    src = cs;                          % all singles
    for i=1:numel(cs)
      for j=1:numel(cs)
        src = [src cs(i), cs(j)];      %#ok all pairs
      end
    end
    lexobj = Lexer(cfg, src);
    lexobj.dump();
    disp 'end   lex trial 5 -------------------------------'
  end    
end %  of tryLexer
