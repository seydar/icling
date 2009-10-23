% FILE:     Generator.m
% PURPOSE:  Generate semantic actions (target independent)
% OVERVIEW:
%   The GENERATOR is a platform independent object that walks the syntax
%   tree and send a sequence of actions to the code Emitter.  The
%   GENERATOR assumes complete type analysis is available. 
%
% USAGE:
%   cc = Generator(p, syms, errCt, exePtr, frmPtr);
%   cc = Generator(p, syms, errCt, exePtr, frmPtr, '-genTrace');
%
% IMPLEMENTATION   
%   The Generator contains a Emitter; the Emitter contains an Assembler.
%   The Emitter implements semantic routines.  As the syntax tree is
%   walked, the semantic routines are called in the appropriate order. 
%   The Symbols pass has already resolved type and use of variables.   
%   Such information as must be passed beween Emitter methods is held 
%   opaquely in the local variables of the Generator stack walkers.
%
% UNIT TESTS
%   testGenerator
%   tryGenerator
% EXAMPLE: 
%  None:  the context required to set up an example is too complicated
%         to supply much help.  Look at calls in xcom.m

% COPYRIGHT W.M.McKeeman 2007.  You may do anything you like with 
% this file except remove or modify this copyright.

function obj = Generator(...
  p,            ... which file from command line
  syms,         ... symbol tables of all subprograms
  errCt,        ... current run time error number
  exePtr,       ... pointer to vector of subprogram entries
  frmPtr,       ... pointer to vector of subprogam frame sizes
  subFlags,     ... the flags for this subroutine
  allFlags      ... the global flags
)

  if nargin <= 6, allFlags = {}; end
  if nargin <= 5, subFlags = {}; end

  lvl = tab();
  % Here is where the target hardware architecture is chosen
  % (under construction)
  platform = computer;
  switch platform
    case {'PCWIN', 'GLNX86', 'MACI', 'GLNXA64'}
      emit = EmitX86(p, syms, errCt, exePtr, frmPtr, lvl, subFlags, allFlags);
    case {'PCWIN64'}   % work in progress
      fprintf('%s\n', ['emulating: platform ' platform ' NYI']);
      emit = EmitX86(p, syms, errCt, exePtr, frmPtr, lvl, subFlags, allFlags);
    otherwise
      fprintf('%s\n', ['emulating: platform ' platform ' NYI']);
      emit = EmitX86(p, syms, errCt, exePtr, frmPtr, lvl, subFlags, allFlags);
  end
  sym  = syms{p};
  tree = sym.tree;
  cfg  = tree.parsed.lexed.cfg;
  rn   = cfg.ruleNumbers;

  TG = findFlag('-genTrace', subFlags);
  genWalk();
  
  obj = public();
  
  return;
    
  % -- ---- nested functions -------
  
  function errno = go(f)
    errno = emit.go(f);
  end

  function [errno, f] = trace(f,s)
    [errno, f] = emit.trace(f,s);
  end

  function [errno, f] = inter(f,s)
    [errno, f] = emit.inter(f,s);
  end

  function [errno, f] = silent(f,s)
    [errno, f] = emit.silent(f,s);
  end

  function genWalk()                             % entry to walkers
    if TG; TR('genWalk', 1); end
    emit.prolog();
    r = tree.getRoot();
    stmtWalk(r);                                 % generate code
    emit.epilog();                               % return
    if TG; TR('genWalk', -1); end
  end   %--------------ccWalk-----------------

  %{
  program
      stmts eof
  stmts
      stmt
      stmts ; stmt
  stmt

      selection
      iteration
      assignment
  %}
  function stmtWalk(nd)
    r = tree.getRule(nd);
    if TG; TR(['stmtWalk node=' num2str(r)], 1); end
    switch r
      case {                                     % nothing to do
          rn.program_stmtseof;
          rn.stmts_stmt
        } 
        stmtWalk(tree.getKid(nd, 1));
      case rn.stmts_stmtsSEMIstmt                % sequence
        stmtWalk(tree.getKid(nd, 1));
        stmtWalk(tree.getKid(nd, 3));

      case rn.stmt_                              % empty
        
      case rn.stmt_selection                     % if fi
        selectionWalk(tree.getKid(nd, 1));
      case rn.stmt_iteration
        iterationWalk(tree.getKid(nd, 1));       % do od
      case rn.stmt_assignment
        an = tree.getKid(nd, 1);                 % :=    
        if tree.getRule(an) == rn.assignment_varsCOLONEQexprs
          assignWalk(an);   
        else
          callWalk(an);
        end
        
      case rn.guard_expr
        tf = exprWalk(tree.getKid(nd,1));        % bool exp
        emit.expr(tf);
        
      otherwise
        genErr('generator: bad case in stmtWalk');
    end
    if TG; TR(['stmtWalk node=' num2str(r)], -1); end
  end   %----------------stmtWalk----------------

  %{
    selection
        if alts fi
  %}
  function selectionWalk(nd)
    if TG; TR('selectionWalk', 1); end
    fixups = altsWalk(tree.getKid(nd, 2), '(beyond if-fi)');% if alts fi
    emit.iffiAbort(tree.getKid(nd, 3));
    emit.iffiEnd(fixups);
    if TG; TR('selectionWalk', -1); end
  end

  %{
    iteration
        do alts od
  %}
  function iterationWalk(nd)
    if TG; TR('iterationWalk', 1); end
    dopc = emit.doodBegin();
    fixups = altsWalk(tree.getKid(nd,2), '(to loop start)'); % do alts od
    emit.doodEnd(fixups, dopc);
    if TG; TR('iterationWalk', -1); end
  end

  %{
  alts
      alt
      alts :: alt 
  %}
  function fixes = altsWalk(nd, ms)
    if TG; TR('altsWalk', 1); end
    if tree.getRule(nd) == rn.alts_altsCOLONCOLONalt
      fs = altsWalk(tree.getKid(nd,1), ms);
      fixes = [altWalk(tree.getKid(nd,3), ms), fs];
    else
      fixes = altWalk(tree.getKid(nd,1), ms);
    end
    if TG; TR('altsWalk', -1); end
  end

  %{
  alt
    guard ? stmts
  guard
    expr
  %}
  function fix = altWalk(nd, ms)
    if TG; TR('altWalk', 1); end
    altopd = exprWalk(tree.getKid(tree.getKid(nd, 1), 1));
    altpc = emit.guardEnd(altopd, tree.getLeaf(tree.getKid(nd, 2)));
    stmtWalk(tree.getKid(nd, 3));
    fix = emit.altEnd(altpc, ms);
    if TG; TR('altWalk', -1); end
  end

  %{
    assignment
      vars := exprs
  %}
  function assignWalk(nd)
    if TG; TR('assignWalk', 1); end
    lhs = varsWalk(tree.getKid(nd, 1));
    rhs = exprsWalk(tree.getKid(nd, 3));
    if numel(lhs) ~= numel(rhs)
      genErr('unbalanced assignment');
    end
    emit.store(lhs, rhs);
    if TG; TR('assignWalk', -1); end
  end

  %{
  vars
    id
    vars , id
  %}
  % a list of tokens, first is rightmost
  function vlst = varsWalk(nd)
    if TG; TR('varsWalk', 1); end
    if tree.getRule(nd) == rn.vars_id
      vlst = emit.var(tree.getKid(nd, 1));
    else
      t = emit.var(tree.getKid(nd,3));
      vlst = [t varsWalk(tree.getKid(nd, 1))];
    end
    if TG; TR('varsWalk', -1); end
  end

 %{
  exprs
    expr
    exprs , expr
  %}
  % a list of expressions, first is rightmost
  function elst = exprsWalk(nd)
    if TG; TR('exprsWalk', 1); end
    if tree.getRule(nd) == rn.exprs_expr
      elst = exprWalk(tree.getKid(nd, 1));
    else
      t = exprWalk(tree.getKid(nd, 3));
      elst = [t exprsWalk(tree.getKid(nd, 1))];
    end
    if TG; TR('exprsWalk', -1); end
  end

  %{
  assignment
    vars := subprogram := exprs
         := subprogram := exprs
    vars := subprogram :=
         := subprogram :=
  %}
  function callWalk(nd)
    r = tree.getRule(nd);
    if TG; TR(['callWalk node=' num2str(r)], 1); end
    switch r
      case rn.assignment_varsCOLONEQsubprogramCOLONEQexprs
        lhs  = varsWalk(tree.getKid(nd, 1));
        name = tree.getLeaf(tree.getKid(tree.getKid(nd, 3),1));
        rhs  = exprsWalk(tree.getKid(nd, 5));
      case rn.assignment_COLONEQsubprogramCOLONEQexprs
        lhs  = [];
        name = tree.getLeaf(tree.getKid(tree.getKid(nd, 2),1));
        rhs  = exprsWalk(tree.getKid(nd, 4));
      case rn.assignment_varsCOLONEQsubprogramCOLONEQ
        lhs  = varsWalk(tree.getKid(nd, 1));
        name = tree.getLeaf(tree.getKid(tree.getKid(nd, 3),1));
        rhs  = [];
      case rn.assignment_COLONEQsubprogramCOLONEQ
        lhs  = [];
        name = tree.getLeaf(tree.getKid(tree.getKid(nd, 2),1));
        rhs  = [];
      otherwise
        error(['bad tree ' num2str(r)]);
    end
    emit.call(lhs, name, rhs);
    if TG; TR(['callWalk node=' num2str(r)], -1); end
  end


  function res = exprWalk(nd)
    r = tree.getRule(nd);
    if TG; TR(['exprWalk node=' num2str(r)], 1); end
    switch r

      % links that could be abstracted in AST
      case {
          rn.expr_disjunction;
          rn.disjunction_conjunction;
          rn.conjunction_negation; 
          rn.negation_relation; 
          rn.relation_sum;
          rn.sum_term;
          rn.term_factor
        }
        res = exprWalk(tree.getKid(nd, 1));
        
      % ( expr )
      case rn.factor_LRexprRR
        res = exprWalk(tree.getKid(nd, 2));

        % | < <= = ~= >= > & + * / // 
      case {
          rn.disjunction_disjunctionORconjunction;
          rn.conjunction_conjunctionANDnegation;
          rn.relation_sumLTsum;
          rn.relation_sumLTEQsum;
          rn.relation_sumEQsum;
          rn.relation_sumNOTEQsum;
          rn.relation_sumGTEQsum;
          rn.relation_sumGTsum;
          rn.sum_sumADDterm;
          rn.sum_sumSUBterm;
          rn.term_termMULfactor;
          rn.term_termDIVfactor;
          rn.term_termDIVDIVfactor
        }
        lft = exprWalk(tree.getKid(nd, 1));
        op  = tree.getKid(nd, 2);                % a token idx
        rgt = exprWalk(tree.getKid(nd, 3));
        res = emit.expr2(r, lft, rgt, op);

      % ~ - b2i r2i i2r 
      case {
          rn.negation_NOTrelation;
          rn.sum_SUBterm;
          rn.factor_b2ifactor;
          rn.factor_i2rfactor;
          rn.factor_r2ifactor
        }
        opd = exprWalk(tree.getKid(nd, 2));
        op = tree.getKid(nd,1);                  % a token idx
        res = emit.expr1(r, opd, op);

      % true false integer real id rand
      case {
          rn.factor_true;
          rn.factor_false;
          rn.factor_integer;
          rn.factor_real;
          rn.factor_id;
          rn.factor_rand
        }
        op = tree.getKid(nd,1);                  % a token idx
        res = emit.expr0(r, op);
        
      otherwise
        genErr(['bad case ' num2str(r)]);
    end
    if TG; TR(['exprWalk node=' num2str(r)], -1); end

  end  % of exprWalk

  % -------------------- utilities ------------------
  function TR(msg, t)
    if nargin == 1; t = 0; end
    if t == -1; lvl.out(); msg = ['leave ' msg];
    elseif t == 1;  msg = ['enter ' msg]; 
    end
    fprintf('Generator: %s%s\n', lvl.val(), msg);
    if t == 1; lvl.in(); end
  end

  function genErr(msg)
    error(['Generator: ' msg]);
  end

  function ct = errorCount()
    ct = errCt;
  end

  function n = ntemps()
    n = emit.ntemps();
  end

  function e = getEntry()
    e = emit.getEntry();
  end

  function rpt = findErr(errno)
    rpt = emit.findErr(errno);
  end

  function dump()
    emit.dump();
  end

% ---------------- public methods and data -----------------
  function o = public()
    o = struct;
    o.go          = @go;
    o.trace       = @trace;
    o.inter       = @inter;
    o.silent      = @silent;
    o.findErr     = @findErr;
    o.errorCount  = @errorCount;
    o.ntemps      = @ntemps;
    o.getEntry    = @getEntry;
    o.dump        = @dump;
  end

end
