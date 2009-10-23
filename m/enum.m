% FILE:    enum.m
% PURPOSE: Basic utility to make up identiers for symbols and
%          associate a unique integer with each identifier.
%          (Analogous to implementing C/C++ enum as a C++ object.)
% METHOD:  Each ASCII character has a name (see idCtor).  
%          Symbol names are the catenation of the character names.
%          Identifiers are their own names.
%          The input is a cell array of strings to be named.
%          The identifiers are used as struct field names.
%          The default field values are 1:n
%          The lowest field value can be set with a second argument
%          Note: MATLAB reserved words are allowed as field names.
% USAGE:   syms = enum(names);       % 1 based
%          syms = enum(names, 0);    % 0 based
% EXAMPLE: 
%  syms = enum({'if', '+', ':='});
%  [syms.if, syms.ADD, syms.COLONEQ]
% SEE ALSO:  idCtor.m

% COPYRIGHT W.M.McKeeman 2006.  You may do anything you like with 
% this file except remove or modify this copyright.

function syms = enum(names, first)
  persistent txtbls;
  if isempty(txtbls)                   % get translating object
    txtbls = idCtor();
  end
  
  base = 1;                            % enums start from 1
  if nargin == 2
    base = first;                      % unless otherwise needed
  end
  
  syms  = struct;
  for j=1:numel(names)
    n = names{j};
    syms.(txtbls.str2id(n)) = int16(base+j-1);
  end
  return;
  
end

