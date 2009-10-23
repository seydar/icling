% FILE:     timeLexer.m
% PURPOSE:  time lex of X text
% EXAMPLE:     
%  timeLexer()

% COPYRIGHT W.M.McKeeman 2006.  You may do anything you like with 
% this file except remove or modify this copyright.

function timeLexer()
  load(fullfile(mxcomRoot, 'cfg.mat'), 'cfg');   % use saved cfg object
  i1 =...
  'a,b:= bb,ccc; if a < 1+1.00001 ? x := r2i(rand*i2r(13))::true?x:=1;fi;';
  i2=...
  'do i<100 ? i:=1+1; od; z := (((((((((101)))))))));';
  i3=...
  'c := (a+b-c*d/e//f)<3 & (b1|b2&~b3) & 1<=2 & 2 <=3000 & a == b;';
  i4 =...
  'longishid:=another+1234567890/21345.987661-3.1415926535894;';
  iall = [i1 i2 i3 i4];
  input = '';
  for i=1:100; input = [input iall]; end         %#ok<AGROW>

  tstart = tic();
  L = Lexer(cfg, input);
  telapsed = toc(tstart);
  
  fprintf('time lex %d tokens, %d sec\n', L.lim, telapsed);
end

% 0.60 sec