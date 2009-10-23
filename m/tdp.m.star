% FILE:        tdp.m
% PURPOSE:     Top-down Machine to execute iogs
% COPYRIGHT:   2008 W. M. McKeeman.  You may do anything you like
%              with this file except remove or alter this notice.
% MODS:	       2008.06.22 -- mckeeman -- original
% WORK IN PROGRESS

function obj = tdp(grammar)
  EOL = 10;                                      % ASCII end of line
  iog = grammar;
  isLhs = false(1,128);                          % false means no
  lhs = [];
  rhs = {};
  tables();                                      % build parsing tables
  goal = lhs(1);                                 % first lhs is goal
  ruleCt = numel(lhs);
  output = '';                                   % placeholders
  input = '';
  ip = 1;
  
  obj = public();
  return;
  
  % ----------------------------------------------------
  
  function o = parse(i)
    input = i;
    ip = 1;
    t = apply(goal);
    if t && ip == numel(input)
      o = output;
    else
      
  end

  % apply a phrase name
  function res = apply(phraseName)
    assert(isLhs(phraseName));
    [s,f] = range(phraseName);
    for rno = s:f
      phrase = rhs{rno};
      eno = 1;
      ipo = ip;
      oct = 0;                                   % output count
      while true
        switch rhs(eno)
          case ''''                              % input
            eno = eno+1;
            if rhs(eno) == input(ipo)
              eno = eno+1;
              ipo = ipo+1;                       % next input ch
            else
              output = output(1:end-oct);        % undo local output
              res = false;
              return;
            end
            assert(rhs(eno) == '''');
            eno = eno+1;
          case '"'                               % output
            eno = eno+1;
            output = [output rhs(ipo)];
            eno = eno+1;
            assert(rhs(eno) == '"');
            eno = eno+1;
          case ';'                               % success
            res = true;
            ip = ipo;                            % update input ptr
            return;
          otherwise                              % phrase names
            assert(isLhs(rhs(eno)));
            t = apply(rhs(eno));
            if t
              eno=eno+1;
            else
              output = output(1:end-oct);        % undo local output
              res = false;
              return;
            end
        end
      end
    end
  end

  % find the range of rules defining phrase name
  function [s,f] = range(phraseName)
    s = 0;
    f = ruleCt;                                  % default
    for rno = 1:ruleCt
      if s==0 && lhs(rno)==phraseName
        s = rno;                                 % start here
      end
      if s~=0 && lhs(rno~=phraseName)
        f = rno-1;                               % finish here
        break;
      end
    end
  end

  function tables()
    idx = 1;
    rn  = 0;
    while idx <= numel(iog)                      % walk the grammar
      phraseName = iog(idx);
      assert(isLetter(phraseName));
      rn = rn+1;                                 % new rule
      lhs(rn) = phraseName;                      % record lhs
      isLhs(rn) = true;
      idx = idx+1;
      assert(iog(idx) == '=');                   % lhs = rhs
      idx = idx+1;                               % pass =
      startPhrase = idx;
      while true                                 % gather rhs
        if iog(idx)==';'
          rhs{rn} = iog(startPhrase:idx);        % including ;
          break;
        end
        idx = idx+1;                             % keep looking
      end
      idx = idx+1;                               % pass ;
    end
  end
  
  function res = isLetter(ch)
    res = 'a'<=ch && ch<='z' || 'A'<=ch && ch<='Z';
  end

  function res = isDigit(ch)
    res = '0'<=ch && ch<='9';
  end

  function dump()
    fprintf('%s\n', lhs);
    fprintf('%s\n', rhs);
  end

  function obj = public()
    obj = struct;
    obj.parse = @parse;
  end
end