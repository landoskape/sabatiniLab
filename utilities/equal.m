function bool = equal(A,mode)
% bool = equal(A,mode)
% A is a matrix
% mode determines output
%
% determines if elements of A are all equal to one another
% if mode is 0, returns single logical for full matrix (~default~)
% if mode is 1, returns row vector indicating equality across columns of A

if (nargin < 2)
    mode = 0;
end

switch mode
    case 0
        bool = all(A(:) == A(1));
    case 1
        bool = all(bsxfun(@eq, A, A(1,:)),1);
end

