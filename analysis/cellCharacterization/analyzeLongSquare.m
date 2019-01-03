function [apFeatures,trainFeatures] = analyzeLongSquare(sweep,injection,Fs)
% sweep is a numeric array of mV values 
% injection: [startTimeInjection durationInjection] both in ms
% Fs  sampling rate

if ~isvector(sweep)
    fprintf(2, 'data not analyzed. sweep must be vector.\n');
    return
end
if numel(injection) ~= 2
    fprintf(2, 'injection must provide injection duration and start time in milliseconds.\n');
end

sweep = sweep(:);

% Filter with 4-Pole Bessel at 10kHz
NP = 4; % number poles
Co = 10000; % cutoff frequency 
[b,a] = besself(NP,2*pi*Co); 
[bd,ad] = bilinear(b,a,Fs); 

sm = filtfilt(bd,ad,sweep); % filtfilt to preserve phase delay
dvdt = diff(sm)*Fs / 1000;

% Putative Events
% -- find group of points where dvdt>20 and goes below zero between events
pAP = find(diff(dvdt>20)>0)+1;
pISI = find(diff(dvdt<0)>0)+1;
pAP = pAP(:); 
pISI = pISI(:);

% Make sure trace dips below zero between each event
validAP = true(length(pAP),1);
for p = 1:length(pAP)-1
    if ~validAP(p)
        % this point already determined to be bad
        continue
    end
    
    cAP = pAP(p); % current AP start idx
    nextISI = pISI(find(pISI > cAP,1)); % next ISI start idx
    idxInvalid = (pAP > cAP) & (pAP < nextISI); % pAP idx's greater than current and less than next ISI
    validAP(idxInvalid) = false;
end

% Putative APs
papStart = pAP(validAP); % return just indices of valid putative AP events
papEnd = cat(1, papStart(2:end), length(sweep)) - 1;
NAP = length(papStart);

% now get features for each AP
% -- {1'apThreshold', 2'apStart(Threshold)Time', 3'peak', 4'peakTime',
%     5'trough', 6'troughTime', 7'fastTrough', 8'fastTroughTime',
%     9'slowTrough', 10'slowTroughTime', 11'troughTimeRatio', 12'height',
%     13'FWHM', 14'upstrokePeak', 15'upstrokePeakTime', 16'downstrokePeak', 
%     17'downstrokePeakTime', 18'Up/Down Ratio'} 

% First Pass - compute features necessary to validate AP
numFeatures = 18;
apFeatures = nan(NAP,numFeatures);
for ap = 1:NAP
    cst = papStart(ap);
    cen = papEnd(ap);
    [apFeatures(ap,3),idx] = max(sweep(cst:cen)); % peak / peakTime
    apFeatures(ap,4) = idx + cst - 1; % adjust for idx window
    
    % up-stroke / down-stroke
    [apFeatures(ap,14),idx] = max(dvdt(cst:apFeatures(ap,4)));
    apFeatures(ap,15) = idx + cst - 1; % adjust for idx window
    
    % Find more accurate threshold
    thresholdDVDT = apFeatures(ap,14) * 0.05;
    idx = find(dvdt(apFeatures(ap,15):-1:1) < thresholdDVDT,1,'first') - 1;
    apFeatures(ap,2) = apFeatures(ap,15) - (idx-1); % adjust for idx window
    apFeatures(ap,1) = sweep(apFeatures(ap,2));
end
    
% Identify good APs
notTooSlow = ((apFeatures(:,4) - apFeatures(:,2)) / Fs) <= 0.002; % treshold to peak < 2ms
notTooSmall = (apFeatures(:,3) - apFeatures(:,1)) >= 2; % thresh to peak voltage > 2mV
notTooShort = apFeatures(:,3) >= -30; % Peak above -30mV

goodAPs = notTooSlow & notTooSmall & notTooShort;  % Master idx of good APs

% Refined estimates of AP Features
avgMaxDVDT = mean(apFeatures(:,14));
thresholdDVDT = avgMaxDVDT * 0.05;

% Second Pass - Compute everything else
idxGoodAPs = find(goodAPs(:)'); % indices of good APs
for ap = idxGoodAPs
    cst = papStart(ap);
    cen = papEnd(ap);
    
    % Find more accurate threshold
    idx = find(dvdt(apFeatures(ap,15):-1:1) > thresholdDVDT,1,'first') - 1;
    apFeatures(ap,2) = apFeatures(ap,4) - (idx-1); % adjust for idx window
    apFeatures(ap,1) = sweep(apFeatures(ap,2));
    
    [apFeatures(ap,5),idx] = min(sweep(cst:cen)); % trough / troughTime
    apFeatures(ap,6) = idx + cst - 1; % adjust for index window
    
    pTime = apFeatures(ap,4); % peak time
    [apFeatures(ap,7),idx] = min(sweep(pTime:pTime+round(0.005*Fs))); % fastTrough/Time
    apFeatures(ap,8) = idx + pTime - 1; % adjust for index window
    [apFeatures(ap,9),idx] = min(sweep(pTime+round(0.005*Fs):cen)); % slowTrough/Time
    apFeatures(ap,10) = idx + pTime + round(0.005*Fs) - 1; % adjust for index window
    
    tTime = apFeatures(ap,10); % slow trough time
    apFeatures(ap,11) = (tTime - cst) / (cen - tTime); % timeRatio slow trough
    
    apFeatures(ap,12) = apFeatures(ap,2) - apFeatures(ap,5); % AP Height
    
    % half-width
    halfHeight = apFeatures(ap,12)/2 + apFeatures(ap,9); 
    beforeHH = find(sweep(pTime:-1:1)<=halfHeight,1,'first');
    afterHH = find(sweep(pTime:end)<=halfHeight,1,'first');
    apFeatures(ap,13) = (beforeHH + afterHH - 2) / Fs; % full-width at half-height
    
    % up-stroke / down-stroke
    [apFeatures(ap,16),idx] = min(dvdt(pTime:tTime));
    apFeatures(ap,17) = idx + pTime - 1; % adjust for idx window
    apFeatures(ap,18) = abs(apFeatures(ap,14) / apFeatures(ap,16)); % up/down ratio
end

NAP = sum(goodAPs); % new number of good APs
apFeatures(~goodAPs,:) = []; % get rid of bad APs


% ------------- AP Train Features ------------- 
% {1'First ISI', 2'AverageISI', 3'ISI CV', 4'AverageRate', 5'Latency',
% 6'AdaptationIndex', 7'Delay', 8'Burst', 9'Pause'}
trainFeatures = zeros(1,9);
isis = 1000 * diff(apFeatures(:,2)) / Fs; % ISIs in seconds
trainFeatures(1) = isis(1); % First ISI
trainFeatures(2) = mean(isis); % Average ISI
trainFeatures(3) = std(isis) / trainFeatures(2); % ISI Coefficient of Variation
trainFeatures(4) = NAP / injection(2) / 1000; % Average Firing Rate (spk/sec)
trainFeatures(5) = 1000*apFeatures(1,2)/Fs - injection(1); % Latency to 1st spike (ms)
trainFeatures(6) = mean((isis(2:end)-isis(1:end-1)) ./ (isis(2:end)+isis(1:end-1))); % Adaptation Index
trainFeatures(7) = trainFeatures(5) > trainFeatures(2); % Delay 1/0
trainFeatures(8) = all(isis([1 2]) <= 5); % Burst 1/0
trainFeatures(9) = any(isis(2:end-1) > 3*max([isis(1:end-2),isis(3:end)],[],2)); % Pause 1/0


