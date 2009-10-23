% FILE:    xenv.m
% PURPOSE: keep track of cross-program data for a single compile/run.
% METHOD:  an object containing the cross-subprogram data.
%          The list of subprogram names is used to construct tables.
%          All tables are accessed via methods.
%          The "trick" is preallocating the tables so addresses can be used 
% EXAMPLE:
%   None:  see use in xcom.m

% COPYRIGHT W.M.McKeeman 2007.  You may do anything you like with 
% this file except remove or modify this copyright.

function fns = xenv(snames)                      % ctor

  % ------------- fields --------------
  names   = snames;                              % cell array of strings
  envct   = numel(snames);                       % number of subprograms
  entries = zeros(1, envct, 'uint32');           % one-time allocation
  frames  = zeros(1, envct, 'uint32');           % one-time allocation

  fns = public();
  return;
  
  % --------------- methods --------------------
  % this is nmber of subprograms on the command line
  function ct = getCount()                       % number of subprogs
   ct = envct;
  end
 
  function idx = findName(name)                  % index of subprog name
    for idx = 1:envct
      if strcmp(name, names(idx))
        return
      end
    end
    idx = 0;                                     % no such name
  end

  function n = getName(idx)                      % name of n-th subprog
    n = names{idx};
  end

  function setEntry(n, e)                        % set n-th entry point
    entries(n) = uint32(e);                      % 32-bit Intel
  end

  function e = getEntry(n)                       % get n-th entry point
    e = entries(n);
  end

  % the start of a vector of entry addresses
  function a = getEntriesAddress()               % hardware address
    a = getpr(entries);
  end

  function setSize(n, s)                         % set n-th frame size
    frames(n) = uint32(s);                       % 32-bit Intel
  end

  function s = getSize(n)                        % get n-th frame size
    s = frames(n);
  end

  % the start of a vector of frame sizes
  function a = getSizesAddress()                % hardware address
    a = getpr(frames);
  end

  % -------------- export public methods ----------------------------

  function fh = public()
    fh = struct;
    fh.getCount  = @getCount;
    fh.getName   = @getName;
    fh.findName  = @findName;

    fh.setEntry  = @setEntry;
    fh.getEntry  = @getEntry;
    fh.getEntriesAddress  = @getEntriesAddress;
    
    fh.setSize  = @setSize;
    fh.getSize  = @getSize;
    fh.getSizesAddress = @getSizesAddress;
  end

end

