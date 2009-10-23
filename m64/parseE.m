% FILE:    parseE.m
% PURPOSE: toy parser
%{
E
  T eof      1
T
  F          2
  T * F      3
F
  i          4
  ( T )      5
%}

function sr = parseE(src)
  sr = '';
  src = [src 0];            % append eof
  E();
  return;
  %---------
  function E()
    T();
    sr = [sr '1'];          % reduce
    assert(arc(1) == 0);    % used all input
  end
  
  function T()
    F();
    sr = [sr '2'];          % reduce
    while src(1) == '*'
      sr = [sr src(1)];     % shift
      src = src(2:end);
      F();
      sr = [sr '3'];        % reduce
    end
  end

  function F()
    switch src(1)
      case 'i'
        sr = [sr src(1)];   % shift
        src = src(2:end);
        sr = [sr '4'];      % reduce
      case '('
        src = src(2:end);   % do not shift
        T();
        assert(src(1)==')');% do not shift
        src = src(2:end);   % reduce
        sr = [sr '5'];
      otherwise
        assert(0);          % bad character
    end
  end
        
end


  