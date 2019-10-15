function signal = nanshift(s,n)

transposeON = 0;
if size(s,1)==1 && size(s,2)>1
    transposeON = 1;
    s = s';
end
    
L = size(s,1);
signal = cat(1, nan(max([n 0]),size(s,2)), s(max([-n+1 1]):L-max([n 0]),:), nan(max([-n 0]),size(s,2)));
if transposeON
    signal = signal';
end


