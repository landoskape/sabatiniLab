function makeEpspApInteractions(epoch)

global meta
global state
global data
global exp

% exp(epoch) = output; % output will be the structure I make here
out = setupExpFields();
out.type = 'epspApInteraction'; 


% Retrieve data specific to this epoch
edata = getEpoch(data, epoch);
estate = getEpoch(state, epoch);

% Get indices for physiology (should be same as imaging)
phidx = find([edata(:).ph] == 1); 
NA = length(phidx); 

% Load data and time
ptime = cellfun(@(t) t*1000, {edata(phidx).pt}, 'uni', 0);
itime = cellfun(@(t) t*1000, {edata(phidx).it}, 'uni', 0);
pdata = {edata(phidx).pdata};
idata = {edata(phidx).idata};

pulse = [edata(phidx).pulse];
blast = [edata(phidx).blast];

lookup = [11 1 96;
           9 1 100;
          14 1 104; 
          16 1 108; 
          18 1 112; 
          20 1 116; 
          10 1 NaN]; % different combinations (add 9/0)

nKind = size(lookup, 1); 
cMap = varycolor(nKind); 

%% Order data
cdata = cell(nKind, 5); % phys, 2 channels 2 ROIs
ctime = cell(nKind, 2); % phys, imaging
for p = 1:NA
    idx = find(pulse(p) == lookup(:,1) & blast(p) == lookup(:,2));
    if isempty(idx), continue, end
    cdata{idx,1} = cat(1, cdata{idx,1}, pdata{p});
    cdata{idx,2} = cat(1, cdata{idx,2}, idata{p}(1,:,1));
    cdata{idx,3} = cat(1, cdata{idx,3}, idata{p}(1,:,2));
    cdata{idx,4} = cat(1, cdata{idx,4}, idata{p}(2,:,1));
    cdata{idx,5} = cat(1, cdata{idx,5}, idata{p}(2,:,2));
    ctime{idx,1} = cat(1, ctime{idx,1}, ptime{p});
    ctime{idx,2} = cat(1, ctime{idx,2}, itime{p});
end
ctime = cellfun(@(t) mean(t,1), ctime, 'uni', 0);
adata = cellfun(@(d) mean(d,1), cdata, 'uni', 0);

%%
figure(1);
clf;
set(gcf,'units','normalized','outerposition',[0 0 1 0.9]);

blastSet = {'off','on'};
for k = 1:nKind
    % Make Header
    if isnan(lookup(k,3)), apName = 'off'; else, apName = [num2str(lookup(k,3)),'ms']; end
    head = {sprintf('AP: %s',apName);sprintf('Blaster: %s',blastSet{lookup(k,2)})};
    
    subplot(2,nKind,k);
    hold on;
    plot(ctime{k,1},cdata{k,1},'color',[0.7 0.7 0.7],'linewidth',0.5,'linestyle','--');
    plot(ctime{k,1},adata{k,1},'color','k','linewidth',1.5,'linestyle','-');
    xlim([90 150]);
    xlabel('Time (ms)');
    ylabel('V_m');
    title(head);
    set(gca,'fontsize',12);
    
    subplot(2,nKind,k+1*nKind);
    hold on;
    plot(ctime{k,2},cdata{k,3},'color',[0.8 0.2 0.2],'linewidth',0.5,'linestyle','--');
    plot(ctime{k,2},adata{k,3},'color','r','linewidth',1.5,'linestyle','-');
    plot(ctime{k,2},cdata{k,2},'color',[0.7 0.7 0.7],'linewidth',0.5,'linestyle','--');
    plot(ctime{k,2},adata{k,2},'color','k','linewidth',1.5,'linestyle','-');
    xlim([90 500]);
    xlabel('Time (ms)');
    ylabel('G/R');
    set(gca,'fontsize',12);
%     xlim([90 250]);
    
%     subplot(5,nKind,k+2*nKind);
%     hold on;
%     plot(ctime{k,2},cdata{k,2},'color',[0.7 0.7 0.7],'linewidth',0.5,'linestyle','--');
%     plot(ctime{k,2},adata{k,2},'color','k','linewidth',1.5,'linestyle','-');
%     xlim([90 250]);
%     
%     subplot(5,nKind,k+3*nKind);
%     hold on;
%     plot(ctime{k,2},cdata{k,5},'color',[0.8 0.2 0.2],'linewidth',0.5,'linestyle','--');
%     plot(ctime{k,2},adata{k,5},'color','r','linewidth',1.5,'linestyle','-');
%     xlim([90 250]);
%     
%     subplot(5,nKind,k+4*nKind);
%     hold on;
%     plot(ctime{k,2},cdata{k,4},'color',[0.7 0.7 0.7],'linewidth',0.5,'linestyle','--');
%     plot(ctime{k,2},adata{k,4},'color','k','linewidth',1.5,'linestyle','-');
%     xlim([90 250]);
end
    
yLim = zeros(nKind,2,2);
for k = 1:nKind
    subplot(2,nKind,k);
    yLim(k,1,1) = max(ylim);
    yLim(k,1,2) = min(ylim);
    subplot(2,nKind,k+1*nKind);
    yLim(k,2,1) = max(ylim);
    yLim(k,2,2) = min(ylim);
%     subplot(5,nKind,k+2*nKind);
%     yLim(k,3,1) = max(ylim);
%     yLim(k,3,2) = min(ylim);
%     subplot(5,nKind,k+3*nKind);
%     yLim(k,4,1) = max(ylim);
%     yLim(k,4,2) = min(ylim);
%     subplot(5,nKind,k+4*nKind);
%     yLim(k,5,1) = max(ylim);
%     yLim(k,5,2) = min(ylim);
end
for k = 1:nKind
    subplot(2,nKind,k);
    ylim([min(min(yLim(:,1,2))) max(max(yLim(:,1,1)))]);
    subplot(2,nKind,k+nKind);
    ylim([0 max(max(yLim(:,2,1)))]);
%     subplot(5,nKind,k+2*nKind);
%     ylim([0 max(max(yLim(:,3,1)))]);
%     subplot(5,nKind,k+3*nKind);
%     ylim([0 max(max(yLim(:,4,1)))]);
%     subplot(5,nKind,k+4*nKind);
%     ylim([0 max(max(yLim(:,5,1)))]);
end
subplot(2,7,7); ylim([yLim(7,1,2),yLim(7,1,1)]);

figure(1);
tightfig;
set(gcf,'units','normalized','outerposition',[0 0 1 0.9]);
        
