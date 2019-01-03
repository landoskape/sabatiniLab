
cd('/Users/LandauLand/Documents/Research/SabatiniLab/data/ATL180126b');
state = epipe.caimaging('/Users/LandauLand/Documents/Research/SabatiniLab/data/ATL180126b',180126,'b');

ad = cell(length(31:66),2);
for i = 1:length(31:66)
    ad{i,1} = load(sprintf('AD0_%d.mat',i+30));
    ad{i,1} = ad{i,1}.(sprintf('AD0_%d',i+30)).data';
    start = state(i+30).phys.cellParams.minInCell0;
    tvec = (start:1/600000:start+100000/600000-1/600000)';
    ad{i,2} = tvec;
end

data = cell2mat(ad);

%% Plotting
figure; 
set(gcf,'units','normalized','outerposition',[0 0 0.9 1]);

hold on;
for i = 1:length(31:66),
    plot(ad{i,2},ad{i,1},'color','k','linewidth',1.5);
end
xlim([20 28]);
ylim([-95 60]);
set(gca,'xticklabel',0:8);
xlabel('Minutes After MNI');
ylabel('mV');
title('Effect of MNI in Bath (+5units/mL GPT & 2mM Pyruvate');
set(gca,'fontsize',24);




