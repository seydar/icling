%%  Can a tiny compiler-compiler grow into something useful?
%
% by Bill McKeeman, Mathworks and Dartmouth, March 2009
%% Abstract
% Context-free grammars are extended to accomodate output.  A grammar
% executing machine is introduced which accepts an input text and a grammar
% and outputs another text.  Both the input text and the output text can
% also be grammars, permitting the production of ever more powerful
% grammars.  In this manner, one can start from a small beginning and
% bootstrap towards a conventional compiler.  
%
% The grammars and the machine have some simple symmetries that lead to
% actions such as backtracking and decompiling.  It is also possible to
% directly execute bit strings in the Intel x86 hardware, opening the
% possibility of indefinite extension.
%
% This development stops well short of even a simple conventional compiler
% but that is not because of any known limitations to the approach.
%% 1 Introduction
% The question is: starting from a minimal extensible compiler-compiler,
% how far can one go?  The question is only partly answered here.
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
%% 1.1 Executable Grammars
% It is well-known that the rewriting rules of a Context-free Grammar can
% be mechanically applied, and that if some sequence of applications
% results in a parse, that parse is correct.  The trick is, of course, in
% finding the correct sequence of applications. 
%
% The _Grammar Executing Machine_ (GEM) presented here can do that, with
% reasonable efficiency, executing its input grammar one character at a
% time.
%% 1.2  IOG: the Input/Output Grammar
% An Input/Output Grammar (IOG), a kind of syntax directed translation
% schema, is a Mealy-like extension of the Context-Free Grammar (CFG).  The
% name is chosen to emphasize the symmetry of input (what any CFG naturally
% defines) and output (which has been added). Following the usual
% conventions for CFGs, an IOG
%
% * ${\cal G} = \langle V_I, V_O, V_N, V_G, \Pi\rangle$
%
% consists of a set of input symbols, a set of output symbols, 
% a set of phrase names, a set of goals, and a set of reduction rules. The
% output symbols are analogous to the {actions} of YACC.  In this paper
% $V_G$ contains only one symbol but for other uses, in particular the
% description of finite automata, multiple goals are useful.
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
% There are some initial restrictions on the IOGs GEM can accept.  
%
% * Whitespace is not allowed between symbols.
% * The input, output and phrase name symbols are all single-character.
% * The IOG must not be left-recursive.  
%
% Part of the task is to use IOGs to relax these restrictions on IOGs.
%% 1.3  GEM: the Grammar Executing Machine
% GEM is a Grammar Executing Machine.  It can be thought of as a function 
%
%   o = GEM(i, g)
%
% where |i| is the input text, |o| is the resulting output text, and |g|
% is the text of the IOG being executed.  The final argument |g| can be 
% thought of as the *stored program* in a Von Neumann computer.
%
% The implementation of GEM and some of its grammars is bundled in a MATLAB
% object.  It can be made available for use in this talk by the following
% lines of MATLAB code.
G   = gem();   % instantiate the object
GEM = G.run;   % GEM is a function
%% 1.4  Running GEM
% A grammar |g| acceptable to GEM is a _sequence_ of rules, each of the
% form 
% 
% p = $\alpha$; 
%
% where p is a letter and $\alpha$ is a _sequence_ of symbols from $V$.
% Letters are used to signify members of $V_N$. By convention, the first
% rule in |g| defines the goal symbol, and therefore is the only member of
% $V_G$.
%
% The word _sequence_ used twice above is significant: grammar rules are
% tried in order, allowing specific cases to be separated out from more
% general cases.  Useful GEM grammars may be technically ambiguous. 
% Three examples suffice to show all the capabilities of GEM.
%%
% IOG g0, the simplest possible input grammar
%
%      r=;
%
% is applied to the null string.  Since this grammar does no output, it
% gives a null string result.  More significantly GEM did not give a
% diagnostic, which implies it actually parsed the null string.
fprintf('res=%s', GEM('', 'r=;'));
%%
% IOG g1 
%
%     r='x'"y";
%
% shows the use of |'| and |"| to delimit members of $V_I$ and $V_O$
% respectively.  This grammar accepts character |x| as input and produces
% character |y| as output.  Note: in a MATLAB string |''| stands for |'|.
fprintf('res=%s',GEM('x', 'r=''x''"y";'));
%%
% IOG g2 
%
%    'r=s;s='1';s='2';
%
% shows the use of additional rules to describe alternatives.  Given the
% string |1| as input, it produces the null string as output.
fprintf('res=%s', GEM('1', 'r=s;s=''1'';s=''2'';'));
%% 1.5 GEM Implementation
% The (GEM) machine itself is implemented in C file iog.c.  Function |iog|
% is called from MATLAB. 
%
% Why not use MATLAB instead of C for iog.c?  Fair question. The answer is
% that GEM is best expressed at a very low level, even lower than C. MATLAB
% is in the wrong direction. Perhaps assembler would be more even more
% appropriate. 
%
% Here is the line-count of the C code (MEX file) for GEM.
!wc -l iog.c  
%%
% The characters in the IOG are opcodes of the machine. The machine has
% three modes: PARSE, SEARCH and BACK. 
%
% The following 80 or so lines of C code execute IOGs.  The compiled C code
% takes a few nanoseconds to execute a step.
dbtype iog.c 113:190
%%
% The MEX file iog.c is an example of no-frills code that runs on the edge 
% of catastophe.  The slightest user error can bring all of MATLAB down in
% a rubble of bits.  It is meant to illustrate an algorithm, as contrasted
% to being actually used.
%
% A more robust version can be found in file iog2.c.  Both are found in the
% <http://www.mathworks.com/matlabcentral/fileexchange/20149 distribution package> 
% for my short course on compilers.
%% 1.6  How GEM works
% One fundamental property of GEM input is that the grammars are symmetric.
% They can be executed right-to-left as easily as they can be executed
% left-to-right.  When executed "backward," the effect is to exactly undo
% the work that was done going forward.  This provides a simple
% micro-managed kind of backtracking.
%
% The initial mode of execution is SEARCH; the initial executable character
% is the goal symbol. GEM searches the grammar for definitions of the goal
% symbol to try.  When one is found, mode PARSE is entered.
% 
% At each step during PARSE, GEM switches on the current character,
% interpreting it as one of: 
%
% * a recursive call, or
% * move ahead in the input (a shift), or 
% * move a character to the output, or
% * end of a grammar rule (a reduce).
%
% When a recursive call is needed, the mode shifts back to SEARCH which
% linearly passes over the entire IOG, looking for candidate rules to call.
% Once a matching rule is found, the mode returns to PARSE.  
% 
% Whenever the actual input fails to match the required input symbol in the
% IOG, the current trial parse fails and mode BACK is entered.  Mode BACK
% is simpler than PARSE becauses the IOG has already been syntax checked,
% at least up to the current point of execution.
% 
% During mode BACK the IOG is un-executed backward.
%
% If, at some point, the input is entirely used and all recursions have
% returned, GEM reports the output.
%% 2 GEM Capabilities
%% 2.1  Predefined Character-class CFGs and IOGs.
% Character classes occur a lot and are rather tedious to specify
% in grammatical form.  Character classes here are analogous to
% functions |isletter|, |isdigit| and the like in C.
%
% Eight such classes of symbols are pre-entered so that the GEM user never
% needs to define them explicitly.
% For example, grammar |digitIOG| defines phrase name |D| to pass digits. 
% Read the first rule as "if you see a zero, emit a zero."
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
% One or more of these grammars can be _appended_ to any grammar to be
% input to GEM. For example, here is an example that accepts any digit and
% passes it to the output.
fprintf('%s', GEM('7', ['r=D;' G.digitIOG])); % MATLAB string concatenation
%% 2.2  Whitespace and IOG |nowhite|
% People like whitespace; GEM does not.  Therefore the first useful IOG is
% a deblanker named |nowhite|.  
%
% A |g| is a sequence of |p|.  There are five kinds of |p| , the first two
% of which do no output.
%
% Since GEM always does first things first, |nowhite| discards blanks and
% newlines, passes $V_I$ and $V_O$ entries (including literal blanks and
% newlines) unchanged to the output, and also as a default (last rule)
% passes everything else to the output. Because phrase name |A| was used,
% character class grammar |asciiIOG| must be appended.
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
% 
%%
% One wants to write |o=GEM(i,nowhite)| to remove whitespace from |i|.  
% But GEM insists on its second argument having no superfluous whitespace
% which the version of |nowhite| above has plenty.  
% We cannot write 
% 
%      nowhite = GEM(nowhite,nowhite);
%
% to make a whitespace-free |nowhite| -- chicken and egg problem.  
%
% So a de-whited |nowhite| has to be prepared by hand ahead of time.  
% All of this tedious work has been done and bundled up in
% function-object |gem| which was called (above) to start things off.  
% The de-whited |nowhite| is available as a field of |G|.  Here it is:
fprintf('%s', G.nowhite);
%%
% The character class CFGs and IOGs are big; it (obviously) pays to
% suppress the details when looking at grammars that use them.  Here is
% |nowhite| again with just a reminder that |asciiIOG| is appended:
idx = strfind(G.nowhite, 'A=');    % the start of asciiIOG
fprintf('%s', G.nowhite(1:idx-1)); % don't print asciiIOG,
fprintf('asciiIOG\n');             % just print it's name instead
%% 2.2.1 Define function |scan| and redefine |GEM|
% Since de-whiting is a frequent activity, it is useful to define a MATLAB
% function for the purpose. At the same time one can redefine GEM to 
% automatically |scan| its second parameter (the grammar). 
scan = @(txt)G.run(txt, G.nowhite);  % (Read the @ as lambda.)
GEM  = @(txt,c)G.run(txt, scan(c));
%%
% Testing scan, the expectation is that the blanks will disappear:
scan('x Y z')
%% 2.3  IOG |pretty|, the antidote to |nowhite|
% Returning |nowhite| to human-readable form can be accomplished by IOG
% |pretty|, which puts the minimal amount of blanks and newlines back. IOG
% |pretty| is an example of its own output (as before, the character class
% definitions |lowerIOG|, |upperIOG| and |asciiIOG| are supressed in this
% presentation).
%
% Note that the rule for |r| precisely describes itself.
idx = strfind(G.pretty, 'L=');  fprintf('%s', G.pretty(1:idx-1));
fprintf('lowerIOG upperIOG asciiIOG\n');
%%
% As a final reward, |pretty| also serves as a *syntax checker* for GEM
% input -- non-grammars will cause a run-time error.
%% 2.4 |pretty| applied to |nowhite|
% IOG |pretty| can be applied to |nowhite| to restore it readability.
% Starting with white-less |nowhite|
fprintf('%s',G.nowhite)
%%
% the pretty version can be computed and printed
pretty=@(g)GEM(g, G.pretty);
gstr = pretty(G.nowhite); idx = strfind(gstr, 'A ='); 
fprintf('%s', gstr(1:idx-1)); fprintf('asciiIOG\n');
%% 2.5  IOG inversion
% The GEM input language is symmetrical in the input and output. 
% Systematically interchanging the input and output delimiters (|'| and
% |"|) turns a *compiler* into *decompiler*. That is, the inverted IOG then
% accepts the original output and recreates the original input. An inverted
% inverter is still an inverter.
idx = strfind(G.invert, 'A=');     % start of asciiIOG
fprintf('%s', G.invert(1:idx-1));  % just the interesting stuff, please
fprintf('asciiIOG\n');
%%
% I suspect the inverter works if and only if the IOG defines a 1-1
% correspondence between input and output stings. On the other hand, I do
% not know under what conditions an IOG mapping is 1-1, so the insight is
% not immediately useful. 
%% 2.5.1  Inversion Example
% Right-associative sum and difference expressions can be defined naturally
% in a right-recursive IOG.  The output of the IOG |sum| is the
% left-to-right sequence of rule applications. 
fprintf('%s\n', G.sum);
%%
% To be tediously explicit, the input string |x+x-x| is rewritten by
% grammar rule applications as follows:
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
% Running the |sum| grammar on an expression yields the predicted sequence
% of rules (often called the canonical parse).
exampleparse = GEM('x+x-x', G.sum) % apply sum to 'x+x-x'
%%
% The |sum| grammar can be inverted and then pretty printed.
invertedsum = GEM(scan(G.sum), G.invert); % apply invert to sum
fprintf('%s', pretty(invertedsum));
%%
% Finally, the inverted sum grammar can be applied to the canonical parse
% and recreate the original input.
fprintf('%s\n', GEM(exampleparse, invertedsum)); % apply inverted sum to 4443210
%% 3 Extending The IOGs
% It seems a long way from these IOGs to compiling machine code. GEM does
% not change. The first trick is to use IOGs to make more capable IOGs. The
% new IOGs are just conveniences: one could get the same results by brute
% force.  
%% 3.1  Multiple character input and output symbols.
% One can extend |nowhite| to accept multiple-character input and output
% symbols. The trick is to let |nowhite| break up multiple character
% entries into a sequence of quoted single characters so that GEM can deal
% with them but save us from having to type all the otherwise required
% quote marks. The trick of the trick is to separate out the cases |'''|
% and |"""| so that the ability to input |'| and output |"| is not lost.

% Here is the new version, called |nowhite2|.
gstr = pretty(G.nowhite2);
idx = strfind(gstr, 'A =');  % start of pretty asciiIOG
fprintf('%s', gstr(1:idx-1));
fprintf('asciiIOG\n');
%% 3.1.1  Redefine |scan|, |pretty| and |GEM|
% It is useful to define and run the upgraded versions of the MATLAB
% functions.
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
%% 3.2  Arithmetic expressions
% Left-associative arithmetic expressions can be described with a trick
% much like that used to write parsers in functional languages such as ML.
% In this case the output is PFN (Polish postfix).  One way to look at this
% IOG is that each arithmetic operator is moved rightwards over its
% right operand.  This IOG is not invertible only because of the rule for
% parentheses.
idx = strfind(G.postfix, 'L=');  % start of lowerIOG
fprintf('%s', G.postfix(1:idx-1));
fprintf('lowerIOG\n'); fprintf('digitIOG\n');
%% 3.2.1  Postfix
% Applying |postfix| to an arithmetic expression yields the postfix PFN.
fprintf('%s\n', GEM('x*(y+3+4)-x/7', G.postfix));
%% 3.2.2  Prefix
% Another IOG (not shown) produces prefix PFN.
fprintf('%s\n', GEM('x*(y+3+4)-x/7', G.prefix));
%% 3.2.3  Intel X86 code
% In case the postfix PFN example did not look much like a compiler,
% a small change to the output vocabulary (using multicharacter symbols)
% results in Intel X86 assembly code.  For example the postfix rule
%
%    r = '+' t "+" r;
%
% becomes the rule
%
%    r = '+' t "fadd
%    " r;
fprintf('%s', GEM('x*(y+3+4)-x/7', G.x86));
%% 3.3  Using Regular Expressions in IOGs
% It is tedious to have to avoid left recursion.  One solution is to add
% the Kleene * to the IOGs. Here is the expression IOG using * .  Because
% of what is coming, one must use only lower-case letters, and not |d|, for
% the rule names.  For convenience, |pretty| is upgraded to handle * .
% Notice that rules |r| and |s| are no longer recursive.
pretty = @(txt)GEM(scan(txt), G.pretty2);
expr = pretty(scan(G.expr));
idx = strfind(expr, 'D ='); fprintf('%s', expr(1:idx-1)); fprintf('digitIOG\n');
%% 3.4 Transforming regular expressions back to IOGs
% GEM knows nothing about the Kleene star, so what must be done to make
% progress is to transform regular expression grammars back to 
% the original IOG form.  The tricks are to replace each
%
%   r*
%
% with a new symbol (say R) and add new rules
%
%   R = rR;  R =;
%
% The tricks are separately applied: the resulting two IOGs are
% concatenated to make a grammar acceptable to GEM.  
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
% Some care must be taken _not_ to use a* if asciiIOG is going to be used,
% creating a clash of meaning for the generated phrase name A.  Similar
% comments apply to the other predefined character classes.
%% 3.4.1 The expression IOG as an example using Kleene *
% For a Kleene-style arithmetic expression grammar, the two steps give
% the following grammars which are then concatenated:
newrules   = GEM(scan(G.expr), G.nostar1);
newgrammar = GEM(scan(G.expr), G.nostar2);
postfix    = [newgrammar newrules];  fprintf('%s\n', pretty(postfix));
%% 
% Applying the newly generated IOG gives postfix as before.
fprintf('%s\n', GEM('2*(6+3+4)-2/7', postfix));
%% 3.4.2  Add Kleene |+|
% Adding Kleene operator |+| could be dealt with in much the same way as
% |*|.  A simpler solution is to translate |r+| into |rr*|, then use
% |nostar1| and |nostar2| to eliminate the |*|. The IOG |noplus| is a
% version of |pretty| with 26 rules of the form
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
%% 4  Making GEM efficient
% It is feasible to hack all sorts of performance enhancing changes into
% GEM without changing its nature. 
%
% * Multiple character input and output symbols could be handled directly. 
% * Tail recursion could be flattened. 
% * The SEARCH could be precomputed (LL(1)-like capability).  
% * An order of magnitude speedup is available by implementing the 
% predefined character classes inside |iog.c| instead of appending them 
% to IOGs. 
%
% I recommend my
% students avoid any kind of optimization while they are learning the
% principles. 
%
% But I am not a student, so I can do as I please before continuing my
% main quest.  The new object is |gem2|. It has the capabilities of |gem|
% and skips some of the tedious initial steps.  The character classes act
% more like builtin functions and less like macro expansions.  None of the
% other optimizations have been implemented.
% 
% The call to G.run is as before, except that the names of character class
% grammars can be added as additional parameters.  For instance
%
%   G.run(i, g, 'A')
%
% makes the new |run| act like |asciiIOG| was appended to |g|. The tradeoff
% is more speed for more complexity in the C code.  The new C MEX file
% called |iog2.c|.  Object |gem2| is smaller because the fat character
% class grammars are gone. |iog2.c| is about twice its original size.
!wc -l iog.c 
!wc -l iog2.c
%% 4.1 Examples of using gem2
% A new version of |pretty| not only puts in needed whitespace, but also
% takes out superflous whitespace.  That is, the input to this |pretty|
% does not need to be prescanned.  In fact it is best not to prescan since
% this version of |pretty| leaves multicharacter input/output symbols
% intact for better readability.  The trick is phrase |b| which eats
% whitespace.
G=gem2();
pretty=@(txt)G.run(txt, G.pretty, 'LUA') ;
prettypretty = pretty(G.pretty0)
%%
% The name G.GEM is used to implement some common uses of G.run.
postfix = G.GEM('1/y*(3+z)+2*x', 'postfix') % using Kleene *
%%
prefix  = G.GEM('1/y*(3+z)+2*x', 'prefix')
%%
sumagain = G.GEM(G.GEM(G.GEM(G.sum, 'invert'), 'invert'), 'pretty')
%% 4.2 Intel X86 Assembler
% All compilers eventually have to connect to the underlying hardware.
% The first step here is an assembler that lays out the bits exactly as
% required for execution on last year's Intel hardware.  
%
% The simplest program that can be run is a subroutine prolog followed by a
% subroutine epilog.  It does nothing useful but illustrates getting into
% and out of execution (by not blowing up).
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
% And then the bits can be run on an X86 (my laptop)
fprintf('rc=%d',G.exe(assembled));
%%
% or the bits can be disassembled
invertedbits = G.run(assembled,G.GEM(G.scan(G.asm),'invert'))
%% 4.4 A calculator
% Instead of assembler, one can compile and run a little 4-register
% calculator language.  As usual, the sequence of calculations is compiled 
% into Intel X86 binary, run, and also decompiled.
make31 = 'b=9;a=3;c=4;a*=b;a+=c;';
compiled = G.run(make31, G.scan(G.calc), 'D'); fprintf('compiled = %s\n', compiled);
executed = G.exe(compiled); fprintf('executed = %d\n',executed);
invertedcalc = G.GEM(G.scan(G.calc),'invert');
decompiled=G.run(compiled, invertedcalc, 'D'); fprintf('decompiled = %s',decompiled);
%%
% Unix function atoi can be implemented by compiling an _ad hoc_ bit of 
% x86 code for a specific string.
intval  = G.exe(G.GEM('376', 'atoi')); fprintf('intval=%d', intval);
%% 4.5 When things go wrong
% Given a bad IOG, or bad text input, GEM will fail.  What GEM will not do
% is give an acceptable diagnostic (it usually backtracks clear out of the
% input text before giving up).  A little help is provided by a trace
% facility. The following demonstration shows two things: something of the
% inner workings of GEM and, indirectly, how much work it is actually doing
% to accomplish simple tasks. 
%
% When GEM fails, the highwater mark on the parse stack or backup stack
% usually gives a hint of whatever went wrong.  At this point one either
% fixes one of the inputs or starts putting print statements in file iog.c
% or iog2.c.  
toy='r=a;r=b;a=''x''"1";b=''y''"2";';
G.GEM(toy,'pretty')
%%
G.run('x',toy,'T');  % turn GEM trace on
%% 5 Summary
% *The input/output grammar was defined and shown to have some useful
% properties; invertible, directly executable, extendible, compilable.  
% How far it can go is an open question.*
%% 6 Reference
% http://www.mathworks.com/matlabcentral/fileexchange/20149
%% 7 Signature
% Presented to the Computer Science Colloquium, Stanford, March 4, 2009
%
% _Bill McKeeman_ , MathWorks Fellow
%% A.1 gem2.m
dbtype gem2.m
%% A.2 iog2.c
dbtype iog2.c

