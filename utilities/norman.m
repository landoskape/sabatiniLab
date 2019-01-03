function out = norman(in)
% takes columns of in and normalizes them from 0 to 1

NP = size(in,1);
up = in - repmat(min(in,[],1),NP,1);
out = up ./ repmat(max(up,[],1),NP,1);



