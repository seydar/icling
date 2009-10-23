% FILE:     idCtor.m
% PURPOSE:  rename arbitrary string to id
% COPYRIGHT W.M.McKeeman 2006.  You may do anything you like with 
% this file except remove or modify this copyright.
% METHOD:   use object for persistent store
%           squeeze out blanks
%           use fixed (uppercase) names for all allowed characters
%           all of A-Z a-z 0-9 _ stand for themselves
%           prepend 'I' if not otherwise legal
%           truncate to namelengthmax
% EXAMPLE:  
%   makeId = idCtor();
%   names  = makeId.names
%   rule   = makeId.str2id('term _ term * factor')
%
% Note:     There is no presumption of uniqueness, for example,
%           strcmp(makeId.str2id('&'), makeId.str2id('AND')) is true.
% TEST:     tidCtor.m
% SEE ALSO: enum.m

function idobj = idCtor()
  lowers = 'a':'z';
  uppers = upper(lowers);
  digits = '0':'9';
  
  chrs = [lowers uppers digits 10 '_~!@#$%^&*()+`-={}|[]\:";''<>?,./'];
  n1 = [num2cell(lowers) num2cell(uppers) num2cell(digits)];
  n2 = {'_' 'not' 'bang' 'at' 'sharp' 'dollar' 'pct' 'hat' 'and' ...
    'mul' 'lr' 'rr' 'add' 'bq' 'sub' 'eq' 'lc' 'rc' 'or' 'ls' 'rs'...
    'back' 'colon' 'dq' 'semi' 'qt' 'lt' 'gt' 'qmark' 'comma' 'dot' 'div'};
  names = [n1 {'EOL'} upper(n2)];
  
  chrno = zeros(1,127, 'uint16');                % will leave some holes
  for i=1:numel(chrs)                            % ascii code to list idx
    chrno(uint16(chrs(i))) = uint16(i);          % avoid ':' MATLAB bug
  end

  idobj = public();                              % pass out method

  return;       % end of constructor
  
  % ----------------------------- end of ctor ------------------
  
  function id = str2id(str)
    if ~ischar(str), error('str2id(arg) requires arg is a string'); end
    id = [names{chrno(uint16(str(str~=' ')))}];
    if ~isvarname(id) && ~iskeyword(id), id = ['I' id]; end
    if numel(id) > namelengthmax
      id = id(1:namelengthmax);   % This is a MATLAB restriction
    end
  end
    
  function o = public()
    o = struct;
    o.names = names;
    o.str2id = @str2id;
  end

end
