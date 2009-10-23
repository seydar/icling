% FILE:     Parser.m
% PURPOSE:  parser for X
% MODS:     2007.08.09 -- mckeeman@dartmouth.edu -- original
%           2007.11.20 -- mckeeman@dartmouth.edu -- added LR(1)
% TEST:     testParser.m
%
% OVERVIEW:
%   Parser.m provides an object containing a shift/reduce sequence from the
%   lexed input, and constant values identifying grammar rules. The
%   output is used by Tree.m.
%
% USAGE:  parseobj = Parser(lexed)
%         parseobj = Parser(lexed, {'-parseTrace'})
%         parseobj = Parser(lexed, {'-bottomUp'})
%         parseobj = Parser(lexed, {'-noAST'})
%         parseobj.sr is the shift/reduce sequence 
%         parseobj.dump() dumps the sr sequence to the command window
%         sr(i) is the i-th entry (+ for shifts, - for rules)
% EXAMPLE:
%   cfg = Cfg(xread('X.cfg'), {'-noLR'});
%   lexed = Lexer(cfg, 'x:=13789');
%   parseobj = Parser(lexed);
%   parseobj.dump()

% COPYRIGHT W.M.McKeeman 2006.  You may do anything you like with 
% this file except remove or modify this copyright.
% IMPLEMENTATION:
%   The vector of token kinds is used to make parsing decisions.  
%   The parser is algorithm is 
%      (a) top-down (default), or
%      (b) bottom-up (if flag -bottomUp is seen).
%   The parser output is
%      (a) the abstracted shift/reduce sequence (default)
%      (b) the syntax tree (if flag -noAST is seen)
%   Note: they are the same speed to within 1%

function obj = Parser(lexed, flags)         % ctor

  assert(isstruct(lexed), ...
    'input lexed must be type struct but is %s\n', class(lexed));
  % persistent fields of Parser object
  TP =  nargin > 1 && findFlag('-parseTrace', flags);
  lvl = tab();
  topDown = nargin == 1 || ~findFlag('-bottomUp', flags);
  noAST = nargin > 1 && findFlag('-noAST', flags);

  cfg   = lexed.cfg;
  rw    = enum(cfg.reserved);                    % set up tables
  rnm   = cfg.ruleNames;
  rule  = cfg.ruleNumbers;
  R     = cfg.R;                                 % rules
  rlen  = cfg.ruleLengths;
  lr    = cfg.lr;                                % LR(1) tables
  NVi   = numel(cfg.Vi);                         % size(Vi)
  
  for si=1:numel(cfg.Vn)
    if strcmp('expr', cfg.Vn{si})
      exprSym = si;                              % expr phrase name
      break;                                     % needed for heads
    end
  end
    
  % AST chain-shortening node removal list
  nullRules = false(1, numel(rnm));              % true means skip
  if ~noAST                                      % choose ignorable rules
    rlist = [
      rule.expr_disjunction 
      rule.disjunction_conjunction
      rule.conjunction_negation
      rule.negation_relation
      rule.relation_sum
      rule.sum_term
      rule.term_factor];
    nullRules(rlist) = true;                     % no nodes for these
  end
  
  tp     = 0;                                    % start at begining
  toklim = lexed.lim;                            % set in parse
  toks   = lexed.kind;                           % token sequence
  st     = lexed.start;
  en     = lexed.finish;
  src    = [lexed.src, 0];
  tok    = 0;                                    % declare tok
  
  LRstack = zeros(1, 100, 'int16');
  psp = 1;                                       % parse stack pointer
  shiftReduce = zeros(1, 100, 'int16');          % init space for output  
  srp = 0;                                       % shift/reduce pointer
  
  parse();                                       % do the work
  
  % pass out public methods and variables
  obj = public();

  return;        % end of constructor
  
  % ----------------------- main entry -----------------------------
  function parse()
    srp    = 1;                                  % first action
    step();                                      % prime the pump
    srp    = 1;                                  % next avail
    if topDown
      if TP; TR('top-down parse'); end
      program();                                 % recursive descent
    else
      if TP; TR('bottom-up parse'); end
      LR1();                                     % Knuth
    end
    shiftReduce = shiftReduce(1:srp-1);          % discard prealloc cells
  end

  % ------------------- bottom up method ---------------------
  
  % The state machine has two kinds of entries.
  % A shift entry is "in state s1, see x, goto state s2"  
  % A reduce entry is "in state s, see x, reduce rule r."
  % The shift entries are distinuish from the reduce entries by sign.
  % A positive entry is a goto state; a negative entry is a reduction.
  % A zero entry indicates a syntax error.
  function LR1()
    initialState = 1;                            % start the DFA
    finalRule = 1;                               % goal symbol def
    state = initialState;                        % LR starting state
    LRstack(psp) = state;                        % on stack
    psp = psp+1;                                 % make room
    while true                                   % until goal is reached
      action = lr(state,tok);                    % shift, reduce or error
      if action > 0                              % shift
        state = action;                          %   new state
        LRstack(psp) = state;                    %   stack state
        psp = psp + 1;                           %   make room for next
        step();                                  %   report, new tok
      elseif action < 0                          % reduce
        rule = -action;                          %   rule number
        psp = psp - rlen(rule);                  %   pop stack
        lhs = R{rule}(1);                        %   lhs of grammar rule
        state = lr(LRstack(psp-1), lhs);         %   new state
        LRstack(psp) = state;                    %   stack state
        psp = psp + 1;                           %   make room for next
        reduce(rule);                            %   report rule
        if rule == finalRule; break; end;        %   goal rule
      else                                       % action == 0
        LRerror(state);                          % diagnose and quit
      end
    end
  end
  
  function LRerror(state)                        % report syntax error
    expect = cfg.V(lr(state, :) ~= 0);
    txt = src(st(tp):en(tp));
    [ln,col] = lexed.lineCol(st(tp));
    msg = 'Parser: expected ';
    ex = sprintf(' %s', expect{:});
    error('%s%s, got %s  at line %d col %d', msg, ex, txt, ln, col);
  end

  % --------------------top down methods ----------------------

  function program()
    if TP; TR('program', 1); end
    stmts();
    accept(lexed.EOF, 'expected eof');
    reduce(rule.program_stmtseof);               % all done
    if TP; TR('program', -1); end
  end

  function stmts()
    if TP; TR('stmts', 1); end
    stmt();
    reduce(rule.stmts_stmt);
    while true
      if tok == rw.SEMI
        step(); stmt(); reduce(rule.stmts_stmtsSEMIstmt);
      else
        break
      end
    end
    if TP; TR('stmts', -1); end
  end

  function stmt()
    if TP; TR('stmt', 1); end
    switch tok
    case rw.if
      selection();                               % if ... fi
      reduce(rule.stmt_selection);
    case rw.do
      iteration();                               % do ... od
      reduce(rule.stmt_iteration);
    case rw.COLONEQ
      assignment();                              % := f :=
      reduce(rule.stmt_assignment);
    case lexed.ID
      assignment();                              % a,b := b,a
      reduce(rule.stmt_assignment);
      otherwise                                  % empty
      reduce(rule.stmt_);
    end
    if TP; TR('stmt', -1); end
  end

  function selection()
    if TP; TR('selection', 1); end
    step();                                      % discard if
    alts();
    accept(rw.fi, 'expected closing ''fi''');    % fi
    reduce(rule.selection_ifaltsfi);
    if TP; TR('selection', -1); end
  end

  function iteration()
    if TP; TR('iteration', 1); end
    step();                                     % discard do
    alts();
    accept(rw.od, 'expected closing ''od''');   % od
    reduce(rule.iteration_doaltsod);
    if TP; TR('iteration', -1); end
  end

  function alts()
    if TP; TR('alts', 1); end
    alt();
    reduce(rule.alts_alt);
    while true
      if tok == rw.COLONCOLON
        step(); alt(); reduce(rule.alts_altsCOLONCOLONalt);    % ::
      else
        break
      end
    end
    if TP; TR('alts', -1); end
  end

  function alt()
    if TP; TR('alt', 1); end
    guard();
    accept(rw.QMARK, 'expected ''?''');          % discard ?
    stmts();
    reduce(rule.alt_guardQMARKstmts);
    if TP; TR('alt', -1); end
  end

  function guard()
    if TP; TR('guard', 1); end
    expr();
    reduce(rule.guard_expr);
    if TP; TR('guard', -1); end
  end

  function assignment()
    if TP; TR('assignment', 1); end
    if tok == rw.COLONEQ                         % starts with := 
      step();                                    % discard 1rst :=
      subprogram();
      accept(rw.COLONEQ, 'expected 2nd '':='''); % discard 2nd :=
      if cfg.ishead(exprSym+NVi, tok)
        exprs();
        reduce(rule.assignment_COLONEQsubprogramCOLONEQexprs); 
      else
        reduce(rule.assignment_COLONEQsubprogramCOLONEQ);
      end
    else                                         % start with var
      vars();
      accept(rw.COLONEQ, 'expected 1rst '':=''');% discard 1rst :=
      if tok == lexed.ID && lookAhead() == rw.COLONEQ
        subprogram();
        accept(rw.COLONEQ, 'expected 2nd '':=''');% discard 2nd :=
        if cfg.ishead(exprSym+NVi, tok)
          exprs();
          reduce(rule.assignment_varsCOLONEQsubprogramCOLONEQexprs); 
         else
          reduce(rule.assignment_varsCOLONEQsubprogramCOLONEQ); 
        end
      else                                       % just assignment
        exprs();
        reduce(rule.assignment_varsCOLONEQexprs);  % v,v := e,e
      end
    end
    if TP; TR('assignment', -1); end
  end

  function vars()                                % v,v,v
    if TP; TR('vars', 1); end
    step();                                      % must be ID
    reduce(rule.vars_id);
    while true
      if tok == rw.COMMA
        step();                                  % discard ,
        accept(lexed.ID, 'expected id on left');
        reduce(rule.vars_varsCOMMAid);
      else
        break
      end
    end
    if TP; TR('vars', -1); end
  end

  function exprs()                               % e,e,e
    if TP; TR('exprs', 1); end
    expr();
    reduce(rule.exprs_expr);
    while true
      if tok == rw.COMMA
        step(); expr(); 
        reduce(rule.exprs_exprsCOMMAexpr);       % discard ,
      else
        break
      end
    end
    if TP; TR('exprs', -1); end
  end

  function subprogram()
    if TP; TR('subprogram', 1); end
    step();                                      % discard identifier
    reduce(rule.subprogram_id);
    if TP; TR('subprogram', -1); end
  end

  function expr()
    if TP; TR('expr', 1); end
    disjunction();
    reduce(rule.expr_disjunction);
    if TP; TR('expr', -1); end
  end

  function disjunction()
    if TP; TR('disjunction', 1); end
    conjunction();
    reduce(rule.disjunction_conjunction);
    while true
      if tok == rw.OR                           % discard |
        step(); conjunction(); 
        reduce(rule.disjunction_disjunctionORconjunction);
      else
        break
      end
    end
    if TP; TR('disjunction', -1); end
  end

  function conjunction()
    if TP; TR('conjunction', 1); end
    negation();
    reduce(rule.conjunction_negation);
    while true
      if tok == rw.AND                           % discard &
        step(); conjunction(); 
        reduce(rule.conjunction_conjunctionANDnegation);
      else
        break
      end
    end
    if TP; TR('conjunction', -1); end
  end

  function negation()
    if TP; TR('negation', 1); end
    if(tok == rw.NOT)
      step(); relation(); reduce(rule.negation_NOTrelation); % discard ~
    else
      relation(); reduce(rule.negation_relation);
    end
    if TP; TR('negation', -1); end
  end

  function relation()
    if TP; TR('relation', 1); end
    sum();
    switch (tok)
    case rw.LT,    step(); sum(); reduce(rule.relation_sumLTsum);
    case rw.LTEQ,  step(); sum(); reduce(rule.relation_sumLTEQsum);
    case rw.EQ,    step(); sum(); reduce(rule.relation_sumEQsum);
    case rw.NOTEQ, step(); sum(); reduce(rule.relation_sumNOTEQsum);
    case rw.GTEQ,  step(); sum(); reduce(rule.relation_sumGTEQsum);
    case rw.GT,    step(); sum(); reduce(rule.relation_sumGTsum);
    otherwise,                    reduce(rule.relation_sum);
    end
    if TP; TR('relation', -1); end
  end

  function sum()
    if TP; TR('sum', 1); end
    if tok == rw.SUB
      step(); term(); reduce(rule.sum_SUBterm);     % discard unary -
    else
      term(); reduce(rule.sum_term);
    end
    while true
      if tok == rw.ADD
        step(); term(); reduce(rule.sum_sumADDterm);       % discard +
      elseif (tok == rw.SUB)
        step(); term(); reduce(rule.sum_sumSUBterm);       % discard -
      else
        break
      end
    end
    if TP; TR('sum', -11); end
  end

  function term()
    if TP; TR('term', 1); end
    factor();
    reduce(rule.term_factor);
    while true
      if tok == rw.MUL
        step(); factor(); reduce(rule.term_termMULfactor);    % discard *
      elseif tok == rw.DIV
        step(); factor(); reduce(rule.term_termDIVfactor);    % discard /
      elseif tok == rw.DIVDIV
        step(); factor(); reduce(rule.term_termDIVDIVfactor); % discard //
      else
        break
      end
    end
    if TP; TR('term', -1); end
  end

% Note that making changes here often requires changes to exprHead.
  function factor()
    if TP; TR('factor', 1); end
    switch tok
    case rw.true,   step(); reduce(rule.factor_true); % discard true
    case rw.false,  step(); reduce(rule.factor_false); % discard false
    case lexed.INT, step(); reduce(rule.factor_integer); % discard int literal
    case lexed.REAL,step(); reduce(rule.factor_real); % discard real literal
    case lexed.ID,  step(); reduce(rule.factor_id); % discard id
    case rw.rand,   step(); reduce(rule.factor_rand);% discard rand
    case rw.b2i,    step(); factor(); reduce(rule.factor_b2ifactor);
    case rw.i2r,    step(); factor(); reduce(rule.factor_i2rfactor);
    case rw.r2i,    step(); factor(); reduce(rule.factor_r2ifactor);
    case rw.LR,     step();                       % discard (
      expr();                                     % parse expr
      accept(rw.RR, 'expected matching '')'''); % discard )
      reduce(rule.factor_LRexprRR);
    otherwise
      reject('expected one of ''true'', ID, ''('', ''rand'', ''b2i'' ...', tok);
    end
    if TP; TR('factor', -1); end
  end

  % ---------------input and output processors----------------
  function step()
    if tp ~= 0, shift(tp); end                   % shift old tok
    tp = tp + 1;
    while true                                   % looking for non-white
      if tp > toklim                             % manufacture EOF
        tok = lexed.EOF;
        break;
      end
      tok = toks(tp);                            % next tok
      switch tok
        case lexed.WHT,  tp=tp+1;                % skip
        case lexed.CMNT, tp=tp+1;                % skip
        case 0, reject('undefined token'); 
        otherwise, break;                        % stop discard loop
      end % of switch
    end % of loop
  end % of step()

  function la = lookAhead()                      % look ahead 1
    savesrp = srp;
    savetp = tp;
    savetok = tok;
    step();
    la = tok;
    srp = savesrp;
    tp = savetp;
    tok = savetok;    
  end

  % action routines
  function shift(t)
    if TP
      TR(['shift token(' num2str(t), ') ', src(st(t):en(t))]);
    end
    if srp >= numel(shiftReduce); shiftReduce(end+end)=0; end
    shiftReduce(srp) = t;                        % + for tokens
    srp = srp + 1;                               % next avail
  end

  function reduce(rno)
    if TP
      TR(['reduce rule(' num2str(rno), ') ', rnm{rno}]);
    end
    if srp >= numel(shiftReduce); shiftReduce(end+end)=0; end
    shiftReduce(srp) = -rno;                     % - for rules
    srp = srp + 1;                               % next avail
  end

  function reject(msg, got)
    [ln,cl] = lexed.lineCol(st(tp));
    txt = '';
    if nargin > 1
      if got <= numel(cfg.reserved)
        txt = cfg.reserved{got};
      end
      switch got
        case lexed.ID
          txt = 'ID';
        case lexed.INT
          txt = 'INT';
        case lexed.REAL
          txt = 'REAL';
        case lexed.EOF
          txt = 'EOF';
      end
      res = sprintf('%s, got ''%s'', at line %d col %d', msg, txt, ln, cl);
    else
      res = sprintf('%s at line %d col %d', msg, ln, cl);
    end
    error(['Parser: ' res]);
  end

  function accept(t, msg)
    if t ~= tok
      if tok ~= 0
        reject(msg, tok)
      else
        reject(msg)
      end
    end
    step();
  end

  % ----------------- utilities ---------------------
  
  function n = getCt()
    n = srp-1;
  end

  function dump()                               % dump
    disp 'Parser: ------- start shift/reduce dump-------------'
    for j=1:getCt()
      r = shiftReduce(j);
      if r <= 0
        fprintf('Parser: rule %s\n', rnm{-r});
      else
        fprintf('Parser: token %s\n', src(st(r):en(r)));
      end
    end
    disp 'Parser: ------- end   shift/reduce dump-------------'
  end

  % trace routines
  function TR(msg, t)
    if nargin == 1; t = 0; end
    if t == -1; lvl.out(); msg = ['leave ' msg];
    elseif t == 1;  msg = ['enter ' msg]; 
    end
    fprintf('Parser:   %s%s\n', lvl.val(), msg);
    if t == 1; lvl.in(); end
  end

  % -------- public methods and values -------------------
  function o = public
    o           = struct;
    o.lexed     = lexed;                         % pass it along
    o.lim       = getCt();
    o.sr        = shiftReduce;
    o.nullRules = nullRules;
    o.dump      = @dump;
  end

end % of parser
