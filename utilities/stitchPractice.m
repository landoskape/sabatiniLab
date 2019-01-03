
%% Get data
pth = '/Users/LandauLand/Documents/Research/SabatiniLab/data/EPSP_AP/ATL180405a';
cd(pth);

MZP342 = load('MZP342');
MZP343 = load('MZP343');
m342 = MZP342.figData.mzp;
m343 = MZP343.figData.mzp;
% m342 = MZP342.figData.mzp(1:2^MZP342.figData.intFactor:end,:);
% m343 = MZP343.figData.mzp(1:2^MZP343.figData.intFactor:end,:);
% m342 = m342(:,1:2^MZP342.figData.intFactor:end);
% m343 = m343(:,1:2^MZP343.figData.intFactor:end);
clear MZP342 MZP343
mzp = cat(3, m342, m343);