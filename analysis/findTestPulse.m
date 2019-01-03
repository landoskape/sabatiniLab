function idx = findTestPulse(in, window)
% idx = findTestPulse(in, window)
% findTestPulse detects the testpulse in a recording. It assumes the window
% is in the last 20% of the input signal. testPulse uses the initial 50
% samples of the signal to determine the baseline, then finds a significant
% deviation from this baseline in a window set by 'window'
% 
% idx is the idx of values of testPulse
%
% Use window as follows:
% For the last X% of the signal, input X
% For the first X% of the signal, input -X
% Example:
% If test pulse occurs at 850ms in a 1000ms recording, use 20 to look for
% it in the 800:1000ms window
% If test pulse occurs at 50ms in a 1000ms recording, use -10 to look for
% it in the first 100ms. 
% If looking for test pulse in beginning of signal, this function excludes
% the first 50ms. 

if (nargin < 2)
    window = 20; % default window is last 20% of signal
end

% Find Baseline
base = mean(in(1:50));
bstd = std(in(1:50));
bthr = 10 * bstd;

% Define testPulse search window
NS = length(in); % number of samples
side = sign(window); % which part of signal to look for
switch side
    case 1
        tpIdx = round(NS*(100-window+1)/100) : NS;
    case -1
        tpIdx = 1:NS*(-window)/100;
end

% Get start/end points of test pulse
tpin = in(tpIdx) - base; % Normalize to baseline, get just tpWindow
tpin = abs(tpin); % make all positive
st = find(tpin > base+bthr, 1, 'first') - 1;
en = find(tpin(st+1:end) < base+bthr, 1, 'first') + st;

% Output
idx = (st:en) + tpIdx(1) - 1;




