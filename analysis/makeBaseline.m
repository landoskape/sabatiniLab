function makeBaseline(epoch)

global meta state data exp

% exp(epoch) = output; % output will be the structure I make here
out = setupExpFields();
out.epoch = epoch;
out.type = 'baseline';
out.ename = meta.ename;

% Retrieve data specific to this epoch
edata = getEpoch(data, epoch);
estate = getEpoch(state, epoch);

% Get indices for physiology
phidx = find([edata(:).ph] == 1); % Just to collect the phys traces
NA = length(phidx);
cMap = varycolor(NA);
pmode = [edata(phidx).pmode];
if equal(pmode), pmode = pmode(1); end
out.meta.pmode = pmode;

% Load data and time
ptime = {edata(phidx).pt};
pdata = {edata(phidx).pdata};

% Setup start times, adjust time vector
stime = zeros(1,NA);
for p = 1:NA, stime(p) = estate(phidx(p)).phys.cellParams.minInCell0; end
stime = 60*stime; % convert to seconds

ntime = cellfun(@(t,off) t + off, ptime, num2cell(stime), 'uni', 0);

% Load input to cell
pin = {edata(phidx).pin};
inFlag = 1;
if any(cellfun(@isempty, pin, 'uni', 1)) 
    % Index of window to ignore because test pulse probably there
    tpidx = cellfun(@(t) length(t)*80/100+1:length(t), ptime, 'uni', 0);
    inFlag = 0;
else
    tpidx = cellfun(@findTestPulse, pin, 'uni', 0); % test pulse indices
end
plotIdx = cellfun(@(t,idx) cat(2, true(1,idx(1)-1),false(1,length(idx)+300),true(1,length(t)-(idx(end)+300))), ptime, tpidx, 'uni', 0);

% Analysis
rest = cellfun(@(d,u) mean(d(1:u(1)-1)), pdata, tpidx, 'uni', 1);
mDist = []; % ---- mini analysis???

% Recording conditions
if inFlag
    % We have an input trace. Doing analysis on the test pulse
    tpamp = cellfun(@(in,idx) mean(in(idx(1)+10:idx(end)-10)), pin, tpidx, 'uni', 1);
    delta = cellfun(@(vm,rest,idx) mean(vm(idx(ceil(end/2):end-2)))-rest,pdata,num2cell(rest),tpidx,'uni',1);
    rms = 10^3*delta./tpamp; % Membrane resistance in megaohms
    Rm = mean(rms);
end


%% output
out.data.ptime = ptime;
out.data.pdata = pdata;
out.data.stime = stime;
out.data.Rms = rms;
out.data.Rm = Rm;
out.an.rest = rest;
out.an.mDist = mDist;

exp(epoch) = out;


% Make a summary figure
name = sprintf('%s - E%d',meta.ename,epoch);

figure(1);
clf;
set(gcf,'units','normalized','outerposition',[0 0 1 0.9]);

subplot(2,2,1);
hold on;
for p = 1:NA
    plot(ptime{phidx(p)},pdata{phidx(p)},'color',cMap(p,:),'linewidth',1.5);
end
xlabel('Time (s)');
ylabel('Potential (mV)');
title(sprintf('%s - Recordings',name));
set(gca,'fontsize',16);

subplot(2,2,3);
plot(rms,'color','k','marker','s','markerfacecolor','k','linewidth',1.5);
ylabel('M\Omega');
title('Recording Conditions');
set(gca,'fontsize',16);

subplot(2,2,2);
plot(stime, rest, 'linewidth', 1, 'color','k','marker','o','markerfacecolor','k','markersize',10);
xlim([stime(1)-mean(diff(stime))/2, stime(end)+mean(diff(stime))/2]);
xlabel('Time in Cell (s)');
ylabel('Potential (mV)');
title('Rest Potential');
set(gca,'fontsize',16);

subplot(2,2,4);
text(0.5, 0.5, 'EPSP/EPSC Analysis Here','units','normalized','horizontalalignment','center','fontsize',20); 
set(gca,'color','none'); 
set(gca,'xtick',[]); 
set(gca,'ytick',[]); 
set(gca,'xcolor','none'); 
set(gca,'ycolor','none'); 

pause(0.2);
response = questdlg('Save summary figure?','Save panel','Yes','No','Yes');
switch response; case 'Yes', sFig = 1; case 'No', sFig = 0; otherwise, sFig = 0; end
if sFig, print(gcf,'-painters',fullfile(meta.dpath,sprintf('%s-Summary-Baseline',name)),'-djpeg'); end
close(1);
