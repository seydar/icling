% FILE:     mxcomRoot.m
% PURPOSE:  find out what the file system thinks the path is.
% METHOD:   keep this function with other functions that MATLAB 
%           needs to find
% EXAMPLE:  
%  pth = mxcomRoot()

% COPYRIGHT W.M.McKeeman 2007.  You may do anything you like with 
% this file except remove or modify this copyright.

function pth = mxcomRoot()
  tmp = which('xcom.m');
  pth = tmp(1:numel(tmp)-6);
end

