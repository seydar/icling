% FILE:    makeMex.m
% PURPOSE: rebuild mex files if necessary
% METHOD:  use mex to compile C functions
%          Run makeMex from MATLAB when the C text has changed
% EXAMPLE: 
%   makeMex()               % compile all runtime functions
%   makeMex runX86.c nox.c  % compile selected C functions 
%
% SEE ALSO:  checkMex.m

% COPYRIGHT W.M.McKeeman 2007.  You may do anything you like with 
% this file except remove or modify this copyright.

function makeMex(varargin)
  % make C helper functions for low-level actions
  
  root = mxcomRoot();
  osdef = computer;                              % platform def

  if nargin == 0
    dirc = dir([root filesep '*.c']);
    cfiles = {dirc.name};                        % all C file
  else
    cfiles = {};                                 % none yet
    for i = 1:numel(varargin)
      f = varargin{i};
      if numel(f) > 2 && ~strcmp(f(end-1:end), '.c')
        cfiles{i} = [f '.c'];                    %#ok<AGROW> 
      else
        cfiles{i} = f;                           %#ok<AGROW>
      end
    end
  end

  disp 'makeMex: Compiling C; be patient.'
  for i = 1:numel(cfiles)
    f = cfiles{i};
    display(['mex -g, -D' osdef ', ' root f]);
    mex('-g', ['-D' osdef], [root f]);           % cc
  end
end

