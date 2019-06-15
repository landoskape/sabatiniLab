



% -- to do
% get rise time of first phase of unnormalized currents


%% -- top stuff --
hpath = '/Users/landauland/Documents/Research/SabatiniLab/data/conductionVelocity';
% load(fullfile(hpath,'results.mat'));



%% -- get data to analyze --

exclude_raisingBaseline = 39;
exclude_losingCell = 88:91;
exclude_noneOrBad_APSignal = [45 48 49 60 66 92:97 105 111:114 131];
exclude_DoubleAPs = 50:57; % Couldn't generate single APs with current injection
exclude_notTrunkL5 = [76 77];

idxInclude = true(numel(res),1);
idxInclude(exclude_raisingBaseline) = false;
idxInclude(exclude_losingCell) = false;
idxInclude(exclude_noneOrBad_APSignal) = false;
idxInclude(exclude_DoubleAPs) = false;
idxInclude(exclude_notTrunkL5) = false;

idxL5 = [res(:).cellNum]>=11;
idxL23 = [res(:).layer]==23;

r2analyze = ([res(:).expID]==1 & (idxL5 | idxL23) & [res(:).temp]==37 & idxInclude'); % don't do 5/150
anres = res(r2analyze);bf



%% -- do analysis --
% Get some meta data
NR = numel(anres); % just to make sure it's here
rDist = [anres(:).distance];
layer = [anres(:).layer];
expID = [anres(:).expID];

layer5idx = layer == 5;

% Filtering/Derivative/Summary - Parameters
h = 6;
dsfactor = 16;
boxcarKernel = 5;
apSmoothing = 12;

% Timing 
dt = 512/4000;
tv = dt:dt:512;
psdt = dt/16;
pstv = psdt:psdt:512;
physdt = 0.01;
phystv = physdt:physdt:1000; % (known)

% ------ Adjust for AP Jitter ------ 
apMaxWin = [find(pstv>=100,1) find(pstv>=105,1)];
allPhys = {anres(:).phys};
smoothPhys = cellfun(@(c) smoothsmooth(c,apSmoothing), allPhys, 'uni', 0);
usphys = cellfun(@(c) interp1(phystv',c,pstv), smoothPhys, 'uni', 0);

% Get index of max AP voltage
apPt = cell(1,NR);
apTime = cell(1,NR);
for r = 1:NR
    [~,apPt{r}] = max(usphys{r}(apMaxWin(1):apMaxWin(2),:),[],1);
    apPt{r} = apPt{r} + apMaxWin(1) - 1;
    apTime{r} = pstv(apPt{r});
end

zpt = find(pstv>=100,1); % we're going to shift it so the peak of the AP is at 100ms
japhys = cell(1,NR);
jadata = cell(1,NR);
allData = cellfun(@double, {anres(:).gtif}, 'uni', 0); % Full dataset
for r = 1:NR
    cphys = usphys{r};
    cdata = allData{r};
    NA = size(cdata,2);
    cjaphys = zeros(size(cphys));
    cjadata = zeros(size(cdata));
    for a = 1:NA
        cp = nanshift(cphys(:,a),zpt - apPt{r}(a));
        cc = nanshift(cdata(:,a),zpt - apPt{r}(a));
        idxnan = find(isnan(cc));
        cp(idxnan) = mean(cp(idxnan(1)-101:idxnan(1)-1));
        cc(idxnan) = mean(cc(idxnan(1)-101:idxnan(1)-1));
        cjaphys(:,a) = cp;
        cjadata(:,a) = cc;
    end
    japhys{r} = cjaphys; % current jitter adjusted phys
    jadata{r} = cjadata; % current jitter adjusted data
end

% ------- down-sample / base-subtract / normalize / filter ------------
ds = cellfun(@(c) dsarray(c, dsfactor), jadata, 'uni', 0);

stBase = find(tv>=78,1);
enBase = find(tv>=98,1);
dsbase = cellfun(@(c) c - repmat(mean(c(stBase:enBase,:),1),size(c,1),1), ds, 'uni', 0);

pkwin = [find(tv>=98,1) find(tv>=115,1)];
pkidx = zeros(1,NR);
pks = cell(1,NR);
for r = 1:NR
    cmean = mean(dsbase{r},2);
    [~,pkidx(r)] = max(cmean(pkwin(1):pkwin(2)));
    pkidx(r) = pkidx(r) + pkwin(1) - 1;
    pks{r} = mean(cmean(pkidx(r):pkidx(r) + round(10/dt)),1);
end
dsnorm = cellfun(@(d,p) d./repmat(p,size(d,1),size(d,2)),dsbase, pks, 'uni', 0);


fdata = cellfun(@(c) smoothsmooth(c, boxcarKernel), dsnorm, 'uni', 0);

% ------- derivative, mean ----------
mdata = cell2mat(cellfun(@(c) mean(c,2), fdata, 'uni', 0));
mphys = cell2mat(cellfun(@(c) mean(c,2), japhys, 'uni', 0));

fptv = tv(1+2*h:end-2*h);
fpca = fivePointDer(mdata,h);


% -- look at first and second phase of current --
phWindow = [99.5 102.5 105.5];
ph1 = [find(fptv>=phWindow(1),1) find(fptv>=phWindow(2),1)]; % these are based on looking at average
ph2 = [find(fptv>=phWindow(2),1) find(fptv>=phWindow(3),1)];

Q1 = sum(fpca(ph1(1):ph1(2),:),1)*dt; % Charge - phase 1
Q2 = sum(fpca(ph2(1):ph2(2),:),1)*dt; % Charge - phase 2

total = Q1+Q2; % norm so sums to 1
Q1 = Q1./total;
Q2 = Q2./total;





%% -- plot --

f = figure(157); clf;
setfpos([0.1 0.3 0.6 0.4],f);

[~,didx] = sort(rDist);

xLim = [95 115];
yLim = [-2 5];

% Fluorescence
subplot(1,3,1); hold on;
plot(tv,mean(mdata(:,~layer5idx),2),'color','k','linewidth',2);
plot(tv,mean(mdata(:,layer5idx),2),'color','r','linewidth',2);

plot(tv,mdata(:,~layer5idx),'color',[0.5 0.5 0.5],'linewidth',0.2);
plot(tv,mean(mdata(:,~layer5idx),2),'color','k','linewidth',2);
plot(tv,mdata(:,layer5idx),'color',[1 0.5 0.5],'linewidth',0.2);
plot(tv,mean(mdata(:,layer5idx),2),'color','r','linewidth',2);

xlim(xLim);
ylim([-0.5 1.75]);
xlabel('Time (ms)');
ylabel('Normalized Fluo-5f');
title('Normalized Calcium Signal');
legend('L23','L5','location','northwest');
set(gca,'fontsize',16);

% dF/dt
subplot(1,3,2); hold on;
patch(fptv([ph1(1) ph1(1) ph1(2) ph1(2)]),[yLim fliplr(yLim)],'b','FaceAlpha',0.05,'EdgeColor','none');
patch(fptv([ph2(1) ph2(1) ph2(2) ph2(2)]),[yLim fliplr(yLim)],'g','FaceAlpha',0.05,'EdgeColor','none');
plot(fptv,fpca(:,~layer5idx),'color',[0.5 0.5 0.5],'linewidth',0.2);
plot(fptv,mean(fpca(:,~layer5idx),2),'color','k','linewidth',2);
plot(fptv,fpca(:,layer5idx),'color',[1 0.5 0.5],'linewidth',0.2);
plot(fptv,mean(fpca(:,layer5idx),2),'color','r','linewidth',2);
% plotvc(tv(1+2*h:end-2*h),fpca(:,didx),f,{'''linewidth''','1.1'});
xlim(xLim);
ylim(yLim);
xlabel('Time(ms)');
ylabel('dF/dt');
title('dF/dt (5-Pt Stencil)');
legend('Phase 1','Phase 2','location','northeast');
set(gca,'fontsize',16);

% Charge Transfer
subplot(1,3,3); hold on;
patch([0.5 0.5 1.5 1.5],[-0.5 1.5 1.5 -0.5],'b','FaceAlpha',0.05,'EdgeColor','none');
patch(1+[0.5 0.5 1.5 1.5],[-0.5 1.5 1.5 -0.5],'g','FaceAlpha',0.05,'EdgeColor','none');

plot(0.8,Q1(~layer5idx),'color',[0.5 0.5 0.5],'linestyle','none','marker','o');
line([0.7 0.9],mean(Q1(~layer5idx))*[1 1],'color','k','linewidth',2);
plot(1.2,Q1(layer5idx),'color',[1 0.5 0.5],'linestyle','none','marker','o');
line([1.1 1.3],mean(Q1(layer5idx))*[1 1],'color','r','linewidth',2);

plot(1.8,Q2(~layer5idx),'color',[0.5 0.5 0.5],'linestyle','none','marker','o');
line([1.7 1.9],mean(Q2(~layer5idx))*[1 1],'color','k','linewidth',2);
plot(2.2,Q2(layer5idx),'color',[1 0.5 0.5],'linestyle','none','marker','o');
line([2.1 2.3],mean(Q2(layer5idx))*[1 1],'color','r','linewidth',2);

xlim([0.5 2.5]);
set(gca,'xtick',1:2);
set(gca,'xticklabel',{'Phase 1','Phase 2'});
ylabel('Integrated Current (normalized)');
line(xlim, [0 0],'color','k','linewidth',1.5);
set(gca,'fontsize',16);









































































