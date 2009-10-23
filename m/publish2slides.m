% FILE:     publish2slides.m
% PURPOSE:  Turn publish output into slide show
% AUTHOR:   McKeeman @ MathWorks.com

function publish2slides(filename)
  EOL = 10;                            % ascii newline
  html = xread(filename);              % HTML file text
  head = xread('slidehead.txt');       % standard HTML header
  tail = '</body></html>';             % standard HTML trailer
  
  % extract main content from published file
  startbody = strfind(html,'<body>');
  body = html(startbody:end);
  inbody = strfind(body, '<div class');
  endbody = strfind(body, '##### SOURCE BEGIN');
  div2div = body(inbody:endbody-1);    % the content
  
  % break the published file into page-sized parts
  marker = '<p>PAGE BREAK</p>';
  nm = numel(marker);
  idx = strfind(div2div, marker);      % find the required page breaks
  fn = cell(numel(idx),0);             % top-of-slide page number
  for i=1:numel(idx)
    fn{i} = sprintf('%s-%02d.html', filename(1:end-5), i-1);
  end
  % wrap content in HTML page; add NEXT|PREV URLs; write each page to file
  for i=2:numel(idx)-1
    fd = fopen(fn{i}, 'w');
    slide1 = [...
      head ...
      '<p align="right">' fn{i}(6:end) '</p>' EOL ...
      div2div(idx(i)+nm:idx(i+1)-1)];
    if i==2
      slide2 = [...
      '<table border=1><tr>'                      ...
      '<td><a href="' fn{i+1}(6:end) '">NEXT</a></td>'...
      '</tr></table>' EOL];
    elseif i==numel(idx-1)-1
      slide2 = [...
      '<table border=1><tr>'                      ...
      '<td><a href="' fn{i-1}(6:end) '">PREV</a></td>' ...
      '</tr></table>' EOL];   
    else
      slide2 = [...
      '<table border=1><tr>'                      ...
      '<td><a href="' fn{i-1}(6:end) '">PREV</a></td>' ...
      '<td><a href="' fn{i+1}(6:end) '">NEXT</a></td>'...
      '</tr></table>' EOL];
    end
    fwrite(fd, [slide1 slide2 tail]);  % write a page
    fclose(fd);
  end
end
