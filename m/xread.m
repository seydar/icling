% FILE:     xread.m
% METHOD:   reads a file and removes ^M as necessary to make unix format.
%
% EXAMPLE:
%  res = xread('xread.m')

% COPYRIGHT W.M.McKeeman 2007.  You may do anything you like with 
% this file except remove or modify this copyright.

function res = xread(filename)
  EOL = 10;                             % ^J
  f = fopen(filename);
  if f == -1
    error('xcom:xread', 'failed to find file %s\n', filename);
  end
  g = fread(f, 'char')';                % make row
  fclose(f);
  c = g==13;                            % 13 is ^M
  res = char(g(~c));                    % kill 'em'
  if res(end) ~= EOL; res(end+1) = EOL; end
end                                     % of xread

