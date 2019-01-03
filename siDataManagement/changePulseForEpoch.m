function [state,status] = changePulseForEpoch(state,epoch,pulse,channel)
% goes through state structure and changes the pulse number in state.cycle
% returns state and a status array of the old pulse and the new pulse
% pulse is a number
% -can be vector but then has to be same numel as sum(epoch)
% pulseName is the field in state.cycle either channel 0 or 1
% -- state.cycle.pulseToUse0 or pulseToUse1
%

epochList = [state(:).epoch];
eidx = find(epochList==epoch);
NA = numel(eidx);
if numel(pulse)~=1 && numel(pulse)~=NA, error('pulse vector needs to be exactly number of acquisitions'); end
if numel(pulse)==1, pulse = pulse*ones(NA,1); end
pulseFieldName = sprintf('pulseToUse%d',channel); 
status = zeros(NA,2);
status(:,2) = pulse;
for a = 1:NA
    status(a,1) = state(eidx(a)).cycle.(pulseFieldName);
    %state(eidx(a)).cycle.(pulseFieldName) = pulse(a);
end
    
    



