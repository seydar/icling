% FILE:    testErr.m
% PURPOSE: exercise error mechanism
% EXAMPLE:   
%  testErr()  % for all trials

% COPYRIGHT W.M.McKeeman 2006.  You may do anything you like with 
% this file except remove or modify this copyright.


function testErr

  for i=1:11
    fn = ['parseError' num2str(i)];
    try
      xcom(['x/' fn '.x'])
      disp(['failed to detect ' fn]);
    catch e1
      %disp(e1.message)
    end
  end
  
  try
    xcom 'x:=;'  % no file
    disp('failed to detect error in command line source');
  catch e2
    %disp(e2.message);
  end

  for i=1:3
    fn = ['runError' num2str(i)];
    try
      xcom(['x/' fn '.x']);
      disp(['failed to detect ' fn]);
    catch e3
      %disp(e3.message)
    end
  end

  switch computer
  case {'PCWIN', 'GLNX86', 'MACI'}
    try
      xcom x/runError1.x x/callError1.x
      disp 'failed to detect 1/0 in subprogram'
    catch e4
      %disp(e4.message);
    end
  end


end
