

dt = 0.01; % ms
T = 1000; % ms
tvec = dt:dt:T; % time vector
NS = length(tvec); % number samples

% You'd provide this I'm just showing you how to make it
% data = rand(NS,1);
amplitudeRC = -5; % mV


rcStart = 850;
rcEnd = 950;
rcDelay = 0.2; % ms to wait after start of rc check to do exponential fit and a few other things

startBaselineSample = find(tvec>=rcStart-(rcEnd-rcStart)*0.1,1,'first'); % calculate baseline with same amount of time
rcStartSample = find(tvec>=rcStart,1,'first'); 
startEndlineSample = find(tvec>=rcStart + (rcEnd-rcStart)*0.9,1,'first') - 1; % endline start sample
rcEndSample = find(tvec>=rcEnd,1,'first');
numDelaySamples = round(rcDelay / dt);

% Compute peak and get peak location
if amplitudeRC > 0
    [pk, pkIdx] = max(data(rcStartSample:rcEndSample));
else
    [pk, pkIdx] = min(data(rcStartSample:rcEndSample));
end
pkIdx = pkIdx + rcStartSample - 1; 

baseline = mean(data(startBaselineSample:rcStartSample-1));
endline = mean(data(startEndlineSample:rcEndSample));


% Higher percentage biases fit to the fast component which is more accurate
% in cells with significant contribution of dendrites.
percentageDecayCutoff = 20; 
decayCutoffValue = (pk-endline)*percentageDecayCutoff/100 + endline;

if amplitudeRC > 0
    decayEnd = find(data(pkIdx+numDelaySamples:rcEndSample)<decayCutoffValue,1,'first'); % Get's first below 20%
else
    decayEnd = find(data(pkIdx+numDelaySamples:rcEndSample)>decayCutoffValue,1,'first'); % Get's first below 20%
end

decayTime = tvec(pkIdx+numDelaySamples:pkIdx+numDelaySamples+decayEnd-1);
decayTime = decayTime - decayTime(1); %start at 0
decayData = data(pkIdx+numDelaySamples:pkIdx+numDelaySamples+decayEnd-1) - endline; 
if amplitudeRC < 0, decayData = -decayData; end

% Fit Options
fitType = fittype('peak*exp(-x/tau)');
fitOptions = fitoptions(fitType);
fitOptions.StartPoint = [pk-endline decayEnd*dt/3];
fitOptions.Lower = [0 0];
fitOptions.Upper = [abs(pk)*10 T];

% Do Fit
decayFit = fit(decayTime(:),decayData(:),fitType,fitOptions);
tau = decayFit.tau; % in whatever units you made tvec (should be ms)

relativeStart = (pkIdx+numDelaySamples - rcStartSample)*dt;

% Extrapolate back for exponential estimate of peak
pkEstimateExponential = decayFit.peak * exp(relativeStart/decayFit.tau) * (-1*(amplitudeRC<0)+1*(amplitudeRC>0)); 

choiceOfPeak = pk; % Or use "pkEstimateExponential"
rs = 1000 * amplitudeRC / choiceOfPeak;
rin = 1000 * amplitudeRC/(endline-baseline) - rs;
cm = 1000 * tau / rs;




