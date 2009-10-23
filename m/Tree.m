% FILE:     Tree.m
% PURPOSE:  tree builder/walker
% TEST:     testTree.m
%
% OVERVIEW:
%   The shift/reduce sequence provided by Parser.m is turned into a syntax
%   tree or abstract syntax tree (AST) with leaves corresponding to the 
%   input tokens and nodes corresponding to the phrase names of X.cfg. 
%
% USAGE:  tr = Tree(parsed)                  % construct tree object
%         tr = Tree(parsed, {'-treeTrace'})  % also trace tree building
%
%   Node access primitives are provided for the tree consumers. The pattern
%   is decoded to enable the walkers to make node/leaf choices without
%   depending on information about specific rules from the grammar.
%   Example:
%         n = tr.getKid(tr.getRoot(), 1)
%   gets the leftmost node of the syntax tree root.
%         tr.dump()
%   displays the entire tree in the MATLAB command window.
% EXAMPLE:
%   cfg = Cfg(xread('X.cfg'), {'-noLR'});
%   lexed = Lexer(cfg, 'x:=13789');
%   parseobj = Parser(lexed);
%   tr = Tree(parseobj);
%   tr.dump();

% COPYRIGHT W.M.McKeeman 2006.  You may do anything you like with 
% this file except remove or modify this copyright.
% IMPLEMENTATION:
%   The tree nodes are built from the S/R sequence in a systematic manner.
%   Each rule has a width which allows the builder to pop the correct
%   number of nodes from the stack.
%
%   The layout in tree-memory of a node is:
%
%     +---------------------------------------+
%     | kid 3 | kid 2 | kid 1 |  pat  | rule  |
%     +---------------------------------------+
%
%   As the S/R info is processed, the nodes are stacked bottom-up, so that
%   when a new node is constructed, the right-end is on the top of the
%   stack, and goes into tree-memory first.  
%
function obj = Tree(parsed, flags)               % a tree ctor

  assert(isstruct(parsed), ...
    'input parsed must be type struct but is %s\n', class(parsed));
  %  ---------- persistent fields of tree object ---------------
  none = uint32(0);                              % NONE
  node = none+1;                                 % NODE
  leaf = node+1;                                 % LEAF
  opaq = leaf+1;                                 % OPAQ
  
  tr    = zeros(1, 0, 'uint32');                 % empty tree
  tp = 1;                                        % next avail tr slot
  stack = zeros(1, 0, 'int32');                  % indices
  kind  = zeros(1, 0, 'uint32');                 % node or leaf
  sp = 1;                                        % next avail stack slot

  sr     = parsed.sr;                            % coded s/r sequence
  ignore = parsed.nullRules;                     % to leave out of AST
  ct     = parsed.lim;
  lexed  = parsed.lexed;                         % the lexer
  src    = lexed.src;
  cfg    = lexed.cfg;
  st     = lexed.start;
  en     = lexed.finish;
  rn     = cfg.ruleNames;                        % name of each rule
  len    = cfg.ruleLengths;                      % length of each rule
  TT = nargin > 1 && findFlag('-treeTrace', flags);  
  build();                                       % fill tree
  obj = public();
  
  return;                                        % end executable
  
  % --------------------- nested functions --------------------
      
  function build()                               % populate syntax tree
    if TT; TR('---enter tree build'); end
    for srp = 1:ct                               % bottom-up walk
      a = sr(srp);                               % get s or r
      if a > 0                                   % shift
        shift(a)                                 % push onto stack
      else                                       % reduce
        reduce(-a);                              % pop stack
      end
    end  
    if TT; TR('---leave tree build'); end
  end
    
  % ---- builder helper functions -----------------
  function shift(t)
    if TT; TR(['shift ' src(st(t):en(t))]); end
    kind(sp) = leaf;
    pushNode(t);
  end

  function reduce(r)
    if ignore(r); return; end                    % skipped for AST
    width = len(r);                              % len of rhs
    pat = uint32(0);                             % new pattern
    for w=1:width                                % place rhs
      putTree(topNode());                        % stack to Tree 
      k = topKind();                             % N or L
      popNode();                                 % done with it
      pat = bitor(bitshift(pat,2),k);            % N/L pattern
    end
    putTree(pat);                                % (N|L)*
    putTree(r);                                  % node name
    if TT, getText(tp-1); end                    % watch build
    kind(sp) = node;                             % result on stack
    pushNode(tp-1);                              % where it is in Tree
  end

  function putTree(t)
    tr(tp) = t; 
    tp = tp+1;                                   % next avail
  end

  function pushNode(t)
    stack(sp) = t;
    sp = sp + 1;                                 % next avail
  end

  function popNode()
    sp = sp - 1;                                 % discard
  end

  function r = topNode()
    r = stack(sp-1);                             % examine stack
  end

  function r = topKind()
    r = kind(sp-1);                              % examine kind
  end

  function res = getText(n)                      % for diagnostics
    a = getPat(n);
    res = sprintf('%5d: r=%2d [ ', n, getRule(n));
    i = 1;
    pa = '';
    while (a ~= 0)
      kid = getKid(n,i);
      if bitand(a,3) == node
        pa = [pa 'N'];
        txt = rn{getRule(kid)};
        res = [res sprintf('N(%d)=%s  ', kid, txt)];
      else
        pa = [pa 'L'];
        txt = getLeaf(kid);
        res = [res sprintf('L(%d)=%s  ', kid, txt)];
      end
      a = bitshift(a, -2);
      i = i + 1;
    end
    res = [res sprintf('pat=%s ]', pa)];
  end

  function [line, col] = getLineCol(nd)          % returns token location
    a = getPat(nd);                              % Node Leaf pattern
    if (a ~= 0)                                  % has to be non-null
      kid = getKid(nd,1);
      if bitand(a,3) == node                     % look for token
        [line, col] = getLineCol(kid);           % recur
      else
        [line, col] = lexed.lineCol(st(kid));
      end
    else
      treeErr('invalid node');
    end
  end

  function [line, col] = runLineCol(tok)         % returns token location
    [line, col] = lexed.lineCol(st(tok));
  end

  % ------------- utilities ---------------------
  
  function dump()                                % dump
    disp('Tree:  -------- start dump----------');
    n = getRoot();                               % start at root
    while n > 0
      fprintf('%s\n', getText(n));
      n = n - getWidth(n) - 2;
    end
    disp('Tree:  -------- end   dump----------');
  end

  function TR(msg)                               % simple trace
    fprintf('%s\n', msg);
  end

  function treeErr(msg)
    error(['Tree: ' msg]);
  end

  % -------------- Tree walkers ------------------------
  
  function n = getRoot()                         % returns NODE
    n = numel(tr);
  end

  function r = getRule(n)                        % returns rule number
    r = tr(n);
  end

  function p = getPat(n)                         % returns N/L info
    p = tr(n-1);
  end

  function w = getWidth(n)                       % width of node
    p = getPat(n);
    w = 0;
    while p ~= 0
      w = w + 1;
      p = bitshift(p,-2);
    end
  end

  function n = getKid(n, p)                      % returns NODE
    n = tr(n-p-1);
  end

  function txt = getLeaf(tp)                     % returns token txt
    txt = src(st(tp):en(tp));
  end

  % -------------- public methods and values --------------
  function o = public()
    o = struct;                                 % object to return
    % static fields
    o.NONE       = none;
    o.NODE       = node;
    o.LEAF       = leaf;
    o.OPAQ       = opaq;
    o.parsed     = parsed;                      % pass on
    
    o.getRoot    = @getRoot;                    % node
    o.getRule    = @getRule;                    % rule
    o.getPat     = @getPat;                     % N|L packing
    o.getWidth   = @getWidth;                   % node width
    o.getKid     = @getKid;                     % node
    o.getLeaf    = @getLeaf;                    % token
    o.getLineCol = @getLineCol;                 % token line/col
    o.runLineCol = @runLineCol;                 % run token line/col
    o.getText    = @getText;                    % text form of node
    o.dump       = @dump;                       % dump entire tree
  end

end

