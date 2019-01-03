function ps = retrieveps(pth,anum,channel,dsfactor)
% pth: path to pointscan
% anum: acquisition number
% channel: (channel:3:end) idx on 3rd dimension (green default)
% dsfactor: how much to downsample out of the box
%           if not multiple of numel(ps), truncates the end
% if pth empty assumes current directory

if (nargin < 2) || isempty(anum)
    fprintf(1, 'requires acquisition number\n');
    return
end
if isempty(pth)
    pth = pwd;
end
if (nargin < 3) || isempty(channel)
    channel = 1; % default is green
end
if (nargin < 4) || ~isnumeric(dsfactor) || isempty(dsfactor)
    dsfactor = 1;
end

d = dir(fullfile(pth,sprintf('*%s.tif',zpadNum(anum,3))));
if numel(d)>1
    fprintf(1, 'more than one tif found with same last number.\n');
    return
end

tif = tifread(fullfile(d.folder,d.name));
data = double(tif(:,:,channel:3:end));
N = numel(data);
ps = reshape(permute(data,[2 1 3]),N,1);
numSamplesToTruncate = rem(N,dsfactor); 
if numSamplesToTruncate
    ps = ps(1:end-numSamplesToTruncate);
    N = N-numSamplesToTruncate;
end
ps = mean(reshape(ps,dsfactor,N/dsfactor),1)';




