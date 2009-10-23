% FILE:     tryEmitX86.m
% PURPOSE:  exercise emitting of executable code
% EXAMPLE:   
%   tryEmitX86()

% COPYRIGHT W.M.McKeeman 2007.  You may do anything you like with 
% this file except remove or modify this copyright.

function tryEmitX86(varargin)  
  load(fullfile(mxcomRoot, 'cfg.mat'), 'cfg');   % use saved cfg object
  sym = Symbols();                               % static
  sym.tree.parsed.lexed.cfg = cfg;
  rn = cfg.ruleNumbers;

  trial1
  trial2
  trial3
  
  return;

  %----------------- nested functions -------------------
  function trial1
    disp 'EmitX86 trial 1: enter'
    env = xenv({''});
    fr = env.getSizesAddress();
    ex = env.getEntriesAddress();
    emit = EmitX86(1, {sym}, 0, ex, fr, {'-emitTrace'});    % a gen
    emit.prolog();
    emit.epilog();
    frame = zeros(1, 0, 'int32');
    emit.go(frame);
    disp 'EmitX86 trial 1: leave'
  end

  function trial2
    disp 'EmitX86 trial 2: enter'
    env = xenv({''});
    fr = env.getSizesAddress();
    ex = env.getEntriesAddress();
    emit = EmitX86(1, {sym}, 0, ex, fr, {'-emitTrace'});    % a gen
    emit.prolog();
    o1 = emit.expr0(rn.factor_true, '');
    emit.expr1(rn.negation_NOTrelation, o1, '');
    emit.epilog();
    frame = zeros(1,0, 'int32');
    emit.go(frame);
    emit.dump();
    disp 'EmitX86 trial 2: leave'
  end

  function trial3
    disp 'EmitX86 trial 3: enter'
    adr = getCfun('rand');
    fprintf('adr(rand)=0x%x\n', adr);
    disp 'EmitX86 trial 3: leave'
  end

end
