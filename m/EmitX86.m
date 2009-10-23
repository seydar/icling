% FILE:     EmitX86.m
% PURPOSE:  Emit executable Intel X86 code (target dependent)
%
% USAGE:   emit = EmitX86(p, syms, errCt, exes, frms)
%          emit = EmitX86(p, syms, errCt, exes, frms, subFlags)
%          emit = EmitX86(p, syms, errCt, exes, frms, subFlags, allFlags)
%   p        which source file from command line (small integer)
%   syms     the list of all symbol tables; they are complete.
%   errCt    the count of possible run time errors prior to this call.
%   exes     the hardware address of the vector of subprogram starts
%   frms     the hardware address of the vector of subprogram frame sizes
%   subFlags optional flag: '-emitTrace'
%
%   Provide semantic actions to generate x86 load-and-go machine code.  
%   Example
%         emit.prolog()
%   generates the header for a subprogram, setting the stack registers and
%   providing frame access.  Further calls populate the executable and
%   eventually
%         [msg, tok, f] = emit.go(frame)
%   executes the compiled code and records the results.
%
% OVERVIEW:
%   EmitX86.m provides operand and branch control logic.  Its functions
%   are called from the tree-walkers in Generator.m.  The design emphasizes
%   simplicity over code quality.  The need to link separate compilations
%   for subprogram linkage causes the extra parameters in the signature
%   of the constructor.
%
% EXAMPLE:
%   None:  The amount of required context for the inputs is too verbose
%          for any useful demonstration.  Use the test instead.
%
% TEST:   testEmitX86.m

% COPYRIGHT W.M.McKeeman 2007.  You may do anything you like with 
% this file except remove or modify this copyright.
% IMPLEMENTATION:
%
% EXPRESSIONS: 
%   X expressions combine variables and literals to compute values.  The
%   names and constants are converted by stages into forms acceptable for
%   the target hardware (in this case Intel 32 bit x86). Each operand is
%   tracked with a stuct giving its present status and the information
%   needed for its use (typically its type and location or value).
%
%   An array of operand structs is maintained.  The array contains structs
%   for active operands as well as a pool of available structs for new
%   operands.  The status of a particular operand is determined by its
%   status flag. Once assigned, an operand is modified in-place via its
%   index and its flag updated accordingly.  When the operand is no longer
%   needed, the operand struct is marked available and returned to the pool
%   for later use (tag A).
%
%   The tags and transitions are as noted below:
%
%                                 F
%      A --- L --------.         / \                    A
%                       \        \ /   /\              /
%                        >------- R --<  X        ----<
%                       /        / \   \/              \
%      A --- S --- M --'        D   F                   E
%                                \ /
%                                 R
%
%   A literal constant (true, 1, 1.0) is marked L, the type is set and the
%   text form of the constant is kept in the operand struct.  When the
%   value is needed, a transition L2R is provided.  The emitting of some
%   x86 code to get the literal into a register is a side-effect.
%   
%   Each variable is already in the symbol table (an earlier pass).  When
%   the name is encountered, the operand is marked with tag S, the type is
%   looked up and copied, and the operand value is set to the symbol table
%   index.  When the variable is needed, a transformation S2M is provided.
%   The type and val remains unchanged, the tag becomes M.
%
%   If the value is needed, a transformation M2R is provided.  Code is
%   emitted to get the value from the frame into a register.  The tag
%   becomes R, the type is unchanged.  If the type is integer or logical,
%   an Intel general register is used and the operand value field is set to
%   the register number; if the type is real, the Intel FPS is used and the
%   value field is ignored.
%
%   The result of a comparison is either in the integer flags (tag F) or
%   the FPS flags (tag D).  The Intel branching logic requires that the
%   information gets to tag F before it can be used.  Unless the value is
%   assigned, the tag F operand immediately becomes available (tag A) after
%   use.
%
%   When a general register is needed and not available, function R2X dumps
%   a busy register into a temporary location in the frame (tag X), the
%   type is unchanged, the value is the temp index.  The pending request
%   for a register can then be satisfied.  Later, function X2R recovers the
%   temporarily saved value and frees the location for later temporary use.
%   To avoid thrashing temporary stores, the lookup for getting a register
%   can protect one register (presumably the one it is immediately going to
%   need).
%
%   In an error situation where the failure report must be delayed, the
%   operand is marked as an error (tag E) and the value is the error
%   message.
%
% OPERAND CONTENTS SUMMARY:
%
% tag    A    L      S      M      X      R     R     D     F 
% ty     ?    b|i|r  b|i|r  b|i|r  b|i|r  b|i   r     b     b 
% val    ?    token  idx    idx    idx    reg   ?     rule  rule
%
% CONTROL LOGIC:
%   Intel x86 control is provided by branching logic.  Branches are 
%   used for conditional execution and also subprogram calls.
%
%   The X 'if-fi' requires a set of forward branches.  After each failed
%   guard the next guard must be tried.  After each successful case, the
%   statement following the 'if-fi' must be reached.  If all guards fail,
%   the X program must abort.  The branches following the guards are
%   conditional; the branches following the statements are unconditional.
%
%   --> if     guard +--> stmts -.
%          ,------<--'           |
%       :: `-> guard +--> stmts -.
%      ,------<--'           |
%       :: `-> guard +--> stmts -.
%          ,------<--'           |
%       :: `-> guard +--> stmts -.
%          ,------<--'           |
%          ` abort               |
%       fi                       |
%      ,----------<--------------'
%      ` next stmt
%
%   The X 'do-od' requires some of the same forward branches plus a set of
%   backward branches.  After each failed guard the next guard must be
%   tried.  After a successful case, the loop must  be repeated.  If all
%   cases fail, the statement after the do-od must be reached.
%
%      ,----------<--------------.
%      |                         |
%  --> `do     guard +--> stmts -'
%          ,------<--'           |
%       :: `-> guard +--> stmts -'
%          ,------<--'           |
%       :: `-> guard +--> stmts -'
%          ,------<--'           |
%       :: `-> guard +--> stmts -'
%       od           |
%      ,----------<--'
%      ` next stmt
%
%   Forward branches must be placed in the code stream before the relative
%   offset to the destination is known.  This is accomplished by leaving a
%   "hole"  for the offset field and then "fixing it up" later.  Backward
%   branches can be filled in immediately or can use the "fixup' mechanism.
%
% FIXUPS:
%   There are two integers that determine the fixup action: the index of
%   the "hole" and the destination.  It is the case the the program counter
%   of the Intel chip (EIP) is always pointing at the next unused byte.
%   During a branch, the EIP is advanced beyound the branch instruction
%   before the relative offset is added.  For forward branches, the
%   destination is implicitly the next instruction since one always chooses
%   to apply the fixups at the earliest possible moment.  For backward
%   branches the destination needs to be saved for later use.
%
%   Each branch instruction emitter supplies the index to its "hole".
%   There is, in addition, a getPc method in Asmx86.m that provides the
%   current location for use in backward branches.
%
% SUBPROGRAMS:
%   In X any program may be a subprogram.  The caller uses the special
%   assignment syntax to invoke the callee.  Each called subprogram needs
%   to be listed on the xcom command line
%      xcom f1.x f2.x f3.x
%   The last file listed (f3.x in this case) is called from xcom.  The
%   rest of the functions are available to call and be called.  The list of
%   available subprogram names is in Emitter argument syms.
%
%   Subprograms take 0 or more arguments and produce 0 or more results.
%   The contents of subprograms are unknown during symbol analysis, thus 
%   there is no checking of input/output types until code generation time.
%   The type and number of arguments must match exactly.
%
%   The call is via a linker function written in C.  The information needed
%   for linking is not available until all subprograms have been compiled.
%   The subprogram frame sizes and entry points are collected in vectors in
%   parallel to the array of function names.
%      syms       cell array of symbol tables (last is main)
%      sizes      corresponding frame sizes
%      entries    corresponding entry points
%   The arrays are held in the Emitter, but not passed in until the outer
%   call.  The call to the linker uses non-standard tricks for its varargs.
%
%   The call to a subprogram is via the Intel X86 calling sequence.  The
%   Intel stack (EBP, ESP) holds a pointer to the frame containing the
%   variables of the active subprogram.  The only communication between
%   subprograms is via the input and output variables.

function obj = EmitX86(...
  srcFileNo,    ... which file from command line
  syms,         ... symbol tables of all subprograms
  errCt,        ... current run time error number
  exes,         ... pointer to vector of subprogram entries
  frms,         ... pointer to vector of subprogam frame sizes
  tabs,         ... tab level for trace
  subFlags,     ... the flags for this subroutine
  allFlags      ... the global flags
)
  if nargin < 6
    emitErr('requires EmitX86(srcFileNo, syms, errCt, exes, frms, tabs)');
  end
  if nargin < 8, allFlags = {}; end
  if nargin < 7, subFlags = {}; end

  TE = findFlag('-emitTrace', subFlags);
  
  asm  = AsmX86(subFlags, allFlags);
  sym  = syms{srcFileNo};
  toks = sym.tree.parsed.lexed;                  % these tokens
  cfg  = toks.cfg;
  rn   = cfg.ruleNumbers;
  tagstates = {'A' 'E' 'D' 'F' 'R' 'L' 'M' 'X' 'S'};
  state = enum(tagstates);                       % what is operand now?
  
  % free/busy for temporary locations in frame
  temps = logical(true);                         % always at least one

  %       EAX   ECX   EDX   EBX
  busy = [false false false false];              % avail to start
  opds = newOpd();                               % one avail

  runErrors = struct('msg', '', 'tok', 0, 'ct', 0, 'file', 0);
  runErrors(1) = [];                             % local run errors 
      
  obj = public();                                % gen services
  lvl = tabs;                                   % set up tabbing
  
  return;                                        % end of ctor
  
  % ---------------------- execution -------------------------
  
  % Call main program.
  function errno = go(frame)
    errno = asm.go(frame);                       % execute!
  end

  % Call main program under line-at-a-time eumulation
  function [errno, frame] = trace(frame, syms)
    [errno, frame] = asm.trace(frame, syms);     % emulate
  end

  % Call main program under line-at-a-time interaction
  function [errno, frame] = inter(frame, syms)
    [errno, frame] = asm.inter(frame, syms);     % interact
  end

  % Call main program under silent emulaton
  function [errno, frame] = silent(frame, syms)
    [errno, frame] = asm.silent(frame, syms);    % interact
  end

  function adr = getEntry()                      % entry point for this
    adr = asm.getEntry();
  end

  % -------------------- expression emitters ----------------
  
  % Function var establishes an operand as a symbol table entry.
  function opd = var(tok)
    if TE; TR('var', 1); end
    txt = toks.src(toks.start(tok):toks.finish(tok));
    idx = sym.lookup(txt);
    if idx == 0, emitErr(['bad symbol: ' txt]); end
    opd = getOpd();                              % avail
    setTag(opd, state.S);                        % now symbol
    setVal(opd, idx);                            % into symbols
    setTy(opd, sym.getType(idx));                % grab type
    if TE; TR('var', -1); end
  end

  % Function expr0 processes leaf expressions.  
  % The inputs are
  %   r  a grammar rule
  %   t  a token (ignored if implicit in rule)
  % The output is an operand struct carry three fields
  %   tag   the state of processing (L, S or R)
  %   type  the type of the operand
  %   value an associated value (literal, symbol index, register number...)
  % Instructions are emitted necessary to establish the output.
  function opd = expr0(r, t)
    if TE; TR('expr0 (no opds)', 1); end
    opd = getOpd();                              % fresh & avail
    switch r
      case rn.factor_true                        % true
        setTag(opd, state.L);
        setTy(opd,  sym.boolTYPE);
        setVal(opd, int32(1));                   % true
      case rn.factor_false                       % false
        setTag(opd, state.L);
        setTy(opd,  sym.boolTYPE);
        setVal(opd, int32(0));                   % false
      case rn.factor_integer                     % 123
        setTag(opd, state.L);
        setTy(opd,  sym.intTYPE);
        txt = toks.src(toks.start(t):toks.finish(t));
        setVal(opd, int32(str2num(txt)));        % 2' complement
      case rn.factor_real                        % 1.11
        setTag(opd, state.L);
        setTy(opd,  sym.realTYPE);
        txt = toks.src(toks.start(t):toks.finish(t));
        setVal(opd, f2i(single(str2num(txt))));  % IEEE 32-bit
      case rn.factor_id                          % id
        txt = toks.src(toks.start(t):toks.finish(t));
        idx = sym.lookup(txt);
        if idx == 0, emitErr(['bad symbol: ' txt]); end
        setTag(opd, state.S);                    % now symbol
        setVal(opd, idx);                        % frame index
        setTy(opd,  sym.getType(idx));           % grab type
      case rn.factor_rand                        % rand
        opd = realRand();
      otherwise
        emitErr('bad case in expr0');
    end
    if TE; TR('expr0', -1); end
  end

  % Function expr1 processes expression with a single argument.  
  % The inputs are
  %   r     a grammar rule
  %   opd   the argument
  %   op    a token (only for reporting errors)
  % The output is an operand struct carry three fields
  %   tag   the state of processing (X or R)
  %   type  the type of the operand
  %   value an associated value (literal, symbol index, register number...)
  % Instructions are emitted necessary to establish the output.
  %
  % The rule for parenthesized expression is never seen here since it is
  % skipped in generator.m.
  %
  function opd = expr1(r, opd, op)
    if TE; TR('expr1 (one opd)', 1); end
    switch getTy(opd)
      case sym.boolTYPE
        protectFlags();
        switch r
          case rn.negation_NOTrelation           % ~
            toR(opd);                            % same type
            asm.notR(getVal(opd));               % same reg, 1's complement
            asm.andRC(getVal(opd), 1, '(mask off all but last bit)');
          case rn.factor_b2ifactor               % b2i
            toR(opd);
            setTy(opd, sym.intTYPE);             % same val
          otherwise
            emitErr('bad bool case in expr1', op);
        end
        
      case sym.intTYPE
        protectFlags();
        switch r
          case rn.sum_SUBterm                    % -
            toR(opd);                            % same type
            asm.negR(getVal(opd));               % same reg
          case rn.factor_i2rfactor               % i2r
            toR(opd);
            toX(opd);                            % in as int
            t = getVal(opd);                     % temp idx
            adr = frameOffset(sym.size()+t);     % get temp address
            localname = ['tmp' num2str(t-1)];
            asm.fildM(adr, localname);           % now on FPS
            freeTemp(t);
            setTag(opd, state.R);                % in reg
            setTy(opd, sym.realTYPE);            % real
            setVal(opd, int32(0));               % ignored
            toX(opd);                            % off FPS
          case rn.factor_absfactor               % abs(int)
            toR(opd);                            % into reg
            asm.cmpRC(getVal(opd),0);            % compare with zero
            fixuploc = asm.jge32(0);             % jmp if nonneg
            asm.negR(getVal(opd));               % negate
            asm.fixup32(fixuploc);               % fill in destination 
          otherwise
            emitErr('bad int case in expr1');
        end
        
      case sym.realTYPE 
        switch r
          case rn.sum_SUBterm
            toR(opd);                            % unary -
            asm.fchs();                          % type conversion
            toX(opd);                            % off FPS
          case rn.factor_r2ifactor
            toR(opd);                            % r2i
            t = getTemp();                       % get temp index
            adr = frameOffset(sym.size()+t);     % get temp address
            localname = ['tmp(' num2str(t-1) ')'];
            asm.fistMp(adr, localname);          % type conversion
            setTag(opd, state.X);                % typeless store
            setTy(opd,  sym.intTYPE);            % now converted
            setVal(opd, t);                      % the temp location
          case rn.factor_absfactor               % abs(real)
            toR(opd);                            % to FPS
            asm.fabs();                          % take float abs
            toX(opd);                            % off FPS into temp
          otherwise
            emitErr('bad real case in expr1');
        end

      otherwise
        emitErr('bad case in expr1');      
    end
    if TE; TR('expr1', -1); end
  end

  % Function expr2 processes expressions with two arguments (e.g.+, *).  
  % The inputs are
  %   r      a grammar rule
  %   left   the left operand
  %   right  the right operand
  %   err    a token (only for reporting errors)
  % The output is an operand struct carry three fields
  %   tag   the state of processing (R, F or D)
  %   type  the type of the result
  %   value an associated value (register number...)
  % Instructions are emitted necessary to establish the output.
  % float values are not left on the FPS
  function opd = expr2(r, left, right, err)
    if TE; TR('expr2 (two opds)', 1); end
    switch getTy(left)
      case sym.boolTYPE                          % use bit-or & bit-and
        protectFlags();                          % save if vulnerable
        toR(left);                               % into a register
        toR(right, getVal(left));                % protect left register
        switch r
          case rn.disjunction_disjunctionORconjunction  
            asm.orRR(getVal(left), getVal(right));
          case rn.conjunction_conjunctionANDnegation 
            asm.andRR(getVal(left), getVal(right));
          otherwise
            emitErr('bad op in logical expr2');
        end
        toA(right);                              % free right operand
        
      case sym.intTYPE
        protectFlags();                          % save if vulnerable
        toR(left);                               % into a register
        lreg = getVal(left);                     % register number
        toR(right, lreg);                        % protect lreg
        rreg = getVal(right);                    % into a register
        switch r
          case {
              rn.relation_sumLTsum;
              rn.relation_sumLTEQsum;
              rn.relation_sumEQsum;
              rn.relation_sumNOTEQsum;
              rn.relation_sumGTEQsum;
              rn.relation_sumGTsum...
            }
            asm.cmpRR(lreg, rreg);               % < <= = ~= >= >
            toA(right);                          % free right operand
            freeReg(lreg);                       % free left register
            setVal(left, int32(r));              % remember operator
            setTag(left, state.F);               % into int flags
            setTy(left, sym.boolTYPE);           % logical result
          case rn.sum_sumADDterm                 % +
            asm.addRR(lreg, rreg);
            toA(right);                          % free right operand
          case rn.sum_sumSUBterm                 % -
            asm.subRR(lreg, rreg);
            toA(right);                          % free right operand
          case rn.term_termMULfactor             % *
            asm.mulRR(lreg, rreg);
            toA(right);                          % free right operand
          case rn.term_termDIVfactor             % /
            intDiv(r, left, right, err);
            toA(right);                          % free right operand
          case rn.term_termDIVDIVfactor          % //
            intDiv(r, left, right, err);
            toA(right);                          % free right operand
          otherwise 
            emitErr(['bad int binop ' num2str(r)]);
        end
        
      case sym.realTYPE
        toR(left);                               % FPS(-1)
        toR(right);                              % FPS(0)
        switch r
          % real values cannot be reliably compared for ==
          case {...
              rn.relation_sumLTsum;
              rn.relation_sumLTEQsum;
              rn.relation_sumGTEQsum;
              rn.relation_sumGTsum...
            }
            protectFlags();
            spillAllRegs();
            asm.fcompp();                        % < <= >= >
            asm.fnstsw('# move FPS status word to EAX');                        % into EAX
            asm.sahf();                          % into flags
            toA(right);
            setTag(left, state.D);               % status word
            setVal(left, int32(r));              % meaning
            setTy(left, sym.boolTYPE);           % type
          case {...
              rn.relation_sumEQsum;
              rn.relation_sumNOTEQsum...
            }
            emitErr('= and ~= are not reliable for real numbers');
            
          % force 32-bit accuracy for consistency
          case rn.sum_sumADDterm                 % +
            asm.faddp();                         % 64 bit answer
            toA(right);
            toX(left);                           % off FPS
          case rn.sum_sumSUBterm                 % -
            asm.fsubp();                         % 64 bit answer
            toA(right);
            toX(left);                           % off FPS
          case rn.term_termMULfactor             % *
            asm.fmulp();                         % 64 bit answer
            toA(right);
            toX(left);                           % off FPS
          case rn.term_termDIVfactor             % /
            asm.fdivp();                         % 64 bit answer
            toA(right);
            toX(left);                           % off FPS
          otherwise
            emitErr('bad op in real expr2');
        end
      otherwise
        emitErr('bad type in expr2');
    end
    opd = left;
    if TE; TR('expr2', -1); end
  end
    
  function store(lhs, rhs)                       % x,y,z := 1,2+3
    if TE; TR('store', 1); end                   % assignment
    for i=1:numel(rhs)
      toR(rhs(i));                               % eval all r.h.s.
    end
    for i=numel(lhs):-1:1
      b = rhs(i);                                % one r.h.s.
      toR(b);                                    % r.h.s. into reg
      a = lhs(i);
      S2M(a);                                    % l.h.s. offset
      va = getVal(a);
      localname = ['(' sym.getName(va) ')'];
      adr = frameOffset(va);
      switch getTy(a)
        case sym.boolTYPE
          asm.movMR(adr, getVal(b), localname);  % bool assignment
        case sym.intTYPE
          asm.movMR(adr, getVal(b), localname);  % int assignment
        case sym.realTYPE
          asm.fstMp(adr, localname);             % real assignment
      end
      toA(a);                                    % free operands
      toA(b);
    end
    checkOpds();                                 % should be avail
    checkTemps();                                % should be avail
    checkRegs();                                 % should not be busy
    if TE; TR('store', -1); end                  % assignment
  end

% ------------------- control generators -------------------

  function prolog()                              % calling seq. in
    if TE; TR('prolog', 1); end
    asm.prolog();
    if TE; TR('prolog', -1); end
  end

  function epilog()                              % calling seq. out
    if TE; TR('epilog', 1); end
    asm.epilog();
    if TE; TR('epilog', -1); end
  end

  function arithAbort(ruleno, errtok)
    if TE; TR('arithAbort', 1); end
    errCt = errCt+1;                             % unique int for this err
    thisErr = struct;
    switch ruleno
      case rn.term_termDIVfactor
        thisErr.msg = 'divide by zero';          % error message
      case rn.term_termDIVDIVfactor
        thisErr.msg = 'remainder by zero';       % error message
      otherwise
        emitErr('bad rule in arithAbort');
    end
    thisErr.tok  = errtok;                       % for line/col
    thisErr.ct   = errCt;                        % save unique int
    thisErr.file = srcFileNo;                    % for file name
    runErrors(end+1)  = thisErr;                 % save until needed
    asm.bailout(errCt);
    if TE; TR('arithAbort', -1); end
  end

  function rpt = findErr(errno)
    for i=1:errCt
      rpt = runErrors(i);                        % error details
      if rpt.ct == errno; return; end            % found it
    end
    rpt = struct([]);                            % not here
  end

  function stmt()                                % does nothing now
  end

  function iffiEnd(f)                            % true cases skip on
    if TE; TR(['iffiEnd ' num2str(numel(f)) ' fixups'], 1); end
    for i=1:numel(f)
      asm.fixup32(f(i));                         % escape beyond fi
    end
    if TE; TR('iffiEnd', -1); end
  end

  function iffiAbort(errtok)                     % no true guard
    if TE; TR('iffiAbort', 1); end
    errCt = errCt + 1;                           % unique int for this err
    thisErr = struct;
    thisErr.msg  = 'if-fi has no true alternative'; 
    thisErr.tok  = errtok;                       % for line/col
    thisErr.ct   = errCt;                        % save unique int
    thisErr.file = srcFileNo;                    % for file name
    runErrors(end+1) = thisErr;                  % hold until needed
    asm.bailout(errCt);
    if TE; TR('iffiAbort', -1); end
  end

  function f = doodBegin()                       % rememeber top of loop
    if TE; TR('doodBegin', 1); end
    f = asm.getPc();                             % for fixup
    if TE; TR('doodBegin', -1); end
  end

  function doodEnd(f, head)                      % bottom of loop
    if TE; TR(['doodEnd ' num2str(numel(f)) ' fixups'], 1); end
    for i=1:numel(f)
      asm.patch32(f(i), head);                   % true cases back to do
    end
    if TE; TR('doodEnd', -1); end
  end

  function f = guardEnd(opd, tok)                % to next case
    if TE; TR('guardEnd', 1); end
    if getTy(opd) ~= sym.boolTYPE
      emitErr('guard must be logical', tok);
    end
    ms = '(to next alt)';
    switch getTag(opd)
      case state.F
        switch getVal(opd) % jump on false
          case rn.relation_sumLTsum,    f = asm.jge32(0, ms);  % <
          case rn.relation_sumLTEQsum,  f = asm.jg32(0, ms);   % <=
          case rn.relation_sumEQsum,    f = asm.jne32(0, ms);  % =
          case rn.relation_sumNOTEQsum, f = asm.je32(0, ms);   % ~=
          case rn.relation_sumGTEQsum,  f = asm.jl32(0, ms);   % >=
          case rn.relation_sumGTsum,    f = asm.jle32(0, ms);  % >
        end
        toA(opd);
      case state.D
        switch getVal(opd)
          case rn.relation_sumLTsum,   f = asm.jbe32(0, ms);   % <
          case rn.relation_sumLTEQsum, f = asm.jb32(0, ms);    % <=
          case rn.relation_sumGTEQsum, f = asm.ja32(0, ms);    % >=
          case rn.relation_sumGTsum,   f = asm.jae32(0, ms);   % >
          otherwise, emitErr('bad op in guard');
        end 
        toA(opd);
      otherwise
        toF(opd);
        f = asm.je32(0, ms);                     % to next case
        toA(opd);
    end
    checkOpds();                                 % should be avail
    checkTemps();                                % should be free
    checkRegs();                                 % should not be busy
    if TE; TR('guardEnd', -1); end
  end

  function f = altEnd(ag, ms)
    if TE; TR('altEnd', 1); end
    f = asm.jmp32(0, ms);                        % beyond fi/ to do
    asm.fixup32(ag);                             % from prev alt
    if TE; TR('altEnd', -1); end
  end

  % -------------- call an X subprogram -------------------------
  
  % Suprogram calls are allowed between programs presented to xcom on the
  % command line.  The details of the calling sequence are recorded with
  % the linker function in getCfun.c
  
  % The indirectness of the calling sequence is because
  % some of the work is traditionally a link-time activity.
  
  % The lfts and rgts are in reverse order.
  
  % This does NOT work on A64 yet
  
  function call(lfts, fName, rgts)               % lfts := fName := rgts
    if TE; TR('call', 1); end
    % find the file of the called function
    calledFileNo = 0;
    for i = 1:numel(syms)
      if strcmp(fName, syms{i}.getFun())         % subprogram name
        calledFileNo = i;                        % found it
        break;
      end
    end
    if calledFileNo == 0                         % did not find it
      emitErr(['no definition for subprogram ' fName ]);
    end

    % check agreements between caller and called
    symCalled = syms{calledFileNo};               % the other symbols
    rgtCt = symCalled.getRgtCt();                % the called inputs
    if numel(rgts) ~= rgtCt
      emitErr(['unexpected number of inputs for ' fName]);
    end
    lftCt = symCalled.getLftCt();                % the called outputs
    if numel(lfts) ~= lftCt
      emitErr(['unexpected number of outputs for ' fName]);
    end    
    
    % pass output target variables to linker, first to last
    % the processing is for x,y,z := fun...
    % the result is lftCt pairs: 
    for i=lftCt:-1:1                             % each local output var
      opd = lfts(i);                             % where result will go
      idx = symCalled.getLeft(lftCt-i+1);        % i-th output variable
      if getTy(opd) ~= symCalled.getType(idx)
        emitErr(['output type mismatch across call for ' fName]); 
      end
      asm.pushC(idx, '  # output offset in called frame');
      asm.pushC(getVal(opd), '  # output offset in caller frame');
      toA(opd);                                  % free LHS operand
    end
    
    % pass the input values to the linker, first to last
    % the processing is for ... fun := e1, e2, e3
    % the result is rgtCt pairs:
    for i=rgtCt:-1:1                             % inputs from caller
      idx = symCalled.getRight(rgtCt-i+1);       % i-th input variable
      asm.pushC(idx, '  # input offset in caller frame'); % into linker
      opd = rgts(i);                             % where input comes from
      val = getVal(opd);
      setVal(opd, val);                          % fake int
      setTy(opd, sym.intTYPE);                   % pass as int
      toR(opd);                                  % into register
      asm.pushR(getVal(opd), '# input value');   % into linker
      toA(opd);                                  % free RHS operand
    end
    % at this point all operands and registers are free

    % set up call to linker; manipulating hardware addresses 
    byteOffset = (calledFileNo-1)*4;             % assuming 32 bits
    asm.movRA(asm.EAX, frms+byteOffset, '# called-frame size');
    asm.pushR(asm.EAX, '# new frame size');      % into linker
    asm.pushC(lftCt, '  # number of outputs');
    asm.pushC(rgtCt, '  # number of inputs');
    asm.movRA(asm.EAX, exes+byteOffset, '# called-subprogram address');
    asm.pushR(asm.EAX, '# new frame address');   % into linker
    asm.pushR(asm.ESI, '# old frame address');   % current frame pointer
    addr=getCfun('link');
    asm.movRC(asm.EAX, addr, '# address of linker');
    asm.callRi(asm.EAX, '# call linker');        % call linker
    
    % return from linker and therefore called X function
    % error code is in EAX  (0 means no error)
    asm.popR(asm.ESI, ' #   restore frame pointer');% restore ESI
    asm.addRC(asm.ESP, 4*(4+2*rgtCt+2*lftCt), '  # discard args');
    asm.cmpRC(asm.EAX, 0, '# error check')       % 0 means OK
    fu = asm.je32(0, '       # skip error exit');
    asm.iepilog();                               % pass error up
    asm.fixup32(fu);
    
    checkOpds();                                 % should be avail
    checkTemps();                                % should be free
    checkRegs();                                 % should not be busy
    if TE; TR('call', -1); end
  end

  % ----------------- temporary location management ---------------
  
  function idx = getTemp()
    if TE; TR('getTemp', 1); end
    for i=2:numel(temps)                         % keep one avail
      if ~temps(i)
        temps(i) = true;
        idx = int32(i);
        if TE; TR(['getTemp, tmp=' num2str(idx)], -1); end
        return;
      end
    end
    temps(end+1) = true;
    idx = int32(numel(temps));
    if TE; TR(['getTemp, tmp=' num2str(idx)], -1); end
  end

  function freeTemp(idx)
    if TE; TR(['free tmp=' num2str(idx)]); end
    temps(idx) = false;
  end

  function checkTemps()
    for i=2:numel(temps)
      if temps(i)
        emitErr(['leaked temp ' num2str(i)]);
      end
    end
  end

  function n = nTemps()
    n = numel(temps);
  end

  % ------------------ register management ------------------
  
  function reg = getReg(exclude)
    if TE; TR('getReg', 1); end
    for i=1:numel(busy)
      if ~busy(i)
        busy(i) = true;
        reg = int32(i-1);                        % EAX is 0
        if TE; TR(['getReg, reg=' num2str(reg)], -1); end
        return; 
      end
    end
    % all regs busy, spill one
    for i=1:numel(opds)
      o = opds(i);                               % all operands
      if o.tag == state.R       ...
      && o.ty  ~= sym.realTYPE  ...
      && o.val ~= exclude                        % it is usable
        reg = o.val;                             % grab it
        R2X(i);                                  % to temp
        if TE; TR(['getReg after spill, reg=' num2str(reg)], -1); end
        return;
      end
    end
    emitErr('getReg failed');
  end
  
  function freeReg(a)
    if TE; TR(['free reg=' num2str(a)]); end
    busy(a+1) = false;                           % EAX is 0
  end

  function spillAllRegs() 
    if TE; TR('enter spillAllRegs', 1); end
    for i=1:numel(opds)
      o = opds(i);                               % all operands
      if o.tag == state.R && o.ty ~= sym.realTYPE
        R2X(i);                                  % to temp
        return;
      end
    end
    if TE; TR('spillAllRegs', -1); end
  end

  function checkRegs()
    for i=2:numel(busy)
      if busy(i)
        emitErr(['leaked reg ' num2str(i)]);
      end
    end
  end
  %--------------------- operand management ------------------
    
  function res = frameOffset(n)                  % n-th symbol item
    res = uint32(4*(n-1));                       % 0-based 32-bit wide frame
  end

  function t = getTag(opd)
    t = opds(opd).tag;
  end
    
  function setTag(opd, t)
    opds(opd).tag = t;
  end
    
  function v = getVal(opd)
    v = opds(opd).val;
  end
    
  function setVal(opd, v)
    opds(opd).val = v;
  end
    
  function t = getTy(opd)
    t = opds(opd).ty;
  end
    
  function setTy(opd, t)
    opds(opd).ty = t;
  end
    
  function opdval = newOpd()                     % reusable operand
    opdval = struct;
    opdval.tag = state.A;                        % available
    opdval.ty  = 0;
    opdval.val = 0;
  end

  function opd = getOpd()
    if TE; TR('getOpd', 1); end
    
    for i=1:numel(opds)
      if getTag(i) == state.A                    % available
        opd = i;                                 % the index
        if TE; TR(['getOpd opd=' num2str(opd)], -1); end
        return;
      end
    end
    opds(end+1) = newOpd();                      % enlarge 
    opd = numel(opds);                           % the index
    if TE; TR(['getOpd opd=' num2str(opd)], -1); end
  end

  function checkOpds()
    for i=1:numel(opds)
      if getTag(i) ~= state.A
        emitErr(['leaked opd ' num2str(i)]); 
      end
    end
  end

  function protectFlags() 
    for i=1:numel(opds)
      if getTag(i) == state.F                    % in flags
        if TE; TR('protected F'); end
        F2R(i);
      elseif getTag(i) == state.D
        if TE; TR('protected D'); end
        D2R(i);
      end
    end
  end

  function toA(a)                                % free operand
    if TE; TR('toA', 1); end
    if getTag(a) == state.R && ...               % stuff in general reg
        (getTy(a) == sym.intTYPE || getTy(a) == sym.boolTYPE)
      freeReg(getVal(a));
    elseif getTag(a) == state.X
      freeTemp(getVal(a));
    end
    setTag(a, state.A);                          % available
    setTy(a,0);                                  % meaningless
    setVal(a,0);                                 % meainingless
    if TE; TR(['free opd=' num2str(a)]); end
    if TE; TR('toA', -1); end
  end

  function toR(opd, sreg)                        % to a register
    if TE; TR('toR', 1); end
    if nargin == 1, sreg = -1; end
    switch getTag(opd)
      case state.D, D2R(opd, sreg);
      case state.F, F2R(opd, sreg);
      case state.R                               % already R
      case state.M, M2R(opd, sreg);
      case state.X, X2R(opd, sreg);
      case state.L, L2R(opd, sreg);
      case state.S, S2M(opd); toR(opd, sreg);
      otherwise, emitErr('bad case in toR');
    end
    if TE; TR('toR', -1); end
  end

  function toX(opd)                              % to temp location
    if TE; TR('toX', 1); end
    switch getTag(opd)
      case state.R, R2X(opd);
      case state.L, L2R(opd); R2X(opd);
      otherwise, emitErr('bad case in toX') ;
    end
    if TE; TR('toX', -1); end
  end

  function toF(opd)
    if TE; TR('toF', 1); end
    toR(opd);
    rv = getVal(opd);
    asm.cmpRC(rv, 0);
    if TE; TR('toF', -1); end
  end

  function L2R(opd, sreg)                        % convert literal
    if TE; TR('L2R', 1); end
    if nargin == 1, sreg = -1; end
    reg = getReg(sreg);                          % anything but sreg
    switch getTy(opd)
      case sym.boolTYPE
        asm.movRC(reg, int32(getVal(opd)));
        setTag(opd, state.R);
        setVal(opd, reg);
      case sym.intTYPE
        asm.movRC(reg, getVal(opd));
        setTag(opd, state.R);
        setVal(opd, reg);
      case sym.realTYPE
        asm.movRC(reg, getVal(opd));             % float bits
        setTag(opd, state.R);                    % in general reg
        setTy(opd,  sym.intTYPE);                % pretend int
        setVal(opd, reg);
        R2X(opd);                                % in as int32
        setTy(opd,  sym.realTYPE);               % stop pretending
        X2R(opd);                                % out as single
      otherwise
        emitErr('bad case in L2R');      
    end
    if TE; TR('L2R', -1); end
  end
    
  function R2X(opd)                              % reg into temp
    if TE; TR('R2X', 1); end
    t = getTemp();
    localname = ['(tmp' num2str(t-1) ')'];
    adr = frameOffset(sym.size()+t);
    switch getTy(opd)
      case {sym.boolTYPE, sym.intTYPE}
        asm.movMR(adr, getVal(opd), localname);  % move to temp
        freeReg(getVal(opd));
      case sym.realTYPE
        asm.fstMp(adr, localname);               % store to temp
      otherwise
        emitErr('bad case in R2X');      
    end
    setVal(opd, t);                              % temp idx
    setTag(opd, state.X);
    if TE; TR('R2X', -1); end
  end

  function X2R(opd, sreg)                        % temp to reg
    if TE; TR('X2R', 1); end
    if nargin==1, sreg = -1; end
    t = getVal(opd);                             % temp idx
    adr = frameOffset(sym.size()+t);
    localname = ['(tmp' num2str(t-1) ')'];
    switch getTy(opd)
      case sym.boolTYPE
        reg = getReg(sreg);
        
        
        asm.movRM(reg, adr, localname);          % into int reg
        setVal(opd, reg);
      case sym.intTYPE
        reg = getReg(sreg);
        asm.movRM(reg, adr, localname);          % into int reg
        setVal(opd, reg);
      case sym.realTYPE
        asm.fldM(adr, localname);                % onto FPS
      otherwise
        emitErr('bad case in X2R');      
    end
    freeTemp(t);
    setTag(opd, state.R);                        % into R
    if TE; TR('X2R', -1); end
  end                                            % of X2R

  function S2M(opd)                              % symbol table to frame
    if TE; TR('S2M', 1); end
    setTag(opd, state.M);
    if TE; TR('S2M', -1); end
  end

  function M2R(opd, sreg)                        % frame to reg
    if TE; TR('M2R', 1); end
    if nargin == 1, sreg = -1; end
    t = getVal(opd);                             % frame idx
    localname = ['(' sym.getName(t) ')'];
    adr = frameOffset(t);
    switch getTy(opd)
      case sym.boolTYPE
        reg = getReg(sreg);                      % protect sreg
        asm.movRM(reg, adr, localname);          % into int reg
        setVal(opd, reg);
      case sym.intTYPE
        reg = getReg(sreg);                      % protect sreg
        asm.movRM(reg, adr, localname);          % into int reg
        setVal(opd, reg);
      case sym.realTYPE
        asm.fldM(adr, localname);                % onto FPS
      otherwise
        emitErr('bad case in M2R');      
    end
    setTag(opd, state.R);
    if TE; TR('M2R', -1); end
  end

  function F2R(opd, sreg)                        % int flags to reg
    if TE; TR('F2R', 1); end
    if nargin == 1, sreg = -1; end
    r = getReg(sreg);                            % frame offset
    switch getVal(opd)                           % X rule
      case rn.relation_sumLTsum,     asm.lR(r)
      case rn.relation_sumLTEQsum,   asm.leR(r)
      case rn.relation_sumEQsum,     asm.eR(r)
      case rn.relation_sumNOTEQsum,  asm.neR(r)
      case rn.relation_sumGTEQsum,   asm.geR(r)
      case rn.relation_sumGTsum,     asm.gR(r)
      otherwise, emitErr('bad flag in F2R');
    end
    setTag(opd, state.R);
    setTy(opd, sym.boolTYPE);
    setVal(opd, r);
    if TE; TR('F2R', -1); end
  end                                            % of F2R

  function D2R(opd, sreg)                        % double flags to reg
    if TE; TR('D2R', 1); end
    if nargin == 1, sreg = -1; end
    r = getReg(sreg);                            % frame offset
    switch getVal(opd)                           % X rule
      case rn.relation_sumLTsum,    asm.aR(r)
      case rn.relation_sumLTEQsum,  asm.aeR(r)
      case rn.relation_sumEQsum,    asm.eR(r)
      case rn.relation_sumNOTEQsum, asm.neR(r)
      case rn.relation_sumGTEQsum,  asm.beR(r)
      case rn.relation_sumGTsum,    asm.bR(r)
      otherwise, emitErr('bad flag in D2R');
    end
    setTag(opd, state.R);
    setTy(opd, sym.boolTYPE);
    setVal(opd, r);
    if TE; TR('D2R', -1); end
  end                                            % of D2R


  % ---------------- functions implemented in C ------------------
  
  function res = realRand()
    if TE; TR('realRand', 1); end
    spillAllRegs();                              % call-side save
    addr = getCfun('rand');                      % 32 or 64 bits
    asm.movRC(asm.EAX, addr, '# addr of rand');  % C code location
    asm.callRi(asm.EAX, '# call runtime');       % go do it
    res = getOpd();                              % fresh operand
    setTag(res, state.R);
    setTy(res,  sym.intTYPE);                    % (float in EAX)
    toX(res);                                    % to temp
    setTy(res,  sym.realTYPE);                   % change type back
    if TE; TR('realRand', -1); end
  end
  
  function intDiv(r, left, right, err)
    if TE; TR('intDiv', 1); end
    switch r                                     % div or rem
      case rn.term_termDIVfactor
        dop = 'div';                             % int divide
        synonym = 113;
      case rn.term_termDIVDIVfactor
        dop = 'rem';                             % int remainter
        synonym = 114;
      otherwise
        emitErr('bad case in intDiv');
    end
    addr = getCfun(dop);                         % C code for div/rem
    r1 = getVal(left);                           % register
    r2 = getVal(right);                          % register
    asm.cmpRC(r2, 0, '# test for div by zero');  % div by zero?
    fu = asm.jne32(0, '# skip over abort');      % skip over err call
    arithAbort(r, err);                          % error call
    asm.fixup32(fu);                             % after error call
    asm.pushR(r2, '# divisor');                % pass args 
    asm.pushR(r1, '# dividend');
    toA(left);
    toA(right);
    if int32(bitshift(addr, -32)) ~= 0         % running on A64
      addr = synonym;                          % magic number for emulator
    end
    spillAllRegs()                             % call-side save
    asm.movRC(asm.EAX, addr, ['# addr of ' dop '']);  % C code location
    asm.callRi(asm.EAX, '# call runtime');     % go do it
    asm.addRC(asm.ESP, 8, '# destroy frame');  % destroy frame
    rg = getReg();                               % will be EAX
    
    setTag(left, state.R);
    setTy(left, sym.intTYPE);
    setVal(left, rg);                            % passed in EAX
    if TE; TR('intDiv', -1); end
  end

  % -------------------- utilities ------------------
  
  function dump()
    asm.dump()
  end
  
  function TR(msg, t)
    if nargin == 1; t = 0; end
    if t == -1; lvl.out(); msg = ['leave ' msg];
    elseif t == 1;  msg = ['enter ' msg]; 
    end
    fprintf('Emitx86:   %s%s\n', lvl.val(), msg);
    if t == 1; lvl.in(); end
  end

  function emitErr(msg, tok)
    if nargin == 1
      error(['EmitX86: ' msg]);
    else
      [ln,cl] = lexed.getLineCol(lexed.start(tok));
      txt = sprintf('%s at line %d col %d', msg, ln, cl);
      error(['EmitX86:' txt]);
    end
  end

  % ----------------public methods-------------------
  
  function o = public()
    o = struct;
    o.sym      = sym;              % pass it along
    
    % Emitter public methods        semantics for:
    o.prolog   = @prolog;          % X program entry
    o.epilog   = @epilog;          % X program exit
    o.abort    = @abort;           % X program run error
    o.stmt     = @stmt;            % statement processing
    o.call     = @call;            % call X subprogram
    o.var      = @var;             % variable processing
    o.expr0    = @expr0;           % 0-ary expression processing
    o.expr1    = @expr1;           % 1-ary expression processing
    o.expr2    = @expr2;           % 2-ary expression processing
    o.store    = @store;           % store to frame
    o.iffiEnd  = @iffiEnd;         % fixups for if alts
    o.iffiAbort= @iffiAbort;       % failed all guards
    o.doodBegin= @doodBegin;       % save loop start
    o.doodEnd  = @doodEnd;         % fixups for do alts
    o.guardEnd = @guardEnd;        % fixups for guards
    o.altEnd   = @altEnd;          % fixups to exit construct
    o.ntemps   = @nTemps;          % total temps allocated
    o.getEntry = @getEntry;        % hardware address
    o.findErr  = @findErr;         % search local run errors
    o.go       = @go;              % execute compiled code
    o.trace    = @trace;           % emulate compiled code
    o.inter    = @inter;           % interact w/compiled code
    o.silent   = @silent;          % no emulator output
    o.dump     = @dump;            % dump assembly code
  end
end
