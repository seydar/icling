% FILE:     Cfg.m
% PURPOSE:  build cfg tables, including LR(1) tables
% USAGE:    g = Cfg(cfgtext, flags);
%           g.xxx for methods and fields xxx.
% EXAMPLE:  
%  g = Cfg(xread('X.cfg'), {'-noLR'}); 
%  g.dump()             % dump the grammar
%  usedchrs = g.opchar  % the characters actually used in operators
%
% METHOD:   See Aho,Sethi,Ullman, or Knuth Info&Control 1965
%
% FLAGS
%   -noLR           skip the LR(1) checking and table building
%   -cfgTrace       trace the internal steps of LR1
%   -cfgDump        dump the cfg
%   -erasureDump    dump the erasing symbols
%   -headDump       dump the head symbols
%   -mainTrace      trace the LR1 main loop
%   -closureTrace   trace the LR1 closure computation
%   -shiftTrace     trace the LR1 shift computation
%   -reduceTrace    trace the LR1 reduce computation
%   -shiftDump      dump the LR1 shifts
%   -reduceDump     dump the LR1 reductions
%   -lrDump         dump the LR1 table
%
% grammar textual format:
%  ' ', EOL and EOF are the only textual grammar delimiters. 
%  Phrase names are identifiers on the LHS of a rule 
%  Everything else is an input symbol.
% SEE ALSO: str2cfg.m, erasingSymbols.m headSymbols.m

% COPYRIGHT W.M.McKeeman 2007.  You may do anything you like with 
% this file except remove or modify this copyright.
% MODS:     2007.04.01 -- mckeeman@dartmouth.edu -- original
%           2007.11.19 -- mckeeman@dartmouth.edu -- incorporated LR(1)
% grammar internal format
%  The grammar is <Vi, Vn, Vg, R>
%  A symbol is represented by its index in V{}.
%  A set of symbols is represented by a logical vector indexing V.
%  In particular, lookahead is always a set.
%  A rule is represented by a vector r of indices into V.
%    V(r(1)) is the lhs
%    V(r(2:end)) is the rhs
%    R{} is the list of rules r
%    Vi is the input symbols
%    Vn is the phase name symbols
%    pn is true if the symbol is a phase name
%    goal = R{1}(1); it is in Vn
%    er is true for symbols that erase
%    hd(n,t) means t is a head of n
%
%  Output is the cfg object, including
%  shift/reduce matrix lr.
%  lr(in state,see symbol) =
%     newstate (shift)
%     -rule    (reduce)
%     0        (error)
%  applying rule -1 after consuming all input means a successful parse.
%
% program organization
%  block of initialized uplevel variables (locals of level 1) 
%  nested function accessing the uplevel variables 
%
%    dumpers
%   
% See *.cfg

  function cfgobj = Cfg(grtxt, flags)

  traceF    = 1;  cfgF     = 2; 
  shiftF    = 3;  reduceF  = 4;
  lrF       = 5;  noLRF    = 6;
  maxF      = 7;

  if nargin == 1; flags = {}; end
  flag = flagger(flags);                         % flag settings
  cfgTrace('enter Cfg');
  
  makeId = idCtor();                             % id constructor factory
  
  % grammar input and internalization
  cfg = str2cfg(grtxt);                          % make internal cfg
  
  V = cfg.V;                                     % grammar internals
  NV = numel(V);
  Vi = cfg.Vi;
  Vn = cfg.Vn;
  pn = cfg.pn;
  R  = cfg.R;
  NR = numel(R);
  er = erasingSymbols(cfg);
  hd = headSymbols(cfg);
  reservedTable = cfg.reservedTable;
  opchar = cfg.opchar;
  
  if flag(cfgF); dumpGrammar(); end              % perhaps print grammar

  if ~flag(noLRF)      % it takes awhile to make tables for X.cfg
    if NR > 10
      fprintf('Cfg: LR1 tables take awhile: be patient\n');
    end
    lrobj = LR1(cfg, flags);
    if flag(shiftF), lrobj.dumpShift(); end
    if flag(reduceF), lrobj.dumpReduce(); end
    if flag(lrF), lrobj.dumpLR(); end
  else
    lrobj = struct;                              % forget it
    lrobj.lr = zeros(1,0,'int16');
  end
  
  cfgobj = public();
  
  cfgTrace('leave Cfg');
  return;                                        % end Cfg executable

  % --------------------- nested functions --------------------
  % flag processing, mostly to control dumpers & tracing
  function res = flagger(flags)
    res = false(1,maxF);
    for f=1:numel(flags)
      switch flags{f}
        case '-noLR',         res(noLRF)     = true;
        case '-cfgTrace',     res(traceF)    = true;
        case '-cfgDump',      res(cfgF)      = true;
        case '-shiftDump',    res(shiftF)    = true;
        case '-reduceDump',   res(reduceF)   = true;
        case '-lrDump',       res(lrF)       = true;
      end
    end
  end  % of flagger

  % ------------------ grammar tables ----------------------------
  function rn = ruleNames()                      % make legal id
    rn = cell(numel(R),1);                       % preallocate
    for i=1:numel(R)
      rule = R{i};                               % which rule
      rn{i} = makeId.str2id([V{rule(1)} '_' V{rule(2:end)}]);
    end
  end  % of ruleNames

  function rl = ruleLengths()
    rl = zeros(numel(R),1, 'int16');             % preallocate
    for i=1:numel(R) 
      rl(i) = numel(R{i})-1;
    end
  end  % of ruleLengths

  function res = reserved()
    res = reservedTable;
  end

  % ------------------- dumpers -----------------------
  
  function cfgTrace(msg)                          % trace major functions
    if ~flag(traceF); return; end
    disp(msg);
  end   % of cfgTrace

  function dumpGrammar()                         % perhaps print V, Vn & Vi
    disp '---grammar vocabulary---'
    fprintf('%d symbols\n', NV);
    fprintf('%s ', V{:}); fprintf('\n');
    disp '---input vocabulary---'
    fprintf('%s ', Vi{:}); fprintf('\n');
    disp '---phrase name vocabulary---'
    fprintf('%s ', Vn{:}); fprintf('\n');
    fprintf('%d grammar rules\n', NR);
    for rn=1:NR
      fprintf('%s ', V{R{rn}}); fprintf('\n');
    end
  end   % of dumpGrammar

  function dumpErasure()
    disp '---erasing symbols---'
    t = V(er);
    fprintf('%s ', t{:}); fprintf('\n');
  end    % of dumpErasure

  function dumpHeads()
    disp '---head symbols---'
    for i=1:numel(V)
      fprintf('%s:\t', V{i});
      fprintf('%s ', V{hd(i,:)}); 
      fprintf('\n');
    end
  end   % of dumpHeads

  function dumpShift()
    lrobj.dumpShift();
  end

  function dumpReduce()
    lrobj.dumpReduce();
  end

  function dumpLR()
    lrobj.dumpLR();
  end

  function o = public()
    o    = struct;                               % the results
    o.Vn = Vn;
    o.Vi = Vi;
    o.V  = V;
    o.R  = R;
    o.pn = pn;
    o.lr = lrobj.lr;
    o.ruleNames   = ruleNames();
    o.ruleNumbers = enum(o.ruleNames);
    o.ruleLengths = ruleLengths();
    o.reserved    = reserved();
    o.opchar      = opchar;
    o.ishead      = hd;
    o.dumpHeads   = @dumpHeads;
    o.dumpErasure = @dumpErasure;
    o.dumpShift   = @dumpShift;
    o.dumpReduce  = @dumpReduce;
    o.dumpLR      = @dumpLR;
    o.dump        = @dumpGrammar;
  end

end  % of Cfg

