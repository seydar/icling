% FILE:        gem2.m
% PURPOSE:     Machine to execute self-describing grammars
% METHOD:      The machine iog2.c has builtin character classes
%              G.pretty cleans up and recreates whitespace
%              Grammars g using Kleene + or - are named g0;
%              the name g is reserved for the executable form.
%              The flag values for G.run are any combination of 
%                  'TdluaDLUA'.
% EXAMPLES:     
%   G = gem2();                          % constructor
%   nw = G.nowhite;                      % a deblanking grammar
%   o = G.run('x y z', nw, 'A')          % deblank string
%   o = G.run('x y', nw, 'AT')           % as above and trace
%   o = G.GEM(G.pretty0, 'pretty')       % pretty print txt
%   o = G.GEM(G.scan(G.sum), 'invert')   % invert txt
%   o = G.GEM('1+2*3', 'postfix')        % make postfix PFN
%   o = G.GEM('1+2*3', 'x86')            % make x86 code
%   o = G.GEM('1+2*3', 'prefix')         % make prefix PFN

% COPYRIGHT:   1988 W. M. McKeeman.  You may do anything you like
%              with this file except remove or alter this notice.
% MODS:	       1988.06.02 -- mckeeman -- original
%              2008.06.11 -- mckeeman@dartmouth -- moved to MEX
%              2009.01.24 -- mckeeman@dartmouth -- reordered args
%              2009.01.28 -- mckeeman@dartmouth -- hacked into gem2

function obj = gem2()
  EOL = 10;                              % ascii end-of-line
  flags = 'TdluaDLUA';                   % all possible flags
 
  %    ------- input grammars -----------------

  %{
    A prescanned scanner expanding multi-character I/O symbols
    and removing whitespace
    What you need for multichar is:
      ''' goes to '''
      'abc' goes to 'a''b''c' (no imbedded ' allowed)
      """ goes to """
      "abc" goes to "a""b""c" (no imbedded " allowed)
  %}
  nowhite = [
    'g=pg;'           ...
    'g=;'             ...
    'p='' '';'        ...  discard blank
    'p=''' EOL ''';'  ...  discard EOL
    'p=III;'          ...  keep '''
    'p=OOO;'          ...  keep """
    'p=''''''i;'      ...  expand 'input stuff'
    'p=''"''o;'       ...  expand "output stuff"
    'p=A;'            ...  pass everything else
    'i='''''';'       ...  comes after input stuff
    'i="''"A"''"i;'   ...  expand one  input char
    'o=''"'';'        ...  comes after output stuff
    'o="""A"""o;'     ...  expand one output char
    'I=''''''"''";'   ...  see ', send '
    'O=''"''""";'     ...  see ", send "
    % asciiIOG
    ];

  % make new rules to define a* (only lower)     
  % 'a*' goes to "A=aA;A=;";
  nostar1 = [       
    'g = r g;'                               EOL ...
    'g =;'                                   EOL ...
    'r = l ''='' f '';'';'                   EOL ...
    'f = p f;'                               EOL ...
    'f =;'                                   EOL ...
    'p = '''''' a '''''';'                   EOL ...
    'p = ''"'' a ''"'';'                     EOL ...
    'p = s;'                                 EOL ...
    'p = l;'                                 EOL ...
    sprintf(sprintf('s=''%c*''"%%c=%c%%c;%%c=;";', ...
      deal2('a':'z')),deal3('A':'Z'))        EOL ...
    % lowerCFG
    % upperCFG
    % asciiCFG
    ];

  % replace a* with A in a grammar (only lower) 
  % a* goes to A
  nostar2 = [       
    'g = r g;'                               EOL ...
    'g =;'                                   EOL ...
    'r = L ''='' "="  f '';'' ";" ;'         EOL ...
    'f = p f;'                               EOL ...
    'f =;'                                   EOL ...
    'p = I A I;'                             EOL ...
    'p = O A O;'                             EOL ...
    'p = s;'                                 EOL ...
    'p = L;'                                 EOL ...
    'I = '''''' "''";'                       EOL ...  see ', send '
    'O = ''"''  """;'                        EOL ...  see ", send "
    sprintf('s=''%c*''"%c";', shuffle('a':'z','A':'Z'))  EOL ...
    % lowerIOG
    % upperIOG
    % asciiIOG
    ];

  % replace a+ in a grammar (only lower) 
  % a+ goes to aa*
  noplus = [       
    'g = r g;'                               EOL ...
    'g =;'                                   EOL ...
    'r = L ''='' "="  f '';'' ";" ;'         EOL ...
    'f = p f;'                               EOL ...
    'f =;'                                   EOL ...
    'p = I A I;'                             EOL ...
    'p = O A O;'                             EOL ...
    'p = S;'                                 EOL ...
    'p = L;'                                 EOL ...
    'I = '''''' "''";'                       EOL ...  see ', send '
    'O = ''"''  """;'                        EOL ...  see ", send "
    sprintf('S=''%c+''"%c%c*";', deal3('a':'z'))  EOL ...
    % lowerIOG
    % upperIOG
    % asciiIOG
    ];

  % an IOG pretty printer
  % handles extra and missing whitespace
  % leaves multicharacter inputs and outputs unchanged
  pretty0 = [
    'g = b* r*;'                             EOL ...
   ['r = L b* ''='' " =" f* b* '';'' b* ";' EOL '";'] EOL ...
    'f = b* " " p;'                          EOL ...
    'p = I I I;'                             EOL ... 
    'p = I i "''";'                          EOL ...
    'p = O O O;'                             EOL ...
    'p = O o """;'                           EOL ...
    'p = L ''*'' "*";'                       EOL ...
    'p = L ''+'' "+";'                       EOL ...
    'p = L;'                                 EOL ...
    'i = '''''';'                            EOL ...
    'i = A i;'                               EOL ... 
    'o = ''"'';'                             EOL ...
    'o = A o;'                               EOL ...
    'I = '''''' "''";'                       EOL ...
    'O = ''"'' """;'                         EOL ...
    'b = '' '';'                             EOL ...
   ['b = ''' EOL ''';']                      EOL ...                             
    % lowerIOG
    % upperIOG
    % asciiIOG
    ];

  % transform away the *
  prettygrammar = run(scan(pretty0), scan(nostar2), 'LUA');
  prettyrules   = run(scan(pretty0), scan(nostar1), 'lua');
  pretty        = [prettygrammar prettyrules];
  
  invert = [
    'g = p g;'                       EOL ...
    'g = ;'                          EOL ...
    'p = '''''' """ A '''''' """;'   EOL ...
    'p = ''"'' "''" A ''"'' "''";'   EOL ...
    'p = A;'                         EOL ...
    % asciiIOG
    ];

  % a right associative grammar for + and -
  sum    = [
    'g = e         "0";'             EOL ...
    'e = t ''+'' e   "1";'           EOL ...
    'e = t ''-'' e   "2";'           EOL ...
    'e = t         "3";'             EOL ...
    't = ''x''       "4";'           EOL ...
    ];

  unsum = run(scan(sum), scan(invert), 'A');
  
  % expr with * to operator-late PFN
  postfix0   = [
    'g = e;'                         EOL ...
    'e = t r*;'                      EOL ...
    'r = ''+'' t "+";'               EOL ...
    'r = ''-'' t "-";'               EOL ...
    't = f s*;'                      EOL ...
    's = ''*'' f "*";'               EOL ...
    's = ''/'' f "/";'               EOL ...
    'f = L;'                         EOL ...
    'f = D;'                         EOL ...
    'f = ''('' e '')'';'             EOL ...
    % lowerIOG
    % digitIOG
    ];

  spfix = scan(postfix0);
  postfix0grammar = run(spfix, scan(nostar2), 'LUA');
  postfix0rules   = run(spfix, scan(nostar1), 'lua');
  postfix         = [postfix0grammar postfix0rules];
    
  % making X86 type double code
  x86   = [
    'g = e;'                         EOL ...
    'e = t r;'                       EOL ...
   ['r = ''+'' t "fadd' EOL '" r;']  EOL ...
   ['r = ''-'' t "fsub' EOL '" r;']  EOL ...
    'r = ;'                          EOL ...
    't = f s;'                       EOL ...
   ['s = ''*'' f "fmul' EOL '" s;']  EOL ...
   ['s = ''/'' f "fdiv' EOL '" s;']  EOL ...
    's = ;'                          EOL ...
   ['f = "fld " L "' EOL '";']       EOL ...
   ['f = "fld =" D "' EOL '";']      EOL ...
    'f = ''('' e '')'';'             EOL ...
    % lowerIOG
    % digitIOG
    ];

  % left associative arithmetic expression to operator-early PFN
  prefix  = [
    'g = e;'                         EOL ...
    'e = "+" t ''+'' e;'             EOL ...
    'e = "-" t ''-'' e;'             EOL ...
    'e = t;'                         EOL ...
    't = "*" f ''*'' t;'             EOL ...
    't = "/" f ''/'' t;'             EOL ...
    't = f;'                         EOL ...
    'f = L;'                         EOL ...
    'f = D;'                         EOL ...
    'f = ''('' e '')'';'             EOL ...
    % lowerIOG
    % digitIOG
    ];

  % a self-describing cfg (laid out for display)
  self   = [
    'g = r g;            g =;'               EOL ...
    'r = l ''='' f '';'';'                   EOL ...
    'f = p f;            f =;'               EOL ...
    'p = '''''' a '''''';      '             ,   ...
    'p = ''"'' a ''"'';      p = l;'         EOL ...  
    % lowerCFG
    % upperCFG
    % asciiCFG
    ];

  % phrase names  (defines phrase names g r f a l)
  Vn   = [
    'g = rg;'                                EOL ...
    'g =;'                                   EOL ...
    'r = L ''='' f '';'';'                   EOL ...
    'f = p f;'                               EOL ...
    'f =;'                                   EOL ...
    'p = l;'                                 EOL ...
    'p = '''''' a '''''';'                   EOL ...
    'p = ''"'' a ''"'';'                     EOL ...
    % lowerCFG
    % upperCFG
    % asciiCFG
    % lowerIOG
    % upperIOG
    ];

  % input symbols  (defines phrase names g r f a l)
  Vi   = [
    'g = rg;'                                  EOL...
    'g =;'                                     EOL...
    'r = l ''='' f '';'';'                     EOL...
    'f = l f;'                                 EOL...
    'f = '''''' A '''''' f;'                   EOL...
    'f = ''"'' a ''"'' f;'                     EOL...
    'f =;'                                     EOL...
    % lowerCFG
    % upperCFG
    % asciiCFG
    % asciiIOG
    ];

  % output symbols  (defines phrase names g r f a l d)
  Vo   = [
    'g = rg;'                                  EOL...
    'g=;'                                      EOL...
    'r = l ''='' f '';'';'                     EOL...
    'f = l f;'                                 EOL...
    'f = '''''' a '''''' f;'                   EOL...
    'f = ''"'' A ''"'' f;'                     EOL...
    'f =;'                                     EOL...
    % lowerCFG
    % upperCFG
    % asciiCFG
    % asciiIOG
    ];

  % using Kleene * to describe itself
  kleene = [
    'g = r*;'                                 EOL ...
    'r = l ''='' f '';'';'                    EOL ...
    'f = p*;'                                 EOL ...
    'p = '''''' a ''''''; p = ''"'' a ''"'';' EOL ...  
    'p = l ''*''; p = l ''+''; p = l;'        EOL ...  
    % lowerCFG
    % upperCFG
    % asciiCFG
    ];
          
  % an Intel X86 assembler (blank sep, EOL forced)
  asm = [
      'p = i p;'                                      EOL ...
      'p =;'                                          EOL ...
      'i = ''pushR EBP''     e            "55";'      EOL ...
      'i = ''movRR EBP ESP'' e            "89E5";'    EOL ...
      'i = ''pushA''         e            "60";'      EOL ...
      'i = ''popA''          e            "61";'      EOL ...
      'i = ''xor EAX EAX''   e            "33C0";'    EOL ...
      'i = ''leave''         e            "C9";'      EOL ...
      'i = ''ret''           e            "C3";'      EOL ...
     ['e = ''' EOL ''';']                             EOL ...
    ];
  
  % a 4-register calculator
  % a = 3;
  % a += b;
  % MOD     = @(m)bitshift(bitand(uint8(m),3),6);
  % REG     = @(r)bitshift(bitand(uint8(r),7),3);
  % R_M     = @(rm)bitand(uint8(rm),7);
  % MOD_REG = @(rm,r)bitor(bitor(MOD(3), REG(r)), R_M(rm));
  rmRR = [...
    'aaC0', 'abC8', 'acD0', 'adD8',...
    'baC1', 'bbC9', 'bcD1', 'bdD9',...
    'caC2', 'cbCA', 'ccD2', 'cdDA',...
    'daC3', 'dbCB', 'dcD3', 'ddDB'];
  
  mrRR = [...
    'aaC0', 'abC1', 'acC2', 'adC3',...
    'baC8', 'bbC9', 'bcCA', 'bdCB',...
    'caD0', 'cbD1', 'ccD2', 'cdD3',...
    'daD8', 'dbD9', 'dcD3', 'ddDB'];
  
  calc = [
    'c = "554889E5" p "C9C3";'                    EOL ...
    'p = i p;'                                    EOL ...
    'p =;'                                        EOL ...
    'i = a;'                                      EOL ...
    'i = x;'                                      EOL ...
    'a = ''a='' "B80" h "000000" '';'' ;'         EOL ...
    'a = ''b='' "B90" h "000000" '';'' ;'         EOL ...
    'a = ''c='' "BA0" h "000000" '';'' ;'         EOL ...
    'a = ''d='' "BB0" h "000000" '';'' ;'         EOL ...
    'a = ''a='' "B8" hh "000000" '';'' ;'         EOL ...
    'a = ''b='' "B9" hh "000000" '';'' ;'         EOL ...
    'a = ''c='' "BA" hh "000000" '';'' ;'         EOL ...
    'a = ''d='' "BB" hh "000000" '';'' ;'         EOL ...
    'h = D;'                                      EOL ...
    'h = ''A''"A";'                               EOL ...
    'h = ''B''"B";'                               EOL ...
    'h = ''C''"C";'                               EOL ...
    'h = ''D''"D";'                               EOL ...
    'h = ''E''"E";'                               EOL ...
    'h = ''F''"F";'                               EOL ...
    sprintf('x = ''%c+=%c;'' "01%c%c";\n',   rmRR),...
    sprintf('x = ''%c-=%c;'' "2B%c%c";\n',   mrRR),...
    sprintf('x = ''%c*=%c;'' "0FAF%c%c";\n', mrRR),...
    sprintf('x = ''%c|=%c;'' "0B%c%c";\n',   rmRR)... 
    % digitIOG
    ];
  
  % convert ascii integer into binary integer
  atoi = [
    'c = "5589E5" "33C0" "B90A000000" p "C9C3";'  EOL ... pro/epilog
    'p = "0FAFC1" i p;'                           EOL ... EAX*=ECX;
    'p =;'                                        EOL ... EAX=0
    'i = ''0'';'                                  EOL ... EAX+=0;
    'i = ''1'' "40";'                             EOL ... EAX+=1;
    'i = ''2'' "0502000000";'                     EOL ... EAX+=2;
    'i = ''3'' "0503000000";'                     EOL ... EAX+=3;
    'i = ''4'' "0504000000";'                     EOL ... EAX+=4;
    'i = ''5'' "0505000000";'                     EOL ... EAX+=5;
    'i = ''6'' "0506000000";'                     EOL ... EAX+=6;
    'i = ''7'' "0507000000";'                     EOL ... EAX+=7;
    'i = ''8'' "0508000000";'                     EOL ... EAX+=8;
    'i = ''9'' "0509000000";'                     EOL ... EAX+=9;
    ];

  obj = public();
  return;
  
  
  % ----------------- nested  --------------------
  
  % Run the optimized form of GEM
  function otxt = run(itxt, gtxt, varargin)
    gtxt = ['=' gtxt(1) '''' 0 ''';' gtxt];      % prepend rule 0
    if nargin == 2
      otxt = iog2(itxt, gtxt);                   % call mex
      return;
    end
    
    flag = uint32(0);
    for f = varargin{1}                          % some of TdluaDLUA
      idx = strfind(flags, f);
      if isempty(idx), error('bad flag %c', f); end
      flag = bitor(flag, bitshift(uint32(1), idx-1));
    end
    otxt = iog2(itxt, gtxt, flag);               % call mex with flags
  end

  function otxt = scan(itxt)
    otxt = run(itxt, nowhite, 'A');
  end

  % canned examples
  function otxt = GEM(itxt, gname)
    switch gname
      case 'nowhite', otxt = run(itxt, nowhite,       'lua');
      case 'pretty',  otxt = run(itxt, pretty,        'LUA');
      case 'invert',  otxt = run(itxt, scan(invert),  'LUA');
      case 'sum',     otxt = run(itxt, scan(sum));
      case 'unsum',   otxt = run(itxt, unsum);
      case 'postfix', otxt = run(itxt, scan(postfix), 'LD');
      case 'x86',     otxt = run(itxt, scan(x86),     'LD');
      case 'prefix',  otxt = run(itxt, scan(prefix),  'LD');
      case 'atoi',    otxt = run(itxt, scan(atoi));
      otherwise, error('grammar %s not yet implemented', gname); 
    end
  end

  % Run hex string on underlying hardware.
  % Squeeze 2 M chars into each code byte.
  function rc = exe(hex)
    nbytes = numel(hex)/2;
    code = zeros(1,nbytes,'uint8');
    for pc = 1:nbytes                       % squeeze out leading zeros
      b1 = val(hex(2*pc-1));
      b2 = val(hex(2*pc));
      code(pc) = bitor(bitshift(b1,4),b2);
    end
    rc = runX86(code,zeros(1,1,'uint32'));  % dummy frame
  end

  function res = val(hexdigit)
    if '0'<=hexdigit && hexdigit<='9', res = hexdigit-'0';
    else res = hexdigit - 'A' + 10;
    end
  end

  function o = public()
    o = struct;
    o.run  = @run;  % execute with all parameters
    o.GEM  = @GEM;  % execute with named grammar
    o.scan = @scan; % prepacked scanner
    
    o.nowhite = nowhite;
    o.nostar1 = nostar1;
    o.nostar2 = nostar2;
    o.noplus  = noplus;

    o.pretty0 = pretty0;  % uses Kleene *
    o.pretty  = pretty;   % executable pretty0
    
    o.invert  = invert;
    o.sum     = sum;
    o.unsum   = unsum;
    o.postfix = postfix;
    o.x86     = x86;
    o.prefix  = prefix;
    o.self    = self;
    o.kleene  = kleene;
    
    o.Vn      = Vn;
    o.Vi      = Vi;
    o.Vo      = Vo;

    o.asm     = asm;
    o.exe     = @exe;
    o.calc    = calc;
    o.atoi    = atoi;
  end

  % abc goes to aabbcc
  function pairs = deal2(chars)
    pairs = shuffle(chars, chars);
  end

  % abc goes to aaabbbccc
  function triples = deal3(chars)
    triples = shuffle(chars, chars, chars);
  end

  % abc 123 $#@ goes to a1$b2#c3@
  function deck = shuffle(varargin)
    tmp = vertcat(varargin{:});
    deck = tmp(:)';
  end

end

