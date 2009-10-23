% FILE:     xcom.m
% PURPOSE:  compile and go for X on Intel X86
%
% USAGE: XCOM 'x:=1'
%   Compile and go for the X program in string 'x:=1'.
%
% USAGE: XCOM('x/src.x')
%   Compile and go for the X program in file x/src.x.
%
% USAGE: XCOM(flagsN, srcN, ... flags2, src2, flags1, src1)
%   Compile and go; src1 is the main program.
%
% FLAGS:
%          global flags
%  -noExecute      do not execute compiled program
%  -xcomTrace      trace xcom (main program)
%  -xcomTime       time xcom compiler 
%  -frameDump      dump main X frame after execution 
%  -matlabStack    dump MATLAB stack on error
%  -interactive    interpret compiled subprograms (interactive)
%  -emulate        interpret compiled subprograms (nonstop no output)
%  -exeTrace       interpret compiled subprograms (nonstop w/output)
%  -noAST          use syntax tree instead of AST
%          per-file flags
%  -srcDump        dump the source for this file
%  -lexDump        dump the lexemes
%  -parseDump      dump the shift/reduce sequence
%  -treeDump       dump the syntax tree
%  -symDump        dump the symbol table
%  -asmDump        dump the hex assembly code
%
%  -parseTrace     trace the parser
%  -treeTrace      trace the syntax tree construction
%  -symTrace       trace the symbol table construction
%  -genTrace       trace the generator actions
%  -emitTrace      trace the emitter actions
%  -asmTrace       trace the assembly code construction
%  -asmHex         trace the assembly code at byte level
%
%  -bottomUp       use LR1 tables instead of recursive parser
%
% EXAMPLES:
%  xcom x:=1
%  xcom x/smoke.x
%  xcom('-symDump', 'x/called.x', '-asmTrace', 'x/caller.x')
%
% OVERVIEW: 
%   XCOM is a compile-and-go implementation of the X language.  
%   If there is no implementation for the underlying hardware,
%   the 'go' step will be Intel x86 emulation (slow).
%   
%   The form of the language is given in file X.cfg.  
%   It is patterned after Dijkstra's language in 
%   {\em A Discipline of Programming}.  
%
%   The meaning of the language is largely conventional.  
%   There are three types (logical, integer and real).  
%   They map into true/false, 32 bit ints and IEEE 32bit floating point.  
%   The type of constants is manifest in their form.
%
%   The arguments to XCOM are strings.  
%   If an argument is valid path name to an X source file (dot-x), 
%   the file will be read; if the argument is a valid flag,
%   it will be used to direct the next compilation; 
%   otherwise the argument itself is taken as X source.  
% 
%   If xcom has more than one source input, 
%   the last one is taken as the main program; the rest are subprograms. 
%
%   The X language is strongly typed.  
%   The type of variables is inferred from use.  
%   It is possible to write an X program where the type cannot be inferred;
%   XCOM will report an error.
%
%   The final value of variables used only on the left of assignments in
%   the main program will be reported as output.  
%   The value of variables never used on the left in the main program 
%   will require input prior to execution.
%
%   X programs may call each other.  The subprogram inputs and outputs map 
%   in order into arguments and returned values.  
%   X programs can call C and/or M functions.
%
%   The design focus for xcom is ease of understanding and extensibility.
%

% COPYRIGHT W.M.McKeeman 2007.  You may do anything you like with 
% this file except remove or modify this copyright.
%
% IMPLEMENTATION:
%   XCOM is implemented as a set of MATLAB functions, each acting as a
%   constructor for a corresponding object.  The value of a constructor
%   function is a struct containing the member functions and fields.  
%   The individual modules also have HELP.
%   
%   The implementation behind the struct fields are nested variables and
%   functions.  The state of the constructed object is kept in the frame of
%   the constructor.  Each module is documented in its help section.  Each
%   module passes along its own input as a field of its result.  As a
%   consequence, for example, all of the modules below have access to the
%   Cfg object.  Such access must be read-only to avoid MATLAB copies.
%
% PREPARATION:
%   makeCfg must be run separately if changes are made to X.cfg or Cfg.m
%   makeRuntime must be run separately if changes are made to MEX files.
%
% MODULES:
%   Cfg.m reads grammar X.cfg and provides tables describing X.
%     cfg = Cfg(xread('X.cfg'))
%   Lexer.m reads an X source file and provides a lexeme stream.
%     lexed = Lexer(cfg, xread('f.x'))
%   Parser.m requires a lexeme stream and provides a shift/reduce sequence.
%     parsed = Parser(lexed)
%   Tree.m requires a shift/reduce sequence and provides a syntax tree.
%     tree = Tree(parsed)
%   Symbols.m requires a function name and a syntax tree; it provides a 
%     symbol table.
%     sym = Symbols(fn, tree)
%   Asmx86.m provides Intel x86 emitters, runtime and execution.
%     asm = Asmx86();
%   Generator.m requires the front end results and an assembler; it
%     chooses x86 code.
%     gen = Generator(fe, asm)
%   Compiler.m requires a generator and populates asm with an executable.
%     Compiler(gen)
%   xcom.m does all of the above for one or more X files and links them.
%     xcom sub1.x sub2.x main.x
%
% UNIT TESTS
%   Each module M.m has a unit test in tests/testM.m
%   testAll.m calls all the tests in sequence.
% UNIT TRIALS
%   Each module M.m has a unit trial in trials/tM.m
%   tryAll.m calls all the trials in sequence.
% TIMING
%   For curiosity only, there are some timing runs in times/*.m.

function xcom(varargin)   

  % process all the xcom arguments, read files, record data for later use
  ct       = 0;                                  % 0 subprograms so far
  subNames = {};                                 % subprogram names
  subFlags = {};                                 % per subprogram flags
  allFlags = {};                                 % global flags
  rawt = tic;                                    % time arg processing
  for a = 1:numel(varargin)                      % all args
    arg = varargin{a};
    switch classify(arg)                         % examine xcom arg
      case 'src'
        ct = ct + 1;                             % a source input
        src{ct} = arg;                           %#ok X source
        subNames{ct} = '';                       %#ok no name
      case 'file'
        arg(arg == '\') = '/';                   % unix name
        ct = ct + 1;                             % a file input
        src{ct} = xread(arg);                    %#ok get the source
        last = max(strfind(arg, '/'));
        if isempty(last), last = 0; end          % no path /
        subNames{ct} = arg(last+1:end-2);        %#ok callable name
      case 'subFlag'                             % per subprogram flags
        if numel(subFlags)<=ct; subFlags{ct+1} = {arg};   %#ok 
        else subFlags{ct+1} = [subFlags{ct+1} arg];      %#ok
        end
      case 'allFlag'                             % global flags
        allFlags = [allFlags arg];               %#ok
      otherwise
        xErr(['failed to classify ' arg]);
    end
  end
  if numel(subFlags)<ct; subFlags{ct}={''}; end  % fill out flags
  
  switch computer
    case {'PCWIN', 'GLNX86', 'MACI'}
    otherwise  % force emulation of one kind or another
      if ~(findFlag('-emulate', allFlags)      ...
      ||   findFlag('-exeTrace', allFlags)     ...
      ||   findFlag('-interactive', allFlags))
        allFlags{end+1} = '-emulate';
      end
  end
  
  t1 = toc(rawt);                                % end of command line

  TR('enter'); 
  
  rawt=tic;                                      % start front end

  % Make new Cfg tables if X.cfg is newer than cfg.mat
  root = mxcomRoot();
  dirc = dir(fullfile(root, 'X.cfg'));           % source
  dirs = dir(fullfile(root, 'cfg.mat'));         % saved
  if numel(dirs) == 0 
    xErr('must first run >> makeCfg X.cfg -saveMat');
  end
  if dirc.datenum > dirs.datenum 
    fprintf('warning: file X.cfg has changed since writing file cfg.mat\n');
  end
  load(fullfile(root, 'cfg.mat'), 'cfg');        % use saved cfg object
  t2 = toc(rawt);
  
  % ---------------------- Front End Phase -----------------------
  rawt=tic;                                      % start front end
  % set up data structures to hold intermediate results (1 per source)
  % subNames{}, src{} and subFlags{} already set
  % steps are Lexer, Parser, Tree


  syms = cell(1,ct);                             % front end results
  checkMex();                                    % runtime integrity
  env = xenv(subNames);                          % cross-subprogram object

  for p=1:ct                                     % each subprogram
    if findFlag('-srcDump', subFlags{p})
      fprintf('begin source code ----\n')
      fprintf('%s', src{p});                     % source dump
      fprintf('\nend   source code ----\n')
    end
    
    TR('xcom Lexer');
    aLex = Lexer(cfg, src{p});                   % new lexer
    if findFlag('-lexDump', subFlags{p})
      aLex.dump();                               % afer lexing
    end
    
    TR('xcom Parser');
    ftmp = subFlags{p};
    if findFlag('-noAST', allFlags); ftmp{end+1} = '-noAST'; end  %#ok
    if findFlag('-xStack', allFlags)             % allow stack dump
      aParse = Parser(aLex, ftmp);               % parse src
    else                                         % supress stack dump
      try
        aParse = Parser(aLex, ftmp);             % parse src
      catch err
        if ~isempty(subNames{p})                 % named file
          suffix = [' in X function ' subNames{p}];
        else
          suffix = '';                           % source text as arg
        end
        msg = [err.message suffix];
        newerr = MException('', msg);            % user error
        newerr.throwAsCaller();
      end
    end
    if findFlag('-parseDump', subFlags{p})
      aParse.dump();                             % after parsing
    end
    
    TR('xcom Tree');
    aTree = Tree(aParse, subFlags{p});           % AST or syntax tree
    if findFlag('-treeDump', subFlags{p})
      aTree.dump();                              % after tree building
    end
    trees{p} = aTree;                            %#ok save the tree
  end
  t3 = toc(rawt);                                % end of front end

  % ------------------ Symbol Analysis Phase ---------------------------
  TR('xcom Symbols');
  rawt=tic;                                      % start front end
  totalUndefs = inf;                             % force complete phase
  while true                                     % repeatedly examine src
    for p=1:ct                                   % each source input
      % process each individual X source in context of all inputs
      if findFlag('-matlabStack', allFlags)      % allow MATLAB stack dump
        aSym = Symbols(trees{p}, p, syms, subNames{p}, subFlags{p});
      else                                       % no MATLAB stack dump
        try
          aSym = Symbols(trees{p}, p, syms, subNames{p}, subFlags{p});
        catch err
          suffix = '';                           % not named file
          if ~isempty(subNames{p})
            suffix = [' in X function ' subNames{p}];  % named file
          end
          msg = [err.message suffix];
          newerr = MException('', msg);          % user error
          newerr.throwAsCaller();
        end
      end
      syms{p} = aSym;                            % results for p-th src
    end
    tot = 0;
    for p=1:ct
      tot = tot + syms{p}.notDef();
    end
    if tot == totalUndefs                        % no change
      if tot > 0                                 % bad defs somewhere
        if findFlag('-matlabStack', allFlags)    % dump MATLAB stack
          symErrors(syms);
        else                                     % supress stack dump
          try
            symErrors(syms);
          catch err
            msg = err.message;
            newerr = MException('', msg);
            newerr.throwAsCaller();
          end
        end
      end
      break;                                     % all def
    else
      totalUndefs = tot;
    end
  end
  for p = 1:ct
    if findFlag('-symDump', subFlags{p})
      aSym.dump();                               % of single file analysis
    end
  end
  t4 = toc(rawt);                                % end of front end

  % ------------------ Back End Phase ------------------
  rawt = tic;                                    % start back end

  exePtr  = env.getEntriesAddress();             % hardware address
  frmPtr  = env.getSizesAddress();               % hardware address
  bes     = cell(ct);                            % backends

  errCt = 0;                                     % for all compiles
  
  for p=1:ct                                     % once per file
    TR('Generator');
    % check for emulation-only cases (requires pure x86 code)
    if findFlag('-matlabStack', allFlags)        % allow M stack dump
      bes{p} = Generator(p, syms, errCt, exePtr, frmPtr, ...
          subFlags{p}, allFlags);
    else                                         % supress M stack dump
      try
        bes{p} = Generator(p, syms, errCt, exePtr, frmPtr, ...
           subFlags{p}, allFlags);
      catch err
        suffix = '';                             % no named file
        myname = env.getName(p);
        if ~isempty(myname)
          suffix = [' in X function ' myname];   % named function
        end
        msg = [err.message suffix];
        newerr = MException('', msg);            % user error
        newerr.throwAsCaller();
      end
    end

    % accumulate run error list, frame sizes and entry points

    errCt = bes{p}.errorCount();                 % update errCt
    env.setSize(p, syms{p}.size() + bes{p}.ntemps());
    env.setEntry(p, bes{p}.getEntry());
    if findFlag('-asmDump', subFlags{p})
      bes{p}.dump();                             % after assembly
    end
  end
  t5 = toc(rawt);                                % end back end
  
  % execute outer program
  if ~findFlag('-noExecute', allFlags) && ct > 0
    outersize = env.getSize(ct);
    frame = zeros(1, outersize, 'int32');        % allocate outer frame

    rawt = tic;                                  % input time
    xInputs();                                   % from command window
    TR('enter execution')
    t6 = toc(rawt);
    
    rawt = tic;                                  % execution time
    if findFlag('-exeTrace', allFlags)
      [rc, frame] = bes{ct}.trace(frame, syms{ct}); % output
    elseif findFlag('-interactive', allFlags)
      [rc, frame] = bes{ct}.inter(frame, syms{ct}); % interactive
    elseif findFlag('-emulate', allFlags)
      [rc, frame] = bes{ct}.silent(frame, syms{ct});% no output
    else
      rc = bes{ct}.go(frame);                    % normal execution
    end
    t7 = toc(rawt);                              % execution
    
    if rc ~= 0                                   % runtime error
      errData = findErr(rc);
      [ln,cl] = syms{errData.file}.tree.runLineCol(errData.tok);
      fname = env.getName(errData.file);
      msg = errData.msg;
      wloc = sprintf(['xcom: ', msg, ' at line %d, column %d'],ln,cl);
      if ~isempty(fname)
        wloc = sprintf([wloc, ' of file %s'], [fname '.x']);
      end
      error(wloc)
    end
    TR('leave execution')
    rawt = tic;
    xOutputs();                                  % to command window
    t8 = toc(rawt);
    if findFlag('-xFrame', allFlags), frameDump(), end
  else
    t7 = 0;
    t8 = 0;
  end
  
  if findFlag('-xcomTime', allFlags)
    fprintf(['xcom times: \n'...
      '    cmd    %g sec\n'...
      '    cfg    %g sec\n'...
      '    fe     %g sec\n'...
      '    sym    %g sec\n'...
      '    be     %g sec\n'...
      '    input  %g sec\n'...
      '    run    %g sec\n'...
      '    output %g sec\n'], t1, t2, t3, t4, t5, t6, t7, t8);
  end

  TR('leave xcom');

  return;
  
  % ------------------- input output -------------------
  
  function xInputs()
    st = syms{ct};
    for v=1:st.size()                            % get inputs
      if st.getUse(v) == st.onRIGHT
        name = st.getName(v);
        switch st.getType(v)
          case st.boolTYPE
            prompt = ['logical input: ' name ':='];
            boolRes = input(prompt);
            if ~islogical(boolRes)
              xErr('input requires logical value');
            end
            frame(v) = int32(boolRes);           % value into var
          case st.intTYPE
            prompt = ['integer input: ' name ':='];
            intRes = input(prompt);
            if int32(intRes) ~= intRes
              xErr('input requires integer value');
            end
            frame(v) = int32(intRes);            % value into var
          case st.realTYPE
            prompt = ['real input: ' name ':='];
            doubleRes = input(prompt);
            if ~isa(doubleRes, 'double') && ~isa(doubleRes, 'single')
              xErr('input requires real value');
            end
            if numel(doubleRes) ~= 1
              xErr('input requires scalar value');
            end
            singleRes = single(doubleRes);       % down to 32 bits
            realFake = f2i(singleRes);           % pun to int32
            frame(v) = int32(realFake);          % value into var
        end
      end
    end
  end

  function xOutputs()
    st = syms{ct};
    for v = 1:st.size()                           % get outputs
      if st.getUse(v) == st.onLEFT
        name = st.getName(v);
        switch st.getType(v)
          case st.boolTYPE
            intRes = frame(v);
            if intRes == 1
              fprintf('%s := true\n', name);
            elseif intRes == 0
              fprintf('%s := false\n', name);
            else 
              xErr('botched logical output');
            end
          case st.intTYPE
            intRes = frame(v);
            fprintf('%s := %d\n', name, intRes);
          case st.realTYPE
            intRes = frame(v);
            fprintf('%s := %f\n', name, i2f(intRes));
          otherwise
            xErr('botched output type');
        end
      end
    end
  end

  %  ---------------- utilities ------------------------
  
  function symErrors(syms)
    for i=1:numel(syms)
      if syms{i}.notDef()
        syms{i}.dump();
        xErr(['types for arg ' num2str(i) ' not fully defined']);
      end
    end
  end
  
  function report = findErr(errno)               % data on run error
    for i=1:ct                                   % search compilations
      report = bes{i}.findErr(errno);
      if ~isempty(report);return; end
    end
  end

  function kind = classify(arg)                  % xcom argument processing
    if ~ischar(arg)
      xErr('arguments must be strings');
    end
    
    switch arg
      case {'-noExecute'                         % do not execute
            '-interactive'                       % like dbstep i
            '-emulate'                           % silent emulation
            '-exeTrace'                          % visible trace
            '-xcomTrace'                         % main program
            '-xcomTime'                          % time main phases
            '-frameDump'                         % dump final frame
            '-matlabStack'                       % whole stack on error
            '-noAST'                             % use whole syntax tree
            }
          kind = 'allFlag';
      case {'-srcDump'                           % dump the source
            '-lexDump'                           % dump the lexemes
            '-parseTrace'                        % trace the parser
            '-parseDump'                         % dump the shift/reduce
            '-bottomUp'                          % use LR1 tables
            '-treeTrace'                         % trace the tree ctor
            '-treeDump'                          % dump the syntax tree
            '-symTrace'                          % trace symbol ctor
            '-symDump'                           % dump complete symbol table
            '-pdfDump'                           % dump pretty .pdf file
            '-genTrace'                          % trace generator
            '-emitTrace'                         % trace emitter
            '-asmTrace'                          % trace assembler
            '-asmHex'                            % trace assembler bytes
            '-asmDump'                           % dump the assembly code
          }
        kind = 'subFlag';
      otherwise
        if numel(arg) > 2 && strcmp(arg(end-1:end), '.x')
          kind = 'file';
        elseif numel(arg) > 0 && arg(1) == '-'
          xErr(['unexpected flag: ' arg]);
        else
          kind = 'src';
        end
    end
  end

  function frameDump()
    disp 'enter frame dump';
    st = syms{end};
    for v=1:st.size()                           % get entries
      name = st.getName(v);                     % frame name
      switch st.getType(v)                      % value type
        case st.boolTYPE
          intRes = frame(v);
          if intRes == 1
            fprintf('logical %s := true\n', name);
          elseif intRes == 0
            fprintf('logical %s := false\n', name);
          else
            xErr('botched logical frame entry');
          end
        case st.intTYPE
          intRes = frame(v);
          fprintf('integer   %s := %d\n', name, intRes);
        case st.realTYPE
          intRes = frame(v);
          fprintf('real      %s := %d\n', name, i2f(intRes));
        case st.fnTYPE
          fprintf('function   %s\n', name);
        otherwise
          xErr('botched symbol type');
      end
    end
    disp 'leave frame dump';
  end

  function TR(msg)
    if findFlag('-xcomTrace', allFlags), fprintf('xcom: %s\n', msg); end
  end

  function xErr(msg)
      error(['xcom: ' msg]);
  end

end
