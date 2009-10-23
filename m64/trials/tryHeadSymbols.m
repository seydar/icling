% FILE:     tryHeadSymbols.m
% PURPOSE:  tryHeadSymbols.m
% METHOD:   transitive closure of immediate erasure
% EXAMPLE:  
%   cfg = str2cfg(xread('E.cfg'));
%   tryHeadSymbols(cfg);

% COPYRIGHT W.M.McKeeman 2007.  You may do anything you like with 
% this file except remove or modify this copyright.
% MODS:     2007.04.01 -- mckeeman@dartmouth.edu -- original
%           2007.11.19 -- mckeeman@dartmouth.edu -- incorporated LR(1)
%           2008.04.28 -- mckeeman@dartmouth.edu -- separate file

grtxt = xread('E.cfg');
cfg = str2cfg(grtxt);
V = cfg.V;

fprintf(grtxt);

hd  = headSymbols(cfg);
for i=1:size(hd,1)
  fprintf('hd(''%s'')=', V{i});
  fprintf('%s ', V{hd(i,:)});
  fprintf('\n');
end

