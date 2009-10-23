% FILE:     tryLR1.m
% PURPOSE:  unit trials of LR table builder 
% METHOD:   try a few grammars
% REQUIRES: readg.m knuth.cfg X.cfg
% USAGE:    testCfg(t1, t2...) for tests t1, t2
% EXAMPLE:
%  tryLR1() % for all tests

% COPYRIGHT W.M.McKeeman 2006.  You may do anything you like with 
% this file except remove or modify this copyright.

function tryLR1(varargin)                       % empty means all tests

  tn = [varargin{:}];                            % cell to vector
  allt = isempty(tn);                            % no arg at all
  pass = 0;                                      % none yet
  testno = 0;
  ERRLIM = 900;                                  % errors are 1000-k
  
  flags = {'-mainTrace', '-closureTrace' '-shiftTrace', '-reduceTrace'};
  if allt || any(tn == 1)
    testno = testno + 1;
    badg = ['x y' 10 ' z' 10];
    try
      bad = str2cfg(badg);
      lr = LR1(bad, flags);                          %#ok
      error('tesLR1: test %d failed to catch bad cfg\n%s', testno, badg); 
    catch e                                      %#ok
      pass = pass + 1;                           % expected result
    end
  end
  
  if allt || any(tn == 2)
    testno = testno + 1;
    disp 'expect diagnostic for ambigious.cfg'
    ambig = str2cfg(xread('ambiguous.cfg'));
    lr = LR1(ambig, flags);
    t = max(lr.lr(:));                           % look for error flag
    if t > ERRLIM
      pass = pass + 1;
    end
  end
  
  if allt || any(tn == 3)                        % duplicate rule disappears
    testno = testno + 1;
    dupg = str2cfg(xread('duplicate.cfg'));
    sr = LR1(dupg, flags);
    t = -min(sr.lr(:));                          % look for error flag
    if t < ERRLIM
      pass = pass + 1;
    end
  end
  
  if allt || any(tn == 4)
    testno = testno + 1;
    knuth1 = str2cfg(xread('knuth1.cfg'));       % (2) in 1965 paper
    lr = LR1(knuth1, flags);
    t = max(-min(lr.lr(:)), max(lr.lr(:)));
    if t < ERRLIM
      pass = pass + 1;
    end
  end
  
  if allt || any(tn == 5)
    testno = testno + 1;
    disp 'expect diagnostic for knuth2a.cfg'     % (6) in paper
    knuth2a = str2cfg(xread('knuth2a.cfg'));
    lr = LR1(knuth2a, flags);
    t = max(-min(lr.lr(:)), max(lr.lr(:)));
    if t > ERRLIM
      pass = pass + 1;
    end
  end
  
  if allt || any(tn == 6)
    testno = testno + 1;
    knuth2b = str2cfg(xread('knuth2b.cfg'));     % (7) in paper
    lr = LR1(knuth2b, flags);
    t = max(-min(lr.lr(:)), max(lr.lr(:)));
    if t < ERRLIM
      pass = pass + 1;
    end
  end
  
  if allt || any(tn == 7)
    testno = testno + 1;
    knuth3 = str2cfg(xread('knuth3.cfg'));       % (8) in paper
    lr = LR1(knuth3, flags);
    t = max(-min(lr.lr(:)), max(lr.lr(:)));
    if t < ERRLIM
      pass = pass + 1;
    end
  end
  
  if allt || any(tn == 8)
    testno = testno + 1;
    knuth4 = str2cfg(xread('knuth4.cfg'));        % (9) in paper
    lr = LR1(knuth4, flags);
    t = max(-min(lr.lr(:)), max(lr.lr(:)));
    if t < ERRLIM
      pass = pass + 1;
    end
  end
  
  if allt || any(tn == 9)
    testno = testno + 1;
    knuth5 = str2cfg(xread('knuth5.cfg'));       % (10) in paper
    lr = LR1(knuth5, flags);
    t = max(-min(lr.lr(:)), max(lr.lr(:)));
    if t < ERRLIM
      pass = pass + 1;
    end
  end
  
  if allt || any(tn == 10)
    testno = testno + 1;
    Eg = str2cfg(xread('E.cfg'));                % minimal expression
    lr = LR1(Eg, flags);
    t = max(-min(lr.lr(:)), max(lr.lr(:)));
    if t < ERRLIM
      pass = pass + 1;
    end
  end
  
  if allt || any(tn == 11)
    testno = testno + 1;
    Er = str2cfg(xread('erase.cfg'));            % check erasing rules
    lr = LR1(Er, flags);
    t = max(-min(lr.lr(:)), max(lr.lr(:)));
    if t < ERRLIM
      pass = pass + 1;
    end
  end
  
  if allt || any(tn == 12)
    testno = testno + 1;
    rr = str2cfg(xread('rrerr.cfg'));            % check erasing rules
    lr = LR1(rr, flags);
    t = max(-min(lr.lr(:)), max(lr.lr(:)));
    if t >= ERRLIM
      pass = pass + 1;
    end
  end
  
  if allt || any(tn == 13)
    disp 'testLR1 X.cfg takes awhile'
    xsrc = xread('X.cfg');
    xcfg = str2cfg(xsrc);
    tic
    lr = LR1(xcfg);
    toc
    testno = testno + 1;
    test(isstruct(lr));
  end
  
  fprintf('LR1: passed %d unit trials out of %d\n', pass, testno);
  
  return;
  
  function test(expr)
    if expr, pass = pass+1; end
  end

end

