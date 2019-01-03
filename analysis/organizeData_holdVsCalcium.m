
expName = 'ATL180424a';
pth = '/Users/LandauLand/Documents/Research/SabatiniLab/data/holdVsCalcium/ATL180424a';
rpth = fullfile(pth,'results');
if ~exist(rpth,'file')
    mkdir(rpth);
end
mpth = fullfile('/Users/LandauLand/Documents/Research/SabatiniLab/data/holdVsCalcium','results');
if ~exist(mpth,'file')
    mkdir(mpth);
end

% Spine 1 (Epochs 6 through 18)
epoch = [7 8 9 10 11 12; -80 -70 -60 -65 -75 -55];% Epoch number; holding potential
result = cell(length(epoch),1);
for e = 1:length(epoch)
    idx = ([data(:).epoch] == epoch(1,e)) & ([data(:).ph] == 1);
    pt = 1000*nanCell({data(idx).pt}); %ms
    it = 1000*nanCell({data(idx).it}); %ms
    pin = {data(idx).pin};
    
    pbaseRange = find(pt(1,:)>=50 & pt(1,:)<100); 
    ibaseRange = find(it(1,:)>=50 & it(1,:)<100); 
    pdata = nanCell({data(idx).pdata});
    pnorm = pdata - repmat(mean(pdata(:,pbaseRange),2),1,size(pdata,2));
    
    idata = nanCell({data(idx).idata},[],4); 
    inorm = idata - repmat(mean(idata(:,ibaseRange,:,:),2),1,size(idata,2)); 
    ifilt = permute(medfilt1(permute(inorm,[2 1 3 4]),10),[2 1 3 4]);
    
    % Analyze
    ppeakRange = find(pt(1,:)>=100 & pt(1,:)<120);
    ipeakRange = find(it(1,:)>=100 & it(1,:)<150);
    ppeak = min(pnorm(:,ppeakRange),[],2);
    ipeak = squeeze(max(ifilt(:,ipeakRange,:,:),[],2));
    pavg = mean(ppeak);
    iavg = mean(ipeak,3);
    result{e} = [ppeak, squeeze(ipeak(1,2,:)), squeeze(ipeak(1,1,:))];
    
    % Plot Data and Results
    fig = callFigs();
    
    subplot(2,2,[1 3]);
    hold on;
    plot(pt' - 100,pnorm','linewidth',0.5); 
    plot(pt(1,:) - 100,mean(pnorm,1),'color','k','linewidth',1.5);
    xlim([80 180] -100);
    xlabel('Time Re: Uncaging (ms)');
    ylabel('\DeltamV');
    title(sprintf('uEPSC... Holding Potential %dmV',epoch(2,e)));
    set(gca,'fontsize',16);
    
    subplot(2,2,2);
    hold on;
    plot(it' - 100,squeeze(ifilt(1,:,2,:)),'linewidth',0.5);
    plot(it(1,:) - 100,squeeze(mean(ifilt(1,:,2,:),4)),'color','k','linewidth',1.5);
    xlim([50 it(1,end)] -100);
    ylim([-0.1 0.6]);
    ylabel('\DeltaG/R');
    title('Spine Calcium');
    set(gca,'fontsize',16);
    
    subplot(2,2,4);
    hold on;
    plot(it' - 100,squeeze(ifilt(1,:,1,:)),'linewidth',0.5);
    plot(it(1,:) - 100,squeeze(mean(ifilt(1,:,1,:),4)),'color','k','linewidth',1.5);
	xlim([50 it(1,end)] -100);
    ylim([-0.1 0.6]);
    ylabel('\DeltaG/R');
    xlabel('Time Re: Uncaging (ms)');
    title('Dendrite Calcium');
    set(gca,'fontsize',16);
    
%     print(gcf,'-painters',fullfile(rpth,sprintf('data_Hold_%dmV',epoch(2,e))),'-djpeg');
end
close all;

%% Summary Figure
msize = 10;
asize = 10;

x = 1:length(epoch);
% [~,xord] = sort(epoch(2,:));
fig = callFigs('phys');
subplot(3,1,1); hold on;
subplot(3,1,2); hold on;
subplot(3,1,3); hold on;
for e = 1:length(epoch)
    ce = xord(e);
    for sf = 1:3
        subplot(3,1,sf);
        plot(e,result{ce}(:,sf),'linestyle','none','marker','o','markersize',msize);
        plot(e,mean(result{ce}(:,sf)),...
            'linestyle','none','marker','o','color','k','markersize',asize,'markerfacecolor','k');
    end    
end
yLabel = {'\DeltamV','\DeltaG/R','\DeltaG/R'};
titles = {sprintf('uEPSC-%s',expName),'Spine Ca','Dendrite Ca'};
for sf = 1:3
    subplot(3,1,sf);
    plot(1:length(epoch),cellfun(@(r) mean(r(:,sf)), result(xord), 'uni', 1),'color','k');
    xlim([0.5 6.5]);
    set(gca,'xticklabel',num2cell(-80:5:-55));
    set(gca,'fontsize',16);
    ylabel(yLabel{sf});
    title(titles{sf})
end

% print(gcf,'-painters',fullfile(mpth,sprintf('Summary-%s',expName)),'-djpeg');
% print(gcf,'-painters',fullfile(rpth,sprintf('Summary-%s',expName)),'-djpeg');

