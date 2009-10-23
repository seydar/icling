% FILE:     AsmX86.m
% PURPOSE:  assemble and execute Intel x86 instructions 
%
% USAGE:  asm = ASMX86()                        % constructor
%         asm = ASMX86({subFlags, allFlags})    % with flags
%
% OVERVIEW:
%   XCOM is a load&go compiler.  Asmx86.m provides methods to emit and
%   execute Intel x86 instructions.  Only the instructions needed by XCOM
%   are implemented.  The names of methods are mnemonic to the use, but not
%   exactly the names used by Intel. 
%
%   Normal use provides an object with methods for assembling and executing
%   machine code.  The '-asmTrace' flag will cause output to be dumped 
%   an instruction at a time into the MATLAB command window as assembly 
%   proceeds.  The '-asmHex' flag will cause hex output to be dumped
%   to the command window.
%
% EXAMPLE: (empty program)
%   asm = AsmX86({'-asmTrace'});    % Asmx86 object
%   frame = zeros(1, 0, 'int32');   % no variables
%   asm.prolog();                   % for any X program
%   asm.epilog();                   % for any X program
%   asm.go(frame);                  % run it
%
% TEST:     testAsmX86.m
% 
% METHODS:
%   See function public for the (many) exported methods.
%
% OPERATING SYSTEM:
%   Executing the assembled code requires access to low level primitives
%   via mex files.  The method makemex insures that they are up to date for
%   the underlying hardware (which at present must be Intel X86 on WIN32,
%   linux or OS X).  The M-files Asmx86.m and Generator.m and the runtime
%   need to be completely replaced to support different underlying hardware. 
%
%   The 64 bit Intel hardware is a special case since it can execute
%   the 32 bit instructions.  The prolog and epilog have to be changed.
%
% SEE ALSO: runx86.c, getCfun.c, EmulateX86.m
% REFERENCE:
%   Intel486 Processor Family, Programmer's Reference Manual, 1995

% COPYRIGHT W.M.McKeeman 2007.  You may do anything you like with 
% this file except remove or modify this copyright.

function obj = AsmX86(subFlags, allFlags)        % ctor

  if nargin < 2; allFlags = {}; end
  if nargin < 1; subFlags = {}; end
    
  TA   = findFlag('-asmTrace', subFlags); 
  TH   = findFlag('-asmHex', subFlags); 

  regs = {'EAX','ECX','EDX','EBX','ESP','EBP','ESI','EDI'};
  R    = enum(regs, 0);
  
  x86  = EmulateX86();                 % for step-by-step X run
  A64  = AsmA64(@emitn, subFlags, allFlags);
    
  % allocate memory to hold executable code
  code  = zeros(1, 1000, 'uint8');               % initial alloc
  r     = nonox(code);                           % make executable
  if r ~= 1, asmErr('cannot establish executable memory'); end
  
  pc      = int32(0);                            % emit index
  FPSsize = int32(0);                            % FPS is empty

  obj = public();                                % export public methods
    
  return;                                        % end of ctor
  
  % --------------------- public methods --------------------

  function rc = go(frame)                        % execute x86 instructions
    if TA
      dump()
      tic;                                       % start execution timer
    end
    
    % rc == 0 implies error-free execution, runx86 is a mex file
    % otherwise rc is an error number known to the caller.
    rc = runX86(code, frame);                    % run 
    
    if TA
      t=toc;                                     % stop execution timer
      fprintf('rc = %d, run time = %g sec\n', rc, t);
      fprintf('frame dump, %d word(s)\n', numel(frame));
      fprintf('0x%08x ', frame); 
      fprintf('\n'); 
    end    
  end

  function [rc, frame] = trace(frame, syms)
    [rc, frame] = x86.trace(code, pc, frame, syms, 1);  % output
  end

  function [rc, frame] = inter(frame, syms)
    [rc, frame] = x86.trace(code, pc, frame, syms, 2);  % interact
  end

  function [rc, frame] = silent(frame, syms)
    [rc, frame] = x86.trace(code, pc, frame, syms, 3);  % no output
  end

  function adr = getCode()
    adr = getpr(code);
  end

  % macro actions
  
  function prolog()
    pushR(R.EBP, '    # save x86 frame pointer');% save frame
    movRR(R.EBP, R.ESP, '# new x86 frame');      % new frame
    movRP(R.ESI, 8, ' # point at new X frame');  % 1rst arg = frame ptr
    pushA('        # callee save');              % callee save iregs
  end

  function epilog()
    popA('      # callee restore');
    xorRR(R.EAX, R.EAX, '# no run error');       % normal return
    iepilog();
  end

  function iepilog()                             % int/err return
    leave('# restore previous x86 stack frame');                                     % rc == EAX
    ret('# restore EIP');
  end

  function bailout(errNo)                        % error return
    movRC(R.EAX, uint32(errNo), '# meaning run error');
    iepilog();
  end

  % system ops
  
  function halt()
    if TA; T('halt'); end
    assmop('f4');                                % force error
  end

  function leave(msg)
    if nargin < 1, msg = ''; end
    if TA; T(['leave ' msg]); end
    assmop('c9');                                % undoes frame
  end

  function ret(msg)
    if nargin < 1, msg = ''; end
    if TA; T(['ret ' msg]); end
    assmop('c3')                                 % simple return
  end

  function sahf(msg)
    if nargin < 1, msg = ''; end
    if TA; T(['sahf ' msg']); end
    assmop('9e');                                % EAX(AH) to flags
  end

% ------------------------ int32 moves --------------------------

  function movRR(r1, r2, msg)
    if nargin < 3; msg = ''; end
    if TA; TRR('mov', r1, r2, msg); end
    assmop('89');                                % r1 = r2
    emit8(MOD_REG(r1,r2));
  end

  function movRC(r, c, msg)
    if nargin < 3; msg = ''; end
    if TA; TF('movRC %s,=%d (0x%x) %s', regs{r+1}, c, c, msg); end
    assmop(bitor(hx2('b8'), uint8(r)));          % r = c
    emit32(c);
  end

  function movRM(r, o, msg)
    if nargin < 3; msg = ''; end
    if TA; TF('movRM %s,%d %s', regs{r+1}, o, msg); end
    assmop('8b');                                % r = *(ESI+o);
    emit8(VIA_ESI(r));
    emit32(o);
  end

  function  movRA(r, i, msg)                     % absolute
    if nargin < 3; msg = ''; end
    if TA; TF('movRA %s,*0x%0x %s', regs{r+1}, i, msg); end
    assmop('8b');                                % r = *i
    emit8(VIA_ABS(r));
    emit32(i);
  end

  function movRP(r, p, msg)
    if nargin < 3; msg = ''; end
    if TA; TF('movRP %s,%d %s', regs{r+1}, p, msg); end
    assmop('8b');                                % parameter
    emit8(VIA_EBP(r));
    emit8(p);                                    % p-th byte
  end

  function movAR(i, r)
    if TA; TF('movAR %d,%s', i, regs{r+1}); end
    assmop('89');                                % *i = r
    emit8(VIA_ABS(r));
    emit32(i);
  end

  function movMR(o, r, msg)
    if nargin < 3; msg = ''; end
    if TA; TF('movMR %d,%s %s', o, regs{r+1}, msg); end
    assmop('89');                                % *(ESI+o) = r
    emit8(VIA_ESI(r));
    emit32(o);
  end

  function movMC(o, c, msg)                      % *(ESI+o) = c
    if nargin < 3; msg = ''; end
    if TA; TF('movMC %d,%d %s', o, c, msg); end
    assmop('c7');
    emit8(VIA_ESI(0));
    emit32(o);
    emit32(c);
  end

  function movAC(i, c, msg)                      % *i = c
    if nargin < 3; msg = ''; end
    if TA; TF('movAC %d,%d', i, c, msg); end
    assmop('c7');
    emit8(VIA_ABS(0));
    emit32(i);
    emit32(c);
  end

  function movRRi(r1, r2, msg)                   % r1 = *r2
    if nargin < 3; msg = ''; end
    if TA; TRR('movRRi %s,%s %s', r1, r2, msg); end
    assmop('8b');
    emit8(VIA_IND(r2, r1));
  end

  function movRiR(r1, r2, msg)                   % *r1 = r2
    if nargin < 3; msg = ''; end
    if TA; TRR('movRiR %s,%s %s', r1, r2+1, msg); end
    assmop('89');
    emit8(VIA_IND(r1, r2));
  end


  % --------------------------- push/pop ----------------------------

  function popA(msg)                             % pop all regs
    if nargin < 1, msg = ''; end
    if TA; TF('popA %s', msg); end
    assmop('61');
  end

  function pushA(msg)                            % push all regs
    if nargin < 1, msg = ''; end
    if TA; TF('pushA %s', msg); end
    assmop('60');
  end

  function popR(r, msg)                          % r = *ESP++
    if nargin < 2, msg = ''; end
    if TA; TF('popR %s %s', regs{r+1}, msg); end
    assmop(bitor(hx2('58'), R_M(r)));
  end

  function pushR(r, msg)                         % *--ESP = r
    if nargin < 2, msg = ''; end
    if TA; TF('pushR %s %s', regs{r+1}, msg); end
    assmop(bitor(hx2('50'), R_M(r)));
  end

  function pushC(c, msg)                         % *--ESP = c
    if nargin < 2; msg = ''; end
    if TA; TF('pushC %d %s', c, msg); end
    assmop('68');
    emit32(c);
  end

  % --------------------------- call ----------------------------

  function callRi(r, msg)
    if nargin < 2; msg = ''; end     
    if TA; TF('callRi %s %s', regs{r+1}, msg); end
    assmop('ff');
    emit8(MOD_REG(r, 2));
  end

  function fcallRi(r, msg)
    if nargin < 2; msg = ''; end
    callRi(r, msg);
    fpsPush(1);
  end

  function fcallRiq(r, msg)
    if nargin < 2; msg = ''; end
    A64.callRi(r, msg);
    fpsPush(1);
  end

  function callCi(m, msg)
    if nargin < 2; msg = ''; end
    if TA; TF('callCi %d', m, msg); end
    assmop('e8');
    emit32(m-(addr(code)+pc+4));
  end

  % ---------------------- condition codes -------------------------
  
  function cmpRR(r1, r2, msg)
    if nargin < 3; msg = ''; end
    if TA; TRR('cmp', r1, r2, msg); end
    assmop('3b');
    emit8(MOD_REG(r2,r1));
  end
  
  function cmpRC(r, c, msg)
    if nargin < 3; msg = ''; end
    if TA; TF('cmpRC %s,%d=0x%x %s', regs{r+1}, c, c, msg); end
    if r == R.EAX    % optimization (not worth it)
      assmop('3d')
    else
      assmop('81');
      emit8(MOD_REG(r, 7));
    end
    emit32(c);
  end
  
  function cmpRM(r, a, msg)
    if nargin < 3; msg = ''; end
    if TA; TRM('cmp', r, a, msg); end
    assmop('2b');
    emit8(VIA_ESI(r));
    emit32(a);
  end
  
  function cmpMC(a, c, msg)
    if nargin < 3; msg = ''; end
    if TA; TF('cmpMC %d,%d', a, c, msg); end
    assmop('81');
    emit8(VIA_ABS(7));
    emit32(a);
    emit32(c);
  end
  
  % macro for setcc
  function setccR(r, op)                         % set flags
    assmop(hx2('0f'));                           % OF SF ZF AF PF CF
    emit8(op);
    emit8(MOD_REG(r,0));
  end

  function seteR(r, msg)                         % r = ==
    if nargin < 2; msg = ''; end
    if TA; TR('sete', r, msg); end               % ZF=1
    setccR(r, hx2('94'));
  end

  function setneR(r, msg)                        % r = ~=
    if nargin < 2; msg = ''; end
    if TA; TR('setne', r, msg); end              % ZF=0
    setccR(r, hx2('95'));
  end

  function setlR(r, msg)                         % r = <
    if nargin < 2; msg = ''; end
    if TA; TR('setl', r, msg); end               % ~(SF=OF)
    setccR(r, hx2('9c'));
  end 

  function setgeR(r, msg)                        % r = >=
    if nargin < 2; msg = ''; end
   if TA; TR('setge', r, msg); end               % SF=OF
   setccR(r, hx2('9d'));
  end

  function setleR(r, msg)                        % r = <=
    if nargin < 2; msg = ''; end
    if TA; TR('setle', r, msg); end              % ~(ZF=0 & SF=OF)
    setccR(r, hx2('9e'));
  end

  function setgR(r, msg)                         % r = >
    if nargin < 1; msg = ''; end
    if TA; TR('setg', r, msg); end               % ZF=0 & SF=OF
    setccR(r, hx2('9f'));
  end

  function setaR(r, msg)                         % above
    if nargin < 1; msg = ''; end
    if TA; TR('seta', r, msg); end               % CF=0 & ZF=0
    setccR(r, hx2('97'));
  end

  function setaeR(r, msg)                        % above or =
    if nargin < 1; msg = ''; end
    if TA; TR('setae', r, msg); end              % CF=1
    setccR(r, hx2('93'));
  end

  function setbR(r, msg)                         % below
    if nargin < 2; msg = ''; end
    if TA; TR('setb', r, msg); end               % CF=0
    setccR(r, hx2('92'));
  end

  function setbeR(r, msg)                        % below or =
    if nargin < 2; msg = ''; end
    if TA; TR('setbe', r, msg); end
    setccR(r, hx2('96'));
  end

  % set reg and mask all but the trailing bit
  function eR(r, msg)                            % r = ==
    if nargin < 2; msg = ''; end
    seteR(r, msg);  andRC(r, 1, '# trailing bit only');
  end

  function neR(r, msg)                           % r = !=
    if nargin < 2; msg = ''; end
    setneR(r, msg); andRC(r, 1, '# trailing bit only');
  end

  function lR(r, msg)                            % r = <
    if nargin < 2; msg = ''; end
    setlR(r, msg);  andRC(r, 1, '# trailing bit only');
  end

  function geR(r, msg)                           % r = >=
    if nargin < 2; msg = ''; end
    setgeR(r, msg);  andRC(r, 1, '# trailing bit only');
  end

  function leR(r, msg)                           % r = <=
    if nargin < 2; msg = ''; end
    setleR(r, msg);  andRC(r, 1, '# trailing bit only');
  end

  function gR(r, msg)                            % r = >
    if nargin < 2; msg = ''; end
    setgR(r, msg);  andRC(r, 1, '# trailing bit only');
  end

  function aR(r, msg)                            % above
    if nargin < 2; msg = ''; end
    setaR(r, msg);  andRC(r, 1, '# trailing bit only');
  end

  function aeR(r, msg)                           % above or =
    if nargin < 2; msg = ''; end
    setaeR(r, msg); andRC(r, 1, '# trailing bit only');
  end

  function bR(r, msg)                            % below
    if nargin < 2; msg = ''; end
    setbR(r, msg);  andRC(r, 1, '# trailing bit only');
  end

  function beR(r, msg)                           % below or =
    if nargin < 2; msg = ''; end
    setbeR(r, msg); andRC(r, 1, '# trailing bit only');
  end

  % ------------------------ branch logic -------------------------
  
  function res = getPc()                         % for branch -
    res = pc;                                    % last used
  end
  
  function fixuploc = jump32(instr, delta, msg)  % helper fn
    if nargin < 3; msg = ''; end
    if numel(instr) == 4; instr = [instr ' ']; end
    if TA; TF('%s %d %s', instr, delta, msg); end
    switch instr
      case 'jmp32',  assmop('e9')
      case 'jl32 ',  assmop('8c0f')
      case 'jle32',  assmop('8e0f')
      case 'je32 ',  assmop('840f')
      case 'jne32',  assmop('850f')
      case 'jge32',  assmop('8d0f')
      case 'jg32 ',  assmop('8f0f')
      case 'ja32 ',  assmop('870f')
      case 'jae32',  assmop('830f')
      case 'jbe32',  assmop('860f')
      case 'jb32 ',  assmop('820f')
    end
    emit32(delta);                               % + or -
    fixuploc = pc - 3;                           % the 'hole'
  end

  %  ---------------- conditional jumps -------------------
  function fixuploc = jmp32(delta, msg)
    if nargin < 2; msg = ''; end
    fixuploc = jump32('jmp32', delta, msg);
  end
  function fixuploc = jl32(delta, msg)
    if nargin < 2; msg = ''; end
    fixuploc = jump32('jl32', delta, msg);
  end
  function fixuploc = jle32(delta, msg)
    if nargin < 2; msg = ''; end
    fixuploc = jump32('jle32', delta, msg);
  end
  function fixuploc = jz32(delta, msg)
    if nargin < 2; msg = ''; end
    fixuploc = jump32('je32', delta, msg);
  end
  function fixuploc = je32(delta, msg)
    if nargin < 2; msg = ''; end
    fixuploc = jump32('je32', delta, msg);
  end
  function fixuploc = jnz32(delta, msg)
    if nargin < 2; msg = ''; end
    fixuploc = jump32('jne32', delta, msg);
  end
  function fixuploc = jne32(delta, msg)
    if nargin < 2; msg = ''; end
    fixuploc = jump32('jne32', delta, msg);
  end
  function fixuploc = jge32(delta, msg)
    if nargin < 2; msg = ''; end
    fixuploc = jump32('jge32', delta, msg);
  end
  function fixuploc = jg32(delta, msg)
    if nargin < 2; msg = ''; end
    fixuploc = jump32('jg32', delta, msg);
  end
  function fixuploc = ja32(delta, msg)
    if nargin < 2; msg = ''; end
    fixuploc = jump32('ja32', delta, msg);
  end
  function fixuploc = jae32(delta, msg)
    if nargin < 2; msg = ''; end
    fixuploc = jump32('jae32', delta, msg);
  end
  function fixuploc = jbe32(delta, msg)
    if nargin < 2; msg = ''; end
    fixuploc = jump32('jbe32', delta, msg);
  end
  function fixuploc = jb32(delta, msg)
    if nargin < 2; msg = ''; end
    fixuploc = jump32('jb32', delta, msg);
  end

  function fixup8(p)                             % 8-bit branch offset
    delta = pc - p;
    assert(delta <=  127);
    assert(delta >= -128);
    tmp = pc;
    pc = p;
    if TA; TF('# fixup8 code(%d)=%d', pc, delta); end
    emit8(delta);
    pc = tmp;
  end

  function patch32(from, to)                     % 32-bit branch offset
    delta = to - from - 3;                       % relative
    assert(delta >= intmin('int32'));
    assert(delta <= intmax('int32'));
    tmp = pc;                                    % save pc
    pc = from-1;
    emit32(delta);                               % put data in hole
    pc = tmp;                                    % restore pc
    if TA; TF('# fixup32 code(%d)=%d (to %d)', from, delta, from+delta+4);end
  end

  function fixup32(from)                         % 32-bit branch offset
    patch32(from, pc);
  end

  % ----------------------- logical arithmetic --------------------
  function notR(r, msg)                          % ~r
    if nargin < 2; msg = ''; end
    if TA; TR('not', r, msg); end
    assmop('f7');
    emit8(MOD_REG(r,2));
  end
  
  function andRR(r1, r2, msg) 
    if nargin < 3; msg = ''; end
    if TA; TRR('and', r1, r2, msg); end
    assmop(hx2('21'));                           % r &= c
    emit8(MOD_REG(r1,r2));
  end

  function andRM(r, a, msg) 
    if nargin < 3; msg = ''; end
    if TA; TRM('and', r, a, msg); end
    assmop(hx2('23'));                           % r &= c
    emit8(VIA_ABS(r));
    emit32(a);
  end

  function andRC(r, c, msg) 
    if nargin < 3; msg = ''; end
    if TA; TRC('and', r, c, msg); end
    assmop(hx2('81'));                           % r &= c
    emit8(MOD_REG(r,4));
    emit32(c);
  end

  function orRR(r1, r2, msg) 
    if nargin < 3; msg = ''; end
    if TA; TRR('or', r1, r2, msg); end
    assmop(hx2('09'));                           % r |= c
    emit8(MOD_REG(r1,r2));
  end

  function orRM(r, a, msg) 
    if nargin < 3; msg = ''; end
    if TA; TRM('or', r, a, msg); end
    assmop(hx2('23'));                           % r |= c
    emit8(VIA_ABS(r));
    emit32(a);
  end

  function orRC(r, c, msg) 
    if nargin < 3; msg = ''; end
    if TA; TRC('or', r, c, msg); end
    if r == R.EAX
      assmop(hx2('0d'))
    else
      assmop(hx2('81'));                         % r |= c
      emit8(MOD_REG(r,1));
    end
    emit32(c);
  end

  function xorRR(r1, r2, msg) 
    if nargin < 3, msg = ''; end
    if TA; TRR('xor', r1, r2, msg); end
    assmop(hx2('33'));                           % r ^= c
    emit8(MOD_REG(r1,r2));
  end

  function xorRC(r, c, msg)
    if nargin < 2; msg = ''; end
    if TA; TRC('xor', r, c, msg); end
    if r == R.EAX   % optimization (not worth it)
      assmop(hx2('35'))
    else
      assmop(hx2('81'));                         % r ^= c
      emit8(MOD_REG(r,6));
    end
    emit32(c);
  end

  % ----------------------- int 32 arithmetic --------------------

  function negR(r, msg)                          % -r
    if nargin < 2; msg = ''; end
    if TA; TR('neg', r, msg); end
    assmop('f7');
    emit8(MOD_REG(r,3));
  end
  
  function addRR(r1, r2, msg)
    if nargin < 3; msg = ''; end
    if TA; TRR('add', r1, r2, msg); end
    assmop(hx2('01'));                           % r1 += r2
    emit8(MOD_REG(r1,r2));
  end

  function addRC(r, c, msg) 
    if nargin < 3; msg = ''; end
    if TA; TF('addRC %s,=%d %s', regs{r+1}, c, msg); end
    if r == R.EAX  % optimization (not worth it)
      assmop(hx2('05'));                         % EAX += c
    else
      assmop(hx2('81'));                         % r += c
      emit8(MOD_REG(r,0));
    end
    emit32(c);
  end

  function addRA(r, i, msg) 
    if nargin < 3; msg = ''; end
    if TA; TF('addRA %s,%d %s', regs{r+1}, i, msg); end
    assmop(hx2('03'));                           % r += *i
    emit8(VIA_ABS(r));
    emit32(i);
  end

  function addRM(r, o, msg)
   if nargin < 3; msg = ''; end
   if TA; TRM('add',r, o, msg); end
    assmop(hx2('03'));                           % r += *(ESI+o)
    emit8(VIA_ESI(r));
    emit32(o);
  end

  function subRR(r1, r2, msg) 
    if nargin < 3; msg = ''; end
    if TA; TRR('sub', r1, r2, msg); end
    assmop(hx2('2b'));                           % r1 -= r2
    emit8(MOD_REG(r2,r1));
  end

  function subRC(r, c, msg) 
    if nargin < 3; msg = ''; end
    if TA; TRC('sub', r, c, msg); end
    assmop(hx2('81'));                           % r -= c
    emit8(MOD_REG(r,5));
    emit32(c);
  end

  function subRA(r, i, msg)
    if nargin < 3; msg = ''; end
    if TA; TF('subRA %s,%d', regs{r+1}, i, msg); end
    assmop(hx2('2b'));                           % r -= *i
    emit8(VIA_ABS(r));
    emit32(i);
  end

  function subRM(r, o, msg)
    if nargin < 3; msg = ''; end
    if TA; TRM('sub', r, o, msg); end
    assmop(hx2('2b'));                           % r -= *(ESI+o)
    emit8(VIA_ESI(r));
    emit32(o);
  end

  function mulRR(r1, r2, msg)
    if nargin < 3; msg = ''; end
    if TA; TRR('mul', r1, r2, msg); end
    assmop(hx4('af0f'));                         % r1 *= r2
    emit8(MOD_REG(r2,r1));
  end

  function mulRC(r, c, msg)
    if nargin < 3; msg = ''; end
    if TA; TRC('mul', r, c, msg); end
    assmop(hx2('69'));                           % r *= c
    emit8(MOD_REG(r,7));  % ???
    emit32(c);
  end

  function mulRA(r, i, msg)
    if nargin < 3; msg = ''; end
    if TA; TF('mulRA %s,%d %s', regs{r+1}, i, msg); end
    assmop(hx4('af0f'));                         % r1 *= *i
    emit8(VIA_ABS(r));
    emit32(i);
  end

  function mulRM(r, o, msg)
    if nargin < 3; msg = ''; end
    if TA; TRM('mul', r, o, msg); end
    assmop(hx4('af0f'));                         % r1 *= *(ESI+o)
    emit8(VIA_ESI(r));
    emit32(o);
  end

  function cltd(msg)                             % edx = sign(eax)
    if nargin < 1; msg = ''; end
    if TA; T(['cltd ', msg]); end
    assmop(hx2('99'));
  end

  function divR(r, msg)
    if nargin < 2; msg = ''; end
    if TA; TR('div', r, msg); end
    assmop(hx2('f7'));                           % eax = eax::edx/*i
    emit8(MOD_REG(r,7));
  end

  function divA(i, msg)
    if nargin < 2; msg = ''; end
    if TA; TF('divA %d %s', i, msg); end
    assmop(hx2('f7'));                           % eax = eax::edx/*i
    emit8 (VIA_ABS(7));
    emit32(i);
  end

% ---------------- double/single arithmetic --------------------

  %  Maintain integrity of the floating point stack
  function fpsPush(n)                            % + is push, - is pop
    FPSsize = FPSsize + n;                       % range is 0:8
    if FPSsize < 0, error('FPS underflow'); end
    if FPSsize > 8, error('FPS overflow'); end
  end

% ---------------- double/single instructions -----------------
  function fld0(msg)                             % fps = 0
    if nargin < 1; msg = ''; end
    if TA; T(['fld =0.0 ', msg]); end
    assmop(hx4('eed9'));
    fpsPush(1);
  end

  function fld1(msg)                             % fps = 1
    if nargin < 1; msg = ''; end
    if TA; T(['fld =1.0 ' msg]); end
    assmop(hx4('e8d9'));
    fpsPush(1);
  end

  function fldPi(msg)                            % fps = pi
    if nargin < 1; msg = ''; end
    if TA; T(['fld =pi ', msg]); end
    assmop(hx4('ebd9'));
    fpsPush(1);
  end

  function fildA(i, msg)                         % fps = *(float*)i
    if nargin < 2; msg = ''; end
    if TA; TF('fildA %d %s', i, msg); end
    assmop(hx2('db'));
    emit8(VIA_ABS(0));
    emit32(i);
    fpsPush(1);
  end

  function fildM(o, msg)                         % fps = *((float*)ESI+o)
    if nargin < 2; msg = ''; end
    if TA; TF('fildM %d (%s)', o, msg); end
    assmop(hx2('db'));
    emit8(VIA_ESI(0));
    emit32(o);
    fpsPush(1);
  end

  function fldA(f, msg)                           % fps = *(*float)f
    if nargin < 2; msg = ''; end
    if TA; TF('fldA %d %s', f, msg); end
    assmop(hx2('d9'));
    emit8(VIA_ABS(0));
    emit32(f);
    fpsPush(1);
  end

  function fldM(o, msg)                          % fps = *(ESI+o)
    if nargin < 2; msg = ''; end
    if TA; TF('fldM  %d %s', o, msg); end
    assmop(hx2('d9'));
    emit8(VIA_ESI(0));
    emit32(o);
    fpsPush(1);
  end

  % this instruction is not used in xcom but is placed here as
  % an example of 64-bit operations, should they be needed
  function dldM(o, msg)                          % fps = *(ESI+o)
    if nargin < 2; msg = ''; end
    if TA; TF('dldM  %d %s', o, msg); end
    assmop(hx2('dd'));
    emit8(VIA_ESI(0));
    emit32(o);
    fpsPush(1);
  end

  function dldA(d, msg)                          % fps = *d
    if nargin < 2; msg = ''; end
    if TA; TF('dldA %d %s', d, msg); end
    assmop(hx2('dd'));
    emit8(VIA_ABS(0));
    emit32(d);
    fpsPush(1);
  end

  function fstAp(f, msg)                         % *f = fps
    if nargin < 2; msg = ''; end
    if TA; TF('fstAp %d %s', f, msg); end
    assmop(hx2('d9'));
    emit8(VIA_ABS(3));
    emit32(f);
    fpsPush(-1);
  end

  function fstMp(o, msg)                         % *(ESI+o) = fps
    if nargin < 2; msg = ''; end
     if TA; TF('fstMp %d %s', o, msg); end
    assmop(hx2('d9'));
    emit8(VIA_ESI(3));
    emit32(o);
    fpsPush(-1);
  end

  % this instruction is not used in xcom but is placed here as
  % an example of 64-bit operations, should they be needed
  function dstMp(o, msg)                         % *(ESI+o) = fps
    if nargin < 2; msg = ''; end
    if TA; TF('dstMp %d %s', o, msg); end
    assmop(hx2('dd'));
    emit8(VIA_ESI(3));
    emit32(o);
    fpsPush(-1);
  end

  function dstAp(d, msg)                         % *d = fps 
    if nargin < 2; msg = ''; end
    if TA; TF('dstAp %d %s', d, msg); end
    assmop(hx2('dd'));
    emit8(VIA_ABS(3));
    emit32(d);
    fpsPush(-1);
  end

  function fistAp(i, msg)                        % *i = (int)fps
    if nargin < 2; msg = ''; end
    if TA; TF('fistAp %d %s', i, msg); end
    assmop(hx2('db'));
    emit8(VIA_ABS(3));
    emit32(i);
    fpsPush(-1);
  end

  function fistMp(o, msg)                        % *(ESI+o) = (int)fps
    if nargin < 2; msg = ''; end
    if TA; TF('fistMp %d %s', o, msg); end
    assmop(hx2('db'));
    emit8(VIA_ESI(3));
    emit32(o);
    fpsPush(-1);
  end

  function fpop(msg)                             % pop fps
    if nargin < 1; msg = ''; end
    if TA; T(['fpop ', msg]); end
    assmop(hx4('d8dd'));
    fpsPush(-1);
  end

  function fxch(msg)                             % swap fps(0,1)
    if nargin < 1; msg = ''; end
    fxchr(1, msg);
  end

  function fxchr(r, msg)                         % swap fps(0,r)
    if nargin < 2; msg = ''; end
    if TA; TF('fxchr %d %s', r, msg); end
    if ~(0<=r && r<=FPSsize); error('FPS violation'); end
    assmop(hx2('d9'));
    assmop(hx2('c8')+uint8(r));
  end

  function fcompp(msg)                           % compare fps
    if nargin < 1; msg = ''; end
    if TA; T(['fcompp ', msg]); end
    assmop(hx4('d9de'));
    fpsPush(-2);
  end

  function fnstsw(msg)                           % store status word
    if nargin < 1; msg = ''; end
    if TA; T(['fnstsw ', msg]); end
    assmop(hx4('e0df'));                         % to AH
  end

  function realInfix(op)
    assmop(op);
    fpsPush(-1);
  end

  function faddp(msg)                            %  +
    if nargin < 1; msg = ''; end
    if TA; T(['faddp ', msg]); end
    realInfix(hx4('c1de'));
  end
  function fsubp(msg)                            % -
    if nargin < 1; msg = ''; end
    if TA; T(['fsubp ' msg]); end
    realInfix(hx4('e9de'));
  end
  function fsubrp(msg)                           %  - reverse
    if nargin < 1; msg = ''; end
    if TA; T(['fsubrp ', msg]); end
    realInfix(hx4('e1de'));
  end 
  function fmulp(msg)                            % *
    if nargin < 1; msg = ''; end
    if TA; T(['fmulp ', msg]); end
    realInfix(hx4('c9de'));
  end
  function fdivp(msg)                            % /
    if nargin < 1; msg = ''; end
    if TA; T(['fdivp ', msg]); end
    realInfix(hx4('f9de'));
  end
  function fdivrp(msg)                           % / reverse
    if nargin < 1; msg = ''; end
    if TA; T(['fdivrp ', msg]); end
    realInfix(hx4('f1de'));
  end

  function realPrefix(op)
    if ~(1 <= FPSsize && FPSsize < 8); error('FPS violation'); end
    assmop(op);
  end

  function fabs(msg)                             % abs
    if nargin < 1; msg = ''; end
    if TA; T(['fabs ', msg]); end
    realPrefix(hx4('e1d9'));
  end
  function fchs(msg)                             % -
    if nargin < 1; msg = ''; end
    if TA; T(['fchs ', msg]); end
    realPrefix(hx4('e0d9'));
  end
  function fsqrt(msg)                            % sqrt
    if nargin < 1; msg = ''; end
    if TA; T(['fsqrt ', msg]); end
    realPrefix(hx4('fad9'));
  end


% ----------------- private functions -------------------
  % x86 32 bit opcode layout functions
 
  function res = MOD(m)                          % (((m)&3)<<6)
    res = bitshift(bitand(uint8(m),3),6);
  end

  function res = REG(r)                          % (((r)&7)<<3)
    res = bitshift(bitand(uint8(r),7),3);
  end

  function res = R_M(rm)                         % ((r)&7)
    res = bitand(uint8(rm),7);
  end

  function res = MOD_REG(rm, r)  % ((uint8)(MOD(3) | REG(r) | R_M(rm)))
    res = bitor(bitor(MOD(3), REG(r)), R_M(rm));
  end

  function res = VIA_IND(rm, r)  % ((uint8)(MOD(0) | REG(r) | R_M(rm)))
    res = bitor(bitor(MOD(0), REG(r)), R_M(rm));
  end

  function res = VIA_ABS(r)       % ((uint8)(MOD(0) | REG(r)  | R_M(5)))
    res = bitor(bitor(MOD(0), REG(r)), R_M(5));
  end

  function res = VIA_ESI(r)       % ((uint8)(MOD(2) | REG(r)  | R_M(ESI)))
    res = bitor(bitor(MOD(2), REG(r)), R_M(R.ESI));
  end

  function res = VIA_EBP(r)       % ((uint8)(MOD(1) | REG(r)  | R_M(EBP)))
    res = bitor(bitor(MOD(1), REG(r)), R_M(R.EBP));
  end

  % op codes
  function assmop(op)                            % polymorphic
    if ischar(op)
      v = hx4(op);
    else
      v = uint16(op);
    end
    if v < 256
      emit8(v);
    else
      emit16(v);
    end
  end

  % emitters
  function emit8(b)    
    pc = pc+1;
    if pc > numel(code) 
      nox(code);                                 % restore non exe
      code(2*end) = 0;                           % preserve type
      if TA; TF('# code reallocation code=%x', getpr(code)); end 
      r = nonox(code);                           % set exe
    end
    if ~isscalar(b)
      asmErr('non scalar arg to emit8');
    end
    if b < 0                                     % 2's complement
      d = uint32(double(b) + 2^8); 
    else
      d = uint32(b);
    end
    code(pc) = bitand(d,uint32(255));
    if TH
      fprintf('Asmx86:      # code(0x%03x) = 0x%02x\n', pc, code(pc));
    end
  end

  function emit16(b)
    if b < 0                                     % 2's complement
      d = uint32(double(b) + 2^16);
    else
      d = uint32(b);
    end
    emit8(bitand(d,uint32(255)));
    emit8(bitshift(d,-8));
  end

  function emit32(b)
    if b < 0                                     % 2's complement
      d = uint32(double(b) + 2^32); 
    else
      d = uint32(b);    
    end 
    emit16(bitand(d,uint32(65535)));
    emit16(bitshift(d,-16));    
  end

  % emitn is called from AsmA64
  function p = emitn(bits)                     % variable length
    p = pc;
    for i=1:numel(bits)
      emit8(bits(i));
    end
  end

  function bit4 = c2h(c)                         % char to hex
    if '0' <= c && c <= '9'
      bit4 = uint8(c-'0');
    elseif 'a' <= c && c <= 'f'
      bit4 = uint8(c-'a'+10);
    elseif 'A' <= c && c <= 'F'
      bit4 = uint8(c-'A'+10);
    else
      error(['bad hex ' c]);
    end
  end

  function bit8 = hx2(s)                         % string to 8 bit hex
    switch numel(s)
      case 1, bit8 = c2h(s);
      case 2, bit8 = bitor(bitshift(c2h(s(1)),4),c2h(s(2)));
      otherwise, error(['bad hex ' s]);
    end
  end

  function bit16 = hx4(s)                        % string to 16 bit hex
    switch numel(s)
      case 1, hi = 0;           lo = hx2(s);
      case 2, hi = 0;           lo = hx2(s);
      case 3, hi = hx2(s(1));   lo = hx2(s(2:3));
      case 4, hi = hx2(s(1:2)); lo = hx2(s(3:4));
      otherwise, error(['bad hex ' s]);
    end
    bit16 = bitor(bitshift(uint16(hi),8), uint16(lo));
  end

  % ---------  utilities  ----------------
  function T(msg)
    fprintf('Asmx86: %4d %s\n', pc+1, msg);
  end
  
  function TR(op, r, msg)
    if nargin < 3; msg = ''; end
    if numel(op) == 3; op = [op 'R ']; else op = [op 'R']; end
    fprintf(['Asmx86: %4d ' op ' %s %s\n'],pc+1,regs{r+1},msg); 
  end

  function TRR(op, r1, r2, msg)
    if nargin < 4; msg = ''; end
    if numel(op) == 2; op = [op 'RR ']; else op = [op 'RR']; end
    fprintf(['Asmx86: %4d ' op ' %s,%s %s\n'],...
      pc+1,regs{r1+1},regs{r2+1},msg); 
  end

  function TRC(op, r, c, msg)
    if nargin < 4; msg = ''; end
    fprintf(['Asmx86: %4d ' op 'RC %s,=%d (0x%0x) %s\n'], ...
        pc+1, regs{r+1}, c, c, msg); 
  end

  function TRM(op, r, o, msg)
    if nargin < 4; msg = ''; end
    fprintf(['Asmx86: %4d ' op 'RM %s,%d %s\n'], pc+1, regs{r+1}, o, msg); 
  end

  function TF(fmt, varargin)
    fprintf(['Asmx86: %4d ' fmt '\n'], pc+1, varargin{:}); 
  end
  
  function asmErr(msg)
    error(['Asmx86: ' msg]);
  end

  function dump()
    fprintf('x86 code dump, %d bytes &code=0x%lx\n', pc, getpr(code));
    fprintf('%02x', code(1:pc));                 % print all hex code
    fprintf('\n');
  end

  % --------------- export public methods and variables --------------
  function o = public()                        % ctor
    o         = struct;
    o.go      = @go;                           % execute assembled code
    o.trace   = @trace;                        % trace assembled code
    o.inter   = @inter;                        % interact w/exe
    o.silent  = @silent;                       % silent emulation
    o.getEntry= @getCode;                      % where the code is
    o.prolog  = @prolog;                       % calling sequence
    o.prologq = @A64.prolog;
    o.epilog  = @epilog;
    o.epilogq = @A64.epilog;
    o.iepilog = @iepilog;
    o.bailout = @bailout;
    o.bailoutq= @A64.bailout;

    o.halt    = @halt;
    o.leave   = @leave;
    o.leaveq  = @A64.leave;
    o.ret     = @ret;
    o.retq    = @A64.ret;
    o.sahf    = @sahf;

    o.movRR   = @movRR;                        % move instructions
    o.movRRq  = @A64.movRR;                    % 64 bit version
    o.movRC   = @movRC;
    o.movRCq  = @A64.movRC;
    o.movRM   = @movRM;
    o.movRA   = @movRA;
    o.movRP   = @movRP;
    o.movAR   = @movAR;
    o.movMR   = @movMR;
    o.movMC   = @movMC;
    o.movAC   = @movAC;
    o.movRRi  = @movRRi;
    o.movRiR  = @movRiR;
    
    o.callRi   = @callRi;                     % calls
    o.callRiq  = @A64.callRi;
    o.fcallRi  = @fcallRi;
    o.fcallRiq = @fcallRiq;
    o.callCi   = @callCi;

    o.popA    = @popA;                        % call stack instructions
    o.pushA   = @pushA;
    o.popR    = @popR;
    o.pushR   = @pushR;
    o.pushC   = @pushC;
    
    o.cmpRR   = @cmpRR;                        % comparisons
    o.cmpRC   = @cmpRC;
    o.cmpRM   = @cmpRM;
    o.cmpMC   = @cmpMC;
    
    o.eR      = @eR;   
    o.neR     = @neR;
    o.lR      = @lR;
    o.geR     = @geR;
    o.leR     = @leR;
    o.gR      = @gR;
    o.aR      = @aR;
    o.aeR     = @aeR;
    o.bR      = @bR;
    o.beR     = @beR;
    
    o.getPc   = @getPc;                        % jumps
    o.jmp32   = @jmp32;
    o.jl32    = @jl32;
    o.jle32   = @jle32;
    o.je32    = @je32;
    o.jz32    = @jz32;
    o.jne32   = @jne32;
    o.jnz32   = @jnz32;
    o.jge32   = @jge32;
    o.jg32    = @jg32;
    o.ja32    = @ja32;
    o.jae32   = @jae32;
    o.jbe32   = @jbe32;
    o.jb32    = @jb32;
    
    o.notR    = @notR;                         % 32 bit logicals
    o.andRR   = @andRR;
    o.andRM   = @andRM;
    o.andRC   = @andRC;
    o.orRR    = @orRR;
    o.orRM    = @orRM;
    o.orRC    = @orRC;
    o.xorRC   = @xorRC;
    o.xorRR   = @xorRR;
    o.xorRRq  = @A64.xorRR;

    o.negR    = @negR;
    o.addRR   = @addRR;                        % 32 bit arithmetic
    o.addRC   = @addRC;
    o.addRCq  = @A64.addRC;
    o.addRA   = @addRA;
    o.addRM   = @addRM;
    o.subRR   = @subRR;
    o.subRC   = @subRC;
    o.subRA   = @subRA;
    o.subRM   = @subRM;
    o.mulRR   = @mulRR;
    o.mulRC   = @mulRC;
    o.mulRA   = @mulRA;
    o.mulRM   = @mulRM;
    o.cldt    = @cltd;
    o.divR    = @divR;
    o.divA    = @divA;

    o.EAX     = R.EAX;                         % 32 bit integer regs
    o.ECX     = R.ECX;
    o.EDX     = R.EDX;
    o.EBX     = R.EBX;
    o.ESP     = R.ESP;
    o.EBP     = R.EBP;
    o.ESI     = R.ESI;
    o.EDI     = R.EDI;

    o.RAX     = A64.R.RAX;                     % 64 bit integer regs
    o.RCX     = A64.R.RCX;
    o.RDX     = A64.R.RDX;
    o.RBX     = A64.R.RBX;
    o.RSP     = A64.R.RSP;
    o.RBP     = A64.R.RBP;
    o.RSI     = A64.R.RSI;
    o.RDI     = A64.R.RDI;
    o.R8      = A64.R.R8;
    o.R9      = A64.R.R9;
    o.R10     = A64.R.R10;
    o.R11     = A64.R.R11;
    o.R12     = A64.R.R12;
    o.R13     = A64.R.R13;
    o.R14     = A64.R.R14;
    o.R15     = A64.R.R15;
    
    o.faddp   = @faddp;                        % 64 bit float arithmetic
    o.fsubp   = @fsubp;                        % convert to 32-bit on store
    o.fsubrp  = @fsubrp;
    o.fmulp   = @fmulp;
    o.fdivp   = @fdivp;
    o.fdivrp  = @fdivrp;
    o.fnstsw  = @fnstsw;
    o.fcompp  = @fcompp;

    o.fld0    = @fld0;                         % FPS stack load and store
    o.fld1    = @fld1;
    o.fldpi   = @fldpi;

    o.fildA   = @fildA;
    o.fildM   = @fildM;
    o.fldA    = @fldA;
    o.fldM    = @fldM;                         % 32 bit IEEE
    o.dldM    = @dldM;                         % 64 bit IEEE
    o.dldA    = @dldA;
    o.fstAp   = @fstAp;
    o.fstMp   = @fstMp;                        % 32 bit IEEE
    o.dstMp   = @dstMp;                        % 64 bit IEEE
    o.dstAp   = @dstAp;
    o.fistAp  = @fistAp;
    o.fistMp  = @fistMp;
    o.fpop    = @fpop;
    o.fxch    = @fxch;
    o.fxchr   = @fxchr;
    o.fldPi   = @fldPi;
    o.fabs    = @fabs;
    o.fchs    = @fchs;
    o.fsqrt   = @fsqrt;
    
    o.getPc   = @getPc;
    o.fixup8  = @fixup8;
    o.fixup32 = @fixup32;
    o.patch32 = @patch32;
    o.dump    = @dump;    
  end

end
