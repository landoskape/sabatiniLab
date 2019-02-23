function ts = getTimeStamps(wvStrings,channel)
% wvStrings is a cell array of wave strings that are global variables

if nargin < 2, channel = []; end

NW = length(wvStrings);
ts = zeros(1,NW);
for w = 1:NW
    ts(w) = getTimeStamp(wvStrings{w},channel);
end

