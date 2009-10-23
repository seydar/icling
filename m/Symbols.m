% FILE:     Symbols.m
% PURPOSE:  symbol table implementation for the programming language X
% TEST:     testSymbols.m
%
% USAGE: sym = SYMBOLS() 
%   When called without syntax tree input, the returned object contains
%   only the static fields.  This is useful when the values defined in
%   SYMBOLS are required, but no tree needs analysis.
%   
% USAGE: sym = SYMBOLS(tree)
% USAGE: sym = SYMBOLS(tree, file)
%   tree: the syntax tree constructed from the source text.
%   file: the name of the file containing the source text (if any).
%
%   Walk the syntax tree gathering information, tabulate it in the SYMBOLS
%   object. For example:
%        sym.dump()
%   after constructions dumps the entire symbol table to the MATLAB command
%   window.  This function is sometimes used in diagnostics.
%
% USAGE: sym = SYMBOLS(tree, file, '-symTrace')
%   Same result but in addition trace output dumped into the MATLAB command 
%   window.
%
% OVERVIEW:  
%   Symbols.m is a symbol table mechanism for the XCOM compiler.  
%
%   X types are logical, integer, real and function.  Every variable has a
%   type. Variables are used to name subprograms, or as targets of
%   assignment (left) or as sources of values (right), or both.
%
%   In the X language variables variables used only on the left imply
%   output and when used only on the right, imply input.
%
%   An X file also defines a subprogram.  Each subprogram has a signature:
%   return values and inputs for a subprogram call must be type correct
%   with respect to the left and right types for the subprogram
%   definition.
%
%   The SYMBOLS module will error on violations of strong typing (no
%   automatic conversions) and also on incomplete type information.
%
%   SYMBOLS expects a name and a syntax tree as input; it provides methods 
%   to get symbol attributes as output.  
% EXAMPLE:
%   None.  Look at use in xcom.m

% COPYRIGHT W.M.McKeeman 2007.  You may do anything you like with 
% this file except remove or modify this copyright.
% IMPLEMENTATION:
%   The form of SYMBOLS is an object.  Each call of SYMBOLS acts like a
%   constructor, returning a struct with fields for each public method and
%   constant exported by SYMBOLS. SYMBOLS requires the Tree object.

% This tree, which file, symbol tables, fn name, flags.
function obj = Symbols(tree, p, syms, fnName, flags)    % ctor, 
  
  symIn = nargin;                                % avail to nested
  
  if symIn > 0
    assert(isstruct(tree), ...
      'input tree must be type struct but is %s\', class(tree));      
    cfg = tree.parsed.lexed.cfg;
    rn  = cfg.ruleNumbers;                       % enumeration
  end

  if symIn > 3                                   % X code in file
    assert(ischar(fnName), ...
      'input file must be type char but is %s\n', class(fnName));
  else
    fnName = '';                                 % meaning no file
  end
  
  TS = symIn > 4 && findFlag('-symTrace', flags);
  lvl = tab();
  
  % types in attribute table table (available statically)
  noType    = uint32(0);
  boolType  = uint32(1);
  intType   = bitshift(boolType, 1);
  realType  = bitshift(intType, 1);
  fnType    = bitshift(realType, 1);
  arithType = bitor(intType, realType);
  undefType = bitor(bitor(arithType, boolType),fnType);
  
  onLeft   = uint32(1);
  onRight  = bitshift(onLeft, 1);
  onBoth   = bitor(onLeft, onRight);
  
  % symbol table data collected to be provided to consumers
  symTable  = {};                                % IDs
  typeTable = uint32([]);                        % bool | int | real
  useTable  = uint32([]);                        % L | R | LR
  
  if ~isempty(fnName)                            % self into table
    fidx = enter(fnName);
    setType(fidx, fnType);
  end
  
  if symIn > 0                                   % there is a tree
    symWalk();                                   % 1 or more times
  end
  
  obj = public();                  % public values and methods
  return;
  
  %--------------- nested functions -----------------------
  function symWalk()                             % populate symTable
    if TS; TR('symWalk', 1); end
    r = tree.getRoot();
    oldCt = -1;
    while true                                   % making progress
      stmtWalk(r);                               % type analysis
      ct = notDef();                             % count incompletes
      if ct == oldCt, break; end                 % not making progress
      oldCt = ct;                                % ready to try again
    end
    if TS; TR('symWalk', -1); end
  end   %--------------symWalk-----------------

  % Statements to not affect types.
  % These rules dispatch to the expression processor
  function stmtWalk(n)
    if TS; TR(['enter stmtWalk node=' num2str(n)], 1); end
    
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
    selection
        if alts fi
    iteration
        do alts od
    alts
        alt
        alts :: alt
    alt
        guard ? stmts
    guard
        expr
    %}
    
    r = tree.getRule(n);                % N is  NODE, L is a leaf
    switch r
      case {...                                  % N
          rn.program_stmtseof;
          rn.stmts_stmt;
          rn.stmt_selection;
          rn.stmt_iteration;
          rn.alts_alt...
        }
        stmtWalk(tree.getKid(n, 1));
        
      case {...                                  %NLN
          rn.stmts_stmtsSEMIstmt;
          rn.alts_altsCOLONCOLONalt;
          rn.alt_guardQMARKstmts...
        }
        stmtWalk(tree.getKid(n, 1));
        stmtWalk(tree.getKid(n, 3));
        
      case rn.stmt_                              % empty
        
      case rn.guard_expr
        exprWalk(tree.getKid(n, 1), boolType);
        
      case rn.stmt_assignment
        exprWalk(tree.getKid(n, 1), undefType);
        
      case {...                                  % LNL
          rn.selection_ifaltsfi;
          rn.iteration_doaltsod
        }
        stmtWalk(tree.getKid(n, 2));
                
      otherwise
        symErr(n, 'bad case in stmtWalk');
    end
    if TS; TR(['stmtWalk node=' num2str(n)], -1); end
  end   %----------------stmtWalk----------------

  % Type analysis for expressions and assignments.
  % The going-in assumption is undefined (union of types).
  % Each result must be one of bool, integer, real or function.
  % Each final entry in the symbol table must have unique type.
 
  function res = exprWalk(nd, mustBe)
    if TS
      TR(['enter exprWalk node=' num2str(nd) ' mustBe=' num2str(mustBe)], 1);
    end

    r = tree.getRule(nd);
    %{
    assignment
      vars := exprs
      vars := subprogram := exprs
           := subprogram := exprs
      vars := subprogram :=
           := subprogram :=
    vars
      id
      vars, id

    exprs
      expr
      exprs, expr
    %}
    switch r

      % types must match across assignment
      case rn.assignment_varsCOLONEQexprs        % vars := exprs
        lVars = getVars(tree.getKid(nd, 1), {}); % get lhs's
        rExprs= getExprs(tree.getKid(nd, 3), []);% get rhs's
        if numel(lVars) ~= numel(rExprs)
          symErr(nd, 'assignment must have equal operand counts');
        end
        for i = 1:numel(lVars)
          idx = enter(lVars{i});                 % into id symbol table
          setUse(idx, onLeft);                   % lhs use
          vTy = getType(idx);                    % type so far
          eTy = exprWalk(rExprs(i), vTy);        % analyze rhs
          setType(idx, eTy);                     % force match
        end
        
      case rn.assignment_varsCOLONEQsubprogramCOLONEQexprs 
        % get subprogram name and enter into symbol table
        fnode = tree.getKid(nd, 3);              % the subprogram
        fn  = tree.getLeaf(tree.getKid(fnode,1));% the name
        idx = enter(fn);                         % enter called function
        setType(idx, fnType);
        fnTbl = getFun(syms, fn);                 % get its defining symT
        
        % collect the l.h.s. variables of call
        lVars = getVars(tree.getKid(nd, 1), {}); % get lhs's
        if fnTbl ~= 0 && syms{fnTbl}.getLftCt() ~= numel(lVars)
          symErr(fnode, 'mismatched number of output variables');
        end
        for i=1:numel(lVars); 
          idx = enter(lVars{i});                 % make sure id is in SymT
          setUse(idx, onLeft);                   % record left use
          if fnTbl ~= 0                          % force type agreement
            setType(idx, syms{fnTbl}.getType(syms{fnTbl}.getLeft(i)));
          end
        end
        
        % collect the r.h.s. expr nodes of call
        rExprs = getExprs(tree.getKid(nd, 5), []);% get rhs's
        if fnTbl ~= 0 && syms{fnTbl}.getRgtCt() ~= numel(rExprs)
          symErr(fnode, 'mismatched number of input variables');
        end
        for i=1:numel(rExprs);                   % analyse rhs's
          startType = undefType;                 % worst case
          if fnTbl ~= 0
            startType = syms{fnTbl}.getType(syms{fnTbl}.getRight(i));
          end
          exprWalk(rExprs(i), startType);        % type from called fn
        end
                        
      case rn.assignment_COLONEQsubprogramCOLONEQexprs
        % get subprogram name and enter into symbol table
        fnode = tree.getKid(nd, 2);              % the subprogram
        fn  = tree.getLeaf(tree.getKid(fnode,1));% the name
        idx = enter(fn);                         % enter called function
        setType(idx, fnType);
        fnTbl = getFun(syms, fn);                 % get its defining symT

        % collect the r.h.s. expr nodes of call
        rExprs = getExprs(tree.getKid(nd, 4), []);% get rhs's
        if fnTbl ~= 0 && syms{fnTbl}.getRgtCt() ~= numel(rExprs)
          symErr(fnode, 'mismatched number of input variables');
        end
        for i=1:numel(rExprs);                   % analyse rhs's
          startType = undefType;                 % worst case
          if fnTbl ~= 0
            startType = getType(syms{fnTbl}.getRight(i));
          end
          exprWalk(rExprs(i), startType);        % type from called fn
        end
        
      case rn.assignment_varsCOLONEQsubprogramCOLONEQ
        % get subprogram name and enter into symbol table
        fnode = tree.getKid(nd, 3);              % the subprogram
        fn  = tree.getLeaf(tree.getKid(fnode,1));% the name
        idx = enter(fn);                         % enter called function
        setType(idx, fnType);
        fnTbl = getFun(syms, fn);                 % get its defining symT
        
        % collect the l.h.s. variables of call
        lVars = getVars(tree.getKid(nd, 1), {}); % get lhs's
        if fnTbl ~= 0 && syms{fnTbl}.getLftCt() ~= numel(lVars)
          symErr(fnode, 'mismatched number of output variables');
        end
        for i=1:numel(lVars); 
          idx = enter(lVars{i});                 % make sure id is in SymT
          setUse(idx, onLeft);                   % record left use
          if fnTbl ~= 0                          % force type agreement
            setType(idx, syms{fnTbl}.getType(syms{fnTbl}.getLeft(i)));
          end
        end
        if fnTbl ~= 0 && syms{fnTbl}.getRgtCt() ~= 0
          symErr(fnode, 'need more input variables');
        end
        
      case rn.assignment_COLONEQsubprogramCOLONEQ
        fnode = tree.getKid(nd, 2);              % the subprogram
        fn = tree.getLeaf(tree.getKid(fnode,1)); % the name
        idx = enter(fn);
        setType(idx, fnType);
        fnTbl = getFun(syms, fn);                 % get its defining symT
        if fnTbl ~= 0 && syms{fnTbl}.getLftCt() ~= 0
          snv = num2str(syms{fnTbl}.getLftCt());
          symErr(fnode, ['need ' snv ' output variables']);
        end
        if fnTbl ~= 0 && syms{fnTbl}.getRgtCt() ~= 0
          snv = num2str(syms{fnTbl}.getRgtCt());
          symErr(fnode, ['need ' snv ' input variables']);
        end
        
      case {...                                  % N=node
          rn.expr_disjunction; 
          rn.disjunction_conjunction; 
          rn.conjunction_negation; 
          rn.negation_relation; 
          rn.relation_sum; 
          rn.sum_term; 
          rn.term_factor...
        }
        res = exprWalk(tree.getKid(nd, 1), mustBe);

      %{
        disjunction
          conjunction
          disjunction | conjunction
        conjunction
          negation
          conjunction & negation
        negation
          relation
          ~ relation
      %}
      case {...                                  % NLN &  |
          rn.disjunction_disjunctionORconjunction;
          rn.conjunction_conjunctionANDnegation...
        }
        if bitand(mustBe, boolType) == noType
          symErr(nd, 'logical type required for & and |');
        end
        exprWalk(tree.getKid(nd, 1), boolType);
        exprWalk(tree.getKid(nd, 3), boolType);
        res = boolType;

      case rn.negation_NOTrelation                % ~ x
        if bitand(mustBe, boolType) == noType
          symErr(nd, 'logical type required for ~');
        end
        exprWalk(tree.getKid(nd, 2), boolType);
        res = boolType;
        
      %{
      relation
          sum
          sum <  sum
          sum <= sum
          sum =  sum
          sum ~= sum
          sum >= sum
          sum >  sum
      %}
      case {...                                  % NLN rel
          rn.relation_sumLTsum;
          rn.relation_sumLTEQsum;
          rn.relation_sumEQsum;
          rn.relation_sumNOTEQsum;
          rn.relation_sumGTEQsum;
          rn.relation_sumGTsum...
          } 
        if bitand(mustBe, boolType) == noType
          symErr(nd, 'logical type not allowed by context');
        end
        k1 = tree.getKid(nd,1);
        k3 = tree.getKid(nd,3);
        if r == rn.relation_sumEQsum || r == rn.relation_sumNOTEQsum 
          exprWalk(k1, intType);
          exprWalk(k3, intType);        
        else
          at1 = exprWalk(k1, arithType);
          at2 = exprWalk(k3, at1);        
          if at2 ~= at1
            exprWalk(k1, at2);
          end
        end
        res = boolType;                          % result of rel
        
      %{
      sum
        term
        - term
        sum + term
        sum - term
      term
        factor
        term * factor
        term / factor
        term // factor
      %}
      case {...                                  % NLN arith
          rn.sum_sumADDterm;
          rn.sum_sumSUBterm;
          rn.term_termMULfactor;
          rn.term_termDIVfactor...
        }
        if bitand(mustBe, arithType) == 0        % some arith must be OK
          symErr(nd, 'arithmetic type needed for + - * /');
        end
        at1 = exprWalk(tree.getKid(nd, 1), bitand(mustBe, arithType));
        at2 = exprWalk(tree.getKid(nd, 3), at1);
        if at1 ~= at2
          exprWalk(tree.getKid(nd, 1), at2);        
        end
        res = at2;                               % most constrained

      case rn.sum_SUBterm                        % - x
        if bitand(mustBe, arithType) == 0
          symErr(nd, 'arithmetic type needed for unary -');
        end
        res = exprWalk(tree.getKid(nd, 2), bitand(mustBe, arithType));

      case rn.term_termDIVDIVfactor              % x // y
        if bitand(mustBe, intType) == 0
          symErr(nd, 'integer type required for //');
        end
        exprWalk(tree.getKid(nd, 1), intType);   % force type
        exprWalk(tree.getKid(nd, 3), intType);
        res = intType;
      
      %{
      factor
          true
          false
          integer
          real
          id
          ( expr )
          b2i factor
          i2r factor
          r2i factor
          rand
      %}
      case {...                                  % true false
          rn.factor_true;
          rn.factor_false...
        } 
        if bitand(mustBe,boolType) == 0
          symErr(nd, 'logical type not allowed by context');
        end
        res = boolType;

      case rn.factor_integer                     % 123
        if bitand(mustBe,intType) == 0
          symErr(nd, 'integer type not allowed by context');
        end
        res = intType;

      case rn.factor_real                        % 123.456
        if bitand(mustBe,realType) == 0
          symErr(nd, 'real type not allowed by context');
        end
        res = realType;

      case rn.factor_id                          % id
        idx = enter(tree.getLeaf(tree.getKid(nd, 1)));
        setType(idx, mustBe);
        setUse(idx, onRight);
        res = getType(idx);

      case rn.factor_LRexprRR                    % ( x )
        res = exprWalk(tree.getKid(nd, 2), mustBe);

      case rn.factor_b2ifactor                   % b2i x
        if bitand(mustBe, intType) == 0
          symErr(nd, 'b2i is type int');
        end
        exprWalk(tree.getKid(nd, 2), boolType);
        res = intType;

      case rn.factor_i2rfactor                   % i2r x
        if bitand(mustBe, realType) == 0
          symErr(nd, 'i2r is type real');
        end
        exprWalk(tree.getKid(nd, 2), intType);
        res = realType;

      case rn.factor_r2ifactor                   % r2i x
        if bitand(mustBe, intType) == 0
          symErr(nd, 'r2i returns type real');
        end
        exprWalk(tree.getKid(nd, 2), realType);
        res = intType;
      
      case rn.factor_absfactor                   % abs
        if bitand(mustBe, arithType) == 0        % arith type is ok
          symErr(nd, 'arithmetic type needed');
        end
        res = exprWalk(tree.getKid(nd, 2), bitand(mustBe, arithType));
      
      case rn.factor_rand                        % rand
        if bitand(mustBe, realType) == 0
          symErr(nd, 'rand returns type real');
        end
        res = realType;
      otherwise
        symErr(nd, 'Symbols: unexpected node in exprWalk');
    end
    if TS; TR('exprWalk', -1); end

  end  %---------------- exprWalk----------------

  % collect names of variables on lhs
  function lVars = getVars(nd, accum)            % list of outputs
    while true
      if tree.getRule(nd) == rn.vars_id          % id
        id = tree.getLeaf(tree.getKid(nd,1));
        accum = [id, accum];
        break;                                   % end of subtree
      else
        id = tree.getLeaf(tree.getKid(nd, 3));   % vars, id
        accum = [accum, id];
        nd = tree.getKid(nd, 1);                 % walk toward leaves
      end
    end
    lVars = accum;
  end

  % collect nodes of exprs on rhs
  function rExprs = getExprs(nd, accum)          % list of inputs
    while true
      if tree.getRule(nd) == rn.exprs_expr       % expr
        en = tree.getKid(nd,1);
        accum = [en, accum];
        break;                                   % end of subtree
      else                                       % exprs, expr
        en = tree.getKid(nd, 3); 
        accum = [accum, en];
        nd = tree.getKid(nd, 1);                 % walk toward leaves
      end
    end
    rExprs = accum;
  end

%------------- symbol table accesors ---------------------
  
  function idx = lookup(id)                      % find name
    for i=1:numel(symTable)                      % hash would be faster
      if strcmp(id, symTable{i})
        idx = int32(i);
        return;                                  % found
      end
    end
    idx = int32(0);                              % failed
    return;
  end

  function idx = enter(id)                       % enter if needed
    if TS; TR(['enter (' id ')'], 1); end
    idx = lookup(id);
    if idx == 0                                  % lookup failed
      idx = int32(numel(symTable)+1);            % grow tables
      symTable{idx} = id;                        % new entry
      typeTable(idx) = undefType;                % no attrs
      useTable(idx)  = 0;                        % not L or R
    end
    if TS; TR('enter', -1); end
    return;
  end

  function n = size()
    n = numel(symTable);
  end

  function ct = notDef()                         % look for undefineds
    if TS; TR('notDef', 1); end
    if symIn == 0, TS = false; end
    k = 0;                                       % none defined yet
    for i=1:numel(symTable)
      t = typeTable(i);
      switch t                                   % type correct
        case {boolType, intType, realType, fnType}
          k = k+1;
      end
    end
    ct = numel(symTable) - k;                    % total undefined
    if TS; TR('notDef', -1); end
  end

  function nm = getName(idx)                     % the name of a sym
    nm = symTable{idx};
  end

  function ty = getType(idx)                     % bool, int, real or fn
    ty = bitand(typeTable(idx), undefType);
  end

  function setType(idx, ty)
    if TS; TR(['set type=' num2str(ty)]); end
    typeTable(idx) = bitand(typeTable(idx), ty);
  end

  function u = getUse(idx)
    u = useTable(idx);
  end

  function setUse(idx, use)
    if TS; TR(['set use=' num2str(use)]); end
    useTable(idx) = bitor(useTable(idx), use);
  end
      
  function fn = getThisName()                    % name of current fn
    fn = fnName;
  end

  function ct = getLftCt()                       % how many on left?
    ct = sum(useTable == onLeft);
  end

  function ofs = getLeft(nth)                    % nth output
    v = find(useTable==onLeft);
    ofs = v(nth);                                % where it is
  end

  function ct = getRgtCt()                       % how many on right?
    ct = sum(useTable == onRight);
  end

  function ofs = getRight(nth)                   % nth input
    v = find(useTable==onRight);
    ofs = v(nth);                                % where it is
  end

%--------------- utilities --------------

  % find symbol table for function fnName
  function tbl = getFun(symTabs, fnName)         % zero means not found
    tbl = 0;                                     % no table yet
    for cf = 1:numel(symTabs)                    % look for fn def
      if ~isempty(symTabs{cf}) && strcmp(symTabs{cf}.getFun(), fnName)
        tbl = cf;                                % found table
        break;
      end
    end
  end

  % report a type error
  function symErr(nd, msg)
    if nd == 0                                   % no line/col
      error(['Symbols: ' msg]);
    else
      [ln, cl] = tree.getLineCol(nd);
      txt = sprintf([msg ' at line %d, col %d'],  ln, cl);
      error(['Symbols: ' txt]);
    end
  end

  function TR(msg, t)                            % trace
    if nargin == 1; t = 0; end
    if t == -1; lvl.out(); msg = ['leave ' msg];
    elseif t == 1;  msg = ['enter ' msg]; 
    end
    fprintf('Symbols:   %s%s\n', lvl.val(), msg);
    if t == 1; lvl.in(); end
  end

  function str = usestr(lr)                      % prepare use entry
    str = '';
    if bitand(lr, onLeft) ~= 0
      str = [str '|left'];
    end
    if bitand(lr, onRight) ~= 0
      str = [str '|right'];
    end
    if ~isempty(str), str = str(2:end); end
  end

  function str = typestr(ty)                     % prepare type entry
    str = '';
    if bitand(ty, boolType) ~= 0
      str = [str '|logical'];
    end
    if bitand(ty, intType) ~= 0
      str = [str '|integer'];
    end
    if bitand(ty, realType) ~= 0
      str = [str '|real'];
    end
    if bitand(ty, fnType) ~= 0
      str = [str '|fn'];
    end
    if ~isempty(str), str = str(2:end); end
  end
    
  function print(j)                              % dump symbol table entry
    ty = typestr(typeTable(j));
    lr = usestr(useTable(j));
    
    fprintf('%4d: %s: ty=%s use=%s\n', ...
      j, symTable{j}, ty, lr);
  end

  function dump()
    if symIn == 0, return; end
    
    disp('Symbols ---------- start dump ------------');
    for i=1:numel(symTable)
      print(i);
    end
    disp('Symbols ---------- end   dump ------------');
  end

  % ---------------- exported values/methods------------------
  
  function o = public()                          % n == 0 is static
    o = struct;
    % statically available fields
    o.boolTYPE = boolType;
    o.intTYPE  = intType;
    o.realTYPE = realType;
    o.fnTYPE   = fnType;
    o.onLEFT   = onLeft;
    o.onRIGHT  = onRight;
    o.onBOTH   = onBoth;
    o.dump     = @dump;
    if symIn == 0, return; end                   % static fields only
    
    % fields resulting from tree walk
    o.tree     = tree;                           % pass it on
    o.lookup   = @lookup;                        % get table index
    %o.enter    = @enter;                         % get table index
    o.notDef   = @notDef;                        % number not fully defined
                                                 % given index, get
    o.getName  = @getName;                       %    name
    o.getType  = @getType;                       %    bool, int, real
    o.getUse   = @getUse;                        %    L or R or LR
    o.getFun   = @getThisName;                   % this function name
    o.getLftCt = @getLftCt;                      % output count
    o.getLeft  = @getLeft;                       % the i-th output
    o.getRgtCt = @getRgtCt;                      % input count
    o.getRight = @getRight;                      % the i-th input
    o.size     = @size;
  end

end
