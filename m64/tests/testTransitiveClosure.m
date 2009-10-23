% FILE:    testTransitiveClosure
% PURPOSE: test transitive closure algorithm
% EXAMPLE:
%  testTransitiveClosure()

% COPYRIGHT W.M.McKeeman 2008.  You may do anything you like with 
% this file except remove or modify this copyright.


t = false(3);
t(1,2)=true;
t(2,3)=true;
tc = transitiveClosure(t);
if ~tc(1,3), error(' test 1'); end

t = false(10);
for i=1:9, t(i,i+1)=true; end
tc = transitiveClosure(t);
for i=1:10; for j=1:10; if i<j ~= tc(i,j), error('test 2'); end; end; end

t = false(10);
for i=1:9, t(i,i+1)=true; t(i,i) = true; end
t(10,10)=true;
tc = transitiveClosure(t);
for i=1:10; for j=1:10; if i<=j ~= tc(i,j), error('test 3'); end; end; end

t = false(10);
for i=1:2:9, t(i,i+1)=true; end
tc = transitiveClosure(t);
if ~all(all(tc==t)), error('test 4'); end;


