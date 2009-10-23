% FILE:     testEmulateX86.m
% PURPOSE:  test emulation of executable x86 code
% CAVEAT:
%   takes about 30 seconds
% EXAMPLE:
%   testEmulate()

% COPYRIGHT W.M.McKeeman 2006.  You may do anything you like with 
% this file except remove or modify this copyright.


function testEmulateX86
  disp 'testEmulateX86: start emulation tests'
  test = {'bools', 'ints', 'reals', 'rels', 'iffis', 'doods'};

  p = 0;
  for i=1:numel(test)
    emTest(test{i}); p = p + 1;
  end
  
  passedEmulate = p;                        %#ok<NASGU>
end

function emTest(fn)
  hot = evalc(['xcom(''x/' fn '.x'')']);
  emu = evalc(['xcom(''-emulate'', ''x/' fn '.x'')']);
  res = emu(end-numel(hot)+1:end);
  if ~strcmp(hot, res); temErr(fn); end
end


function temErr(fn)
  error(['testEmulate: failed test ' fn]);
end
  
