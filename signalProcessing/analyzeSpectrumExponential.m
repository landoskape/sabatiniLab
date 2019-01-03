

a = 1; % Amplitude
t = 10:10:200; % Time Constant
L = max(t) * 100; % length of each signal

N = length(t); % number of time constants

curves = cell(N,2); % Cell array of exponential signals

for i = 1:N
    curves{i,1} = a * exp(-(0:L-1)'/t(i));
    curves{i,2} = curves{i,1} / sum(curves{i,1}); % Normalized signal
end
Fs = num2cell(1000*ones(N,2));

[spectra,freq] = cellfun(@getSpectrum, curves, Fs, 'uni', 0);

cmap = varycolor(N);

callFigs; 
hold on
for i = 1:N
    plot(freq{i,2},spectra{i,2},'color',cmap(i,:));
end

legend(cellfun(@num2str,num2cell(t),'uni',0),'location','northeast');


