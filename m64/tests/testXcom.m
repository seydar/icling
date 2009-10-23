% FILE:    testXcom.m
% PURPOSE: test whole compiler for various inputs
% EXAMPLE:
%  testXcom()

% COPYRIGHT W.M.McKeeman 2006.  You may do anything you like with 
% this file except remove or modify this copyright.

function testXcom()
  disp 'testXcom: start feature tests'
  flags = {{}, {'-noAST'}, {'-bottomUp'}, {'-noAST', '-bottomUp'}};
  
  for i=1:numel(flags)
    fl = flags{i};
    txt = '';
    for j=1:numel(fl); txt = [txt ' ' fl{j}]; end %#ok
    fprintf('combo %d: xcom flags = %s\n', i, txt);
    xcom(fl{:}, '-matlabStack', 'x/smoke.x');
    fprintf('passedsmoke := true\n');
    xcom(fl{:}, '-noExecute', '-matlabStack', 'x/symbols.x');
    fprintf('passedsymbols := true\n');
    switch computer
      case {'PCWIN', 'GLNX86', 'MACI'}
        xcom(fl{:}, '-matlabStack', ...
          'x/bools.x', 'x/rels.x',  'x/ints.x',  'x/reals.x', ...
          'x/iffis.x', 'x/doods.x', 'x/ops.x');   
      case 'GLNXA64'
        xcom(fl{:}, '-matlabStack', 'x/bools.x');
        xcom(fl{:}, '-matlabStack', 'x/rels.x');
        xcom(fl{:}, '-matlabStack', 'x/ints.x');
        xcom(fl{:}, '-matlabStack', 'x/reals.x');
        xcom(fl{:}, '-matlabStack', 'x/iffis.x');
        xcom(fl{:}, '-matlabStack', 'x/doods.x');
      otherwise
        error(['testXcom: unexpected platform ' computer]);
    end
    switch computer
    case {'PCWIN', 'GLNX86', 'MACI'}
      xcom(fl{:}, '-matlabStack', 'x/called.x', 'x/caller.x');
      % the order of file names does not matter (except the last is "main")
      xcom(fl{:}, '-matlabStack', 'x/called.x', 'x/caller.x', 'x/callercaller.x');
      xcom(fl{:}, '-matlabStack', 'x/caller.x', 'x/called.x', 'x/callercaller.x');
      xcom(fl{:}, '-matlabStack', 'x/called12.x', 'x/caller12.x');
      xcom(fl{:}, '-matlabStack', 'x/called35.x', 'x/caller35.x');
      xcom(fl{:}, '-matlabStack', 'x/pi.x', 'x/callpi.x');
      fprintf('passedsubrs := 4\n');
    end
  end
  disp 'testXcom: finish feature tests -- 4 flag combos passed'
end
