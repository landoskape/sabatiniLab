function makeApProps(epoch)

global meta
global state 
global data 
global exp

% exp(epoch) = output; % output will be the structure I make here 
out = setupExpFields();
out.epoch = epoch;
out.type = 'apProps';
out.ename = meta.ename;

% Retrieve data specific to this epoch
edata = getEpoch(data, epoch);
estate = getEpoch(state, epoch);

% Get indices for physiology
phidx = find([edata(:).ph] == 1); % Just to collect the phys traces
NA = length(phidx);
cMap = varycolor(NA);
pmode = [edata(phidx).pmode];
if any(pmode ~= 1) 
    warning('some acquisitions in voltage clamp... ignoring those trials'); 
    newIdx = (pmode == 1);
    phidx = phidx(newIdx);
    pmode = pmode(newIdx);
end
if equal(pmode), pmode = pmode(1); end
out.meta.pmode = pmode;

% Load data and time
ptime = {edata(phidx).pt};
pdata = {edata(phidx).pdata};

ptime = cellfun(@(s) 1000*s, ptime, 'uni', 0); % Convert to milliseconds

% Setup start times, adjust time vector
stime = zeros(1,NA);
for p = 1:NA
    stime(p) = estate(phidx(p)).phys.cellParams.minInCell0; 
end
stime = 1000*60*stime; % convert to milliseconds

ntime = cellfun(@(t,off) t + off, ptime, num2cell(stime), 'uni', 0);

% Load input to cell
pin = {edata(phidx).pin};
inFlag = 1;
if all(cellfun(@isempty, pin, 'uni', 1)) 
    % Index of window to ignore because test pulse probably there
    tpidx = cellfun(@(t) length(t)*80/100+1:length(t), ptime, 'uni', 0);
    inFlag = 0;
else
    tpidx = cellfun(@findTestPulse, pin, 'uni', 0); % test pulse indices
end

% Analysis 
restx = cellfun(@(t) (t > 80) & (t < 100), ptime, 'uni', 0); % Resting window 
apidx = cellfun(@(t) (t > 100) & (t < 200), ptime, 'uni', 0); % AP window
rest = cellfun(@(vm, idx) mean(vm(idx)), pdata, restx, 'uni', 1); % Resting potential
[~,thidx] = cellfun(@(vm) max(diff(diff(vm))), pdata, 'uni', 0);  % Compute second der and get idx of max
thvm = cellfun(@(vm, idx) vm(idx), pdata, thidx, 'uni', 1); % Threshold potential
[mxvm,mxidx] = cellfun(@max, pdata, 'uni', 1); % Get max potential 
amps = mxvm - thvm; % Get amplitude of AP 
[~,durAPx] = cellfun(@(vm, mxidx, thvm) max(diff(diff(vm(mxidx:end)))), pdata, thidx, num2cell(thvm), 'uni', 0);
durAPx = cellfun(@(dur, off) dur + off, durAPx, num2cell(mxidx), 'uni', 0); % Corrected offset
durAP = cellfun(@(t,st,en) t(en) - t(st), ptime, thidx, durAPx, 'uni', 1); % Duration of AP
durADx = cellfun(@(vm, thidx, rest) find(vm(thidx:end) < (rest+3), 1, 'first') + thidx - 1, pdata, thidx, num2cell(rest), 'uni', 0);
durAD = cellfun(@(t,st,en) t(en) - t(st), ptime, thidx, durADx, 'uni', 1); % Duration back to rest
aDep = cellfun(@(vm, t, idx) vm(idx + 3/diff(t(1:2))), pdata, ptime, thidx, 'uni', 1);

% Recording conditions
if inFlag
    % We have an input trace. Doing analysis on the test pulse
    tpamp = cellfun(@(in,idx) mean(in(idx(1)+10:idx(end)-10)), pin, tpidx, 'uni', 1);
    delta = cellfun(@(vm,rest,idx) mean(vm(idx(ceil(end/2):end-2)))-rest,pdata,num2cell(rest),tpidx,'uni',1);
    rms = 10^3*delta./tpamp; % Membrane resistance in megaohms
    Rm = mean(rms);
end

%% Output
out.data.ptime = ptime;
out.data.pdata = pdata;
out.data.rest = rest;
out.data.thresh = thvm;
out.data.maxvm = mxvm;
out.data.amp = amps;
out.data.durAP = durAP;
out.data.durAD = durAD;
out.data.aDep = aDep;
out.data.Rms = rms;
out.data.Rm = Rm;

out.an.thr = mean(thvm);
out.an.amp = mean(amps);
out.an.durAP = mean(durAP);
out.an.durAD = mean(durAD);
out.an.aDep = mean(aDep);
out.an.sAmp = std(amps);
out.an.sDur = std(durAD);
out.an.sADep = std(aDep);

exp(epoch) = out;


%% Make a summary figure
f = callFigs();

name = sprintf('%s - E%d',meta.ename,epoch);

subplot(5,2,[1 3 5 7 9]);
plot(nanCell(ptime)'-100,nanCell(pdata)');
xlim([90 150]-100);
xlabel('Time Re: AP Trig (ms)');
ylabel('mV');
title(sprintf('APs - %s',name));
set(gca,'fontsize',24);

subplot(5,2,[2 4]);
hold on;
plot(amps, 'color','k','marker','o','markerfacecolor','k','markersize',8,'linewidth',1.5);
yLim = ylim;
yExt = diff(yLim);
ylim([yLim(1)-0.3*yExt yLim(2)+0.3*yExt]);
set(gca,'fontsize',16);
legend('Amplitude','location','best');
ylabel('Potential (mV)');
title('AP Amplitude');

subplot(5,2,[6 8]);
hold on;
plot(rest, 'color','b','marker','s','markersize',8,'linewidth',1.5);
plot(aDep, 'color',[0.1 0.5 0.1], 'marker','*','markersize',8,'linewidth',1.5);
yLim = ylim;
yExt = diff(yLim);
ylim([yLim(1)-0.15*yExt yLim(2)+0.15*yExt]);
set(gca,'fontsize',16);
legend('Rest','After-Dep','location','best');
ylabel('Potential (mV)');

subplot(5,2,10);
plot(rms, 'color','r','marker','x','markersize',8,'linewidth',1.5);
yLim = ylim;
yExt = diff(yLim);
ylim([yLim(1)-0.3*yExt yLim(2)+0.3*yExt]);
xlabel('Trial');
ylabel('M\Omega');
set(gca,'fontsize',16);
title('Membrane Resistance');

pause(0.2);
response = questdlg('Save summary figure?','Save panel','Yes','No','Yes');
switch response; case 'Yes', sFig = 1; case 'No', sFig = 0; end
if sFig, print(gcf,'-painters',fullfile(meta.dpath,sprintf('%s - Summary-AP Props',name,epoch)),'-djpeg'); end
close(f);
