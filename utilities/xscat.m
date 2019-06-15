function xvals = xscat(data,range)

ND = numel(data);
[N,~,b] = histcounts(data,10); % count data and bin into 10 groups
N = N(:);
b = b(:);
dispersion = range*N/max(N); % how much should we disperse the data on average?

xvals = rand(ND,1) .* dispersion(b) - dispersion(b)/2; % return xvalues


