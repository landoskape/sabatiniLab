function v = normrange(x, rng)
% v = normrange(x, rng)
% normrange takes an array x of any size and normalizes it to a range set
% by the 2 element vector rng. rng(1) will be 0 and rng(2) will be 1

if (nargin == 1)
    rng = [min(x(:)), max(x(:))];
end

v = (x - rng(1)) ./ repmat(diff(rng),size(x));



