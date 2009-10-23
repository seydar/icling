% FILE:     erasingSymbols.m
% PURPOSE:  Find erasing phrase names in cfg
%           a phrase name is erasing if '' <-* A
% USAGE:    er = erasingSymbols(cfgobj);
% METHOD:   transitive closure of immediate erasure
% EXAMPLE:
%  cfg = str2cfg(xread('X.cfg'));
%  e   = erasingSymbols(cfg);
%  cfg.V(e)

% COPYRIGHT W.M.McKeeman 2006.  You may do anything you like with 
% this file except remove or modify this copyright.
% MODS:     2007.04.01 -- mckeeman@dartmouth.edu -- original
%           2007.11.19 -- mckeeman@dartmouth.edu -- incorporated LR(1)
%           2008.04.28 -- mckeeman@dartmouth.edu -- separate file

function er = erasingSymbols(cfg)
    R = cfg.R;
    er = false(1,numel(cfg.V));                  % initially none
    change = true;                               % do at least once
    while change
      change = false;                            % none yet this pass
      for ei=1:numel(R)
        ri = R{ei};                              % the ei-th rule
        lhs = ri(1);                             % the defined symbol
        if ~er(lhs)                              % not yet known
          guess = true;                          % suppose it erases
          for j=2:numel(ri)
            guess = guess & er(ri(j));           % attempt to falsify
          end
          if guess                               % it is another eraser
            er(lhs) = true;                      % record it
            change = true;                       % keep trying
          end
        end
      end
    end
  end  % of erasingSymbols
