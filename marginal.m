function m = marginal(A,d,func)
% m = marginal(A,d)
% 
% A is an array of N dimensions
% d is a dimension of A (1<=d<=N)
% func is a function (default = 'mean') --- not coded yet though!
%
% if d is an array of dimensions then 
% 
% m is the values of dimension d, marginalized across all other dimensions
% e.g. if A is (5x10x3) and d=1, m = mean(mean(A,2),3)
% 
% m is squeezed before return

if nargin<3, func = 'mean'; end
ND = ndims(A);
if ~all(round(d)==d) || any(d>ND) || any(d<1)
    error('D must be an integer of one of A''s dimensions');
end

dimIdx = 1:ND;
dimIdx(d) = [];

head = repmat(sprintf('%s(',func),1,length(dimIdx));
tail = sprintf(',%d)',dimIdx);
m = eval([head,'A',tail,';']);
m = squeeze(m);

