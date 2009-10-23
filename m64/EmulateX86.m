% FILE:     EmulateX86.m
% PURPOSE:  emulate Intel x86 instructions 
%
% OVERVIEW:
%   XCOM is a load&go compiler.  EmulateX86.m provides step-by-step trace
%   of executed Intel x86 instructions.  Only the instructions needed by 
%   XCOM are implemented. 
%
% USAGE:  x86 = EMULATEX86()    % constructor
%         x86.trace(x86code, len, inframe, st, 2) % interactive
%         x86.trace(x86code, len, inframe, st, 3) % silent
%
%  When XCOM is run with the -interactive flag, the emulator will provide
%  interactive step-by-step display of the contents of the x86 registers.
%  The register EBP and ESP are simulated and constant, therefore are
%  marked na in the display.  EBI is not used, so also marked na. After
%  each display of information, the prompt
%  step=
%  will appear on the command line.  The number of steps may be any integer
%  value, positive or negative.  No value is taken as step 1.  step=inf
%  will continue exection without further output. step=-inf will cause an
%  error, thus immediately terminating the emulation.
%
%  For purposes of hands-off testing, xcom can be called with the
%  -exeTrace flag.  The consequence is to run the emulator without
%  requesting the step, and tracing every step.
%
%  Builtin function calls (to C functions) are stubbed off in the 
%  emulator, the required value being produced as though the builtin had
%  actually been called.   Subprogram linkage is not implemented at all.
%  The consequence is that only the main subprogram can be emulated.
%
% TEST:   testEmulateX86.m
%
% REFERENCE:
%   Intel486 Processor Family, Programmer's Reference Manual, 1995
%   http://www.x86.org/intel.doc/486manuals.htm
%
% EXAMPLE:  compile and emulate the empty program
%
%  xcom -exeTrace -asmTrace ''
%
% SEE ALSO:  AsmX86.m

% COPYRIGHT W.M.McKeeman 2007.  You may do anything you like with 
% this file except remove or modify this copyright.
% IMPLEMENTATION:
%   All output is captured in a history array.  Stepping back in time
%   time means going back in history and redisplaying old, perhaps 
%   previously skipped, data.  
%

function obj = EmulateX86()                       % ctor

  regs = {'EAX','ECX','EDX','EBX','ESP','EBP','ESI','EDI'};
  R = enum(regs, 0);
  iregs = zeros(1,8, 'int32');
  aop = xarith();

  x86 = struct;                                  % useful names
  x86.addRR = hx2('01');
  x86.mulRR = hx2('af');
  x86.andRR = hx2('23');
  x86.subRR = hx2('2b');
  x86.cmpRR = hx2('3b');
  x86.pushA = hx2('60');
  x86.popA  = hx2('61');
  x86.pushC = hx2('68');
  
  x86.setbR = hx2('92');
  x86.setaeR= hx2('93');
  x86.seteR = hx2('94');
  x86.setneR= hx2('95');
  x86.setbeR= hx2('96');
  x86.setaR = hx2('97');
  x86.setlR = hx2('9c');
  x86.setgeR= hx2('9d');
  x86.setleR= hx2('9e');

  x86.jb32  = hx2('82');
  x86.jae32 = hx2('83');
  x86.je32  = hx2('84');
  x86.jne32 = hx2('85');
  x86.jbe32 = hx2('86');
  x86.ja32  = hx2('87');
  x86.jl32  = hx2('8c');
  x86.jge32 = hx2('8d');
  x86.jg32  = hx2('8f');
  x86.jle32 = hx2('8e');
  
  x86.sahf  = hx2('9e');
  x86.setgR = hx2('9f');
  x86.ret   = hx2('c3');
  x86.leave = hx2('c9');
  x86.negR  = hx2('f7');
  
  % establish nonlocals
  code   = uint8(0);                             % the x86 ops
  frame  = zeros(1,0, 'int32');                  % emulated frame
  cstack = zeros(1,0, 'int32');                  % emulated C stack
  fps    = zeros(1,0, 'single');                 % floating point stack
  hexdig = '0123456789abcdef';                   % for printing
  eip    = uint32(0);
  esi    = uint32(0);
  ZF = false; CF = false; SF = false; OF = false; 
  C0 = false; C3 = false;                        % from FPU
  pc     = uint32(0);
  done   = false;
  see    = 1;                                    % current step
  sMode  = 3;                                    % silent mode
  iMode  = 2;                                    % interative mode
  syms   = struct;                               % make global
  
  obj = public();
   
  return;
  
  % ----------------- nested functions -------------------
  function [rc, outframe] = trace(x86code, len, inframe, st, mode)
    syms = st;                                   % outer symbol table
    % fill simulated frame with input values
    for i=1:numel(inframe), frame(i) = inframe(i); end
    % the hardware executable bits
    code = x86code;                              % read-only ops
    pc  = 1;                                     % into code array
    eip = getpr(code);                           % hardware address
    
    esi = getpr(inframe);                        % hardware address
    see = 1;                                     % looking at
    ihistory = {};                               % capture code output
    rhistory = {};                               % capture reg output
    done = false;                                % still tracing
    rc = 0;                                      % normal exit
    fprintf('Start x86 emulation: EIP=0x%x, len=%d frame=%d words\n', ...
      eip, len, numel(inframe));
    while ~done    
      while see > numel(ihistory)                % catch up
        if pc <= len                             % safe
          stepahead = numel(ihistory)+1;         % next slot
          [h,r] = singleStep(stepahead);
          ihistory{stepahead} = h;               % retain trace output
          rhistory{stepahead} = r;               % retain register values
        else
          fprintf('stepped off end of code; terminated emulation\n');
          outframe=frame;
          return;                                % off end of code
        end
      end
      if mode ~= sMode                           % not silent
        h = ihistory{see}; 
        fprintf(h);                              % to cmd window
        r = rhistory{see};
        fprintf(r);
      end
      if mode == iMode                           % interactive
        prompt = 'step=';
        step = input(prompt);                    % new step value
        if isempty(step) 
          step = 1;                              % normal case
        else
          assert(...
            isscalar(step)&&isnumeric(step)&&floor(step)==step,...
            'step must be scalar integer');
        end
      else
        step = 1;                                % trace all
      end
      
      see = see + step;                          % next viewpoint
      if see <= 0
        fprintf('cannot step before start of code\n');
        rc = 0;                                  % not an error
        outframe=frame;                          % for caller
        return;
      end
    end
    fprintf('Finish x86 emulation\n');
    rc = iregs(R.EAX+1);                         % return code
    outframe=frame;                              % for caller
  end

  % ------------------ disassemble & do --------------------

  function [in, rg] = singleStep(newstep)
    st = eip+pc-1;
    h = sprintf('%4d/%4d(0x%x): ', newstep, pc, st); % standard header
    op = next1();                                % increment pc
    
    % take care of special 1-byte operators
    nyb = bitshift(bitshift(op, -3), 3);         % leading 5 bits
    if nyb == hx2('50')                          % pushR
      r = UN_R_M(op);                            % get the R
      in = sprintf([h '%s %s\n'], 'pushR', regs{r+1});
      cstack(end+1) = iregs(r+1);
    elseif nyb == hx2('58')                      % popR
      r = UN_R_M(op);                            % get the R
      in = sprintf([h '%s %s\n'], 'popR', regs{r+1});
    elseif nyb == hx2('b8')                      % movRC
      r = UN_R_M(op);                            % get the R
      opd4 = next4();
      so = u2s(opd4);
      in = sprintf([h '%s %s,=%d\n'], 'movRC', regs{r+1}, so);
      iregs(r+1) = so;
      
    else                                         % switch on lead byte
      switch op                                  % sorted for sanity
        case hx2('01')                           % addRR
          opd1 = next1();
          [r1, r2, m] = UN_MOD_REG(opd1);
          assert(m==3);
          iregs(r1+1) = aop.add(iregs(r1+1), iregs(r2+1));
          n1 = regs{r1+1};
          n2 = regs{r2+1};
          in = sprintf([h '%s %s,%s\n'], 'addRR', n1, n2);
        case hx2('09')                           % orRR
          opd1 = next1();
          [r1, r2, m] = UN_MOD_REG(opd1);
          assert(m==3);
          iregs(r1+1) = aop.or(iregs(r1+1), iregs(r2+1));
          n1 = regs{r1+1};
          n2 = regs{r2+1};
          in = sprintf([h '%s %s,%s\n'], 'orRR', n1, n2);
        case hx2('0f')                           % IEEE FP
          opd1 = next1();
          switch opd1
            case x86.mulRR                       % mulRR
              opd1 = next1();
              [r1, r2, m] = UN_MOD_REG(opd1);
              assert(m==3);
              iregs(r2+1) = aop.mul(iregs(r1+1), iregs(r2+1));
              n1 = regs{r1+1};
              n2 = regs{r2+1};
              in = sprintf([h '%s %s,%s\n'], 'mulRR', n2, n1);
              
            case x86.setbR,  cc = CF==1;         % setbR
              opd1 = next1();
              [r1, r2, m] = UN_MOD_REG(opd1);
              assert(m==3);
              assert(r2==0);
              iregs(r1+1) = cc;
              n1 = regs{r1+1};
              in = sprintf([h '%s %s cc=%d\n'], 'setbR', n1, cc);
            case x86.setaeR, cc = CF==0;         % setaeR
              opd1 = next1();
              [r1, r2, m] = UN_MOD_REG(opd1);
              assert(m==3);
              assert(r2==0);
              iregs(r1+1) = cc;
              n1 = regs{r1+1};
              in = sprintf([h '%s %s cc=%d\n'], 'setaeR', n1, cc);
            case x86.seteR,  cc = ZF==1;         % seteR
              opd1 = next1();
              [r1, r2, m] = UN_MOD_REG(opd1);
              assert(m==3);
              assert(r2==0);
              iregs(r1+1) = cc;
              n1 = regs{r1+1};
              in = sprintf([h '%s %s cc=%d\n'], 'seteR', n1, cc);
            case x86.setneR, cc = ZF==0;         % setneR
              opd1 = next1();
              [r1, r2, m] = UN_MOD_REG(opd1);
              assert(m==3);
              assert(r2==0);
              iregs(r1+1) = cc;
              n1 = regs{r1+1};
              in = sprintf([h '%s %s cc=%d\n'], 'setneR', n1, cc);
            case x86.setbeR, cc = CF==1 | ZF==1; % setbeR
              opd1 = next1();
              [r1, r2, m] = UN_MOD_REG(opd1);
              assert(m==3);
              assert(r2==0);
              iregs(r1+1) = cc;
              n1 = regs{r1+1};
              in = sprintf([h '%s %s cc=%d\n'], 'setbeR', n1, cc);
            case x86.setaR,  cc = CF==0 & ZF==0; % setaR
              opd1 = next1();
              [r1, r2, m] = UN_MOD_REG(opd1);
              assert(m==3);
              assert(r2==0);
              iregs(r1+1) = cc;
              n1 = regs{r1+1};
              in = sprintf([h '%s %s cc=%d\n'], 'setaR', n1, cc);
            case x86.setlR,  cc = SF~=OF;        % setlR
              opd1 = next1();
              [r1, r2, m] = UN_MOD_REG(opd1);
              assert(m==3);
              assert(r2==0);
              iregs(r1+1) = cc;
              n1 = regs{r1+1};
              in = sprintf([h '%s %s cc=%d\n'], 'setlR', n1, cc);
            case x86.setgeR, cc = SF==OF;        % setgeR
              opd1 = next1();
              [r1, r2, m] = UN_MOD_REG(opd1);
              assert(m==3);
              assert(r2==0);
              iregs(r1+1) = cc;
              n1 = regs{r1+1};
              in = sprintf([h '%s %s cc=%d\n'], 'setgeR', n1, cc);
            case x86.setleR, cc = ZF==1 | SF~=OF;% setleR
              opd1 = next1();
              [r1, r2, m] = UN_MOD_REG(opd1);
              assert(m==3);
              assert(r2==0);
              iregs(r1+1) = cc;
              n1 = regs{r1+1};
              in = sprintf([h '%s %s cc=%d\n'], 'setleR', n1, cc);
            case x86.setgR,  cc = ZF==0 & SF==OF;% setgR
              opd1 = next1();
              [r1, r2, m] = UN_MOD_REG(opd1);
              assert(m==3);
              assert(r2==0);
              iregs(r1+1) = cc;
              n1 = regs{r1+1};
              in = sprintf([h '%s %s cc=%d\n'], 'setgR', n1, cc);
              
            case x86.jb32
              opd4 = next4();
              so   = u2s(opd4);
              dest = s2u(aop.add(pc, so));
              if CF==1
                pc = dest;                       % the branch
              end
              in=sprintf([h '%s dest=%d=0x%08x\n'],'jb32',pc,eip+dest-1);
            case x86.jae32
              opd4 = next4();
              so   = u2s(opd4);
              dest = s2u(aop.add(pc, so));
              if CF==0
                pc = dest;                       % the branch
              end
              in=sprintf([h '%s dest=%d=0x%08x\n'], 'jae32',pc,eip+dest-1);
            case x86.je32
              opd4 = next4();
              so   = u2s(opd4);
              dest = s2u(aop.add(pc, so));
              if ZF==1
                pc = dest;                       % the branch
              end
              in=sprintf([h '%s dest=%d=0x%08x\n'],'je32',pc,eip+dest-1);
            case x86.jne32
              opd4 = next4();
              so   = u2s(opd4);
              dest = s2u(aop.add(pc, so));
              if ZF==0
                pc = dest;                       % the branch
              end
              in=sprintf([h '%s dest=%d=0x%08x\n'],'jne32',pc,eip+dest-1);
            case x86.jbe32
              opd4 = next4();
              so   = u2s(opd4);
              dest = s2u(aop.add(pc, so));
              if CF==1 || ZF==1
                pc = dest;                       % the branch
              end
              in=sprintf([h '%s dest=%d=0x%08x\n'],'jbe32',pc,eip+dest-1);
            case x86.ja32
              opd4 = next4();
              so   = u2s(opd4);
              dest = s2u(aop.add(pc, so));
              if CF==0 && ZF==0
                pc = dest;                       % the branch
              end
              in=sprintf([h '%s dest=%d=0x%08x\n'],'ja32',pc,eip+dest-1);
            case x86.jl32
              opd4 = next4();
              so   = u2s(opd4);
              dest = s2u(aop.add(pc, so));
              if SF==OF
                pc = dest;                       % the branch
              end
              in=sprintf([h '%s dest=%d=0x%08x\n'],'jge32',pc,eip+dest-1);
            case x86.jge32
              opd4 = next4();
              so   = u2s(opd4);
              dest = s2u(aop.add(pc, so));
              if SF==OF
                pc = dest;                       % the branch
              end
              in=sprintf([h '%s dest=%d=0x%08x\n'],'jg32',pc, eip+dest-1);
            case x86.jg32
              opd4 = next4();
              so   = u2s(opd4);
              dest = s2u(aop.add(pc, so));
              if ZF==0 && SF==OF
                pc = dest;                       % the branch
              end
              in=sprintf([h '%s dest=%d=0x%08x\n'],'jge32',pc, eip+dest-1);
            case x86.jle32
              opd4 = next4();
              so   = u2s(opd4);
              dest = s2u(aop.add(pc, so));
              if ZF==1 || SF~=OF
                pc = dest;                       % the branch
              end
              in=sprintf([h '%s dest=%d=0x%08x\n'],'jle32',pc,eip+dest-1);
            otherwise
              eErr(['operator 0f ' h2c(opd1) ' NYI']);
          end
        case hx2('21')                           % andRR
          opd1 = next1();
          [r1, r2, m] = UN_MOD_REG(opd1);
          assert(m==3);
          iregs(r1+1) = aop.and(iregs(r1+1), iregs(r2+1));
          n1 = regs{r1+1};
          n2 = regs{r2+1};
          in = sprintf([h '%s %s,%s\n'], 'andRR', n1, n2);
        case hx2('2b')                           % subRR
          opd1 = next1();
          [r2, r1, m] = UN_MOD_REG(opd1);
          assert(m==3);
          iregs(r1+1) = aop.sub(iregs(r1+1), iregs(r2+1));
          n1 = regs{r1+1};
          n2 = regs{r2+1};
          in = sprintf([h '%s %s,%s\n'], 'subRR', n1, n2);
        case hx2('33')                           % xorRR
          opd1 = next1();
          [r1, r2, m] = UN_MOD_REG(opd1);
          assert(m==3);
          iregs(r1+1) = aop.xor(iregs(r1+1), iregs(r2+1));
          n1 = regs{r1+1};
          n2 = regs{r2+1};
          in = sprintf([h '%s %s,%s\n'], 'xorRR', n1, n2);
        case hx2('3b')                           % cmpRR
          opd1 = next1();
          [r2, r1, m] = UN_MOD_REG(opd1);
          assert(m==3);
          v1 = iregs(r1+1);  v2 = iregs(r2+1);
          cv = v1 - v2;
          ZF = cv == 0;
          SF = cv < 0;  % OF AF PF CF
          n1 = regs{r1+1};
          n2 = regs{r2+1};
          in = sprintf([h '%s %s,%s ZF=%d SF=%d\n'],'cmpRR',n1,n2,ZF,SF);
        case hx2('3d')                           % cmpRC
          opd4 = next4();
          v1 = iregs(1);  v2 = u2s(opd4);
          cv = v1 - v2;
          ZF = cv == 0;
          SF = cv < 0;  % OF AF PF CF
          in = sprintf([h '%s EAX, =%d ZF=%d SF=%d\n'],'cmpRC',v2, ZF,SF);
        case hx2('60')                           % pushA
          in = sprintf([h '%s\n'], 'pushA');
        case hx2('61')                           % popA
          in = sprintf([h '%s\n'], 'popA');
        case hx2('68')                           % pushC
          opd4 = next4();
          in = sprintf([h '%s =%u\n'], 'pushC', opd4);
        case hx2('c3')                             % ret
          in = sprintf([h '%s\n'], 'ret');
          done = true;
        case hx2('c9')                           % leave
          in = sprintf([h '%s\n'], 'leave');
        case hx2('81')
          opd1 = next1();
          [r1, r2, m] = UN_MOD_REG(opd1);
          assert(m==3);
          if r2==4                               % andRC
            opd4 = next4();
            iregs(r1+1) = aop.and(iregs(r1+1), opd4);
            n1 = regs{r1+1};
            in = sprintf([h '%s %s,=%d\n'], 'andRC', n1, opd4);
          elseif r2==6
            r1,r2
            eErr('81 NYI');
          elseif r2==7                           % cmpRC
            v1 = iregs(r1+1);  
            v2 = u2s(next4());                   % 2's complement
            cv = v1 - v2;
            ZF = cv == 0;
            SF = cv < 0;  % OF AF PF CF
            n1 = regs{r1+1};
            in = sprintf([h '%s %s,=%d ZF=%d SF=%d\n'],'cmpRC',n1,v2,ZF,SF);
          elseif r2==0                           % addRC
            opd4 = next4();
            delta = u2s(opd4);
            iregs(r1+1) = aop.add(iregs(r1+1), delta);
            n1 = regs{r1+1};
            if r1==R.ESP                         % return from builtin
              cstack = cstack(1:end-delta/4);    % simulated C stack
            end
            in = sprintf([h '%s %s,=%d\n'], 'addRC', n1, delta);
          else
            r1,r2
            eErr('81 NYI');
          end
        case hx2('89')
          opd1 = next1();
          [r1, r2, m] = UN_MOD_REG(opd1);
          if m == 3                              % movRR
            iregs(r1+1) = iregs(r2+1);
            n1 = regs{r1+1};
            n2 = regs{r2+1};
            in = sprintf([h '%s %s,%s\n'], 'movRR', n1, n2);
          elseif m == 2                          % movMR
            assert(r1 == R.ESI);  
            opd4 = next4();
            ofs = opd4/4;
            frame(ofs+1) = iregs(r2+1);
            nm = symName(ofs+1);
            n2 = regs{r2+1};
            in = sprintf([h '%s %s,%s\n'], 'movMR',nm,n2);
          else
            r1,r2,m
            eErr('bad mode in mov 89');
          end
        case hx2('8b')
          opd1 = next1();
          [r1, r2, m] = UN_MOD_REG(opd1);
          if m == 2                              % movRM
            assert(r1 == R.ESI); 
            opd4 = next4();
            ofs = opd4/4;
            iregs(r2+1) = frame(ofs+1);
            nm = symName(ofs+1);
            n2 = regs{r2+1};
            in = sprintf([h '%s %s,%s\n'], 'movRM', n2, nm);
          elseif m == 1                          % movRP
            assert(r1 == 5);                     % EBP
            n2 = regs{r2+1};
            opd1 = next1();                      % one byte offset
            ofs = opd1/4;
            if ofs == 2
              iregs(r2+1) = esi;                 % fake calling sequence
            end
            in = sprintf([h '%s %s,cstack(%d)\n'], 'movRP', n2, ofs);
          elseif m == 0
            r1,r2,m
            eErr(['operator 8b ' h2c(opd1) ' (X subprogram call not implemented)']);
          else
            r1,r2,m
            eErr('8b NYI');
          end           
        case hx2('9e')                           % sahf
          % SF ZF xx AF xx PF xx CF
          switch iregs(1)
            case 0, CF = 0; ZF = 0;
            case 1, CF = 1; ZF = 0;
            case 2, CF = 0; ZF = 1;
          end
          in = sprintf([h '%s CF=%d ZF=%d\n'], 'sahf', CF, ZF);
        case hx2('d9')
          opd1 = next1();
          if opd1 == hx2('e0')                  % fchs
            x = fps(end);
            fps(end) = -x;
            in = sprintf([h '%s fps(%d)=%f\n'], 'fchs', numel(fps), x);
          else
            [r1, r2, m] = UN_MOD_REG(opd1);
            assert(m==2);
            if r2==0                             % fldM
              assert(r1==R.ESI);
              opd4 = next4();
              ofs = opd4/4;
              x = i2f(frame(ofs+1));
              nm = symName(ofs+1);
              nel=numel(fps);
              fps(end+1)=x;                      % push FPS
              in=sprintf([h '%s %s fps(%d)=%f\n'],'fldM',nm,nel,x);
            elseif r2==3                         % fstMp
              assert(r1==R.ESI); 
              opd4 = next4();
              ofs = opd4/4;
              nm = symName(ofs+1);
              x = fps(end);
              frame(ofs+1) = f2i(x);             % top of FPS
              fps(end) = [];                     % pop FPS
              in=sprintf([h '%s %s %f\n'],'fstMp',nm,x);
            else
              r1,r2,m
              eErr(['operator d9 ' h2c(opd1) ' NYI']);
              eErr('d9 NYI');
            end
          end
        case hx2('db')
          opd1 = next1();
          [rm, r, m] = UN_MOD_REG(opd1);
          if r==0 && m==2 && rm == R.ESI         % fildM
            opd4 = next4();                      % address
            ofs = opd4/4;                        % frame offset
            x = single(frame(ofs+1));
            nm = symName(ofs+1);
            nel = numel(fps);
            fps(end+1)=x;                        % push FPS
            in = sprintf([h '%s %s fps(%d)=%f\n'], 'fildM', nm, nel, x);
          elseif r==3 && m==2 && rm == R.ESI     % fistMp
            opd4 = next4();                      % address
            ofs = opd4/4;                        % frame offset
            nm = symName(ofs+1);
            x = floor(fps(end));                 % int from FPS
            fps = fps(1:end-1);                  % pop FPS
            frame(ofs+1) = x;
            in=sprintf([h '%s %s %f\n'],'fistMp', nm, x);
          else
            rm,r,m
            eErr('db NYI');
          end
          
        case hx2('de')
          opd1 = next1();
          [r1, r2, m] = UN_MOD_REG(opd1);
          assert(m==3);
          assert(r1==1);
          y = fps(end);                          % y=st is top
          fps(end) = [];                         % pop
          x = fps(end);                          % x=st1 is top-1
          if r2 == 3                             % fcompp
            % C0 C1 C2 C3
            % CF  0 PF ZF
            if     y < x, C0 = true;  C3 = false; % >
            elseif y ==x, C0 = false; C3 = true;  % =(never)
            elseif y > x, C0 = false; C3 = false; % <
            else          C0 = true;  C3 = true;     % NaN
            end
            fps(end) = [];                       % pop
            fop = 'fcompp';
            in = sprintf([h '%s C3=%d C0=%d\n'], fop, C3, C0);
          else
            switch r2
              case 0, x = x + y;  fop = 'faddp';   % faddp
              case 5, x = x - y;  fop = 'fsubp';   % fsubp
              case 1, x = x * y;  fop = 'fmulp';   % fmulp
              case 7, x = x / y;  fop = 'fdivp';   % fdivp
              otherwise
                r2
                eErr('de NYI');
            end
            fps(end) = x;
            in = sprintf([h '%s fps=%f\n'], fop, x);
          end
        case hx2('df')
          opd1 = next1();
          if opd1 == hx2('e0')                   % fnstsw
            fop = 'fnstsw';
            if     C0, res = 1;  fl = 'CF=1 ZF=0';
            elseif C3, res = 2;  fl = 'CF=0 ZF=1';
            else       res = 0;  fl = 'CF=0 ZF=0';
            end
            iregs(1) = res;                      % into EAX
            in = sprintf([h '%s %s\n'], fop, fl);
          else
            opd1
            eErr('df NYI');
          end
        case hx2('e9')                           % jmp32
          opd4 = next4();                        % 32 unsigned bits
          dest = aop.add(pc, u2s(opd4));         % signed add
          pc   = s2u(dest);
          in = sprintf([h '%s dest=%d (0x%08x)\n'], 'jmp32', pc, eip+pc-1);
        case hx2('f7')
          opd1 = next1();
          [r1, r2, m] = UN_MOD_REG(opd1);
          assert(m==3);
          if r2 == 3                             % -
            iregs(r1+1) = aop.neg(iregs(r1+1));
            n1 = regs{r1+1};
            in = sprintf([h '%s %s\n'], 'negR', n1);
          elseif r2 == 2                         % ~
            iregs(r1+1) = aop.not(iregs(r1+1));
            n1 = regs{r1+1};
            in = sprintf([h '%s %s\n'], 'notR', n1);
          else
            eErr('f7 NYI');
          end
        case hx2('ff')
          opd1 = next1();
          [r1, r2, m] = UN_MOD_REG(opd1);         %#ok<NASGU>
          assert(r2==2);
          n1 = regs{r1+1};
          % This is the start of the builtin calling sequence
          in = sprintf([h '%s %s\n'], 'callRi', n1); 
          if iregs(r1+1) == getCfun('rand')
            fps(end+1) = rand;  % the wrong rand, but who can tell?
          elseif iregs(r1+1) == getCfun('div')
            a = cstack(end); b = cstack(end-1);
            iregs(R.EAX+1) = aop.div(a,b);       % a/b (the answer)
          elseif iregs(r1+1) == getCfun('rem')
            a = cstack(end); b = cstack(end-1);
            iregs(R.EAX+1) = aop.rem(a,b);       % a%b (the answer)
          elseif iregs(r1+1) == 112              % fake 64 bit pointer
            fps(end+1) = rand;  % the wrong rand, but who can tell?
          elseif iregs(r1+1) == 113              % face 64 bit pointer
            a = cstack(end); b = cstack(end-1);
            iregs(R.EAX+1) = aop.div(a,b);       % a/b (the answer)
          elseif iregs(r1+1) == 114              % fake 64 bit pointer
            a = cstack(end); b = cstack(end-1);
            iregs(R.EAX+1) = aop.rem(a,b);       % a%b (the answer)
          else
            eErr('builtin NYI');
          end
        otherwise
          in = sprintf([h '0x%02x\n'], op);
          eErr('NYI');
      end
    end
    rg = '';
    for i=1:8                                    % int regs
      if i == 5 || i == 6 || i == 8, sval = '  na  ';
      else
        rval = iregs(i);
        if abs(rval) <= 9999999
          sval = sprintf('%10d ', rval);
        else
          sval = sprintf('0x%08x ', rval); 
        end
      end
      rg = [rg sval];
    end
    rg(end) = 10;                                 % eol
  end

% -------------------- formatters ---------------------------
  function opd = next1()
    opd = code(pc);
    pc = pc + 1;
  end

  function opd = next4()                         % unsigned !!!
    opd = uint32(0);
    for i=3:-1:0
      opd = bitor(bitshift(opd, 8), uint32(code(pc+i)));
    end
    pc = pc + 4;
  end

  function m = UN_MOD(mr)
    m = bitand(bitshift(mr, -6), 3);
  end

  function rm = UN_R_M(mr)
    rm = bitand(mr, 7);
  end

  function r = UN_REG(mr)
    r = bitand(bitshift(mr, -3), 7);
  end

  function [rm, r, m] = UN_MOD_REG(mr)
    rm  = UN_R_M(mr);
    r   = UN_REG(mr);
    m   = UN_MOD(mr);
  end

% ------------------ utilities ----------------------

  function nm = symName(ofs)
    if ofs <= syms.size()
      nm = syms.getName(ofs);
    else
      nm = ['tmp' num2str(ofs-syms.size()-1)];
    end
  end

  function bit4 = c2h(c)                         % char to hex
    if '0' <= c && c <= '9'
      bit4 = uint8(c-'0');
    elseif 'a' <= c && c <= 'f'
      bit4 = uint8(c-'a'+10);
    elseif 'A' <= c && c <= 'F'
      bit4 = uint8(c-'A'+10);
    else
      error(['bad hex ' c]);
    end
  end

  function c2 = h2c(h)
    c2 = [hexdig(bitshift(h,-4)+1) hexdig(bitand(h,15)+1)];
  end
      
  function bit8 = hx2(s)                         % string to 8 bit hex
    switch numel(s)                              % same as hex2dec
      case 1, bit8 = c2h(s);
      case 2, bit8 = bitor(bitshift(c2h(s(1)),4),c2h(s(2)));
      otherwise, error(['bad hex ' s]);
    end
  end

%{
  function bit16 = hx4(s)                        % string to 16 bit hex
    switch numel(s)
      case 1, hi = 0;           lo = hx2(s);
      case 2, hi = 0;           lo = hx2(s);
      case 3, hi = hx2(s(1));   lo = hx2(s(2:3));
      case 4, hi = hx2(s(1:2)); lo = hx2(s(3:4));
      otherwise, error(['bad hex ' s]);
    end
    bit16 = bitor(bitshift(uint16(hi),8), uint16(lo));
  end
%}

  function eErr(msg)
    error(['Emulatex86: ' msg]);
  end

% --------------------- exports ----------------

  function o = public()
    o = struct;
    o.trace = @trace;
  end

end
