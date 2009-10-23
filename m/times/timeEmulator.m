% FILE:     timeEmulator.m
% PURPOSE:  race emulator against x86
% REQUIRES: Cfg.m Lexer.m Parser.m
% EXAMPLE:    
%  timeEmulator()

% COPYRIGHT W.M.McKeeman 2006.  You may do anything you like with 
% this file except remove or modify this copyright.


function timeEmulator()

  test = {'x/ints.x', 'x/rels.x', 'x/iffis.x'};
  
  disp 'timeEumulator: ---- start trials -----------------------------'
   for i=1:numel(test)                           %#ok
     timeit(test{i});
   end
  disp 'timeEmulator: ---- end trials -------------------------------'
   
  %------------------ nested functions -------------------------
  function timeit(filename)
    fprintf('timeEmulator: %s\n', filename);
    REPS = 5;
    tstart = tic;
    cmd = ['xcom(''' filename ''')'];
    for i = 1:REPS                               %#ok
      dummy = evalc(cmd);                        %#ok hot
    end  % use evalc above to supress output from 'filename'
    thot = toc(tstart)/REPS;
    tstart = tic;
    cmd = ['xcom(''' filename ''', ''-emulate'')'];
    dummy = evalc(cmd);                          %#ok emulated
    temu = toc(tstart);
    tstart = tic;
    cmd = ['xcom(''' filename ''', ''-noExecute'')'];
    for i = 1:REPS                               %#ok
      dummy = evalc(cmd);                        %#ok compile overhead
    end  % use evalc above to supress output from 'filename'
    tnox = toc(tstart)/REPS;
    fprintf(['file %10s hot time      = %g sec\n',...
             '                emulated time = %g sec\n'],...
      filename, max(thot-tnox,0), temu-tnox);
  end

end
%{
timeEmulator: ---- start trials -----------------------------
timeEmulator: x/ints.x
file   x/ints.x hot time      = 0.0134979 sec
                emulated time = 0.838494 sec
timeEmulator: x/rels.x
file   x/rels.x hot time      = 0.0377542 sec
                emulated time = 0.726219 sec
timeEmulator: x/iffis.x
file  x/iffis.x hot time      = 0.0331615 sec
                emulated time = 0.288061 sec
timeEumulator: ---- end trials -------------------------------
%}

