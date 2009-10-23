% FILE:     makeIndex.m
% PURPOSE:  Collect signficant files and prepare HTML index to them.
% EXAMPLE:
%   makeIndex();

% COPYRIGHT W.M.McKeeman 2007.  You may do anything you like with 
% this file except remove or modify this copyright.

function makeIndex()
  cd ../doc
  dirs = {'.', 'final', 'labs', 'notation', '../yacc', ...
    '../m', '../m/html', '../m/pdf', ...
    '../m/tests', '../m/trials', '../m/times', '../m/x'};
  src  = {'*.h', '*.c', '*.cpp', '*.m', '*.l', '*.y', ...
          '*.x', '*.htm', '*.html', '*.pdf', '*.txt'};

  fileNames  = cell(1,300);  % estimate number of files
  upperNames = cell(1,300);
  filePaths  = cell(1,300);
  entry = 0;
  for d = 1:numel(dirs)      % find all the interesting files
    for j = 1:numel(src)
      f = [dirs{d} '/' src{j}];                        % all combinations
      try
        fff=dir(f);                                    % set of file names
        for c=1:numel(fff)
          entry = entry + 1;
          fileNames{entry}  = fff(c).name;             % name for display
          upperNames{entry} = upper(fff(c).name);      % name for sort
          filePaths{entry}  = [dirs{d} '/' fff(c).name];% path to name
        end
      catch nothing      %#ok<NASGU> supress missing file error
      end
    end
  end

  [d,idx] = sort(upperNames);                          % alphabetic order
  nf = numel(fileNames);                               % count index entries
  EOL = 10;

  % Index page header material
  htmltxt = cell(1,1000); htmlidx = 1;

  append2html('<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">');
  append2html('<!-- FILE:    Index.html', EOL);
  append2html('     PURPOSE: List significant files in mxcom', EOL);
  append2html('     NOTE:    Do not edit; this file generated by makeIndex.m', EOL);
  append2html('-->', EOL, EOL);
  append2html('<HTML>', EOL);
  append2html('<HEAD>', EOL);
  append2html('<TITLE>', EOL);
  append2html('Index -- A Short Course in Compilers', EOL);
  append2html('</TITLE>', EOL);
  append2html('</HEAD>', EOL);
  append2html('<BODY BGCOLOR="#FFF0D0">', EOL);

  % set up HTML page shape and margins
  append2html('<TABLE>', EOL);
  append2html('<TR><TD WIDTH="50"></TD><TD WIDTH="600">', EOL);

  % author information
  append2html('<P ALIGN="RIGHT">', EOL);
  append2html('<SMALL>', EOL);
  append2html('<EM>File</EM> Index.html&nbsp;&nbsp;&nbsp;', EOL);
  append2html('<EM>Author</EM> McKeeman&nbsp;&nbsp;&nbsp;', EOL);  
  append2html('<EM>Copyright</EM> &copy; 2009&nbsp;&nbsp;&nbsp;', EOL);
  append2html('</SMALL>', EOL);
  append2html('</P>', EOL);

  append2html('<H3>Generated Index of Files in Compiler Course</H3>', EOL);

  % the <table> with index content
  append2html('<TABLE>', EOL);
  entry = 1;
  ncol=3;          % three index columns
  nrow=25;         % 25 rows per index page

  blank = cell(ncol+2);
  blank{1} = '<TR>';  % prepare separater between pages of index
  for i=1:ncol
    blank{i+1} = '<TD>&nbsp;</TD>'; 
  end
  blank{ncol+2} = '</TR>';

  for pages=1:100  % used inf in the "old days", like C for(;;)
    % capture data a page at a time
    name = cell(0);% the names to display
    loc = cell(0); % the URLs to reach the file
    for col = 1:ncol               % a column at a time
      for row = 1:nrow
        if entry <= nf
          ii = idx(entry);         % grab next entry from unsorted data
          txt = fileNames{ii};
          pth = filePaths{ii};
          entry = entry + 1;
        else
          txt = '&nbsp;';          % off the end of the index list
          pth = '';
        end
        name{row,col} = txt;       % 2-D layout
        loc{row,col} = pth;
      end
    end

    % lay out one page
    for row = 1:nrow               % layout by rows (that's HTML folks)
      append2html('<TR>', EOL);       % start row
      for col = 1:ncol
        append2html( '  <TD> ');  % add item to row
        if ~isempty(loc{row,col})
          append2html('<A HREF="', loc{row,col}, '" ', '> ');
          append2html(name{row,col}, ' </A>');
        else
          append2html('&nbsp;'); % leave blank item
        end
        append2html('</TD>', EOL);% end item
      end
      append2html('</TR>', EOL);  % end row
    end
    % separate index pages with a blank <table> row
    append2html(blank{:}, EOL, blank{:}, EOL);
    if entry > nf; break; end      % limit 100 on pages is ignored
  end
  append2html('</TABLE>', EOL);    % complete HTML <table>

  % finish off page shape and margins
  append2html('</TD><TD WIDTH="50"></TD></TR>', EOL);
  append2html('</TABLE>', EOL);
  append2html('</BODY>', EOL);
  append2html('</HTML>', EOL);

  fh = fopen('Index.html', 'w');    % write the HTML index file
  fwrite(fh, [htmltxt{:}]);
  fclose(fh);
  cd ../m %#ok<*MCCD>
  return

  function append2html(varargin)    % collect text for later horzcat
    for str=1:numel(varargin)
      htmltxt{htmlidx} = varargin{str};
      htmlidx = htmlidx + 1;
    end
  end
    
end
