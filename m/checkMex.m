% FILE:    checkMex.m
% PURPOSE: detect missing/out of date MEX files
% EXAMPLE: 
%  checkMex()       % check all C files
% METHOD:  Each dot-C file is checked
%   * it has been compiled
%   * it is not newer than the compiled file
% SEE ALSO: makeMex.m

% COPYRIGHT W.M.McKeeman 2007.  You may do anything you like with 
% this file except remove or modify this copyright.

function checkMex()
  % make sure C helper functions for low-level actions are present
  root = mxcomRoot();
  ext   = mexext;                              % mex extension
  dirc = dir([root filesep '*.c']);
  cfiles = {dirc.name};                        % all C files
  for i = 1:numel(cfiles)                      % once per file
    f = cfiles{i};                             % make row vector    
    dirc = dir([root f]);
    fname = f(1:end-2);
    dirm = dir([root fname '.' ext]);
    if isempty(dirm)
      error(['checkMex: must use makeMex for function ' f]);
    end
    if dirc.datenum > dirm.datenum
      fprintf(...
      ['checkMex: ' f ' has changed since ' fname '.' ext ' was compiled\n']);
    end
  end
end


