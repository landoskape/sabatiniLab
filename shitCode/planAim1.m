

ppat = -4:4:16;

pulses = length(ppat)+2; % Number combos + (AP + uEPSP alone)
period = 20;
trials = 10;

tSec = pulses * period * trials;

fprintf('%d pulses\n',pulses);
fprintf('%d seconds\n',tSec);
fprintf('%.1f minutes\n\n',tSec/60);

