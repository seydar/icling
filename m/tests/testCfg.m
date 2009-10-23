% FILE:     testCfg.m
% PURPOSE:  unit test grammar decoder 
% METHOD:   try a few grammars
% REQUIRES: xread.m knuth.cfg X.cfg
% USAGE:    testCfg(t1, t2...) for tests t1, t2
% EXAMPLE:
%   testCfg()  % for all tests

% COPYRIGHT W.M.McKeeman 2006.  You may do anything you like with 
% this file except remove or modify this copyright.

function testCfg(varargin)        % empty means all tests

  tn = [varargin{:}];          % cell to vector
  allt = isempty(tn);          % no arg at all
  pass = 0;                    % none yet
  testno = 0;
  ERRLIM = 900;                % errors are 1000-k for small k
  
  if allt || any(tn == 1)
    testno = testno + 1;
    badg = ['x y' 10 ' z' 10];
    try
      Cfg(badg);
      error('tCfg: test %d failed to catch bad cfg\n%s', testno, badg); 
    catch
      pass = pass + 1;
    end
  end
  
  if allt || any(tn == 2)
    testno = testno + 1;
    disp 'expect diagnostic for ambigious.cfg'
    ambg = Cfg(xread('ambiguous.cfg'));
    lr = ambg.lr;
    t = max(lr(:));            % look for error flag
    if t > ERRLIM
      pass = pass + 1;
    end
  end
  
  if allt || any(tn == 3)        % duplicate rule disappears
    testno = testno + 1;
    dupg = Cfg(xread('duplicate.cfg'));
    sr = dupg.lr;
    t = -min(sr(:));            % look for error flag
    if t < ERRLIM
      pass = pass + 1;
    end
  end
  
  if allt || any(tn == 4)
    testno = testno + 1;
    knuth1 = Cfg(xread('knuth1.cfg'));  % (2) in LR paper
    lr = knuth1.lr;
    t = max(-min(lr(:)), max(lr(:)));
    if t < ERRLIM
      pass = pass + 1;
    end
  end
  
  if allt || any(tn == 5)
    testno = testno + 1;
    disp 'expect diagnostic for knuth2a.cfg'   % (6) in paper
    knuth2a = Cfg(xread('knuth2a.cfg'));
    lr = knuth2a.lr;
    t = max(-min(lr(:)), max(lr(:)));
    if t > ERRLIM
      pass = pass + 1;
    end
  end
  
  if allt || any(tn == 6)
    testno = testno + 1;
    knuth2b = Cfg(xread('knuth2b.cfg'));  % (7) in paper
    lr = knuth2b.lr;
    t = max(-min(lr(:)), max(lr(:)));
    if t < ERRLIM
      pass = pass + 1;
    end
  end
  
  if allt || any(tn == 7)
    testno = testno + 1;
    knuth3 = Cfg(xread('knuth3.cfg'));  % (8) in paper
    lr = knuth3.lr;
    t = max(-min(lr(:)), max(lr(:)));
    if t < ERRLIM
      pass = pass + 1;
    end
  end
  
  if allt || any(tn == 8)
    testno = testno + 1;
    knuth4 = Cfg(xread('knuth4.cfg'));  % (9) in paper
    lr = knuth4.lr;
    t = max(-min(lr(:)), max(lr(:)));
    if t < ERRLIM
      pass = pass + 1;
    end
  end
  
  if allt || any(tn == 9)
    testno = testno + 1;
    knuth5 = Cfg(xread('knuth5.cfg'));  % (10) in paper
    lr = knuth5.lr;
    t = max(-min(lr(:)), max(lr(:)));
    if t < ERRLIM
      pass = pass + 1;
    end
  end
  
  if allt || any(tn == 10)
    disp 'testCfg X.cfg takes about a minute, use testAll(''-noLR'') to avoid'
    xsrc = xread('X.cfg');
    xcfg = Cfg(xsrc, varargin);
    testno = testno + 1;
    test(class(xcfg) == 'struct');
    
    % find expr in V
    for i=1:numel(xcfg.V)
      if strcmp(xcfg.V{i}, 'expr')
        ex = i;
        break;
      end
    end
    % test heads of expr
    for i=1:numel(xcfg.reserved)
      symbol = xcfg.reserved{i} ;
      testno = testno + 1;
      tval = xcfg.ishead(ex, i);
      switch symbol
        case '(';       test(tval);    % ( is head of expr
        case '-';       test(tval);    % - is head of expr
        case '~';       test(tval);    % ~ is head of expr
        case '(';       test(tval);    % ( is head of expr
        case 'true';    test(tval);    % true is head of expr
        case 'false';   test(tval);    % false is head of expr
        case 'rand';    test(tval);    % rand is head of expr
        case 'b2i';     test(tval);    % b2i is head of expr
        case 'r2i';     test(tval);    % r2i is head of expr
        case 'i2r';     test(tval);    % i2r is head of expr
        case ' id';     test(tval);    % id is head of expr
        case ' real';   test(tval);    % real is head of expr
        case ' integer';test(tval);    % integer is head of expr
          
        case ':=';      test(~tval);   % := is not a head of expr
        case '::';      test(~tval);   % :: is not a head of expr
        case ',';       test(~tval);   % , is not a head of expr
        case ';';       test(~tval);   % ; is not a head of expr
        case '&';       test(~tval);   % & is not a head of expr
        case '<';       test(~tval);   % < is not a head of expr
        case '<=';      test(~tval);   % <= is not a head of expr
        case '=';       test(~tval);   % = is not a head of expr
        case '~=';      test(~tval);   % ~= is not a head of expr
        case '>=';      test(~tval);   % >= is not a head of expr
        case '>';       test(~tval);   % > is not a head of expr
        case '+';       test(~tval);   % + is not a head of expr
        case '*';       test(~tval);   % * is not a head of expr
        case '/';       test(~tval);   % / is not a head of expr
        case '//';      test(~tval);   % // is not a head of expr
        case ')';       test(~tval);   % ) is not a head of expr
          
        case 'if';      test(~tval);   % if is not a head of expr
        otherwise; testno = testno - 1;
      end
    end;
  end
  
  fprintf('Cfg: passed %d unit tests out of %d\n', pass, testno);
  
  return;
  
  function test(expr)
    if expr, pass = pass+1; end
  end

end

