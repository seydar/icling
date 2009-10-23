% FILE:    tryFlags.m
% PURPOSE: interactive program to test each flag in xcom
% AUTHOR:  Alec Rogers
% METHOD:  >> testFlags()
%          then hit RETURN after each test.
%          For the -interactive test, type inf to get to the end.

function tryFlags()
  flag = {
     ''
     '-noExecute'
     '-xcomTrace'
     '-xcomTime'
     '-frameDump'
     '-matlabStack'
     %'-interactive'
     '-emulate'
     '-exeTrace'
     '-noAST'
     '-srcDump'
     '-lexDump'
     '-parseDump'
     '-treeDump'
     '-symDump'
     '-asmDump'
     '-parseTrace'
     '-treeTrace'
     '-symTrace'
     '-genTrace'
     '-emitTrace'
     '-asmTrace'
     '-asmHex'
     '-bottomUp'
  };

  file = ['nterms:=4; ' fileread('x/pi.x')];

  for i=1:length(flag)
      fprintf('============ flag "%s" ============\n', flag{i});
      xcom(flag{i}, file);
  end

end