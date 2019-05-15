function tif = organizeImageData(raw,numChannel)

if nargin<2
    numChannel = 3;
end

NL = size(raw,1);
NP = size(raw,2);
NF = size(raw,3)/numChannel;
if NF~=round(NF), error('channel count is wrong'); end

tif = zeros(NL*NF,NP,numChannel);
for c = 1:numChannel
    cData = raw(:,:,c:numChannel:end);
    tif(:,:,c) = transpose(reshape(permute(cData,[2 1 3]),[NP,NL*NF,1]));
end


