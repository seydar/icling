% FILE:    tryXcom.m
% PURPOSE: try whole compiler for various inputs
% EXAMPLE:
%  tryXcom()

% COPYRIGHT W.M.McKeeman 2006.  You may do anything you like with 
% this file except remove or modify this copyright.

function tryXcom()
  disp 'tryXcom: start flag trials----'
  xcom -noExecute   x:=1
  xcom -xcomTrace   x:=2
  xcom -xcomTime    x:=3
  xcom -frameDump   x:=4  
  xcom -matlabStack x:=5
  % xcom -interactive x:=6   % stalls in step=
  xcom -exeTrace    x:=7
  xcom -emulate     x:=8
  %xcom -cfgDump
  xcom -noAST       x:=9
  xcom -srcDump     x:=10
  xcom -lexDump     x:=11
  xcom -parseDump   x:=12
  xcom -parseDump -bottomUp  x:=13
  xcom -treeDump    x:=14
  xcom -treeDump -noAST  x:=15
  xcom -symDump     x:=16
  xcom -asmDump     x:=17
  
  xcom -parseTrace  x:=18
  xcom -treeTrace   x:=19
  xcom -symTrace    x:=20
  xcom -genTrace    x:=21
  xcom -emitTrace   x:=22
  xcom -asmTrace    x:=23
  
  disp 'tryXcom: finish flag trials----'
  
  disp 'tryXcom: start subprogram trials----'
  xcom x/called.x x/caller.x
  xcom x/called12.x x/caller12.x
  xcom -xcomTime x/called35.x x/caller35.x
  xcom x/pi.x x/callpi.x
  disp 'tryXcom: finish subprogram trials----'
end
