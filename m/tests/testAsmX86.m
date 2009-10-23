% FILE:    testAsmX86.m
% PURPOSE: exercise X86 assembler 
% METHOD:  the frame is 32 bit ints
%          32 bit floats are cast in, and cast out
%          short assembly sequences are tested for effect
% USAGE:   testAsmX86(t1, t2...) for tests t1, t2
% EXAMPLE:
%  testAsmX86() % for all tests
%
% REQUIRES:Asmx86.m

% COPYRIGHT W.M.McKeeman 2006.  You may do anything you like with 
% this file except remove or modify this copyright.


function testAsmX86(varargin)                    % empty means all tests  
  tn     = [varargin{:}];                        % cell to vector
  allt   = isempty(tn);                          % no arg at all

  pass   = 0;                                    % none yet
  testno = 0;                                    % none yet  
  dummy = xenv({});                              %#ok insure makemex
  flags = {};
  
  testno = testno + 1;                           % punning real->int->real
  if allt || any(tn == testno)
    f = i2f(f2i(single(211.91)));  
    if ~test(f == single(211.91)), tAsmErr(); end    
  end

  testno = testno + 1;                           % get in, get out
  if allt || any(tn == testno)
    m=AsmX86(flags);
    m.prolog();
    m.movRC(m.EAX, 17);                          % EAX = 17
    m.epilog();
    frame = zeros(1,0,'int32');                  % empty
    rc = m.go(frame);                            % do nothing
    if ~test(rc == 0); tAsmErr(); end
  end
  
  testno = testno + 1;                           % simplest int arith
  if allt || any(tn == testno)
    m=AsmX86(flags);                             % make assembler object
    m.prolog();                                  % emit subroutine prolog
    m.movRC(m.EAX, 1);
    m.movRC(m.ECX, 2);
    m.addRR(m.EAX, m.ECX);                       % 1+2
    m.movMR(0, m.EAX);                           % set first local to res
    m.epilog();
    frame = zeros(1,3,'int32');
    rc = m.go(frame);
    if ~test(rc == 0); tAsmErr(); end             % 1+2
    if ~test(frame(1) == 3); tAsmErr(); end
  end
  
  testno = testno + 1;                           % int * + -
  if allt || any(tn == testno)
    m=AsmX86(flags);
    m.prolog();
    m.movRC(m.EAX, 10);
    m.movRC(m.ECX, 11);
    m.mulRR(m.EAX, m.ECX);                       % 10*11
    m.movRM(m.EDX, 0);                           % get first local
    m.addRR(m.EAX, m.EDX);                       % 10*11+3
    m.subRC(m.EAX, 7);                           % 10*11+3-7
    m.movMR(4, m.EAX);                           % set second local
    m.epilog();
    frame = zeros(1,3,'int32');
    frame(1)=3;                                  % input
    frame(2)=12;                                 % 12 gets clobbered
    frame(3)=13;
    rc = m.go(frame);
    if ~test(rc == 0); tAsmErr(); end             % int * + -
    if ~test(frame(1)==3); tAsmErr(); end         % still there
    if ~test(frame(2)==10*11+3-7); tAsmErr(); end % output value
  end
  
  testno = testno + 1;                           % float +
  if allt || any(tn == testno)
    m = AsmX86(flags);
    m.prolog();
    m.fldM(0);                                   % load arg into frame(1)
    m.fld1();
    m.faddp();
    m.fstMp(4);                                  % arg+1 into frame(2)
    m.epilog();
    frame = zeros(1,3,'int32');
    frame(1) = f2i(single(3.1));                 % input
    rc = m.go(frame);
    if ~test(rc == 0); tAsmErr(); end            % float +
    if ~test(i2f(frame(1))==single(3.1)); tAsmErr(); end
    if ~test(i2f(frame(2))==single(4.1)); tAsmErr(); end
  end

  testno = testno + 1;                           % sqrt
  if allt || any(tn == testno)
    m=AsmX86(flags);
    m.prolog();
    m.fldM(0);                                   % load 3.1
    m.fsqrt();
    m.fstMp(4);                                  % store in frame(2)
    m.epilog();
    frame = zeros(1,2,'int32');
    frame(1) = f2i(single(3.1));                         % input
    rc = m.go(frame);
    if ~test(rc == 0); tAsmErr(); end            % sqrt
    if ~test(i2f(frame(2))==single(sqrt(3.1))); tAsmErr(); end
  end

  testno = testno + 1;                           % branch forward
  if allt || any(tn == testno)
    m=AsmX86(flags);
    m.prolog();
    m.movRC(m.EAX, 17);                          % EAX = 17
    fixuploc = m.jmp32(0);                       % skip over next
    m.movRC(m.EAX, 1);                           % EAX = 1
    m.fixup32(fixuploc);                         % next inst is dest
    m.movMR(0, m.EAX);                           % 17 into frame(1)
    m.epilog();
    frame = zeros(1,1,'int32');
    rc = m.go(frame);
    if ~test(rc == 0); tAsmErr(); end            % branch forward
    if ~test(frame(1)==17); tAsmErr(); end
  end

  testno = testno + 1;                           % branch back
  if allt || any(tn == testno)
    m=AsmX86(flags);
    m.prolog();
    m.movMC(0, 13);                              % frame(1) = 13
    m.movRC(m.EAX, 17);                          % EAX = 17
    p = m.getPc();                               % loop begin     
    m.addRC(m.EAX, -1);                          % EAX -= 1        <----.
    fixuploc = m.jnz32(0);                       % back to ++      >----'
    m.patch32(fixuploc, p);                      % prev inst is dest 
    m.movMR(0, m.EAX);                           % frame(1) = EAX
    m.epilog();
    frame = zeros(1,1,'int32');
    rc = m.go(frame);
    if ~test(rc == 0); tAsmErr(); end            % branch back
    if ~test(frame(1)==0); tAsmErr(); end
  end
  
  testno = testno + 1;                           % all ops used by xcom
  if allt || any(tn == testno)
    m = AsmX86(flags);
    m.halt();
    m.leave();
    m.ret();
    m.sahf();
    m.movRR(m.EAX, m.ECX);
    m.movRC(m.EBX, 1000);
    m.movRM(m.EAX, 4);
    m.movRA(m.EAX, 100000);
    m.movRP(m.EBX, 2);
    m.movAR(10000, m.EAX);
    m.movMR(4, m.EBX);
    m.movMC(4, 101);
    m.movAC(100000, 102);
    m.movRRi(m.EAX, m.EBX);
    m.movRiR(m.EAX, m.EBX);
    m.popA();
    m.pushA();
    m.popR(m.EAX);
    m.pushR(m.EAX);
    m.pushC(1000);
    m.addRR(m.EAX, m.EBX);
    m.addRC(m.EAX, 1000);
    m.addRA(m.EAX, 4);
    m.addRM(m.EAX, 2);
    m.subRR(m.EAX, m.EBX);
    m.subRC(m.EAX, 1000);
    m.subRA(m.EAX, 4);
    m.subRM(m.EAX, 2);
    m.mulRR(m.EAX, m.EBX);
    m.mulRC(m.EAX, 1000);
    m.mulRA(m.EAX, 4);
    m.mulRM(m.EAX, 2);
    m.divR(m.EAX);
    m.divA(1000);
    m.fld0();
    m.fld1();
    m.fldPi();
    m.fildA(1000);
    m.fildM(8);
    m.fldA(4.5);
    m.fldM(1000);
    m.fstAp(5.5);
    m.fstMp(1000);
    m.dstAp(3000);
    m.dldA(2000);
    m.fistAp(4000);
    m.fistMp(1000);
    m.fpop();
    m.fxch();
    m.fxchr(m.EAX);
    m.fcompp();
    m.fnstsw();
    m.fld0();
    m.fld1();
    m.faddp();
    m.fsubp();
    m.fld0();
    m.fld1();
    m.fsubrp();
    m.fmulp();
    m.fld0();
    m.fld1();
    m.fdivp();
    m.fdivrp();
    m.fld0();
    m.fld1();
    m.fabs();
    m.fchs();
    m.fld0();
    m.fld1();
    m.fsqrt();
    
    m.eR(m.EAX);
    m.neR(m.EAX);
    m.lR(m.EAX);
    m.geR(m.EAX);
    m.leR(m.EAX);
    m.gR(m.EAX);
    m.aR(m.EAX);
    m.aeR(m.EAX);
    m.bR(m.EAX);
    m.beR(m.EAX);
    test(true);                                  % no SEGVs
    % note: the above code is nonsense; never actually run it!
  end
  
  fprintf('AsmX86: passed %d unit tests\n', pass);
  return;
  
  function res = test(expr)
    pass = pass+1;
    res = expr;
  end

  function tAsmErr()
   error('asmX86 test failed, testno=%d', testno);
  end

end
