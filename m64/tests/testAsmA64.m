% FILE:    testAsmA64.m
% PURPOSE: exercise 64 bit assembler assembler 
% METHOD:  the frame is 32 bit ints
%          32 bit floats are cast in, and cast out
%          short assembly sequences are tested for effect
% USAGE:   testAsmA64(t1, t2...) for tests t1, t2
% EXAMPLE:
%  testAsmA64() % for all tests
%
% REQUIRES:Asmx86.m

% COPYRIGHT W.M.McKeeman 2009.  You may do anything you like with 
% this file except remove or modify this copyright.


function testAsmA64(varargin)                    % empty means all tests  
  tn     = [varargin{:}];                        % cell to vector
  allt   = isempty(tn);                          % no arg at all
  platform = computer;
  if ~strcmp(platform, 'GLNXA64'), return; end
  
  pass   = 0;                                    % none yet
  testno = 0;                                    % none yet  
  dummy = xenv({});                              %#ok insure makeMex
  flags = {};
  RAX=0; RCX=1; RDX=2; RBX=3; RSP=4; RBP=5; RSI=6; RDI=7;% A64 registers
  big = uint64(intmax('uint32'));                % avoid saturation
  big = uint64(bitshift(big, 8));                % ffff ffff 0

  testno = testno + 1;                           % punning real->int->real
  if allt || any(tn == testno)
    f = i2f(f2i(single(211.91)));  
    if ~test(f == single(211.91)), tAsmErr(0); end    
  end

  testno = testno + 1;                           % get in, get out
  if allt || any(tn == testno)
    m = AsmX86(flags);                           % get an assembler
    m.pushR(RBP);                                % prolog
    m.movRRq(RBP,RSP);
    m.xorRRq(RAX, RAX);                          % return code 0
    m.leave();
    m.ret();
    frame = zeros(1,0,'int32');                  % empty
    rc = m.go(frame);                            % do nothing
    if ~test(rc == 0); tAsmErr(rc); end
  end
  
  testno = testno + 1;                           % fetch a local
  if allt || any(tn == testno)
    m = AsmX86(flags);                           % get an assembler
    m.pushR(RBP);                                % prolog
    m.movRRq(RBP,RSP);
    m.movRRq(RSI,RDI);                           % frame address
    m.movRM(m.EAX, 0);                           % get first local
    m.leave();
    m.ret();
    frame = int32(13:14);                        % contains data
    rc = m.go(frame);                            % get frame[0]
    if ~test(rc == 13); tAsmErr(rc); end
  end
  
  testno = testno + 1;                           % fetch a constant
  if allt || any(tn == testno)
    m = AsmX86(flags);                           % get an assembler
    m.pushR(RBP);                                % get in and get out
    m.movRRq(RBP,RSP);
    m.movRRq(RSI,RDI);                           % frame address
    m.xorRRq(RAX, RAX);                          % clear RAX
    m.movRC(m.EAX, 17);                          % mix x86 and A64
    m.leave();
    m.ret();
    frame = int32(13:14);                        % contains data
    rc = m.go(frame);                            % do nothing
    if ~test(rc == 17); tAsmErr(rc); end
  end
  
  testno = testno + 1;                           % 64 bit push and pop
  if allt || any(tn == testno)
    m = AsmX86(flags);                           % test 64 bit stuff
    m.pushR(RBP);                                % get in and get out
    m.movRRq(RBP,RSP);
    m.movRRq(RSI,RDI);                           % frame address
    m.xorRRq(RAX, RAX);                          % clear RAX
    m.movRCq(RCX, big);                          % big constant into RCX
    m.pushR(RCX);                                % push big 
    m.popR(RAX);                                 % pop big 
    m.leave();
    m.ret();
    frame = int32(13:14);                        % contains data
    rc = m.go(frame);                            % do nothing
    if ~test(rc == big); tAsmErr(rc); end        % 
  end
  % conclusion, pushR and pushRq have the same effect on A64
  % so use pushR
        
  % this test generated from bug in A64 emit
  % x,y := 7/3,13/4
  testno = testno + 1;                           % get in, get out
  if allt || any(tn == testno)
    addr = getCfun('div');                       % C code for div/rem
    m = AsmX86(flags);                           % test 64 bit stuff
    m.pushR(RBP);                                % get in and get out
    m.movRRq(RBP,RSP);
    m.movRRq(RSI,RDI);                           % frame address
    
    m.movRC(m.EAX,13);                           % 13 / 4
    m.movRC(m.ECX,4);
    m.cmpRC(m.ECX,0);                            % /0 check
    m.jne32(12);   % jmp+12
    m.movRCq(RAX,1);                             % error bailout
    m.leave();
    m.ret();
    m.pushR(RSI);
    m.pushR(RBX);
    m.movRR(m.ESI,m.ECX);                        % pass parameters
    m.movRR(m.EDI,m.EAX);
    m.movRCq(RAX, addr);
    m.callRiq(RAX);
    m.popR(RBX);
    m.popR(RSI);
    
    m.movRC(m.ECX,7);                            % 7 / 3
    m.movRC(m.EDX,3);
    m.cmpRC(m.EDX,0);                            % /0 check
    m.jne32(12);   % jmp+12
    m.movRCq(RAX,2);                             % error bailout
    m.leave();
    m.ret();
    m.pushR(RSI);
    %m.pushRq(RBX);                               % not OK to push
    %m.xorRRq(RBX, RBX);                          % OK to CLOBBER
    m.movRR(m.ESI,m.EDX);                        % pass parameters
    m.movRR(m.EDI,m.ECX);
    m.movRCq(RAX, addr);
    m.callRiq(RAX);
    m.popR(RSI);
    %m.popRq(RBX);                                % matching pop
    
    m.movRM(m.ECX,12);                           % tmp1
    m.movMR(0,m.EAX);                            % x
    m.movMR(4,m.ECX);                            % y
    
    m.xorRRq(RAX,RAX);                           % return code
    m.leave();
    m.ret();
    frame = int32(13:16);                        % contains data
    rc = m.go(frame);                            % do nothing
    if ~test(rc==0); tAsmErr(rc); end
    if ~test(frame(1)==2); tAsmErr(frame(1)); end
    %if ~test(frame(2)==1); tAsmErr(frame(2)); end
    m.dump();
  end
    
  fprintf('AsmA64: passed %d unit tests\n', pass);
  return;
  
  function res = test(expr)
    pass = pass+1;
    res = expr;
  end

  function tAsmErr(data)
   data
   error('asmA64 test failed, testno=%d', testno);
  end

end
