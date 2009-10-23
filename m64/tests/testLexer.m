% FILE:     testLexer.m
% PURPOSE:  unit test lexer
% REQUIRES: Lexer.m
% METHOD:   a series of small tests of related constructs
% USAGE:    testLexer(t1, t2...)  % for tests t1, t2
% EXAMPLE:
%    testLexer()  % for all tests

% COPYRIGHT W.M.McKeeman 2006.  You may do anything you like with 
% this file except remove or modify this copyright.

function testLexer(varargin)           % empty means all tests

  tn     = [varargin{:}];              % cell to vector
  allt   = isempty(tn);                % no arg at all
  load(fullfile(mxcomRoot, 'cfg.mat'), 'cfg');   % use saved cfg object
  rw     = enum(cfg.reserved);         % set up tables
  pass   = 0;                          % none yet
  
  if allt || any(tn == 1)              % gold test
    lexobj = Lexer(cfg, 'x  := 13333');
    lim     = lexobj.lim;                        %   token count
    kind    = lexobj.kind;                       %   kinds of token
    start   = lexobj.start;                      %   starts of token texts
    finish  = lexobj.finish;                     %   ends of token texts
    % The following
    assert(lim == 6);              pass = pass + 1;
    assert(kind(1) == lexobj.ID);  pass = pass + 1;
    assert(kind(2) == lexobj.WHT); pass = pass + 1;
    assert(kind(3) == rw.COLONEQ); pass = pass + 1;
    assert(kind(4) == lexobj.WHT); pass = pass + 1;
    assert(kind(5) == lexobj.INT); pass = pass + 1;
    assert(kind(6) == lexobj.EOF); pass = pass + 1;
    assert(start(1) == 1);         pass = pass + 1;
    assert(start(2) == 2);         pass = pass + 1;
    assert(start(3) == 4);         pass = pass + 1;
    assert(start(4) == 6);         pass = pass + 1;
    assert(start(5) == 7);         pass = pass + 1;
    assert(start(6) == 12);        pass = pass + 1;
    assert(finish(1) == 1);        pass = pass + 1;
    assert(finish(2) == 3);        pass = pass + 1;
    assert(finish(3) == 5);        pass = pass + 1;
    assert(finish(4) == 6);        pass = pass + 1;
    assert(finish(5) == 11);       pass = pass + 1;
    assert(finish(6) == 11);       pass = pass + 1;
  end
  
  if allt || any(tn == 2)              % smoke test
    src = 'x  := 1 + 22 * 333/4444 `comment';
    lexobj = Lexer(cfg, src);
    assert(lexobj.lim == 18);      pass = pass + 1;
    newsrc = '';
    for i=1:18
      newsrc = [newsrc src(lexobj.start(i):lexobj.finish(i))]; %#ok
    end
    assert(strcmp(newsrc, src));   pass = pass + 1;
    dsrc = '';  % discard white space and try again
    dkind = lexobj.kind~=lexobj.WHT;
    dstart = lexobj.start(dkind);
    dfinish = lexobj.finish(dkind);
    for i=1:numel(dstart)
      dsrc = [dsrc src(dstart(i):dfinish(i))]; %#ok<AGROW>
    end
    assert(strcmp(dsrc, src(src~=' ')));  pass = pass + 1;
  end
  
  fprintf('Lexer: passed %d unit tests\n', pass);
end %  of testLexer


