function [p,f] = getSpectrum(s, Fs)

L = size(s,1);
n = 2^nextpow2(L);
Y = fft(s,n);

pfull = abs(Y/n);
p = pfull(1:n/2+1,:);
p(2:end-1,:) = 2*p(2:end-1,:);

f = Fs*(0:(n/2))/n;



