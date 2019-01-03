function stimage = stitch(im1,im2,method,noise)

% Deal with inputs
if (nargin < 3)
    method = [];
    noise = [];
elseif (nargin < 4)
    noise = []; 
end

% Setup defaults
if isempty(method), method = 'mzp'; end % Maximum Z-Projection over stitch
if isempty(noise), noise = 0; end %default to no-noise adjustment

% Compute shift
shift = POCShift(im1,im2,noise);

if all(~shift)
    % Simple case of no shift
    stimage = cat(3, im1, im2);
else
    % Compute size of output and preallocate
    sz1 = size(im1);
    sz2 = size(im2);
    szOut = sz1 + sz2 - min([sz1;sz2],[],1) + abs(shift);
    stimage = zeros(szOut(1),szOut(2),2);
    
    % Setup indices for each input image
    y1 = (1:sz1(1)) + abs((shift(1)>0)*shift(1));
    x1 = (1:sz1(2)) + abs((shift(2)>0)*shift(2));
    
    y2 = (1:sz2(1)) + abs((shift(1)<0)*shift(1));
    x2 = (1:sz2(2)) + abs((shift(2)<0)*shift(2));
    
    % Translate
    stimage(y1,x1,1) = im1;
    stimage(y2,x2,2) = im2; 
end

% Merge images
switch method
    case 'mzp'
        stimage = max(stimage, [], 3);
    case 'avg'
        stimage = mean(stimage, 3);
end










