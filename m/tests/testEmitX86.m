% FILE:     testEmitX86.m
% PURPOSE:  test emitting of executable code
% COPYRIGHT W.M.McKeeman 2007.  You may do anything you like with 
% this file except remove or modify this copyright.
% EXAMPLE:   
%  testEmit() 

% COPYRIGHT W.M.McKeeman 2006.  You may do anything you like with 
% this file except remove or modify this copyright.

function testEmitX86(varargin)   
  load(fullfile(mxcomRoot, 'cfg.mat'), 'cfg');   % use saved cfg object
  sym    = Symbols();                            % static
  sym.tree.parsed.lexed.cfg = cfg;
  rn     = cfg.ruleNumbers;
  pass   = 0;                                    % none yet
  testno = 0;                                    % none yet
  lvl = tab();
   
  testno = testno + 1;
  testempty
  testno = testno + 1;
  testnegate
  testno = testno + 1;
  testgetCfun
  
  fprintf('EmitX86: passed %d unit tests\n', pass);
  return;

  %----------------- nested functions -------------------
  function testempty                             % empty program
    env = xenv({''});
    fr = env.getSizesAddress();
    ex = env.getEntriesAddress();
    emit = EmitX86(1, {sym}, 0, ex, fr, lvl);% an emitter
    emit.prolog();
    emit.epilog();
    frame = zeros(1, 0, 'int32');
    err = emit.go(frame);
    if ~test(err == 0); testEmitErr(); end       % no run error
  end

  function testnegate
    env = xenv({''});
    fr = env.getSizesAddress();
    ex = env.getEntriesAddress();
    emit = EmitX86(1, {sym}, 0, ex, fr, lvl);% an emitter
    emit.prolog();
    o1 = emit.expr0(rn.factor_true, '');         % true
    emit.expr1(rn.negation_NOTrelation, o1, ''); % ~true
    emit.epilog();
    frame = zeros(1,0, 'int32');
    err = emit.go(frame);
    if ~test(err == 0); testEmitErr(); end       % no run error
  end

  function testgetCfun
    getCfun('rand');
    test(true);                                  % no SEGv
  end

  function res = test(expr)
    pass = pass+1;
    res = expr;
  end

  function testEmitErr()
    error('testEmitErr: failed test %d', testno);
  end

end
