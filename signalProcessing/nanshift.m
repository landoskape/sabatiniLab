function signal = nanshift(s,n)

s = s(:);
L = length(s);
signal = cat(1, nan(max([n 0]),1), s(max([-n+1 1]):L-max([n 0])), nan(max([-n 0]),1));


