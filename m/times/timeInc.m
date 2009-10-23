% FILE:    timeInc.m
% PURPOSE: compare xcom with MATLAB.
% METHOD:  do 100,000,000 million increments by 1
%          use xcom timing flag to gather data
%          use tic/toc for MATLAB comparisons.

function timeInc()
  disp 'running timeIntegerInc.x'
  xcom -xcomTime x/timeIntegerInc.x

  % int32 scalar arithmetic
  reps = int32(100);
  rep  = int32(0);
  lim  = int32(1000000);
  tstart = tic;
  while rep < reps
    ctr = int32(0);
    while ctr < lim    % 100,000,000 times
      ctr = ctr + 1;
      ctr = ctr + 1;
      ctr = ctr + 1;
      ctr = ctr + 1;
      ctr = ctr + 1;
      
      ctr = ctr + 1;
      ctr = ctr + 1;
      ctr = ctr + 1;
      ctr = ctr + 1;
      ctr = ctr + 1;
    end
    rep = rep + 1;
  end
  ti = toc(tstart);
  fprintf(['MATLAB int32 time (compare with ''run'' above):\n'...
           '    run    %g sec\n'], ti);

  % single precision IEEE scalar arithmetic
  disp 'running timeRealInc.x'
  xcom -xcomTime x/timeRealInc.x

  sreps = single(100);
  srep  = single(0);
  slim  = single(1000000);
  sone  = single(1);
  tstart = tic;
  while srep < sreps
    sctr = single(0);
    while sctr < slim             % 100,000,000 times
      sctr = sctr + sone;
      sctr = sctr + sone;
      sctr = sctr + sone;
      sctr = sctr + sone;
      sctr = sctr + sone;
      
      sctr = sctr + sone;
      sctr = sctr + sone;
      sctr = sctr + sone;
      sctr = sctr + sone;
      sctr = sctr + sone;
    end
    srep = srep + sone;
  end
  ts = toc(tstart);
  fprintf(['MATLAB single time (compare with ''run'' above):\n'...
           '    run    %g sec\n'], ts);
end

%{
30-Nov-2008
running timeIntegerInc.x
xcom times: 
    cmd    0.000939226 sec
    cfg    0.0598691 sec
    fe     0.0950017 sec
    sym    0.442726 sec
    tex    0.0001232 sec
    be     0.288677 sec
    input  0.0017086 sec
    run    0.656417 sec
    output 0.00173206 sec
MATLAB int32 time (compare with 'run' above):
    run    2.47174 sec
running timeRealInc.x
xcom times: 
    cmd    0.000971632 sec
    cfg    0.0592637 sec
    fe     0.0947894 sec
    sym    0.441458 sec
    tex    0.000113422 sec
    be     0.37988 sec
    input  0.0018941 sec
    run    1.35563 sec
    output 0.00174072 sec
MATLAB single time (compare with 'run' above):
    run    1.34782 sec
%}


