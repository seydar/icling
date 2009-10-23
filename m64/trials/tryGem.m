function tryGem()
  G = gem()   % build the grammar executing machine object
  scan = @(txt)G.run(txt,G.nowhite)
  GEM  = @(i,c)G.run(i,scan(c))   % always deblank c
  GEM('x y z', G.nowhite)
  scan('x y z')

  GEM(scan(G.self), G.self)
  GEM(G.nowhite,G.pretty)
  pretty = @(txt)GEM(txt,G.pretty)
  pretty(scan(G.pretty))
  GEM('x+x-x', G.sum)
  invert = @(txt)GEM(txt,G.invert)
  GEM('4443210', invert(G.sum))

  scan = @(txt)G.run(txt,G.nowhite2);
  GEM  = @(i,c)G.run(i,scan(c));   % always deblank c
  scan('''hello'' "there"')
  GEM('x*(y+3)-x/7',G.postfix)
  GEM('x*(y+3)-x/7',G.prefix)
  GEM('x*(y+3)-x/7',G.x86)

  self2 = G.self2
  testself2 = GEM(scan(self2),self2)

  nostar1 = GEM(scan(G.nostar1),G.pretty2);
  littlek = 'x=w*y*;w=''1'';y=''2'';';
  newrules = GEM(littlek,G.nostar1)
  nostar2 = GEM(scan(G.nostar2), G.pretty2);
  newgrammar = GEM(littlek,G.nostar2)
  nostar = [newgrammar newrules];
  GEM('11122',nostar)
 
  % kleene parsing itself
  newrules = GEM(scan(G.kleene),G.nostar1)
  newgrammar = GEM(scan(G.kleene),G.nostar2)
  nostar = [newgrammar newrules];
  GEM(scan(G.kleene),nostar)

  % expr using kleene
  newrules = GEM(scan(G.expr),G.nostar1)
  newgrammar = GEM(scan(G.expr),G.nostar2)
  nostar = [newgrammar newrules];
  pfnagain = GEM('1*(2+3)-4/7',nostar)
 end
