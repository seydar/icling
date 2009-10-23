% FILE:     Proposition.m
% PURPOSE:  recursive parser for propositions
% USAGE:    sr = Proposition(src)
%
% Proposition = Disjunction                      0
% Disjunction = Disjunction | Conjunction        1
% Disjunction = Conjunction                      2
% Conjunction = Conjunction & Negation           3
% Conjunction = Negation                         4
% Negation    = ~ Boolean                        5
% Negation    = Boolean                          6
% Boolean     = t                                7
% Boolean     = f                                8
% Boolean     = ( Disjunction )                  9
%
% EXAMPLE:
%    sr = Proposition('t|f')

% COPYRIGHT W.M.McKeeman 2007.  You may do anything you like with 
% this file except remove or modify this copyright.

function sr = Proposition(src)

  EOF  = 0;  src = [src EOF];   % append artificial EOF
  next = ''; ip  = 1; scan();   % initialize next
  sr   = ''; op  = 1;           % next avail output position
    
  Disjunction();
  
  switch next
    case EOF; reduce('0');
    otherwise; error('missing EOF'); 
  end
  
  return;              % end of main function
  
  % ------------- nested functions ------------
  function Disjunction()
    Conjunction(); reduce('2');
    while next == '|'
      shift(); Conjunction(); reduce('1');
    end
  end

  function Conjunction()
    Negation(); reduce('4');
    while next == '&'
      shift(); Negation(); reduce('3');
    end
  end

  function Negation()
    switch next
      case '~'; shift(); Boolean(); reduce('5');
      otherwise; Boolean(); reduce('6');
    end
  end

  function Boolean()
    switch next
      case 't'; shift(); reduce('7');
      case 'f'; shift(); reduce('8');
      case '('; shift(); Disjunction();
        switch next
          case ')'; shift(); reduce('9');
          otherwise; error('missing )');
        end
      otherwise; error(['unexpected operand ' next]);
    end
  end

  function shift()
    emit(next); scan();
  end

  function reduce(r)
    emit(r);
  end

  function scan()
    next = src(ip); ip = ip+1;
  end

  function emit(s)
    sr(op) = s; op = op+1;
  end

end