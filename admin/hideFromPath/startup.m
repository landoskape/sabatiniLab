% Startup.m is automatically called by MATLAB when the program is launched
% here we look for 

waveUserDefaults('axisAutoScale', 2);
global state gh
state.hasDevices=0; 

% warning('off', 'MATLAB:dispatcher:InexactMatch');
% warning('off', 'daq:daqmex:propertyConfigurationError');
% warning('off', 'MATLAB:dispatcher:InexactCaseMatch');

state.devices=[];

if isempty(state.devices)
    disp('*** NO DEVICES FOUND.  STARTING UP IN ANALYSIS MODE ***');
	disp('');
    beep
    state.hasDevices=0;
    state.deviceIDs={};
else
    disp('*** DEVICES FOUND.  STARTING UP IN ACQUISITION MODE ***');
	disp('');
    state.hasDevices=1;
	state.deviceIDs=cell(1, length(state.devices));
	
	for counter=1:length(state.devices)
		state.deviceIDs{counter}=[state.devices(counter).ID ' ' state.devices(counter).Description];
    end
end

gh.chooser = guihandles(chooser);
close(gcf);
