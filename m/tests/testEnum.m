% FILE:    testEnum.m
% PURPOSE: exercise M version of symbol naming 
% METHOD:  each character has an identifier,
%          each symbol is the catenation of the names of its characters
% HINT:    run tryEnum() for a dump of information about testEnum.m
% EXAMPLE:   
%   testEnum()

% COPYRIGHT W.M.McKeeman 2006.  You may do anything you like with 
% this file except remove or modify this copyright.


function testEnum()
  load(fullfile(mxcomRoot, 'cfg.mat'), 'cfg');   % use saved cfg object
  name = enum(cfg.reserved());         % from the X language
  check = fields(name);                % all reserved names
  pass = 0;                            % none yet
  for i=1:numel(check)
    assert(name.(check{i}) == i);
    pass = pass + 1;
  end
  
  fprintf('enum: passed %d unit tests\n', pass);
  return;
  
end %  of testEnum


