function dp = dprime(noise, signal)
% dp = dprime(noise, signal)
% works on columns if inputs are same sized arrays

if isrow(noise), noise = noise(:); end
if isrow(signal), signal = signal(:); end

if size(noise) ~= size(signal)
    error('size of arrays must be the same');
end

dp = (mean(signal,1) - mean(noise,1)) ./ sqrt( 1/2 * (std(signal,[],1) + std(noise,[],1)));


