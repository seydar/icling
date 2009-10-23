% FILE:    tryEnum.m
% PURPOSE: exercise M version of symbol naming 
% METHOD:  each character has an identifier,
%          each symbol is the catenation of the names of its characters
% EXAMPLE: 
%  tryEnum()

% COPYRIGHT W.M.McKeeman 2007.  You may do anything you like with 
% this file except remove or modify this copyright.

function tryEnum()
  load(fullfile(mxcomRoot, 'cfg.mat'), 'cfg');   % use saved cfg object
  name = enum(cfg.reserved());         % from the X language
  fprintf('name.if=%d\n',        name.if);
  fprintf('name.AND=%d\n',       name.AND);
  fprintf('name.LTEQ=%d\n',      name.LTEQ);
  fprintf('name.NOT=%d\n',       name.NOT);
  fprintf('name.do=%d\n',        name.do);
  fprintf('name.OR=%d\n',        name.OR);
  
  fields(name)                         % all the names
end %  of tryEnum

