% FILE:     Lexer.m
% PURPOSE:  lex X text
%
% OVERVIEW:
%   Lexer.m provides an object containing a sequence of lexemes from the
%   source input, and constant values identifying the kinds of lexemes. 
%   The lexer is called by Parser.m.
%
%   Reserved lexemes are identified from the X cfg as presented in the cfg
%   input object.  Each reserved lexeme has a unique kind value. The
%   lexemes include two kinds of identifiers.  The first is the
%   conventional identifier consisting of letter and digits.  The second is
%   an operator identifier consisting of a sequence of so-called operator
%   characters.  The lexemes also include numbers, separators and white
%   space.  The cfg information is passed on, as a read-only field in the
%   lexer object, to the consumer of the lexer output.
%
% TEST:     testLexer.m
%
% EXAMPLE:  
%   %The input to the Lexer ctor is a cfg object.
%   cfg = Cfg(xread('X.cfg'), {'-noLR'});
%   lexobj = Lexer(cfg, 'x:=13789;');
%
%   % static fields of the Lexer object are always available.
%   x = lexobj.ID
%
%   % The results are persistent in the object.
%   % The vectors of token descriptions are
%   knd = lexobj.kind()
%   st  = lexobj.start()
%   en  = lexobj.finish()
%
%   % The kind of the i-th token is
%   i = 3;
%   k = knd(i)           % The kind of an unrecognized token is 0.
%
%   %The spelling t of the i-th token is
%   st = lexobj.start();  fn = lexobj.finish();
%   src = lexobj.src();  % Kept in the lexer object.
%   t = src(st(i):en(i))
%
%   % The line and column of the start of the i-th token is
%   [ln,col] = lexobj.lineCol(st(i))
%
%   lexobj.dump();      % Look at the tables

% COPYRIGHT W.M.McKeeman 2006.  You may do anything you like with 
% this file except remove or modify this copyright.
% IMPLEMENTATION:
%   The whole text is first examined to record alpha, numeric and white
%   positions.  That information applied to the leading character is used
%   to dispatch the kind of lexeme. The dispatch leads to a section of code
%   for each kind of token where the right end is determined.  The end 
%   points are recorded and then the delimited text is looked up to see if 
%   it is reserved.
%  
%   This lexer is designed for readability and ease of modification.
%   Traditional lexers are more efficient, using a switch on the
%   leading character instead of cascaded if-elseif discrimination and fast
%   lookup for reserved words.  If large languages are expected, the lexer
%   needs to be made more efficient.  

function lexobj = Lexer(cfg, src)                % ctor

  assert(isstruct(cfg), ...
    'Lexer input cfg must be type struct but is %s\n', class(cfg));
  assert(ischar(src), ...
    'Lexer input src must be type char but is %s\n', class(src));
  % persistent fields of the Lexer object
  rw    = cfg.reserved();    % make reserved table
  ops   = cfg.opchar();      % characters used
  EOL   = 10;                % ASCII CTRL-J
  % the order of calls here matters
  ID    = idCode();          % generic identifier
  OP    = opCode();          % generic operator
  INT   = intCode();         % generic integer literal
  REAL  = realCode();        % generic real literal
  WHT   = whiteCode();       % generic whitespace
  CMNT  = commentCode();     % generic comment
  EOF   = eofCode();         % eof token code
  LIM   = limit();           % biggest token code

  % -------------- public methods/fields/values -----------------

  kind   = zeros(1, 100, 'uint8');               % storage for results
  start  = zeros(1, 100, 'uint32');
  finish = zeros(1, 100, 'uint32');
  tp     = 0;                                    % token pointer
  src    = [src 0];                              % end marker
  
  % Each entry in the table of reserved words starts with some
  % ASCII character (in the range 1-127).  Each time a lexeme
  % is delimited, it must be looked up to see if it reserved.
  % (See lexlookup below).  The following rws table records the
  % first possible entry based on the first character of the lexeme.
  % If the table contains 0 for that character, the lexeme is not
  % in the table.  Otherwise, the lookup can begin at the first
  % possible location instead of the beginning of the table.
  % This is a weak substitute for a hashed dictionary lookup.
  rws =  zeros(1,128);                           % for fast lookup
  for ri=numel(rw):-1:1; rws(double(rw{ri}(1))) = ri; end
  
  lex();                                         % do the work
  lexobj = public();                             % public methods/fields
  
  return;               % end of constructor
  
  % ------------------ nested functions ------------------

  % lex entire input, fill vectors of results
  function lex()
    cp = 1;                            % first char
    tp = 1;                            % first token
    alf = isstrprop(src, 'alphanum');  % prescan
    dig = isstrprop(src, 'digit');
    wht = isstrprop(src, 'wspace');
    
    while true                         % process entire file
      currtok = 0;                     % token code not yet known
      r = numel(src);                  % limit in case all else fails
      if cp >= r
        currtok = EOF;                 % nothing more to lex
        
      elseif dig(cp)                   % 123
        for i=cp:r
          if ~dig(i)                   % one beyond integer part
            t = i;
            break;
          end
        end
        if src(t) == '.'               % 123.456
          for j=t+1:r
            if ~dig(j)                 % one beyond fraction
              t = j;
              break;
            end
          end
          currtok = REAL;
        else
          currtok = INT;
        end
        r = t;

      elseif alf(cp)                   % xyz123 (leading digit seen above)
        for i=cp+1:r
          if ~alf(i)                   % one beyond id
            r = i;
            break;
          end
        end
        currtok = ID;

      elseif any(src(cp) == ops)       % +-* etc
        for i=cp+1:r
          if all(src(i) ~= ops) 
            r = i;                     % one beyond op id
            break;
          end
        end
        currtok = OP;

      elseif src(cp) == '`'            % comment
        for i=cp+1:r
          if src(i) == EOL 
            r = i+1;                   % skip over EOL
            break;
          end
        end
        currtok = CMNT;

      elseif wht(cp)                   % white space
        for i=cp+1:r
          if ~wht(i)                   % one beyond white space
            r = i;
            break
          end
        end
        currtok = WHT;

      else
        r = cp+1;                      % single char
      end

      % reserved word lookup -- exclude WHT, CMNT, INT, REAL, EOF
      if currtok == ID || currtok == OP || currtok == 0
        t = lexlookup(cp,r-1);
        if t ~= 0                      % found it
          currtok = t;
        end
      end
      nk = numel(kind);
      if nk <= tp                      % preallocate
        kind(2*nk) = 0;                % 100, 200, 400, etc.
        start(2*nk) = 0;
        finish(2*nk) = 0;
      end
      kind(tp) = currtok;
      start(tp) = cp;
      finish(tp) = r-1;
      cp = r;                          % next start chr
      tp = tp + 1;                     % next token slot
      if currtok == EOF; break; end    % all done
    end  % end of main lex loop
    kind   = kind(1:tp-1);             % discard overallocations
    start  = start(1:tp-1);
    finish = finish(1:tp-1);
  end

% ------------------ public methods ------------------

  function n = getCt()                 % token count
    n = tp-1;
  end

  % --- after-the-fact line and column number information ---
  % --- line and column are 1-based
  
  function [ln,col] = getLineCol(errloc)
    ln = 0;  col = 0;
    errloc = min(errloc, numel(src));           % avoid eof effect
    if errloc == 0, return; end                 % no line or col
    errstr = src(1:errloc);
    ln = sum(errstr==EOL);                      % count line ends
    if src(errloc) ~= EOL
      t = max(strfind(errstr, EOL));
      ln = ln+1;                                % 1-based
    else
      t = max(strfind(errstr(1:end-1), EOL));
    end;
    if isempty(t)                               % not there
      t = 0;
    end
    col = numel(errstr) - t;
  end

  % ------------------- dumper ----------------------------

  function dump()                      % for testing
    disp 'Lexer: ---------- start dump --------------'
    cnt = zeros(1,LIM);                % count kinds
    for i=1:getCt()                    % count tokens
      tok = kind(i);
      fprintf('tok: %d %s\n', tok, ...
        src(start(i):finish(i)));
      if tok ~= 0
        cnt(tok) = cnt(tok)+1;         % just to see...
      end
    end
    fprintf('Lexer: %d tokens, %d whitespace %d comment %d IDs\n',...
      getCt(), cnt(WHT), cnt(CMNT), cnt(ID));
    disp 'Lexer: ---------- end   dump --------------'
  end

  % ---------------- private methods -------------------
  
  % reserved symbol lookup
  function code = lexlookup(st,en)
    code = 0;                                    % pessimistic
    if en<st                                     % null input
      code = EOF;                                % to stop lex
      return
    end
    
    % faster lookup:
    %  0. (at call) look only for ID and OP and single chars
    %  1. do not copy lexeme (pass indices instead)
    %  2. don't look if can't be there (leading character)
    %  3. start rws at first possible match
    %  4. early loop exit when character comparison fails
    %  5. early lookup exit when string comparison succeeds
    %  -------------functionally the same as---------------
    
    %  for i=1:numel(rw)
    %    if strcmp(src(st:en), rw{i};
    %      code = i; return;
    %    end
    %  end
    
    %------------------------------------------------------
    ar = rws(double(src(st)));                   % starting point
    if ar == 0; return; end                      % not in rw
    
    for i=ar:numel(rw)                           % starting point
      tb = rw{i};                                % get rw from cell array
      lp = en-st+1;                              % the input length
      if numel(tb) == lp                         % both same length?
        failed = false;                          % yes, so compare
        for j=1:lp                               % loop instead of strcmp
          if src(st+j-1) ~= tb(j)                % does not require copy 
            failed = true;                       % found difference, quit
            break;
          end
        end
        if ~failed                               % compared equal
          code = i;                              % found rw
          return;                                % stop looking
        end
      end
    end

  end  % of lexlookup

  % ---- values for the nonstandard reserved words ------------
  function tok = idCode()
    for i=1:numel(rw)
      if strcmp(rw{i}, ' id')
        tok = i;
        break;
      end
    end
  end

  function tok = intCode()
    for i=1:numel(rw)
      if strcmp(rw{i}, ' integer')
        tok = i;
        break;
      end
    end
  end

  function tok = realCode()
    for i=1:numel(rw)
      if strcmp(rw{i}, ' real')
        tok = i;
        break;
      end
    end
  end

  function tok = eofCode()
    for i=1:numel(rw)
      if strcmp(rw{i}, ' eof')
        tok = i;
        break;
      end
    end
  end

  function tok = opCode()
    tok = numel(rw)+1;
  end

  function tok = commentCode()
    tok = opCode()+1;
  end

  function tok = whiteCode()
    tok = commentCode()+1;
  end

  function tok = limit()
    tok = commentCode()+1;
  end

  % ------------------ collect public fields/methods ---------------
  function o = public()
    o = struct;
    % static fields
    o.cfg     = cfg;                             % pass along
    o.src     = src;                             % needed for lexeme text
    o.ID      = ID;                              % generic identifier
    o.INT     = INT;                             % generic integer literal
    o.REAL    = REAL;                            % generic real literal
    o.WHT     = WHT;                             % generic whitespace
    o.CMNT    = CMNT;                            % generic comment
    o.EOF     = EOF;                             % eof token code
    o.LIM     = LIM;                             % max token kind end  
    o.lim     = getCt();                         %   token count
    o.kind    = kind;                            %   kind of token
    o.start   = start;                           %   start of token text
    o.finish  = finish;                          %   end of token text
    
    % member functions
    o.dump    = @dump;                           % for tests and debugging
    o.lineCol = @getLineCol;                     % for errors
  end

end % of lex