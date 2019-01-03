function makeUncaging(epoch)

global meta
global state
global data
global exp

% exp(epoch) = output; % output will be the structure I make here
out = setupExpFields(); 
out.type = 'uncaging'; 
out.ename = meta.ename; 

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

% Load Tifs 
tifs = cell(length(edata),1);
for t = 1:length(edata)
    tifs{t} = tifread(edata(t).tif);
end

pldata = nanCell(pdata)';
pltime = nanCell(ptime)';
ildata = nanCell(idata, [], 4);
iltime = nanCell(itime)';

%Physiology
ppRange = [find(pltime(:,1) > 80, 1, 'first'), find(pltime(:,1) >= 200, 1, 'first')]; % plotting range
bpRange = [find(pltime(:,1) > 50, 1, 'first'), find(pltime(:,1) < 100, 1, 'last')]; % Baseline range
%Imaging
% piRange = [find(iltime(:,1) > 80, 1, 'first'), find(iltime(:,1) >= 400, 1, 'first')]; % plotting range
biRange = [find(iltime(:,1) > 50, 1, 'first'), find(iltime(:,1) < 100, 1, 'last')]; % Baseline range

basephys = mean(pldata(bpRange(1):bpRange(2), :),1);
baseimag = mean(squeeze(ildata(1,biRange(1):biRange(2),2,:)),1);

callFigs('phys');
subplot(2,2,1);
plot(pltime(ppRange(1):ppRange(2),:), pldata(ppRange(1):ppRange(2),:)); 
subplot(2,2,3); 
plot(pltime(ppRange(1):ppRange(2),:), pldata(ppRange(1):ppRange(2),:) - repmat(basephys, diff(ppRange)+1, 1)); 

subplot(2,2,2);
plot(iltime, squeeze(ildata(1,:,2,:)));

subplot(2,2,4);
plot(iltime, squeeze(ildata(1,:,2,:))-repmat(baseimag, size(ildata,2),1));

% callFigs('imag');




%%
% figure(1);
% clf;
% set(gcf,'units','normalized','outerposition',[0 0 1 0.9]);
% 
% blastSet = {'off','on'};
% for k = 1:nKind
%     % Make Header
%     if isnan(lookup(k,3)), apName = 'off'; else, apName = [num2str(lookup(k,3)),'ms']; end
%     head = {sprintf('AP: %s',apName);sprintf('Blaster: %s',blastSet{lookup(k,2)})};
%     
%     subplot(2,nKind,k);
%     hold on;
%     plot(ctime{k,1},cdata{k,1},'color',[0.7 0.7 0.7],'linewidth',0.5,'linestyle','--');
%     plot(ctime{k,1},adata{k,1},'color','k','linewidth',1.5,'linestyle','-');
%     xlim([90 150]);
%     xlabel('Time (ms)');
%     ylabel('V_m');
%     title(head);
%     set(gca,'fontsize',12);
%     
%     subplot(2,nKind,k+1*nKind);
%     hold on;
%     plot(ctime{k,2},cdata{k,3},'color',[0.8 0.2 0.2],'linewidth',0.5,'linestyle','--');
%     plot(ctime{k,2},adata{k,3},'color','r','linewidth',1.5,'linestyle','-');
%     plot(ctime{k,2},cdata{k,2},'color',[0.7 0.7 0.7],'linewidth',0.5,'linestyle','--');
%     plot(ctime{k,2},adata{k,2},'color','k','linewidth',1.5,'linestyle','-');
%     xlim([90 500]);
%     xlabel('Time (ms)');
%     ylabel('G/R');
%     set(gca,'fontsize',12);
% %     xlim([90 250]);
%     
% %     subplot(5,nKind,k+2*nKind);
% %     hold on;
% %     plot(ctime{k,2},cdata{k,2},'color',[0.7 0.7 0.7],'linewidth',0.5,'linestyle','--');
% %     plot(ctime{k,2},adata{k,2},'color','k','linewidth',1.5,'linestyle','-');
% %     xlim([90 250]);
% %     
% %     subplot(5,nKind,k+3*nKind);
% %     hold on;
% %     plot(ctime{k,2},cdata{k,5},'color',[0.8 0.2 0.2],'linewidth',0.5,'linestyle','--');
% %     plot(ctime{k,2},adata{k,5},'color','r','linewidth',1.5,'linestyle','-');
% %     xlim([90 250]);
% %     
% %     subplot(5,nKind,k+4*nKind);
% %     hold on;
% %     plot(ctime{k,2},cdata{k,4},'color',[0.7 0.7 0.7],'linewidth',0.5,'linestyle','--');
% %     plot(ctime{k,2},adata{k,4},'color','k','linewidth',1.5,'linestyle','-');
% %     xlim([90 250]);
% end
%     
% yLim = zeros(nKind,2,2);
% for k = 1:nKind
%     subplot(2,nKind,k);
%     yLim(k,1,1) = max(ylim);
%     yLim(k,1,2) = min(ylim);
%     subplot(2,nKind,k+1*nKind);
%     yLim(k,2,1) = max(ylim);
%     yLim(k,2,2) = min(ylim);
% %     subplot(5,nKind,k+2*nKind);
% %     yLim(k,3,1) = max(ylim);
% %     yLim(k,3,2) = min(ylim);
% %     subplot(5,nKind,k+3*nKind);
% %     yLim(k,4,1) = max(ylim);
% %     yLim(k,4,2) = min(ylim);
% %     subplot(5,nKind,k+4*nKind);
% %     yLim(k,5,1) = max(ylim);
% %     yLim(k,5,2) = min(ylim);
% end
% for k = 1:nKind
%     subplot(2,nKind,k);
%     ylim([min(min(yLim(:,1,2))) max(max(yLim(:,1,1)))]);
%     subplot(2,nKind,k+nKind);
%     ylim([0 max(max(yLim(:,2,1)))]);
% %     subplot(5,nKind,k+2*nKind);
% %     ylim([0 max(max(yLim(:,3,1)))]);
% %     subplot(5,nKind,k+3*nKind);
% %     ylim([0 max(max(yLim(:,4,1)))]);
% %     subplot(5,nKind,k+4*nKind);
% %     ylim([0 max(max(yLim(:,5,1)))]);
% end
% subplot(2,7,7); ylim([yLim(7,1,2),yLim(7,1,1)]);

callFigs('phys');
tightfig;
set(gcf,'units','normalized','outerposition',[0 0 1 0.9]);
        
