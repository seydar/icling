% FILE:     testGem.m 
% PURPOSE:  test gem (the grammar executing machine)
% METHOD:   test a few grammars
% REQUIRES: gem.m iog.c
% EXAMPLE:    
%   testGem() % for all tests

% COPYRIGHT W.M.McKeeman 2008.  You may do anything you like with 
% this file except remove or modify this copyright.

function testGem()  
  EOL    = 10;                                    % ascii code for newline
  tests  = 0;                                     % none yet
  passed = 0;                                     % none yet
  
  G = gem();                                      % instantiate GEM object
  
  %       -------------- xxxCFG and xxxIOG tests ------------
  
  % --- test G.digitCFG ---
  tests = tests + 1;
  if numel(G.digitCFG)==6*10; passed = passed + 1; end

  idata = '0123456789';
  for ch = idata
    tests = tests + 1;
    G.run(ch,G.digitCFG);
    passed = passed + 1;
  end
  
  % negative test
  tests = tests + 1;
  try
    x=evalc('G.run(''x'',G.digitCFG);'); %#ok<NASGU>
  catch %#ok<CTCH>
    passed = passed + 1;
  end
  
  % --- test G.lowerCFG ---
  tests = tests + 1;
  if numel(G.lowerCFG)==6*26; passed = passed + 1; end
  
  tests = tests + 1;
  G.run('z',G.lowerCFG);
  passed = passed + 1;

  % negative test
  tests = tests + 1;
  try
    x=evalc('G.run(''X'',G.lowerCFG);'); %#ok<NASGU>
  catch %#ok<CTCH>
    passed = passed + 1;
  end

  % --- test G.upperCFG ---
  tests = tests + 1;
  if numel(G.upperCFG)==6*26; passed = passed + 1; end
  
  tests = tests + 1;
  G.run('Z',G.upperCFG);
  passed = passed + 1;

  % negative test
  tests = tests + 1;
  try
    x=evalc('G.run(''x'',G.upperCFG);'); %#ok<NASGU>
  catch %#ok<CTCH>
    passed = passed + 1;
  end
  
  % --- test G.asciiCFG ---
  tests = tests + 1;
  if numel(G.asciiCFG)==(26+26+44)*6; passed = passed + 1; end
  
  tests = tests + 1;
  G.run('a',G.asciiCFG);
  passed = passed + 1;
  tests = tests + 1;
  G.run('A',G.asciiCFG);
  passed = passed + 1;
  
  idata = [EOL ' ':'~'];
  for ch = idata
    tests = tests + 1;
    G.run(ch,G.asciiCFG);
    passed = passed + 1;
  end

  % negative test
  tests = tests + 1;
  try
    x=evalc('G.run(char([0]),G.asciiCFG);'); %#ok<NASGU>
  catch %#ok<CTCH>
    passed = passed + 1;
  end
  
  % --- test G.digitIOG ---
  tests = tests + 1;
  if numel(G.digitIOG)==9*10; passed = passed + 1; end

  idata = '0123456789';
  odata = '';
  for ch = idata
    tests = tests + 1;
    odata = [odata G.run(ch,G.digitIOG)];  %#ok<AGROW>
    passed = passed + 1;
  end
  tests = tests + 1;
  if strcmp(odata,idata); passed = passed + 1; end

  % negative test
  tests = tests + 1;
  try
    x=evalc('G.run(''x'',G.digitIOG);'); %#ok<NASGU>
  catch %#ok<CTCH>
    passed = passed + 1;
  end
  
  % --- test G.lowerIOG ---
  tests = tests + 1;
  if numel(G.lowerIOG)==9*26; passed = passed + 1; end

  idata = 'a':'z';
  odata = '';
  for ch = idata
    tests = tests + 1;
    odata = [odata G.run(ch,G.lowerIOG)];  %#ok<AGROW>
    passed = passed + 1;
  end
  tests = tests + 1;
  if strcmp(odata,idata); passed = passed + 1; end

  % negative test
  tests = tests + 1;
  try
    x=evalc('G.run(''X'',G.lowerIOG);'); %#ok<NASGU>
  catch %#ok<CTCH>
    passed = passed + 1;
  end
  
  % --- test G.upperIOG ---
  tests = tests + 1;
  if numel(G.upperIOG)==9*26; passed = passed + 1; end

  idata = 'A':'Z';
  odata = '';
  for ch = idata
    tests = tests + 1;
    odata = [odata G.run(ch,G.upperIOG)];  %#ok<AGROW>
    passed = passed + 1;
  end
  tests = tests + 1;
  if strcmp(odata,idata); passed = passed + 1; end

  % negative test
  tests = tests + 1;
  try
    x=evalc('G.run(''x'',G.upperIOG);'); %#ok<NASGU>
  catch %#ok<CTCH>
    passed = passed + 1;
  end
  
  % --- test G.asciiIOG ---
  tests = tests + 1;
  if numel(G.asciiIOG)==(26+26+44)*9; passed = passed + 1; end

  idata = [EOL ' ':'~'];
  odata = '';
  for ch = idata
    tests = tests + 1;
    odata = [odata G.run(ch,G.asciiIOG)];  %#ok<AGROW>
    passed = passed + 1;
  end
  tests = tests + 1;
  if strcmp(odata,idata); passed = passed + 1; end

  % negative test
  tests = tests + 1;
  try
    x=evalc('G.run(char([0]),G.asciiIOG);'); %#ok<NASGU>
  catch %#ok<CTCH>
    passed = passed + 1;
  end

  %   -------------- deblanking and scan() ------------
  
  % supress blanks in arbitrary string
  tests = tests + 1;
  t1 = G.run('x y z', G.nowhite);
  if strcmp(t1, 'xyz'); passed = passed+1; end;

  scan=@(txt)G.run(txt,G.nowhite);

  % same test, use scan
  tests = tests + 1;
  t1 = scan('x y z');
  if strcmp(t1, 'xyz'); passed = passed+1; end;
  
  % supress blanks in arbitrary string with multi-char I/O
  tests = tests + 1;
  t1 = G.run('x y z', G.nowhite2);
  if strcmp(t1, 'xyz'); passed = passed+1; end;

  scan=@(txt)G.run(txt, G.nowhite2);

  % same test, use scan
  tests = tests + 1;
  t1 = scan('x y z');
  if strcmp(t1, 'xyz'); passed = passed+1; end;

  % deblank '''
  tests = tests + 1;
  t1 = scan('''''''');  % just '''
  if strcmp(t1, ''''''''); passed = passed+1; end;
  
  % deblank multicharacter input symbol
  tests = tests + 1;
  t1 = scan('''xyz''');  % just 'xyz'
  if strcmp(t1, '''x''''y''''z'''); passed = passed+1; end;
  
  % deblank """
  tests = tests + 1;
  t1 = scan('"""');  % just """
  if strcmp(t1, '"""'); passed = passed+1; end;
  
  % deblank multicharacter output symbol
  tests = tests + 1;
  t1 = scan('"xyz"');  % just "xyz"
  if strcmp(t1, '"x""y""z"'); passed = passed+1; end;
  
  % deblank input and output symbol
  tests = tests + 1;
  t1 = scan('g=''123''"xyz";');  % a typical rule 
  if strcmp(t1, 'g=''1''''2''''3''"x""y""z";'); passed = passed+1; end;
  
  %     ---------- pretty printing and pretty() -----------
  
  % pretty print a typical grammar
  tests = tests + 1;
  t1 = G.run('g=ab;a=''A'';b="B";', scan(G.pretty));  % a typical grammar 
  res = ['g = a b;' EOL 'a = ''A'';' EOL 'b = "B";' EOL];
  if strcmp(t1, res); passed = passed+1; end;
  
  % define pretty printing function
  pretty = @(g)G.run(scan(g), scan(G.pretty));
  
  % pretty on pretty
  tests = tests + 1;
  t1 = pretty(G.pretty);                       % pretty pretty
  res = G.pretty;
  res = res(1:120);
  if strcmp(t1(1:120), res); passed = passed+1; end;

  %            ------------- inverting ---------------
  % invert invert twice gets you back to invert
  tests = tests + 1;
  i0 = scan(G.invert);
  i1 = G.run(i0, i0);                          % inverted invert
  i2 = G.run(i1, i1);                          % inverted^2 invert
  if strcmp(i2, i0); passed = passed+1; end;
  
  % right recursive sum and invert
  tests = tests + 1;
  t1 = G.run('x+x+x', scan(G.sum));            % sum
  res = '4443110';
  if strcmp(t1, res); passed = passed+1; end;
  tests = tests + 1;
  g2 = G.run(scan(G.sum), scan(G.invert));     % inverted sum
  t2 = G.run(res,g2);                          % recreated sum
  if strcmp(t2,'x+x+x'); passed = passed+1; end;
  
  %        -------- arithmetic expressions --------------
  
  % convert infix to postfix
  tests = tests + 1;
  t1 = G.run('x*(y+3)-x/7', scan(G.postfix));
  res = 'xy3+*x7/-';
  if strcmp(t1, res); passed = passed+1; end;

  % convert infix to prefix
  tests = tests + 1;
  t1 = G.run('x*(y+3)-x/7', scan(G.prefix));
  res = '-*x+y3/x7';
  if strcmp(t1, res); passed = passed+1; end;

  %         ----------- grammar grammar --------------
  % self on self
  tests = tests + 1;
  t1 = G.run(scan(G.self), scan(G.self));
  res = '';
  if strcmp(t1, res); passed = passed+1; end;
  
  % self with * on self
  tests = tests + 1;
  t1 = G.run(scan(G.self2), scan(G.self2));
  res = '';
  if strcmp(t1, res); passed = passed+1; end;
    
  %     ------------ implement Kleene * -----------------
  
  % pretty with * on kleene
  tests = tests + 1;
  t1 = G.run(scan(G.kleene),scan(G.pretty2));
  res = scan(G.kleene);
  if strcmp(scan(t1), res); passed = passed+1; end;

  % remove * from simple CFG
  tests = tests + 1;
  t1 = G.run('r=a*b*;',scan(G.nostar1));
  res = 'A=aA;A=;B=bB;B=;';
  if strcmp(scan(t1), res); passed = passed+1; end;

  % remove * from kleene
  tests = tests + 1;
  k1 = G.run(scan(G.kleene),scan(G.nostar1));
  passed = passed+1;

  % replace a* with A, b* with B in simple CFG
  tests = tests + 1;
  t1 = G.run('r=a*b*;',scan(G.nostar2));
  res = 'r=AB;';
  if strcmp(scan(t1), res); passed = passed+1; end;

  % replace r* with R, p* with P in kleene
  tests = tests + 1;
  k2 = G.run(scan(G.kleene),scan(G.nostar2));
  passed = passed+1;
  
  % run kleene on r=a*b*;
  tests = tests + 1;
  g1 = 'r=a*b*;';
  k3 = scan([k2 k1]);
  t1 = G.run(g1,k3);
  res = '';  % no output from kleene
  if strcmp(scan(t1), res); passed = passed+1; end;

  % run kleene on kleene
  tests = tests + 1;
  t1 = G.run(scan(G.kleene),k3);
  res = '';  % no output from kleene
  if strcmp(scan(t1), res); passed = passed+1; end;
  
  fprintf('gem: passed %d tests out of %d\n', passed, tests);
  
end

