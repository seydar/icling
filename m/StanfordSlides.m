%%
% PAGE BREAK
%%
% PAGE BREAK
%% ABSTRACT
% *Can a tiny compiler-compiler grow into something useful?*
%
% by Bill McKeeman
% 
% The grammars presented here are like computer programs in that they
% accept input and produce output.  The output may be another grammar,
% which can in turn be used to make yet another grammar. The question is:
% how far can one go?
%
% I do not know, but let us at least get started.
%
% *Note:* I have used this material only for teaching. I do not know of any
% practical or theoretical consequences. The material has some resonance
% with Guy Steele's 1998 OOPSLA talk _Growing a Language_.  
%
% *Note:* This presentation was prepared by the MATLAB publish feature
% which accepts a commented MATLAB script as input.  This paragraph came
% from a MATLAB comment. The grey-bar sections are MATLAB code.  
format compact  % help MATLAB save screen space
%%
% Immediately following the each code section is the corresponding output
% (if any).  There was no output from the |format| statement above.
%
% PAGE BREAK
%% 1 Executable Grammars
% It is well-known that the rewriting rules of a Context-free Grammar can
% be mechanically applied, and that if some sequence of applications
% results in a parse, that parse is correct.  The trick is, of course, in
% finding the correct sequence of applications. 
%
% The _Grammar Executing Machine_ (GEM) presented here can do that, with
% reasonable efficiency, executing its input grammar one character at a
% time.
%
% Topics
%
% * Input/Output Grammar (IOG)
% * GEM primitives
% * How GEM works
% * Basic GEM capabilities
% * Extending IOGs
% * Efficiency and convenience
% * Compiling
% * Debugging
%
% PAGE BREAK
%% 1.1  IOG: the Input/Output Grammar
%
% * ${\cal G} = \langle V_I, V_O, V_N, V_G, \Pi\rangle$
%
% An IOG satisfies the following constraints:
%
% * $V  = V_I \cup V_O \cup V_N$  
% * $V_I \cap V_O = \{\}$
% * $V_I \cap V_N = \{\}$
% * $V_O \cap V_N = \{\}$
% * $V_G \subseteq V_N$
% * $\Pi \subseteq V_N\times V^*$
%
% When $V_O$ is empty, an IOG is a conventional CFG with terminal symbols 
% $V_I$.
%
% There are some initial restrictions 
%
% * Whitespace is not allowed between symbols.
% * The input, output and phrase name symbols are all single-character.
% * The IOG must not be left-recursive.  
%
% PAGE BREAK
%% 1.2  GEM: the Grammar Executing Machine
% GEM is a Grammar Executing Machine.  It can be thought of as a function 
%
%   o = GEM(i, g)
%
% where |i| is the input text, |o| is the resulting output text, and |g|
% is the text of the IOG being executed.  The final argument |g| can be 
% thought of as the *stored program* in a Von Neumann computer.
%
% GEM is made available for use in this talk by the following MATLAB code
G   = gem();   % instantiate the object
GEM = G.run;   % GEM is a function
%%
% PAGE BREAK
%% 1.3  Running GEM
% The simplest possible IOG is applied to the null string
fprintf('res=%s', GEM('', 'r=;'));
%%
% IOG |g1| shows the use of |'| and |"| to delimit members of $V_I$ and
% $V_O$ respectively.
%%
g1 = 'r=''x''"y";'; fprintf('%s\n', g1); 
%%
fprintf('res=%s',GEM('x', g1));
%%
% IOG |g2| shows the use of additional rules to describe alternatives
%%
g2 = 'r=s;s=''1'';s=''2'';'; fprintf('%s\n', g2); 
%%
fprintf('res=%s', GEM('1', g2));
%%
% PAGE BREAK
%% 1.4 GEM Implementation
% The (GEM) machine itself is implemented in C file iog.c.  Function |iog|
% is called from MATLAB. 
%
% The following 80 or so lines of C code execute IOGs.  The compiled C code
% takes a few nanoseconds to execute a step.
%
% The MEX file iog.c is an example of no-frills code that runs on the edge 
% of catastophe.  The slighest user error can bring all of MATLAB down in
% a rubble of bits.  It is meant to illustrate an algorithm, as contrasted
% to being actually used.
% A more robust version can be found in file iog2.c.
dbtype iog.c 113:190
%%
% PAGE BREAK
%% 1.5  How GEM works
% The grammars are symmetric:
%
% * they can be executed right-to-left
% * they can be executed left-to-right. 
%
% When executed "backward," the effect is to exactly undo
% the work that was done going forward. 
%
% At each step during PARSE, GEM switches on the current character,
% interpreting it as one of: 
%
% * a recursive call, or
% * move ahead in the input (a shift), or 
% * move a character to the output, or
% * end of a grammar rule (a reduce).
%
% When a recursive call is needed, the mode shifts to SEARCH which linearly
% passes over the IOG. Once a matching rule is found, the mode returns to
% PARSE.  
% 
% Whenever the actual input fails to match the required input symbol in the
% IOG, the current trial parse fails and mode BACK is entered.
% 
% During mode BACK the IOG is un-executed backward.
%
% If, at some point, the input is entirely used and all recursions have
% returned, GEM reports the output.
%
% PAGE BREAK
%% 2 GEM Capabilities
%% 2.1  Predefined Character-class CFGs and IOGs.
% Character classes analogous to functions |isletter|, |isdigit| and the
% like in C occur often
%
% Eight such classes of symbols are pre-entered so that the GEM user never
% needs to define them explicitly. For example, grammar |digitIOG| defines
% phrase name |D| to pass digits. Read the first rule as "if you see a
% zero, emit a zero."
%
%     D = '0' "0";
%     D = '1' "1";
%     D = '2' "2";
%     D = '3' "3";
%     D = '4' "4";
%     D = '5' "5";
%     D = '6' "6";
%     D = '7' "7";
%     D = '8' "8";
%     D = '9' "9";
%
% The list of pre-entered CFG and IOG character classes is
%
%  digitCFG  (defines phrase d, accept any digit)
%  upperCFG  (defines phrase l, accept any upper case letter)
%  lowerCFG  (defines phrase l, accept any lower case letter)
%  asciiCFG  (defines phrase a, accept any character)
%  digitIOG  (defines phrase D, (above) accept and pass on any digit)
%  upperIOG  (defines phrase L, accept and pass on any upper case letter)
%  lowerIOG  (defines phrase L, accept and pass on any lower case letter)
%  asciiIOG  (defines phrase A, accept and pass on any character)
%
% One or more of these grammars can be *appended* to any grammar to be
% input to GEM. For example, here is an example that accepts any digit and
% passes it to the output.
fprintf('%s', GEM('7', ['r=D;' G.digitIOG])); % MATLAB string concatenation
%%
%
% PAGE BREAK
%% 2.2  Whitespace and IOG |nowhite|
% People like whitespace; GEM does not.  Therefore the first useful IOG is
% a deblanker named |nowhite|.  Since GEM always does first things first, 
% |nowhite| discards blanks and newlines, passes $V_I$ and $V_O$ entries
% (including literal blanks and newlines) unchanged to the output, and also
% as a default (last rule) passes everything else to the output. Because
% phrase name |A| was used, character class grammar |asciiIOG| must be
% appended.
%
%     g = p g;
%     g = ;
%     p = ' '; 
%     p = '  
%     ';  
%     p = I A I; 
%     p = O A O; 
%     p = A;
%     I = ''' "'"
%     O = '"' """
%     asciiIOG
%
% PAGE BREAK
%%
% A de-whited |nowhite| has to be prepared by hand ahead of time;
% it is available as a field of |G|.
fprintf('%s', G.nowhite);
%%
% Since the character class CFGs and IOGs are big, it pays to suppress the
% details when looking at grammars that use them.  Here is |nowhite| again:
idx = strfind(G.nowhite, 'A=');    % the start of asciiIOG
fprintf('%s', G.nowhite(1:idx-1)); % don't print asciiIOG,
fprintf('asciiIOG\n');             % just print it's name instead
%%
%
% PAGE BREAK
%% 2.2.1 Define function |scan| and redefine |GEM|
% Define a MATLAB function to run |nowhite| and at the same time we can
% redefine GEM to automatically scan its second parameter (the grammar). 
scan = @(txt)G.run(txt, G.nowhite);  % (Read the @ as lambda.)
GEM  = @(txt,c)G.run(txt, scan(c));
%%
% Test scan:
scan('x Y z')
%%
%
% PAGE BREAK
%% 2.3  IOG |pretty|, the antidote to |nowhite|
% Returning |nowhite| to human-readable form can be accomplished by IOG
% |pretty|, which puts the minimal amount of blanks and newlines back. IOG
% |pretty| is an example of its own output (as before, the character class
% definitions |lowerIOG|, |upperIOG| and |asciiIOG| are supressed in these
% slides).
%
% Note that the rule for |r| precisely describes itself.
idx = strfind(G.pretty, 'L=');  fprintf('%s', G.pretty(1:idx-1));
fprintf('lowerIOG upperIOG asciiIOG\n');
%%
% IOG |pretty| also serves as a *syntax checker* for GEM input --
% non-grammars will cause a run-time error
%%
% PAGE BREAK
%% 2.4  IOG inversion
% Systematically interchanging the input and output delimiters (|'| and
% |"|) turns a *compiler* into *decompiler*. That is, the inverted IOG then
% accepts the original output and recreates the input. An inverted inverter
% is still an inverter.
idx = strfind(G.invert, 'A='); fprintf('%s', G.invert(1:idx-1)); fprintf('asciiIOG\n');
%%
%
% PAGE BREAK
%% 2.5.1  Inversion Example
% Right-associative sum and difference expressions can be expressed
% naturally in a right-recursive IOG.  The output of the IOG |sum| is the
% left-to-right sequence of rule applications. 
fprintf('%s\n', G.sum);
%%
%
%     string    rule to be applied
%     x+x-x     4
%     t+x-x     4
%     t+t-x     4
%     t+t-t     3
%     t+t-e     2
%     t+e       1
%     e         0
%     g         QUIT
%
exampleparse = GEM('x+x-x', G.sum) % apply sum to 'x+x-x'
%%
invertedsum = GEM(scan(G.sum), G.invert); % apply invert to sum
fprintf('%s', G.run(invertedsum, scan(G.pretty)));
%%
fprintf('%s\n', GEM(exampleparse, invertedsum)); % apply inverted sum to 4443210
%%
%
% PAGE BREAK
%% 3 Extending The IOGs
%% 3.1  Multiple character input and output symbols.
% One can extend |nowhite| to accept multiple-character input and output
% symbols. Here is the new version, called |nowhite2|.
gstr = G.run(G.nowhite2, scan(G.pretty2));
idx = strfind(gstr, 'A ='); fprintf('%s', gstr(1:idx-1)); fprintf('asciiIOG\n');
%%
%
% PAGE BREAK
%% 3.1.1  Redefine |scan|, |pretty| and |GEM|
% Redefine and run the upgraded versions of the functions.
scan   = @(txt)G.run(txt, G.nowhite2);
GEM    = @(txt,c)G.run(txt, scan(c));
scan('r="Hello World";')    % test enhanced scan
%%
GEM('', 'r="Hello World";') % use enhanced scan
%%
% If you want to do a thought-problem, figure out what the new scan will
% do with an empty input or output symbol, e.g. 
%
%    scan('r=ab""c')
%
% PAGE BREAK
%% 3.2  Arithmetic expressions
% _Left-associative_ arithmetic expressions can be described with a trick
% much like that used to write parsers in functional languages such as ML.
% In this case the output is PFN (Polish postfix).
idx = strfind(G.postfix, 'L=');  % start of expr lowerIOG
fprintf('%s', G.postfix(1:idx-1));
fprintf('lowerIOG\n'); fprintf('digitIOG\n');
%%
%
% PAGE BREAK
%% 3.2.1  Postfix
% Applying |postfix| to an arithmetic expression yields the postfix PFN.
fprintf('%s\n', GEM('x*(y+3+4)-x/7', G.postfix));
%% 3.2.2  Prefix
% Another IOG (not shown) produces prefix PFN.
fprintf('%s\n', GEM('x*(y+3+4)-x/7', G.prefix));
%% 3.2.3  Intel X86 code
% In case the postfix PFN example did not look much like a compiler,
% a small change to the output vocabulary (using multicharacter symbols)
% results in Intel X86 assembly code:
fprintf('%s', GEM('x*(y+3+4)-x/7', G.x86));
%%
%
% PAGE BREAK
%% 3.3  Using Regular Expressions in IOGs
% 
% Here is the expression IOG using Kleene *.  Because of what is coming,
% one must use only lower-case letters, and not |d|, for the rule names.
expr = G.run(scan(G.expr),scan(G.pretty2));
idx = strfind(expr, 'D ='); fprintf('%s', expr(1:idx-1)); fprintf('digitIOG\n');
%%
% PAGE BREAK
%% 3.4 Transforming regular expressions back to IOGs
% GEM knows nothing about the Kleene star, so what must be done to make
% progress is to transform regular expression grammars back to the original
% IOG form, as was earlier done with multicharacter input and output
% symbols.  The trick is to replace each
%
%   r*
%
% with a new symbol (say R) and add new rules
%
%   R = rR;  R =;
%
% This trick is applied in two steps: the resulting IOGs are concatenated
% to make a grammar acceptable to GEM.  
%
% The new rules are created by IOG |nostar1| which _throws away the
% grammar_ and makes a few new rules.  |nostar1| contains 26 rules of the
% form
%
%   s = 'a*' "A=aA;A=;";
%   s = 'b*' "B=bB;B=;";
%   ...
%   s = 'z*' "Z=zZ;Z=;";
%
% The |r*| items are replaced _in the grammar_ by IOG |nostar2|, a version
% of |pretty| containing 26 rules of the form
%
%   s = 'a*' "A";
%   s = 'b*' "B";
%   ...
%   s = 'z*' "Z";
%
% PAGE BREAK
%% 3.4.1 The expression IOG as an example using *
newrules   = GEM(scan(G.expr), G.nostar1);
newgrammar = GEM(scan(G.expr), G.nostar2);
postfix    = [newgrammar newrules]; 
fprintf('%s\n', G.run(postfix, scan(G.pretty2)));
%% 
% Applying the newly generated IOG gives postfix
fprintf('%s\n', GEM('2*(6+3+4)-2/7', postfix));
%%
% PAGE BREAK
%% 3.4.2  Add Kleene |+|
% Adding Kleene operator |+| is accomplished by translating |r+| into
% |rr*|, then use |nostar1| and |nostar2| to eliminate the |*|. The IOG
% |noplus| is a version of |pretty| with 26 rules of the form
%
%   s = 'a+' "aa*';
%   s = 'b+' "bb*';
%   ...
%   s = 'z+' "zz*';
% 
plusexample = 'r=a+b+;a=''1''"O";b=''2''"T";'; fprintf(GEM(plusexample,G.pretty2));
%%
plusres = GEM(plusexample, G.noplus); fprintf(GEM(plusres,G.pretty2));
%%
plusout = GEM('11122', [GEM(plusres,G.nostar2) GEM(plusres,G.nostar1)])
%%
% PAGE BREAK
%% 4  Making GEM efficient and reliable
% It is feasible to hack all sorts of enhancements into GEM without
% changing its nature. 
%
% * Tail recursion can be flattened. 
% * The SEARCH can be precomputed (LL(1)-like capability).  
% * Predefined character classes can be implemented inside |iog.c|.
% * Internal consistency checks can be added.
%
% Program |gem2| provides a more efficient and reliable alternative. It has
% exactly the capabilities of |gem| except the character classes act more
% like builtin functions and less like macro expansions and it has more
% internal checks.  
%
% The call to G.run is as before, except that the names of character class
% grammars can be added as additional parameters.  For instance
%
%   G.run(i, g, 'A')
%
% makes the new |run| act like |asciiIOG| was appended to |g|.
%
% The third parameter can contain any of 'TdluaDLUA' standing for Trace and
% the appended character classes digitCFG.... asciiIOG.
%%
% PAGE BREAK
%% 4.1 Examples of using gem2
% A new version of |pretty| puts in _or_ takes out whitespace to make a
% standard readable version of an IOG.
G=gem2();
pretty=@(txt)G.run(txt, G.pretty, 'LUA') ;
prettypretty = pretty(G.pretty0)
%%
% PAGE BREAK
%%
% The name G.GEM is used to implement some common uses of G.run.
postfix = G.GEM('1/y*(3+z)+2*x', 'postfix') % using Kleene *
%%
prefix  = G.GEM('1/y*(3+z)+2*x', 'prefix')
%%
sumagain = G.GEM(G.GEM(G.GEM(G.sum, 'invert'), 'invert'), 'pretty')
%%
% PAGE BREAK
%% 4.2 Intel X86 Assembler
% All compilers eventually have to connect to the underlying hardware.
% The first step here is an assembler that lays out the bits exactly as
% required for execution as a subroutine on last year's Intel hardware.  
%
% Each subroutine starts with a prolog followed by its own computation
% followed by an epilog.  Just executing the prolog followed by the 
% epilog is a no-op.
EOL = 10;      % newline
prolog = [                     ...
  'pushR EBP'              EOL ... push the base pointer on the stack
  'movRR EBP ESP'          EOL ... replace the base with the stack pointer
  'pushA'                  EOL ... save all the general registers
  ];
epilog = [                     ...
  'popA'                   EOL ... restore the general registers
  'xor EAX EAX'            EOL ... zero return code means success
  'leave'                  EOL ... restore stack
  'ret'                    EOL ... restore program counter
  ];

assembled = G.run([prolog epilog], G.scan(G.asm))
%%
% And then we can run the bits on an X86 (my laptop).  Return code zero
% is computed by the xor and signifies successful completion.
fprintf('rc=%d',G.exe(assembled));
%%
% Using inversion, we can disassemble the bits to recover the assembler input.
invertedbits = G.run(assembled,G.GEM(G.scan(G.asm),'invert'))
%%
% PAGE BREAK
%% 4.4 A calculator
% Moving to a higher level, one can compile and run a little 4-register
% calculator language.  As usual, the sequence of calculations is compiled 
% into Intel X86 binary, run, and also decompiled.
make31 = 'b=9;a=3;c=4;a*=b;a+=c;';
compiled = G.run(make31, G.scan(G.calc), 'D'); fprintf('compiled = %s\n', compiled);
executed = G.exe(compiled); fprintf('executed = %d\n',executed);
invertedcalc = G.GEM(G.scan(G.calc),'invert');
decompiled=G.run(compiled, invertedcalc, 'D'); fprintf('decompiled = %s',decompiled);
%%
% Unix function atoi
intval  = G.exe(G.GEM('376', 'atoi')); fprintf('intval=%d', intval);
%%
% PAGE BREAK
%% 4.5 When things go wrong
% Given a bad IOG, or bad text input, GEM will fail.  What GEM will not do
% is give an acceptable diagnostic (it usually backtracks clear out of the
% input text before giving up).
%
% When GEM fails, the highwater mark on the parse stack or backup stack
% usually gives a hint of whatever went wrong.  At this point one turns on
% the trace and either fixes one of the inputs or starts putting print
% statements in file iog.c or iog2.c.  Here is the run of a simple grammar
% with the trace turned on.
toy='r=a;r=b;a=''x''"1";b=''y''"2";';
G.GEM(toy,'pretty')
%%
G.run('x',toy,'T');
%%
% PAGE BREAK
%% 5 Summary
% *The input/output grammar was defined and shown to have some useful
% properties; invertible, directly executable, extendible, compilable.  
% How far it can go is an open question.*
%% Reference
% http://www.mathworks.com/matlabcentral/fileexchange/20149
%% Signature
% Presented to the Computer Science Colloquium, Stanford, March 4, 2009
%
% <<../../images/signature.jpg>>
%
% _Bill McKeeman_, MathWorks Fellow
%
% PAGE BREAK
