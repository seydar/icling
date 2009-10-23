% FILE:     headSymbols.m
% PURPOSE:  build head symbol tables for cfg
% USAGE:    hd = headSymbols(cfg);
%           hd(A,B) means B is a head of A
% EXAMPLE:  
%   cfg = str2cfg(xread('E.cfg'));
%   cfg.V
%   hd = headSymbols(cfg)
%   hd(6,1)               % '(' is a head of E
%
% METHOD:   transitive closure on immediate heads

% COPYRIGHT W.M.McKeeman 2007.  You may do anything you like with 
% this file except remove or modify this copyright.
% MODS:     2007.04.01 -- mckeeman@dartmouth.edu -- original
%           2007.11.19 -- mckeeman@dartmouth.edu -- incorporated LR(1)
%           2008.04.29 -- mckeeman@dartmouth.edu -- separate file
%


  % Establish grammatical head symbols for each symbol in V
  % Results in hd()
  function hds = headSymbols(cfg)
    R = cfg.R;
    hds = logical(eye(numel(cfg.V)));            % A <-* A 
    for g=1:numel(R)                             % A <-  B beta
      r = R{g};
      if numel(r) > 1
        hds(r(1), r(2)) = true;                  % r(2) head of r(1)
      end
    end
    hds = headClosure(hds);                      % closure
  end                                            % of headSymbols
  
  % Transitive closure of A <- B beta
  % Results in hds(:,:)
  function hds = headClosure(hds)
    NV = size(hds,1);
    change = true;                               % do at least once
    while change
      change = false;                            % optimistic
      for i=1:NV;
        for j=1:NV
          for k=1:NV
            if hds(i,j) && hds(j,k)              % transitive
              if ~hds(i,k)
                hds(i,k) = true;
                change = true;
              end
            end
          end
        end
      end
    end
  end  % of headClosure
 
