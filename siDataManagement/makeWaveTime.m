function t = makeWaveTime(wv)

NP = length(wv);
startTime = wv.xscale(1);
dt = wv.xscale(2);
endTime = (NP-1)*dt + startTime;

t = startTime : dt : endTime;



