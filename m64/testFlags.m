% FILE:    testFlags.m
% PURPOSE: interactive program to test each flag in xcom
% AUTHOR:  Alec Rogers
% METHOD:  >> testFlags()
%          then hit RETURN after each test.
%          For the -interactive test, type inf to get to the end.

function testFlags()
  flag = {
     ''
     '-noExecute'
     '-xcomTrace'
     '-xcomTime'
     '-frameDump'
     '-matlabStack'
     '-interactive'
     '-emulate'
     '-exeTrace'
     '-noAST'
     '-srcDump'
     '-lexDump'
     '-parseDump'
     '-treeDump'
     '-symDump'
     '-asmDump'
     '-texDump'
     '-parseTrace'
     '-treeTrace'
     '-symTrace'
     '-genTrace'
     '-emitTrace'
     '-asmTrace'
     '-asmHex'
     '-bottomUp'
  };

  %    '-pdfDump'

  file = fileread('x/pi.x');
  file = regexprep(file, '`[^\n]*\n', '');
  file = ['nterms:=4; ' file];

  for i=1:length(flag)
      fprintf('=========================================\n');
      input(sprintf('Output from using "%s"', flag{i}), 's');
      fprintf('=========================================\n');
      xcom(flag{i}, file);
  end

end