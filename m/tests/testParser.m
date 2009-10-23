% FILE:     testParser.m
% PURPOSE:  unit test parser
% METHOD:  
% REQUIRES: Cfg.m Lexer.m Parser.m
% USAGE:    testParser(t1, t2...) for tests t1, t2...  
% EXAMPLE:
%   testParser() % for all tests

% COPYRIGHT W.M.McKeeman 2008.  You may do anything you like with 
% this file except remove or modify this copyright.

function testParser(varargin)          % empty means all tests
  tn     = [varargin{:}];              % cell to vector
  allt   = isempty(tn);                % no arg at all
  load(fullfile(mxcomRoot, 'cfg.mat'), 'cfg');   % use saved cfg object
  pass   = 0;                          % none yet
  
  pos = {
    ''                                 % 1
    'x := 17;'                         % 2
    'if 1<2 ? x:=2 fi'                 % 3
    'x,y,z := fn := 1,2,3'             % 4
  };

  % These are a so-called Gold-File tests.
  % Since the data below was taken from observing the parser,
  % it tests nothing except freedom from regression.
  % Typically a gold-file test is fragile -- any change to the
  % X language is likely to break it.
  res = {
    [-4, -2, 1, -1]' % only EOF is shifted
    [ 1              % shift x
    -19              % allpy rule 19
      3              % shift :=
      5              % shift 17
    -48              % and so on...
    -42
    -38
    -31
    -29
    -27
    -25
    -24
    -21
    -14
     -7
     -2
      6               % shift ;
     -4
     -3
      7               % shift EOF
     -1]
     [    %if 1<2 ? x:=2 fi
      1               % shift if
      3               % shift 1
    -48    
    -42    
    -38    
      4               % shift <
      5               % shift 2
    -48    
    -42    
    -38
    -32    
    -29    
    -27    
    -25    
    -24    
    -13      
      7                % shift ?
      9                % shift x
    -19    
     10                % shift :=
     11                % shift 2
    -48    
    -42    
    -38    
    -31    
    -29    
    -27    
    -25    
    -24    
    -21
    -14     
     -7     
     -2    
    -12    
    -10     
     13                % shift fi
     -8     
     -5     
     -2     
     14                % shift EOF
     -1 
     ]
     [
      1                % shift x
    -19      
      2                % shift ,
      3                % shift y
    -20      
      4                % shift ,
      5                % shift z
    -20      
      7                % shift :=
      9                % shift fn
    -23     
     11                % shift :=
     13                % shift 1
    -48    
    -42    
    -38    
    -31    
    -29    
    -27    
    -25
    -24    
    -21     
     14                % shift ,
     15                % shift 2
    -48    
    -42    
    -38    
    -31    
    -29    
    -27
    -25    
    -24    
    -22     
     16                % shift ,
     17                % shift 3
    -48    
    -42    
    -38    
    -31    
    -29
    -27    
    -25    
    -24    
    -22    
    -15     
     -7     
     -2     
     18                % shift EOF
     -1
    ]
  };
  
  for t = 1:length(pos)
    if allt || any(tn == t)
      try
        positive(t, {});
      catch e
        fprintf('failed top down positive test %d\n', t);
        break;
      end
      try
        positive(t, {'-bottomUp'});
      catch e
        fprintf('failed bottom up positive test %d\n', t);
        break;
      end
    end
  end  
  
  negs = {
    'x := 17==17'
    'if true ? if false ? fi '
  };
  
  for t = 1:length(negs)
    if allt || any(tn == -t)
      negative(t);
    end
  end
  fprintf('Parser: passed %d unit tests\n', pass);
  
  return;

  %------------------ nested functions -------------------------
  function positive(t, flags)
    aLexer = Lexer(cfg, pos{t});
    aParse = Parser(aLexer, flags);
    sr = aParse.sr;
    n = aParse.lim;
    if test(n ~= numel(res{t}))
      error('testParser: test %d bad sr count', t);
    end
    if test(any(sr(1:n) ~= res{t}'))
      error('testParser: test %d bad shift or reduce', t);
    end
  end

  function negative(t)
    try
      aLexer = Lexer(cfg, negs{t});
      aParse = Parser(aLexer);                   %#ok but error out
      error('testParser: negative test %d failed\n', t);
    catch e
      pass = pass+1;
    end
  end

  function res = test(expr)
    pass = pass+1;
    res = expr;
  end


end
