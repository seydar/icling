% FILE:     timeParser.m
% PURPOSE:  exercise parser
% REQUIRES: Cfg.m Lexer.m Parser.m
% USAGE:    timeParser(t1, t2...) for tests t1, t2...
% EXAMPLE:
%  timeParser() % for all tests

% COPYRIGHT W.M.McKeeman 2006.  You may do anything you like with 
% this file except remove or modify this copyright.


function timeParser(varargin)          % empty means all tests
  EOL    = 10;                         % end of line
  tn     = [varargin{:}];              % cell to vector
  allt   = isempty(tn);                % no arg at all
  load(fullfile(mxcomRoot, 'cfg.mat'), 'cfg');   % use saved cfg object
  
  disp 'timeParser: ---- start trials -------------------------------'
  pos = {
    ''                                 % 1
    [...                                 6
      '` FILE:    fibbonacci.x'         EOL ...
      '` PURPOSE: recursive Fibbonacci' EOL ... 
      '`          input n, output fib'  EOL ...
                                        EOL ...
      'p := n;'                         EOL ...
      'if p <= 1 ? fib := 1'            EOL ...
      ':: p > 1  ?'                     EOL ... 
      '  fib := fibbonacci := p-1;'     EOL ...
      '  tmp := fibbonacci := p-2;'     EOL ...
      '  fib := fib + tmp'              EOL ...
      'fi'                              EOL ...
    ]
  };
  
  longish = ['` FILE: none really' EOL];
  longish = [longish '`PURPOSE: race parsers' EOL];
  longish = [longish 'x := 1000000.0;' EOL];
  for lng = 1:1000
    longish = [longish 'x := x * rand;' EOL]; %#ok
  end
  pos{end+1} = longish;
  
  for t = 1:length(pos)
    if allt || any(tn == t)
      timeit(t);
    end
  end  
  disp 'timeParser: ---- end trials -------------------------------'
    
  return;

  %------------------ nested functions -------------------------
  function timeit(t)
    fprintf('timeParser: trial %d\n', t);
    aLexer = Lexer(cfg, pos{t});
    aParse = Parser(aLexer);                     %#ok warm them up
    aParse = Parser(aLexer, {'-bottomup'});      %#ok
    tpar = tic;
    aParse = Parser(aLexer);                     %#ok
    top = toc(tpar);
    tpar = tic;
    aParse = Parser(aLexer, {'-bottomUp'});      %#ok
    bot = toc(tpar);
    fprintf(['len(src)=%6d topDown  = %g sec\n',...
             '                bottomUp = %g sec\n'],...
      numel(pos{t}), top, bot);
  end

end
%{
timeParser: ---- start trials -------------------------------
timeParser: trial 1
len(src)=     0 topDown  = 0.0136216 sec
                bottomUp = 0.0138434 sec
timeParser: trial 2
len(src)=   207 topDown  = 0.0271043 sec
                bottomUp = 0.0301756 sec
timeParser: trial 3
len(src)= 15059 topDown  = 2.00347 sec
                bottomUp = 2.36757 sec
timeParser: ---- end trials -------------------------------
%}

