function pulse = getPulseFromEpoch(state,epoch)
% returns two column array of pulse from epoch in pulseToUse0 and 1
epochList = [state(:).epoch];
eidx = epochList==epoch;
NA = sum(eidx);
pulse = zeros(NA,2);
cycle = [state(eidx).cycle];
pulse(:,1) = [cycle(:).pulseToUse0];
pulse(:,2) = [cycle(:).pulseToUse1];
