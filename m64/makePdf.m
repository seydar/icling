% FILE:     makePdf.m
% PURPOSE:  make pdf files from latex files in /doc
%
% OVERVIEW:
%   Using MikTex, a LaTeX file can be compiled into a dot-pdf file.
%   Run this function in the mxcom directory
% METHOD:
%   LaTeX and friends are called from MATLAB using the system command.
%   
% ARGUMENTS
%   The arguments to makepdf are strings. 
%   If an argument starts with '-', it is interpreted as a flag.
%   If an argument is valid path name to a LaTeX source file (dot-tex), 
%   the file will be processed by the system into a dot-pdf file.
%
% FLAGS
%   -pdfTrace    follow steps of computation
%   -latexLog    dump log for LaTeX step to command window
%
% EXAMPLE:
%   makePdf -latexLog -pdfTrace ReferenceX.tex
%
   
% COPYRIGHT W.M.McKeeman 2007.  You may do anything you like with 
% this file except remove or modify this copyright.

function makePdf(varargin)

  pdfTrace = false;
  latexLog = false;
  
  cd ../doc
  
  for i=1:numel(varargin)
    arg = varargin{i};
    if arg(1) == '-'
      if strcmp(arg, '-pdfTrace'); pdfTrace = true; end
      if strcmp(arg, '-latexLog'); latexLog = true; end
    elseif numel(arg)>4 && strcmp(arg(end-3:end), '.tex')
      cmd = ['latex ' arg];
      if pdfTrace; traceCmd(cmd); end
      try system(cmd); catch L; cd ../m; rethrow(L); end
      filename = arg(1:end-4);
      cmd = ['dvips -Ppdf ' filename '.dvi'];
      if pdfTrace; traceCmd(cmd); end
      try system(cmd); catch D; cd ../m; rethrow(D); end
      cmd = ['ps2pdf ' filename '.ps'];
      if pdfTrace; traceCmd(cmd); end
      try system(cmd); catch P; cd ../m; rethrow(P); end
      if latexLog; type([filename '.log']); end
    else
      cd ../m
      errPdf(['bad argument ' arg]);
    end
  end
  cd ../m
end

function traceCmd(cmd)
  fprintf('makePdf: %s\n', cmd);
end

function errPdf(msg)
  error(['Error makePdf: ' msg]);
end

  
