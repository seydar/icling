% FILE:     LR1.m
% PURPOSE:  build LR(1) tables
% USAGE:    >> LR1(cfg, flags)
% METHOD:   See Aho,Sethi,Ullman, or Knuth Info&Control 1965
%
% FLAGS
%   -mainTrace      trace the actions of the outer loop
%   -closureTrace   trace makeClosure actions
%   -shiftTrace     trace computing of shifts
%   -reduceTrace    trace computing of reductions
% The flags trace the computations.  They were used during development.
% EXAMPLE:
%   cfg = Cfg(xread('E.cfg'));
%   lrobj = LR1(cfg);
%   lrobj.dumpLR()

% COPYRIGHT W.M.McKeeman 2006.  You may do anything you like with 
% this file except remove or modify this copyright.
% MODS:     2007.04.01 -- mckeeman@dartmouth.edu -- original
%           2008.04.30 -- mckeeman@dartmouth.edu -- complete rewrite
% SEQUENCE OF EVENTS:
% Starting with a cell array containing only the start state
% alternate closure and transitions filling the cell array
% with all the kernel states of the LR(1) machine.
% Each rule can be marked from position 1 to beyond the end of the rule.
% Each marked rule is a rule, mark and lookahead.
% Each kernel state is a set (array) of marked rules.
% The closure is useful only while computing the transitions.
% The reduce actions are computed from the closures.
% Finally check for shift/reduce conflicts.

function obj = LR1(cfg, flags)
  V  = cfg.V;                                    % the vocabulary
  NV = numel(cfg.V);                             % number of symbols
  pn = cfg.pn;                                   % phrase names
  R  = cfg.R;                                    % the cfg rules
  EOL = 10;                                      % ascii ctrl-j
  
  if nargin == 1, flags = {}; end
  [traceMain,traceClosure,traceShift,traceReduce] = flagger(flags);
  
  % grammar properties
  er = erasingSymbols(cfg);                      % s erasable if er(s)
  hd = headSymbols(cfg);                         % heads of s are V(hd(s,:))
  firstR = starts(R);                            % first rule in R
  
  % the matrices of shift/reduce actions (they will acquire rows)
  shift  = zeros(1, NV, 'int16');
  reduce = zeros(1, NV, 'int16'); 
  
  % MAIN LOOP
  % Start with single kernel containing goal rule.
  % Alternate completion/transition computations, adding kernels.
  kernels = {makeItem(1, 1, false(1,NV))};       % rule 1, no lookahead
  currentTarget = 1;
  while currentTarget <= numel(kernels)          % until no new ones
    currentState = kernels{currentTarget};       % pick next state
    closure = makeClosure(currentState);         % close it
    
    makeReduction(currentTarget, closure);       % record reductions
    
    txs = makeTransitions(closure);              % get shift transitions
    for ti=1:numel(txs)
      dest = 0;                                  % eventual goto state 
      for ki=1:numel(kernels)
        if sameState(txs{ti}, kernels{ki})       % already there
          dest = ki;                             % remember destination
          break;
        end
      end
      if dest == 0                               % not found
        kernels{end+1} = txs{ti};                %#ok<AGROW> add to kernels
        dest = numel(kernels);
      end
      dot = txs{ti}(1).k;                        % mark position
      rule = txs{ti}(1).r;                       % rule
      see = R{rule}(dot);                        % shifted symbol
      TRM(sprintf('in state %d see %s goto %d', ...
        currentTarget, V{see}, dest));
      shift(currentTarget, see) = dest;          % record shift
    end
    currentTarget = currentTarget + 1;           % ready for next target
  end

  checkSRconflicts();                            % look for s/r errors
  
  obj = public();                                % return object
          
  return;  % end of ctor
  
  %--------------------methods---------------------
  
  % flag processing
  function [m,c,s,r] = flagger(flgs)
    m=0; c=0; s=0; r=0;
    for i=1:numel(flgs)
      switch flgs{i}
        case '-mainTrace',    m = true;
        case '-closureTrace', c = true;
        case '-shiftTrace',   s = true;
        case '-reduceTrace',  r = true;
      end
    end
  end

  % Record first definition for each phrase name defined in R.
  % This is here only to make lookups faster.
  % R{st(sym)}(1) == sym
  function st = starts(R)
    st = zeros(1, NV, 'int16');
    for i=numel(R):-1:1; st(R{i}(1)) = i; end
  end

  % An item is a rule, mark and lookahead.
  % [lhs rhs] vector is R{mr.r}
  %   lhs  r0
  %   rhs     r1 r2 r3 ... rn
  % mark k is to the left of rk (thus in range 1:n+1)
  function item = makeItem(rule, mark, lookahead)
    item = struct('r', rule, 'k', mark, 'la', lookahead);
  end

  % Given some kernel state,
  % add rules for phrase names to the right of the mark,
  % carrying along the lookahead.
  % Added rules are always marked at left end
  % data format:   state{item, item, item, ...}
  % data format:   item(mr, mr, mr...)
  function closure = makeClosure(state)
    TRC('enter');
    TRC(['input:', EOL, stateText(state)]);
    currentItem = 0;                             % no items yet
    while currentItem < numel(state)             % look at each item
      currentItem = currentItem + 1;             % ready for next item
      mr = state(currentItem);                   % state = marked rules
      TRC(['process ', itemText(mr)]);
      v = R{mr.r};                               % [lhs rhs] vector
      if mr.k >= numel(v); continue; end;        % off end of rule
      sym = v(mr.k+1);                           % get sym right of mark
      if ~pn(sym); continue; end;                % not phrase name
      la = lookahead(v, mr.k+1, mr.la);          % new lookahead
      
      % phrase name to right of mark, need to add new marked rules
      TRC(['adding rules for ', V{sym}]);
      for i=firstR(sym):numel(R)                 % just look at defs of sym
        if R{i}(1) ~= sym; break; end            % passed last def of sym
        newmr = makeItem(i, 1, la);              % new item m arked left
        dup = false;
        for j=1:numel(state)                     % look through state
          %if sameItem(newmr, state(j))   (inlined for speed)
          if i==state(j).r && 1==state(j).k && all(la==state(j).la)
            dup = true;                          % already in state
            break;                               % ready to move la up
          end
        end
        if ~dup                                  % new, have to add
          state(end+1) = newmr;                  % add new item
          TRC(['added   ' itemText(newmr)]);
        end
      end
    end
      
    % Marked rules were entered above without regard to lookahead;
    % a particular marked rule may appear more than once.
    % If the last marked rule in the list is a duplicate, 
    % merge its lookahead forward and delete the last marked rule.
    TRC('merging lookaheads');
    for i = numel(state) : -1 : 2
      late = state(i);
      merged = false;
      for j = i-1 : -1 : 1
        early = state(j);
        if late.r==early.r && late.k==early.k
          state(j).la = early.la | late.la;    % merge lookaheads
          merged = true;
          TRC(['merged: ' V{early.la} ' : ' V{late.la} EOL]);
          break;
        end
      end
      if merged
        state(i) = [];                         % delete redundant state
      end
    end

    closure = state;
    TRC(['output:' EOL, stateText(closure)]);
    TRC('leave');
  end

  % lookahead one symbol beyond mark k
  function la = lookahead(v, k, outerla)         % v = [lhs rhs]
    la   = false(1,NV);                          % no lookahead yet
    % gather heads until something is non eraseable
    for q=k+1:numel(v)                           % remaining rhs
      la = la | hd(v(q),:);                      % head symbols
      if ~er(v(q)); return; end                  % not eraseable
    end
    la = la | outerla;                           % add whole-rule la
  end

  % given the closure of a state, compute the transition states
  function txs = makeTransitions(closure)
    TRT('enter');
    txs = {};
    for i = 1:NV                                 % possible transition sym
      tr    = closure;                           % get state type
      tr(:) = [];                                % empty array of states
      for j=1:numel(closure)                     % look at items
        it = closure(j);                         % an item
        v  = R{it.r};                            % [lhs rhs]
        if it.k >= numel(v); continue; end       % off end of rule
        if R{it.r}(it.k+1) == i                  % marked symbol 
          it.k = it.k+1;                         % move mark right
          tr(end+1) = it;                        % collect shifts
        end
        tr = sortItems(tr);                      % canonical order
      end
      if numel(tr) > 0                           % collect transitions
        txs{end+1} = tr; 
        TRT(stateText(tr));
      end; 
    end
    TRT('leave');
  end

  % Put items in order for set insertion comparisons.
  % Sort on r, then m.
  function tr = sortItems(tr)
    for i=1:numel(tr)
      for j=i:numel(tr)
        if tr(i).r < tr(j).r; continue; end
        if tr(i).r == tr(j).r && tr(i).k < tr(j).k; continue; end  
        x = tr(j); tr(j) = tr(i); tr(i) = x;     % exchange
      end
    end
  end

  % check for transition state already existing (now inlined)
  %function res = sameItem(mr1, mr2)
  %  res = mr1.r==mr2.r && mr1.k==mr2.k && all(mr1.la==mr2.la);
  %end

  % Already sorted, need only check corresponding items.
  function res = sameState(s1, s2)
    res = false;                                 % pessimistic
    if numel(s1) ~= numel(s2); return; end;
    for i=1:numel(s1)
       %if ~sameItem(s1(i), s2(i)); return; end  250 sec w/o inline
       if s1(i).r~=s2(i).r || s1(i).k~=s2(i).k || any(s1(i).la~=s2(i).la)
         return;
       end
    end
    res = true;                                  % identical
  end

  % Look at a state for reduction rules.
  function makeReduction(idx, state) 
    red = zeros(1,0, 'int16');                   % no reductions yet
    for j=1:numel(state)                         % look through state
      mr = state(j);                             % marked rule
      if mr.k == numel(R{mr.r})                  % a reduce
        red = [red, j];                          % list of reduces
        if any(mr.la)
          reduce(idx, mr.la) = mr.r;             % record reduce
        else                                     % only final reduce
          reduce(idx, :) = mr.r;                 % final state
        end
        TRR([markedRuleText(mr), '   la: ', laText(mr.la)]);
      end
    end
    
    % If there is more than one reduce, there may be rr conflicts.
    rr = zeros(0,0,'int16');                     % no conflicts yet
    if numel(red) > 1                            % more than one reduce
      for j=1:numel(red)-1                       % look at pairs
        mr1 = state(red(j));                     % first marked rule
        la1 = mr1.la;                            % lookahead set 1
        for k=2:numel(red)
          mr2 = state(red(k));                   % second marked rule
          la2 = mr2.la;                          % lookahead set 2
          conflict = la1&la2;                    % must be disjoint
          if any(conflict)                       % rr error
            rr = [rr; [j, k]];                   % record the bad pair
          end
        end
      end
    end

    % Report rr errors (if any).
    if numel(rr) > 0
      for j=1:size(rr,1)
        err = rr(j,:);
        mr1 = state(err(1));
        mr2 = state(err(2));
        ms1 = itemText(mr1);
        ms2 = itemText(mr2);
        reduce(idx, mr1.la&mr2.la) = 999;        % record bad spot
        rrErr(sprintf('%s\n%s', ms1, ms2));
      end
    end
  end

  function checkSRconflicts()
    if numel(shift)<numel(reduce)
      shift(size(reduce,1),1) = 0;               % match reduce matrix
    elseif numel(reduce)<numel(shift)
      reduce(size(shift,1),1) = 0;
    end
    c = shift~=0 & reduce~=0;                    % must be disjoint
    if any(c(:))
      [inst, insym] = find(c);
      for i=1:numel(inst)
        shift(inst(i), insym(i)) = 999;
        srErr(sprintf('%s\n',stateText(kernels{inst(i)})));
      end
    end
  end
  % -------------------- utilities -----------------
  
  function dumpShift()
    fprintf('start %dx%d LR(1) shift matrix---\n', size(shift));
    fprintf('V: ');
    fprintf('%s ', V{:});
    fprintf('\n');
    fprintf('states  ');
    for i=1:numel(V)
      pn = [V{i} '   '];
      fprintf('%4s', pn(1:3));
    end
    fprintf('\n');
    for i=1:size(shift,1)
      fprintf('%3d:  ', i);
      fprintf('%4d', shift(i,:));
    fprintf('\n');
    end
    disp 'end   shift matrix---'
  end  % of dumpShift

  function dumpReduce()
    fprintf('start %dx%d LR(1) reduce matrix---\n', size(reduce));
    fprintf('V: ');
    fprintf('%s ', V{:});
    fprintf('\n');
    fprintf('states  ');
    for i=1:numel(V)
        pn = [V{i} '   '];
        fprintf('%4s', pn(1:3));
    end
    fprintf('\n');
    for i=1:size(reduce,1)
      fprintf('%3d:  ', i);
      fprintf('%4d', reduce(i,:));
      fprintf('\n');
    end
    disp 'end   reduce matrix---'
  end  % of dumpReduce

  function dumpLR()
    fprintf('start %dx%d LR(1) matrix---\n', size(reduce));
    fprintf('V: ');
    fprintf('%s ', V{:});
    fprintf('\n');
    fprintf('states  ');
    for i=1:numel(V)
        pn = [V{i} '   '];
        fprintf('%4s', pn(1:3));
    end
    fprintf('\n');
    lr = shift-reduce;
    for i=1:size(lr,1)
      fprintf('%3d:  ', i);
      fprintf('%4d', lr(i,:));
      fprintf('\n');
    end
    disp 'end   LR(1) matrix---'
  end  % of dumpLR

  % output is text form of marked rule
  function txt = markedRuleText(mr)
    v = R{mr.r};
    txt = [V{v(1)} ' ='];
    if mr.k==1; txt = [txt '.']; else txt = [txt ' ']; end
    for i=2:numel(v)
      if i == mr.k; sep = '.'; else sep = ' '; end
      txt = [txt, V{v(i)}, sep];
    end
  end

  % la is the lookahead boolean, txt is the list of symbols
  function txt = laText(la) 
    las = {V{la}};
    txt = sprintf('%s ', las{:});
  end

  % text form of marked rule mr
  function txt = itemText(mr)
    txt = '    item: ';
    txt = [txt, markedRuleText(mr)];
    txt = [txt, sprintf('    la: %s', laText(mr.la))];
  end

  % text form of state s  
  % s = {item, item, item... }
  function txt = stateText(s)
    txt = ['  state:' EOL];
    for k=1:numel(s)
      txt = [txt, itemText(s(k)), EOL];
    end
    txt = [txt, '------------------' EOL];
  end

  % report shift/reduce error
  function srErr(msg)
    fprintf('sr error:\n%s\n', msg);
  end

  % report reduce/reduce error
  function rrErr(msg)
    fprintf('rr error:\n%s\n', msg);
  end

  %------------------ trace functions -----------------
  
  function TRR(msg)                              % trace
    if traceReduce; TR(['makeReduction: ' msg]); end
  end

  function TRT(msg)                              % trace
    if traceShift; TR(['makeTransitions: ' msg]); end
  end

  function TRC(msg)                              % trace
    if traceClosure; TR(['makeClosure: ' msg]); end
  end

  function TRM(msg)                              % trace
    if traceMain; TR(['main loop: ' msg]); end
  end

  function TR(msg)
    fprintf('makeLR: %s\n', msg);
  end

  function o = public()
    o = struct;
    o.er = er;
    o.hd = hd;
    o.lr = shift-reduce;
    o.dumpShift  = @dumpShift;
    o.dumpReduce = @dumpReduce;
    o.dumpLR     = @dumpLR;
  end
end % of makeLR