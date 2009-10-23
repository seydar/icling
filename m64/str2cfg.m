% FILE:  str2cfg.m
% PURPOSE: convert string rep of cfg to cfg components
% USAGE:  obj = str2cfg(cfgtxt)
% EXAMPLE:
%    o = str2cfg(xread('X.cfg'));   % constructor
%    o.Vi                           % input vocabulary
%    o.Vn                           % phrase names
%
% METHOD:
% Context-free grammar internalization.
%   input text is a string.
%   # in column 1 is a comment
%   blank in column1 starts rhs
%   otherwise, line is lhs
%   analyze and record rules.  
%   accumulate V.  
%   separate V and Vn. 
% a -> bbb represented by [a b b b] in R
% SEE ALSO:  cfg.m, makeCfg.m

% COPYRIGHT W.M.McKeeman 2006.  You may do anything you like with 
% this file except remove or modify this copyright.

function obj = str2cfg(text)                     % whole grammar
  
  EOL = 10;                                      % eol char code
  C_M = 13;                                      % PC EOL marker
  text = text(text~=C_M);                        % clean them out
  R = {};
  ends = find(text==EOL);                        % all eols
  strt = [0, ends(1:end-1)]+1;                   % starts of lines      
  V = {};                                        % no symbols yet
  NV = int16(0);
  Vn = {};                                       % phrase names
  pn = logical([]);                              % true for phrase names
  reservedTable = {};
  opchar = '';
  Vi = {};                                       % input symbols
  R = {};                                        % no rules yet

  for ie = 1:numel(strt)                         % each line
    ln = text(strt(ie):ends(ie));                % grab line
    % empty rhs, force leading blank
    if ln == EOL; ln = [' ' ln]; end;            %#ok<AGROW> 
    if ln(1) == '#'; continue; end;              % cfg comment line
    if ln(1) ~= ' '                              % new lhs
      lhs = strtok(ln);                          % discard trailing blanks
      r0 = enterV(lhs);                          % it is a symbol
    else                                         % new rhs
      ru = zeros(1,0,'int16');                   % empty rhs
      while true                                 % look at rhs
        [rs, ln] = strtok(ln);                   %#ok next deblanked sym
        if isempty(rs); break; end               % done w/this rule
        ru(end+1) = enterV(rs);                  %#ok it is a symbol
      end
      R{end+1} = [r0, ru];                       %#ok add rule to grammar
    end
  end
  NR = numel(R);                                 % number of rules

  % separate inputs from phrase names
  pn = false(1,NV);                              % assume all input
  for g=1:NR                                     % get phase names
    r = R{g};                                    % g^th rule
    pn(r(1)) = true;                             % on lhs
  end
  Vi = sort(V(~pn));                             % V = [Vi, Vn]
  Vn = sort(V(pn));

  % standardize symbol numbering
  %   inputs first
  %   phrase names last
  %   both groups sorted
  % First prepend a non-ascii character to each member of V
  % so that the inputs sort earlier than the phrase names.
  % Then used the permutation vector to remap all the data in the
  % rules that was entered before V was sorted.
  % From this point on the LR generation uses the canonical (sorted)
  % numbering.  This is the same ordering used in the lexer.

  for ix = 1:NV
    V{ix} = [uint16(pn(ix)), V{ix}];             %#ok prepend sort flag
  end
  [V, idx] = sort(V);                            % in desired order
  for ix = 1:NV
    V{ix} = V{ix}(2:end);                        % remove sort flag
  end
  tx(idx) = 1:NV;                                % old to new
  for g=1:NR
    R{g} = tx(R{g});                             %#ok rules updated
  end

  % separate input symbols from phrase names again
  pn = false(1,NV);                              % assume all terminal
  for g=1:NR                                     % get nonterminals
    r = R{g};                                    % g^th rule
    pn(r(1)) = true;                             % on lhs
  end

      % rename id, integer, real and eof (they are not reserved)
  for i=1:numel(Vi)
    switch Vi{i}
      case {'id', 'integer', 'real', 'eof'};
        resname = [' ' Vi{i}];
      otherwise
        resname = Vi{i};
    end
    reservedTable{end+1} = resname;              %#ok record reserved
  end

  % Tabulate all characters that are to be allowed in operator
  % identifiers.  
  opchar = unique([reservedTable{:}]);           % all chrs in grammar
  % disallow letters, digits, and white space
  opchar = opchar(~(isstrprop(opchar, 'alphanum')...
                   |isstrprop(opchar, 'wspace')));
  opchar(opchar == '(') = [];                    % disallow seps 
  opchar(opchar == ')') = [];
  opchar(opchar == '[') = [];
  opchar(opchar == ']') = [];
  opchar(opchar == '{') = [];
  opchar(opchar == '}') = [];
  opchar(opchar == ',') = [];
  opchar(opchar == ';') = [];
  opchar(opchar == '.') = [];
  
  obj = public();
  return;

  % Lookup symbol.  Record new symbol.  Return index.
  function res = enterV(str)                     % lookup/enter symbol in V
    for idx=1:NV
      if strcmp(V{idx}, str)
        res = int16(idx);
        return;                                  % found it
      end
    end
    V{end+1} = str;                              % enter new symbol
    NV = int16(numel(V));
    res = NV;
  end  % of enterV

  function o = public()                          % report public fields
    o.Vi = Vi;
    o.Vn = Vn;
    o.V  = V;
    o.R  = R;
    o.pn = pn;
    o.reservedTable = reservedTable;
    o.opchar = opchar;
  end

end  % of str2cfg

