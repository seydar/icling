% ANY2STR  convert most MATLAB values to textual form
%   str = ANY2STR(val) converts the value to a string
%
% NOTE:  MATLAB objects not supported
%
% EXAMPLES:
%   str = any2str([])
%   str = any2str({})
%   str = any2str(ones(1,3))
%   str = any2str(ones(2))
%   str = any2str(ones(2,2,2))
%   str = any2str(int8(1:2))
%   str = any2str({{1},{2,3}})
%   str = any2str({{1};{2,3}})
%   str = any2str(cell(2,2,2))
%   str = any2str(struct('a', 1, 'b', '2'))
%   str = any2str({1,2:3,'abc',{4,5}, {{6}}})


function str = any2str(d)
  if isnumeric(d);    str = array2str(d);
  elseif iscell(d);   str = cell2str(d);
  elseif ischar(d);   str = stringize(d);
  elseif isstruct(d); str = struct2str(d);
  elseif strcmp(class(d), 'function_handle'), str= fh2str(d); 
  else error('type conversion NYI');
  end
  return;

  % ----- nested functions-----

  function str = array2str(a)
    if isempty(a)
      str = '[]';
    elseif isscalar(a) == 1
      str = sprintf('%d', a);
    elseif ndims(a) > 2                        % N-D
      s = size(a);                             % vector of dims
      str = 'array('
      for i=1:numel(s)-1
        str = [str num2str(s(i)) 'x'];
      end
      str = [str num2str(s(end)) ')'];
    elseif size(a, 1) == 1                     % row vector
      str = '[';
      for i=1:numel(a)-1; 
        str = [str num2str(a(i)) ','];
      end
      str = [str num2str(a(end)) ']'];
    else                                       % 2-D
      str = '[';
      for i=1:size(a,1)-1 
        for j=1:size(a,2)-1
          str = [str num2str(a(i,j)) ','];
        end
        str = [str num2str(a(i,end)) ';'];
      end
      for j=1:size(a,2)-1
        str = [str num2str(a(end,j)) ','];
      end
      str = [str num2str(a(end,end))];
      str = [str ']'];
    end
    if ~strcmp(class(a), 'double')             % get the type right
      str = [class(a) '(' str ')'];
    end
  end

  function str = cell2str(c)
    if isempty(c) 
      str = '{}';
    elseif ndims(c) > 2                        % N-D
      s = size(c);                             % vector of dims
      str = 'cell(';
      for i=1:numel(s)-1
        str = [str num2str(s(i)) 'x'];
      end
      str = [str num2str(s(end)) ')'];
    elseif size(c,1) == 1                     % row vector
      str = '{';
      for i=1:numel(c)-1; 
        str = [str any2str(c{i}) ','];
      end
      str = [str any2str(c{end}) '}'];
    else                                       % 2-D
      str = '{';
      for i=1:size(c,1)-1 
        for j=1:size(c,2)-1
          str = [str any2str(c{i,j}) ','];
        end
        str = [str any2str(c{i,end}) ';'];
      end
      for j=1:size(c,2)-1
        str = [str any2str(c{end,j}) ','];
      end
      str = [str any2str(c{end,end})];
      str = [str '}'];
    end
  end

  function t = struct2str(s)
    f = fields(s);
    t = 'struct(';
    n = numel(f);
    for i=1:n-1
      t = [t stringize(f{i}) ',' any2str(s.(f{i})) ', '];
    end
    t = [t stringize(f{n}) ',' any2str(s.(f{n})) ')'];
  end

  function s = fh2str(d)
    s = ['@' func2str(d)];
  end   

  function res = stringize(chrs)
    v = strfind(chrs, '''');         % double '
    for is = numel(v):-1:1
      chrs = [chrs(1:v(is)) '''' chrs(v(is)+1:end)];
    end
    res = ['''' chrs ''''];
  end
end


