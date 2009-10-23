% FILE:     tryParser.m
% PURPOSE:  exercise parser
% REQUIRES: Cfg.m Lexer.m Parser.m
% USAGE:    tryParser(t1, t2...) for tests t1, t2...
% EXAMPLE:
%   tryParser() % for all tests

% COPYRIGHT W.M.McKeeman 2006.  You may do anything you like with 
% this file except remove or modify this copyright.

function tryParser(varargin)           % empty means all tests
  EOL    = 10;                         % end of line
  tn     = [varargin{:}];              % cell to vector
  allt   = isempty(tn);                % no arg at all
  load(fullfile(mxcomRoot, 'cfg.mat'), 'cfg');   % use saved cfg object
  
  disp 'tryParser: ----start positive trials -------------------------------'
  pos = {
    ''                                 % 1
    'x := 17;'                         % 2
    'if 1<2 ? x:=2 fi'                 % 3
    'x,y,z := fn := 1,2,3'             % 4
    [...                                 5
      'b,i,r := '                                 EOL...
      '1<2 & 2.0<=3.& ~3=4&4~=5 | ~5>=6 | ~6>7,'  EOL...
      'r2i i2r b2i(true),'                        EOL...
      '1+2-3*4/5//rand;'                          EOL...
    ]
    [...                                 6
      '` FILE:    fibbonacci.x'         EOL ...
      '` PURPOSE: recursive Fibbonacci' EOL ... 
      '`          input n, output fib'  EOL ...
                                        EOL ...
      'p := n;'                         EOL ...
      'if p <= 1 ? fib := 1'            EOL ...
      ':: p > 1  ?'                     EOL ... 
      '  fib := fibbonacci := p-1;'     EOL ...
      '  tmp := fibbonacci := p-2;'     EOL ...
      '  fib := fib + tmp'              EOL ...
      'fi'                              EOL ...
    ]
  };
  
  for t = 1:length(pos)
    if allt || any(tn == t)
      positive(t, {});
      positive(t, {'-bottomUp'});
    end
  end  
  disp 'tryParse: ----end   positive trials -------------------------------'
  
  disp 'tryParse: ----start negative trials -------------------------------'
  negs = {
    'x := 17==17'
    'if true ? if false ? fi '
    'if true ? do false ? fi'
    'if true ;'
    '1 := 1;'
    ':= a;'
    'a;'
    'a,1:=3,4;'
    'x := (;'
    'x := (1;'
  };
  
  for t = 1:length(negs)
    if allt || any(tn == -t)
      negative(t);
    end
  end
  disp 'tryParse: ----end   negative tests -------------------------------'
  
  return;

  %------------------ nested functions -------------------------
  function positive(t, flags)
    fprintf('trial input:\n%s\n', pos{t});
    fprintf('tryParser: positive trial %d\n', t);
    aLexer = Lexer(cfg, pos{t});
    aParse = Parser(aLexer, flags);
    aParse.dump();                               % examine results
  end

  function negative(t)
    fprintf('trial input ''%s''\n', negs{t});
    try                                          % try to parse it
      aLexer = Lexer(cfg, negs{t});
      aParse = Parser(aLexer);                   %#ok but error out
      fprintf('tryParser: negative trial %d failed\n', t);
    catch expectedSyntaxError                    % report the error
      fprintf('tryParser: negative trial %d detected %s\n', ...
        t, expectedSyntaxError.message);
    end
  end

end
