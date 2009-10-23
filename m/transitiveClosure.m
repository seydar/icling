% FILE:    transitiveClosure.m
% PURPOSE: implement the transitive closure of a logical relation
% METHOD:  Let < represent an arbitrary transitive relation, and
%          R be square a matrix of values representing <.  That is:
%          R(i,j) iff i<j.
%          Compute R^2 (matrix multiply using & and |).
%          R^2(i,k) iff exists j so that i<j<k (closure to distance 2).
%          The iteration R = R | R^k converges quickly.
%          R(i,n) iff i<j<....<m<n (closure of all distances)
%          In MATLAB, simulate &| with *+
% EXAMPLE:
%  B = rand(10) < 0.2
%  transitiveClosure(B)

% COPYRIGHT W.M.McKeeman 2007.  You may do anything you like with 
% this file except remove or modify this copyright.


function res = transitiveClosure(B)
  assert(islogical(B));
  C = single(B);
  while true
    newC = single(C*C>0|C);            % matrix multiply
    if ~any(any(newC-C)), break; end
    C = newC;
  end
  res = logical(C);
end