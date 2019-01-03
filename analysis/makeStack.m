
zz = cell(1,3);
for c = 1:3
    zz{c} = z(:,:,c:3:end);
end

intFactor = 5;

r = zz{2};
dim = size(r,1);
rint1 = zeros(dim, (dim-1)*intFactor+1, size(r,3));
rint2 = zeros((dim-1)*intFactor+1, (dim-1)*intFactor+1, size(r,3));
for row = 1:dim
    rint1(row,:,:) = permute(...
        interp1(1:dim, squeeze(double(r(row,:,:))), 1:(1/intFactor):dim),[3 1 2]); 
end
for frame = 1:size(rint1,3)
    rint2(:,:,frame) = interp1(1:dim, rint1(:,:,frame), 1:(1/intFactor):dim);
end

rFilt = zeros(size(rint2));
for frame = 1:size(rint2,3)
    rFilt(:,:,frame) = medfilt2(rint2(:,:,frame));
end

rFilt3 = medfilt3(rint2);

%%

genFig(1,'square');
imagesc(max(rFilt3, [],3 )); colormap('hot');

genFig(2,'square');
imagesc(max(rFilt, [], 3)); colormap('hot');

genFig(3,'square');
imagesc(max(rint2, [], 3)); colormap('hot');

genFig(4,'square');
imagesc(max(r, [], 3)); colormap('hot');

%%
genFig(1,'square');
imagesc(max(acq33, [], 3)); colormap('hot');

genFig(2,'square');
imagesc(max(acq34, [], 3)); colormap('hot');

genFig(3,'square');
imagesc(max(acq35, [], 3)); colormap('hot');

genFig(4,'square');
imagesc(max(acq36, [], 3)); colormap('hot');
