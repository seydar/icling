% FILE:     findFlag.m
% PURPOSE:  flag is, or is not, in list
%
% USAGE:  isFlag = findFlag(flag, list)
% EXAMPLE:
%  isf = findFlag('-flag', {'-flag'})
%
% COPYRIGHT W.M.McKeeman 2007.  You may do anything you like with 
% this file except remove or modify this copyright.

function res = findFlag(flg, lst)                % lookup flg in lst
  res = true;                                    % optimistic
  for i=1:numel(lst)
    if strcmp(flg, lst{i}), return; end          % found it
  end
  res = false;                                   % did not find it
end
