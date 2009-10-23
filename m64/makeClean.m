% FILE:     makeClean.m
% PURPOSE:  remove temporary files before ship, clean up file access
% EXAMPLE:
%   makeClean();

% COPYRIGHT W.M.McKeeman 2007.  You may do anything you like with 
% this file except remove or modify this copyright.

function makeClean()
dirs = {'.', '..', '../doc', '../doc/labs', '../doc/notation', 'x', 'tests', 'trials', 'times'};
junk = {'*.asv', '*~', '*.ilk', '*.pdb', '*.log', ...
        '*.aux', '*.dvi',  '*.ps', '*.out'};
src  = {'*.h', '*.c', '*.cpp', '*.m', '*.l', '*.y', ...
        '*.x', '*.htm', '*.html', '*.pdf', '*.cfg', ...
        '*.txt', '*.tex', '*.xls', '*.doc'};
    
for d = 1:numel(dirs)
  for j = 1:numel(junk)
    delete([dirs{d} '/' junk{j}]);
  end
  for j = 1:numel(src)
    f = [dirs{d} '/' src{j}];
    try
      fileattrib(f, '-x');
    catch nothing      %#ok<NASGU> supress missing file error
    end
  end
end
