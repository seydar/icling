% FILE:     AsmA64.m
% PURPOSE:  assemble executable code (target dependent)
%           addons for Intel 64 bit


function obj = AsmA64(emitn, subFlags, allFlags) % ctor

  if nargin < 3; allFlags = {}; end
  if nargin < 2; subFlags = {}; end
    
  TA   = findFlag('-asmTrace', subFlags); 

  regs = {'RAX','RCX','RDX','RBX','RSP','RBP','RSI','RDI',...
           'R8', 'R9','R10','R11','R12','R13','R14','R15'};
  R     = enum(regs, 0);
    
  obj = public();                                % export public methods
    
  return;                                        % end of ctor

  function prolog()
    pushR(R.RBP, '    # save a64 frame pointer');  % save frame
    movRR(R.RBP, R.RSP, '# new a64 frame');        % new frame
    movRR(R.RSI, R.RDI, '# new X frame pointer');  % 1rst arg = frame ptr
  end

  function bailout(errNo)                        % error return
    movRC(R.RAX, uint32(errNo), '# meaning run error');
    iepilog()
  end

  function epilog()
    xorRR(R.RAX, R.RAX, '# no run error');       % normal return
    iepilog();
  end

  function iepilog()                             % int/err return
    leave('# restore previous A64 stack frame');
    ret('# restore previous RIP');
  end

  function leave(msg)
    if nargin == 0, msg = ''; end
    pc = emitn(hx2('c9'));                       % undoes frame
    if TA; T(pc, 'leave', msg); end
  end

  function ret(msg)
    if nargin == 0, msg = ''; end
    pc = emitn(hx2('c3'));                       % simple return
    if TA; T(pc, 'ret', msg); end
  end

  function pushR(r, msg)                         % *--RSP = r
    if nargin < 2, msg = ''; end
    pc = emitn(bitor(hx2('50'), R_M(r)));
    if TA; T(pc, 'pushR', sprintf('%s %s', regs{r+1}, msg)); end
  end

  function popR(r, msg)                          % r = *RSP++
    if nargin < 2, msg = ''; end
    pc = emitn(bitor(hx2('58'), R_M(r)));
    if TA; T(pc, 'popR', sprintf('%s %s ', regs{r+1}, msg)); end
  end

  function movRR(r1, r2, msg)
    if nargin < 3, msg = ''; end
    pc = emitn([hx2('48'), hx2('89'), MOD_REG(r1,r2)]);
    if TA
      T(pc, 'movRRq', sprintf('%s,%s %s', regs{r1+1}, regs{r2+1}, msg)); 
    end
  end

  function movRC(r, c, msg)
    if nargin < 3, msg = ''; end
    pc = emitn([hx2('48'), bitor(hx2('b8'), uint8(r)), emit64(c)]);
    if TA
      T(pc, 'movRCq', sprintf('%s,=%d (0x%lx) %s)', regs{r+1}, c, c, msg)); 
    end
  end

  function xorRR(r1, r2, msg)
    if nargin < 3, msg = ''; end
    pc = emitn([hx2('48'), hx2('33'), MOD_REG(r1,r2)]);
    if TA
      T(pc, 'xorRRq', sprintf('%s,%s %s', regs{r1+1}, regs{r2+1}, msg));
    end
  end

  function addRC(r, c, msg) 
    if nargin < 3, msg = ''; end
    pc = emitn([hx2('48'), hx2('81'), MOD_REG(r,0), emit64(c)]);
    if TA
      T(pc, 'addRCq', sprintf('%s,=%d (0x%x) %s'), regs{r+1}, c, c, msg); 
    end
  end

  function callRi(r, msg)
    if nargin < 2, msg = ''; end
    pc = emitn([hx2('48'), hx2('ff'), MOD_REG(r, 2)]);
    if TA; T(pc, 'callRiq', sprintf('%s %s', regs{r+1}, msg)); end
  end

% --------------  op codes  ----------------------
  function res = MOD(m)                          % (((m)&3)<<6)
    res = bitshift(bitand(uint8(m),3),6);
  end

  function res = REG(r)                          % (((r)&7)<<3)
    res = bitshift(bitand(uint8(r),7),3);
  end

  function res = MOD_REG(rm, r)  % ((uint8)(MOD(3) | REG(r) | R_M(rm)))
    res = bitor(bitor(MOD(3), REG(r)), R_M(rm));
  end

  function res = R_M(rm)                         % ((r)&7)
    res = bitand(uint8(rm),7);
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

  function bit8 = hx2(s)                         % string to 8 bit hex
    switch numel(s)
      case 1, bit8 = c2h(s);
      case 2, bit8 = bitor(bitshift(c2h(s(1)),4),c2h(s(2)));
      otherwise, error(['bad hex ' s]);
    end
  end
  
  function res = emit64(iv)                      % little endian
    uv = uint64(iv);
    res = zeros(1,8,'uint8');
    for idx = 1:8
      res(idx) = uint8(bitand(uv, 255));
      uv = bitshift(uv, -8);
    end
  end
  
  function T(pc, op, msg)
    if nargin < 3; msg = ''; end
    fprintf('AsmA64: %4d %s %s\n', pc+1, op, msg); 
  end

  function o = public()
    o = struct;
    o.R       = R;
    o.prolog  = @prolog;
    o.epilog  = @epilog;
    o.bailout = @bailout;
    o.leave   = @leave;
    o.ret     = @ret;
    o.movRR   = @movRR;
    o.pushR   = @pushR;    
    o.popR    = @popR;
    o.addRC   = @addRC;
    o.xorRR   = @xorRR;
    o.movRC   = @movRC;
    o.callRi  = @callRi;
  end

end