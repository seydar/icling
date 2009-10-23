% FILE:     tryCfg.m
% PURPOSE:  exercise grammar decoder 
% METHOD:   try a few grammars
% REQUIRES: readg.m knuth.cfg X.cfg
% USAGE:    tryCfg(t1, t2...) for trials t1, t2
% EXAMPLE:
%   tryCfg() % for all trials

% COPYRIGHT W.M.McKeeman 2006.  You may do anything you like with 
% this file except remove or modify this copyright.

function tryCfg(varargin)      % empty means all trials

  tn = [varargin{:}];          % cell to vector
  allt = isempty(tn);          % no arg at all
  flags = {...
    '-noLR'           % skip the LR(1) checking and table building
    '-hashDump'       % dump statistics on hash bucket use
    '-cfgTrace'       % trace the internal steps of LR1
    '-cfgDump'        % dump the cfg
    '-erasureDump'    % dump the erasing symbols
    '-headDump'       % dump the head symbols
    '-closureDump'    % dump the LR1 closure
    '-kernelDump'     % dump the LR1 kernel
    '-shiftDump'      % dump the shifts
    '-reduceDump'     % dump the reductions
  };
  
  disp 'start cfg trials -------------------------------'

  if allt || any(tn == 1)
    disp 'start  test Knuth cfg,  (10) in paper'
    gr = xread('knuth5.cfg');
    for i = 1:numel(flags)
      disp(['>> Cfg knuth5.cfg ' flags{i}])
      Cfg(gr, flags(i));
    end
  end
  
  if allt || any(tn == 2)
    disp 'start  test Knuth cfg,  (6) in paper'
    gr = xread('knuth2a.cfg');
    disp '>> Cfg knuth2a.cfg'
    x = Cfg(gr);
    x.dump();
  end
  
  if allt || any(tn == 3)
    disp 'full run of Cfg for X; be patient'
    gr = xread('X.cfg');
    x = Cfg(gr);
    x.dump();
  end
  
end

