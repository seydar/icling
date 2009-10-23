% FILE:     testGem2.m 
% PURPOSE:  test gem (the grammar executing machine)
% METHOD:   test a few grammars
% REQUIRES: gem2.m iog2.c
% EXAMPLE:    
%   testGem2() % for all tests

% COPYRIGHT W.M.McKeeman 2009.  You may do anything you like with 
% this file except remove or modify this copyright.

function testGem2()  
  EOL    = 10;                                    % ascii code for newline
  tests  = 0;                                     % none yet
  passed = 0;                                     % none yet
  
  G = gem2();                                     % instantiate GEM object

  trace = ~true;                                  % toggle for more output
  %       -------------- xxxCFG and xxxIOG tests ------------
  
  % --- test digitCFG ---

  idata = '0123456789';
  for ch = idata
    tests = tests + 1;
    G.run(ch,'r=d;','d');
    passed = passed + 1;
  end
  traceit();
  
  % negative test
  tests = tests + 1;
  try
    x=evalc('G.run(''x'',''d'');'); %#ok<NASGU>
  catch %#ok<CTCH>
    passed = passed + 1;
  end
  
  % --- test lowerCFG ---
  
  lodata = 'a':'z';
  for ch = lodata
    tests = tests + 1;
    G.run(ch,'r=l;', 'l');
    passed = passed + 1;
  end

  % negative test
  tests = tests + 1;
  try
    x=evalc('G.run(''X'',''r=l;'', ''l'');'); %#ok<NASGU>
  catch %#ok<CTCH>
    passed = passed + 1;
  end
  traceit();

  % --- test upperCFG ---
  hidata = 'A':'Z';
  for ch = hidata
    tests = tests + 1;
    G.run(ch,'r=l;', 'u');
    passed = passed + 1;
  end
  
  % negative test
  tests = tests + 1;
  try
    x=evalc('G.run(''x'',''r=l;'', ''u'');'); %#ok<NASGU>
  catch %#ok<CTCH>
    passed = passed + 1;
  end
  traceit();
  
  % --- test asciiCFG ---
  
  tests = tests + 1;
  G.run('a','r=a;', 'a');
  passed = passed + 1;
  tests = tests + 1;
  G.run('A','r=a;', 'a');
  passed = passed + 1;
  
  idata = [EOL ' ':'~'];
  for ch = idata
    tests = tests + 1;
    G.run(ch,'r=a;', 'a');
    passed = passed + 1;
  end

  % negative test
  tests = tests + 1;
  try
    x=evalc('G.run(char([0]), ''a'');'); %#ok<NASGU>
  catch %#ok<CTCH>
    passed = passed + 1;
  end
  traceit();
  
  % --- test digitIOG ---
  idata = '0123456789';
  odata = '';
  for ch = idata
    tests = tests + 1;
    odata = [odata G.run(ch,'r=D;', 'D')];  %#ok<AGROW>
    passed = passed + 1;
  end
  tests = tests + 1;
  if strcmp(odata,idata); passed = passed + 1; end

  % negative test
  tests = tests + 1;
  try
    x=evalc('G.run(''x'', ''r=D;'', ''D'');'); %#ok<NASGU>
  catch %#ok<CTCH>
    passed = passed + 1;
  end
  traceit();
  
  % --- test lowerIOG ---
  idata = 'a':'z';
  odata = '';
  for ch = idata
    tests = tests + 1;
    odata = [odata G.run(ch, 'r=L;', 'L')];  %#ok<AGROW>
    passed = passed + 1;
  end
  tests = tests + 1;
  if strcmp(odata,idata); passed = passed + 1; end

  % negative test
  tests = tests + 1;
  try
    x=evalc('G.run(''X'',''r=L;'', ''L'');'); %#ok<NASGU>
  catch %#ok<CTCH>
    passed = passed + 1;
  end
  traceit();
  
  % --- test upperIOG ---
  idata = 'A':'Z';
  odata = '';
  for ch = idata
    tests = tests + 1;
    odata = [odata G.run(ch, 'r=L;', 'U')];  %#ok<AGROW>
    passed = passed + 1;
  end
  tests = tests + 1;
  if strcmp(odata,idata); passed = passed + 1; end

  % negative test
  tests = tests + 1;
  try
    x=evalc('G.run(''x'',''r=L;'', ''U'');'); %#ok<NASGU>
  catch %#ok<CTCH>
    passed = passed + 1;
  end
  traceit();
  
  % --- test asciiIOG ---
  idata = [EOL ' ':'~'];
  odata = '';
  for ch = idata
    tests = tests + 1;
    odata = [odata G.run(ch, 'r=A;', 'A')];  %#ok<AGROW>
    passed = passed + 1;
  end
  tests = tests + 1;
  if strcmp(odata,idata); passed = passed + 1; end
  traceit();

  %   -------------- deblanking and scan() ------------
  
  % supress blanks in arbitrary string
  tests = tests + 1;
  t1 = G.run('x y z', G.nowhite, 'A');
  if strcmp(t1, 'xyz'); passed = passed+1; end;
  % internally defined scan
  G.scan('x y z');
  
  % deblank '''
  tests = tests + 1;
  t1 = G.scan('''''''');  % just '''
  if strcmp(t1, ''''''''); passed = passed+1; end;
  
  % deblank multicharacter input symbol
  tests = tests + 1;
  t1 = G.scan('''xyz''');  % just 'xyz'
  if strcmp(t1, '''x''''y''''z'''); passed = passed+1; end;
  
  % deblank """
  tests = tests + 1;
  t1 = G.scan('"""');  % just """
  if strcmp(t1, '"""'); passed = passed+1; end;
  
  % deblank multicharacter output symbol
  tests = tests + 1;
  t1 = G.scan('"xyz"');  % just "xyz"
  if strcmp(t1, '"x""y""z"'); passed = passed+1; end;
  
  % deblank input and output symbol
  tests = tests + 1;
  t1 = G.scan('g=''123''"xyz";');  % a typical rule 
  if strcmp(t1, 'g=''1''''2''''3''"x""y""z";'); passed = passed+1; end;
  traceit();
  
  %     ---------- pretty printing and pretty() -----------
  
  % pretty print a typical grammar
  tests = tests + 1;
  t1 = G.GEM('g=ab;a=''A'';b="B";', 'pretty');
  res = ['g = a b;' EOL 'a = ''A'';' EOL 'b = "B";' EOL];
  if strcmp(t1, res); passed = passed+1; end;
  
  % pretty on pretty
  tests = tests + 1;
  t1 = G.GEM(G.pretty0, 'pretty');             % pretty pretty
  res = G.pretty0;
  if strcmp(t1, res); passed = passed+1; end;
  traceit();

  %            ------------- inverting ---------------
  % invert invert twice gets you back to invert
  tests = tests + 1;
  i0 = G.scan(G.invert);
  i1 = G.run(i0, i0, 'A');                     % inverted invert
  i2 = G.run(i1, i1, 'A');                     % inverted^2 invert
  if strcmp(i2, i0); passed = passed+1; end;
  
  % right recursive sum and invert
  tests = tests + 1;
  t1 = G.run('x+x+x', G.scan(G.sum));          % sum
  res = '4443110';
  if strcmp(t1, res); passed = passed+1; end;
  tests = tests + 1;
  g2 = G.run(G.scan(G.sum), G.scan(G.invert), 'A');% inverted sum
  t2 = G.run(res,g2,'A');                      % recreated sum
  if strcmp(t2,'x+x+x'); passed = passed+1; end;
  traceit();
  
  %        -------- arithmetic expressions --------------
  
  % convert infix to postfix
  tests = tests + 1;
  t1 = G.run('x*(y+3)-x/7', G.postfix, 'LD');
  res = 'xy3+*x7/-';
  if strcmp(t1, res); passed = passed+1; end;

  % convert infix to prefix
  tests = tests + 1;
  t1 = G.run('x*(y+3)-x/7', G.scan(G.prefix), 'LD');
  res = '-*x+y3/x7';
  if strcmp(t1, res); passed = passed+1; end;

  % convert infix to x86
  tests = tests + 1;
  G.run('x*(y+3)-x/7', G.scan(G.x86), 'LD');
  passed = passed+1;
  traceit();

  %         ----------- grammar grammar --------------
  % self on self
  tests = tests + 1;
  t1 = G.run(G.scan(G.self), G.scan(G.self), 'lua');
  if isempty(t1); passed = passed+1; end;
  traceit();
    
  %         ----------- Vn Vi Vo ------------
  
  % Vn of self
  tests = tests + 1;
  t1 = G.run(G.scan(G.self), G.scan(G.Vn), 'luaLU');
  res = 'fgpr';
  if strcmp(unique(t1), res); passed = passed+1; end;
  
  % Vi of sum
  tests = tests + 1;
  t1 = G.run(G.scan(G.sum), G.scan(G.Vi), 'luaA');
  res = '+-x';
  if strcmp(unique(t1), res); passed = passed+1; end;
  
  % Vo of sum
  tests = tests + 1;
  t1 = G.run(G.scan(G.sum), G.scan(G.Vo), 'luaA');
  res = '01234';
  if strcmp(unique(t1), res); passed = passed+1; end;
  traceit();
  
  %     ------------ implement Kleene * -----------------
  
  % pretty on kleene
  tests = tests + 1;
  t1 = G.run(G.scan(G.kleene),G.scan(G.pretty), 'LUA');
  res = G.scan(G.kleene);
  if strcmp(G.scan(t1), res); passed = passed+1; end;

  % remove * from simple CFG
  tests = tests + 1;
  t1 = G.run('r=a*b*;',G.scan(G.nostar1), 'lua');
  res = 'A=aA;A=;B=bB;B=;';
  if strcmp(G.scan(t1), res); passed = passed+1; end;

  % remove * from kleene
  tests = tests + 1;
  k1 = G.run(G.scan(G.kleene),G.scan(G.nostar1), 'lua');
  passed = passed+1;

  % replace a* with A, b* with B in simple CFG
  tests = tests + 1;
  t1 = G.run('r=a*b*;',G.scan(G.nostar2), 'LUA');
  res = 'r=AB;';
  if strcmp(G.scan(t1), res); passed = passed+1; end;

  % replace r* with R, p* with P in kleene
  tests = tests + 1;
  k2 = G.run(G.scan(G.kleene),G.scan(G.nostar2), 'LUA');
  passed = passed+1;
  
  % run kleene on r=a*b*;
  tests = tests + 1;
  g1 = 'r=a*b*;';
  k3 = G.scan([k2 k1]);
  t1 = G.run(g1,k3, 'lua');
  if isempty(G.scan(t1)); passed = passed+1; end;

  % run kleene on kleene
  tests = tests + 1;
  t1 = G.run(G.scan(G.kleene),k3, 'lua');
  if isempty(G.scan(t1)); passed = passed+1; end;
  traceit();
  
  fprintf('gem2: passed %d tests out of %d\n', passed, tests);
  %--------------------------------
  function traceit()
    if trace, fprintf('tests=%d passed=%d\n', tests, passed); end
  end
end

