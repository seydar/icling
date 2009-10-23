% FILE:    tryErr.m
% PURPOSE: exercise error mechanism
% EXAMPLE:   
%   tryErr() % for all trials

% COPYRIGHT W.M.McKeeman 2007.  You may do anything you like with 
% this file except remove or modify this copyright.


function tryErr

  for i=1:11
    fn = ['parseError' num2str(i)];
    try
      xcom(['x/' fn '.x'])
      disp(['failed to detect ' fn]);
    catch
      t=lasterror;
      disp(t.message)
    end
  end

  try
    xcom -trace x:=;  % no file
  catch
    t = lasterror;
    disp(t.message);
  end

  for i=1:3
    fn = ['runError' num2str(i)];
    try
      xcom('-xcomTrace', ['x/' fn '.x'])
      disp(['failed to detect ' fn]);
    catch
      t=lasterror;
      disp(t.message)
    end
  end

  try
    xcom -srcDump x/runError1.x -srcDump x/callError1.x
    disp 'failed to detect 1/0 in subprogram'
  catch
    t = lasterror;
    disp(t.message);
  end


end
