% FILE:     makeCfg.m
% PURPOSE:  build tables from a cfg file
% COPYRIGHT W.M.McKeeman 2007.  You may do anything you like with 
% this file except remove or modify this copyright.
% USAGE:    makeCfg cfgfile flags
% EXAMPLE:  
%  makeCfg E.cfg -lrDump
%
% OVERVIEW:
%   A context-free grammar is a set of rules; X.cfg is an example.
%   Information needed by the XCOM compiler is extracted and tabulated.
%   One can think of Cfg.m as an analog to unix program YACC.
%
%   This program is run from the command line as a part of the personal
%   workflow while the X.cfg grammar is being changed.
%   
% ARGUMENTS
%   The arguments to makeCfg are strings. 
%   If an argument starts with '-', it is interpreted as a flag.
%   If an argument is valid path name to a CFG source file (dot-cfg), 
%   the file will be read; otherwise the argument will be treated as
%   the text of a cfg.
%
% FLAGS
%   -saveMat    if there are no errors, write the file cfg.mat
%   see Cfg.m for dumper flags
%
% UNIT TEST:
%   tmakeCfg.m
%
% METHOD:
%  The cfg textual format uses ' ', EOL and EOF as the only grammar
%  delimiters. Identifiers are non-terminals on LHS of a rule. Everything
%  else is terminal.  There are some terminal symbols that represent
%  classes of symbols, namely identifiers and literal constants.  These
%  symbols are "normal" to CFG but require special handling in the lexer.
% SEE ALSO: Cfg.m, str2cfg.m

function makeCfg(varargin)

  flags = {};                                    % none yet
  saveMat = false;                               % default
  if nargin == 0, error('makeCfg requires a file name'); end
  for a = 1:numel(varargin)                      % all args
    arg = varargin{a};
    if numel(arg)== 0; error('bad argument to makeCfg'); end
    if arg(1) == '-'
      switch arg
        case '-saveMat'; saveMat = true;
        otherwise; flags = [flags, arg];         %#ok<AGROW>
      end
    elseif numel(arg)>4 && strcmp(arg(end-3:end),'.cfg')
      cfgtxt = xread(arg);                       % grammar from file
    else
      cfgtxt = arg;                              % grammar from arg
    end
  end
  
  cfg = Cfg(cfgtxt, flags);                      %#ok<NASGU>
  if saveMat 
    save('cfg','cfg');                           % for xcom
  else
    disp 'makeCfg: no -saveMat flag; CFG tables not saved'
  end 
end
