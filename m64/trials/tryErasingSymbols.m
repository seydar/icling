% FILE:     tryErasingSymbols.m
% PURPOSE:  try erasingSymbols.m
% METHOD:   transitive closure of immediate erasure
% EXAMPLE:  
%   addpath trials
%   cfg = str2cfg(xread('E.cfg'))
%   tryErasingSymbols(cfg);

% COPYRIGHT W.M.McKeeman 2007.  You may do anything you like with 
% this file except remove or modify this copyright.
% MODS:     2007.04.01 -- mckeeman@dartmouth.edu -- original
%           2007.11.19 -- mckeeman@dartmouth.edu -- incorporated LR(1)
%           2008.04.28 -- mckeeman@dartmouth.edu -- separate file

cfg = str2cfg(xread('E.cfg'));
er  = erasingSymbols(cfg);
if any(er); fprintf('Error erasingSymbols\n'); end

cfg = str2cfg(xread('X.cfg'));
er  = erasingSymbols(cfg);
fprintf('Erasing in X.cfg: ');
fprintf('%s ', cfg.V{er});
fprintf('\n');
