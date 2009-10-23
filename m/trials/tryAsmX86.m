% FILE:    tryAsmX86.m
% PURPOSE: exercise M version of assembler 
% METHOD:  the frame is 32 bit ints
%          32 bit floats are cast in, and cast out
%          command window printout displays inner workings
% USAGE:   tryAsmX86(t1, t2...) for trials t1, t2
% EXAMPLE:
%   tryAsmX86() % for all trials

% COPYRIGHT W.M.McKeeman 2006.  You may do anything you like with 
% this file except remove or modify this copyright.

function tryAsmX86(varargin)   % empty means all trials

  tn = [varargin{:}];          % cell to vector
  allt = isempty(tn);          % no arg at all
  
  trialno = 0;
  
  disp 'start asmX86 trials -------------------------------'

  trialno = trialno + 1;
  if allt || any(tn == trialno)
    fprintf('start trail %d (pun)\n', trialno);
    f = i2f(f2i(single(211.91)));
    fprintf('finish trial %d\n', trialno);
    fprintf('punned 211.91, expected %g\n', f);
  end
%{  
  trialno = trialno + 1;
  if allt || any(tn == trialno)
    disp 'start  cleanup nox bits'
    Asmx86('-reset');
    disp 'finish cleanup nox bits'
  end
%}
  trialno = trialno + 1;
  if allt || any(tn == trialno)
    fprintf('start trial %d (empty)\n', trialno);
    m=AsmX86({'-asmTrace'});
    m.prolog();
    m.movRC(m.EAX, 17);
    m.epilog();
    frame = zeros(1,0,'int32');  % empty
    rc = m.go(frame);
    fprintf('finish trial %d rc=%d\n', trialno, rc);
  end

  trialno = trialno + 1;
  if allt || any(tn == trialno)
    fprintf('start trial %d (int addition)\n', trialno);
    disp 'start  int addition trial'
    m=AsmX86({'-asmTrace'});     % make assembler object
    m.prolog();                  % emit subroutine prolog
    m.movRC(m.EAX, 1);
    m.movRC(m.ECX, 2);
    m.addRR(m.EAX, m.ECX);
    m.movMR(0, m.EAX);           % set first local
    m.epilog();
    frame = zeros(1,3,'int32');
    rc = m.go(frame);
    fprintf('finish trial %d rc = %d\n', trialno, rc);
    fprintf('computed 1+2, expected 3, got %d\n', frame(1));
  end

  trialno = trialno + 1;
  if allt || any(tn == trialno)
    fprintf('start trial %d (int arithemtic)\n', trialno);
    m=AsmX86({'-asmTrace'});
    m.prolog();
    m.movRC(m.EAX, 10);
    m.movRC(m.ECX, 11);
    m.mulRR(m.EAX, m.ECX);       % 10*11
    m.movRM(m.EDX, 0);           % get first local
    m.addRR(m.EAX, m.EDX);       % 10*11+3
    m.subRC(m.EAX, 7);           % 10*11+3-7
    m.movMR(4, m.EAX);           % set second local
    m.epilog();
    frame = zeros(1,3,'int32');
    frame(1)=3;   % input
    frame(2)=12;  % make sure 12 gets clobbered
    frame(3)=13;
    rc = m.go(frame);
    fprintf('finish trial %d rc=%d\n', rc);
    fprintf('computed 10*11+3-7, expected 106, got %d\n', frame(2));
  end
  
  trialno = trialno + 1;
  if allt || any(tn == trialno)
    fprintf('start trial %d (real arithmetic)\n', trialno);
    m=AsmX86({'-asmTrace'});
    m.prolog();
    m.fldM(0);                          % load 3.1
    m.fld1();
    m.faddp();
    m.fstMp(4);                         % store in frame(1)
    m.epilog();
    frame = zeros(1,3,'int32');
    frame(1) = f2i(single(3.1));                % input
    rc = m.go(frame);
    fprintf('finish trial %d rc=%d\n', trialno, rc);
    fprintf('computed 3.1+1, expected 4.1, got %g\n', i2f(frame(2)));
  end

  trialno = trialno + 1;
  if allt || any(tn == trialno)
    fprintf('start trial %d (real sqrt)\n', trialno);
    m=AsmX86({'-asmTrace'});
    m.prolog();
    m.fldM(0);                          % load 3.1
    m.fsqrt();
    m.fstMp(4);                         % store in frame(1)
    m.epilog();
    frame = zeros(1,2,'int32');
    frame(1) = f2i(single(3.0));                % input
    rc = m.go(frame);
    fprintf('finish trial %d rc=%d\n', trialno, rc);
    fprintf('computed sqrt(3), expected 1.732, got %g\n', i2f(frame(2)));
  end

  trialno = trialno + 1;
  if allt || any(tn == trialno)
    fprintf('start trial %d (branch forward)\n', trialno);
    m=AsmX86({'-asmTrace', '-emitTrace'});
    m.prolog();
    m.movRC(m.EAX, 17);                 % EAX = 17
    fixuploc = m.jmp32(0);              % skip over next
    m.movRC(m.EAX, 1);                  % EAX = 1
    m.fixup32(fixuploc);                % next inst is dest
    m.movMR(0, m.EAX);                  % 17 into frame(1)
    m.epilog();
    frame = zeros(1,1,'int32');
    rc = m.go(frame);
    fprintf('finish trial %d rc=%d\n', trialno, rc);
    fprintf('expected 17, got %d\n', frame(1));
  end

  trialno = trialno + 1;
  if allt || any(tn == trialno)
    fprintf('start trial %d (branch back)\n', trialno);
    m=AsmX86({'-asmTrace', '-emitTrace'});
    m.prolog();
    m.movMC(0, 13);                     % frame(1) = 13
    m.movRC(m.EAX, 17);                 % EAX = 17
    p = m.getPc();                      % loop begin     
    m.addRC(m.EAX, -1);                 % EAX -= 1        <----.
    fixuploc = m.jnz32(0);              % back to ++      >----'
    m.patch32(fixuploc, p);             % prev inst is dest 
    m.movMR(0, m.EAX);                  % frame(1) = EAX
    m.epilog();
    frame = zeros(1,1,'int32');
    rc = m.go(frame);
    fprintf('finish trial %d rc=%d\n', trialno, rc);
    fprintf('loop finished expected 0, got %d\n', frame(1));
  end
  
  trialno = trialno + 1;
  if allt || any(tn == trialno)
    m = AsmX86({'-asmTrace'});
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

    % note: this program is COMPLETE nonsense; NEVER actually run it!
    % rc = m.go(frame);
    disp 'finish trial every-instruction'
  end

  disp 'finish asmX86 trials ---------------------------------'
end
