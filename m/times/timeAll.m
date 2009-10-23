% FILE:    timeAll.m
% PURPOSE: time various aspects of xcom
% EXAMPLE:
%  timeAll()

% COPYRIGHT W.M.McKeeman 2006.  You may do anything you like with 
% this file except remove or modify this copyright.

function timeAll()
  format compact;
  datestr(now)
  disp '-----enter time runs -----------'
  timeInc();
  timeEmulator();
  timeLexer();
  timeParser();
  disp '-----leave time runs -----------'

%{
23-Dec-2007 16:13:12
-----enter time runs -----------
running timeIntegerInc.x
xcom times: 
    cmd    0.00124513 sec
    cfg    0.162286 sec
    fe     0.145618 sec
    be     0.17015 sec
    input  0.000570184 sec
    run    0.284994 sec
    output 0.000917714 sec
running timeRealInc.x
xcom times: 
    cmd    0.00105432 sec
    cfg    0.163252 sec
    fe     0.145591 sec
    be     0.159209 sec
    input  0.000568229 sec
    run    0.779345 sec
    output 0.000922743 sec
MATLAB comparison times:
int32 
    run    0.14698 sec
single
    run    0.0731526 sec
timeParser: ---- start trials -------------------------------
timeParser: trial 1
len(src)=    0 topDown=0.0588832 sec
              bottomUp=0.0579646 sec
timeParser: trial 2
len(src)=  207 topDown=0.065246 sec
              bottomUp=0.0651521 sec
timeParser: trial 3
len(src)=15059 topDown=1.15924 sec
              bottomUp=1.09907 sec
timeParser: ---- end trials -------------------------------
-----leave time runs -----------
%}
  