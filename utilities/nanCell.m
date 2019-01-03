function A = nanCell(C,L,dCat,dPad)
% nanCell Convert the contents of a cell array with unequal dimensions into
% a single matrix. 
%     A = nanCell(C,L) converts a one-dimensional cell array with numeric
%     elements into a single matrix. The contents of C must have the same
%     size except in one dimension. In the unequal dimension, nanCell will
%     nanpad the array to the size of the longest element or to 'L' if that
%     input is defined. 
% 
%     dCat - dimension to concatenate over (1st equal dimension is default)
%     dPad - dimension to pad over (unequal dimension is default)

C = C(:);

dims = cellfun(@ndims, C, 'uni', 1);
if ~all(dims == dims(1))
    error('Elements of C must have same number of dimensions');
end

siz = cell2mat(cellfun(@size, C(:), 'uni', 0)); % sizes of each element
dEqual = all(bsxfun(@eq, siz, siz(1,:)),1); % dimensions that are equal across elements
if sum(~dEqual) > 1
    error('More than one dimension has unequal size.');
end

% Deal with inputs
switch nargin
    case 1 
        L = [];
        dCat = [];
        dPad = [];
    case 2
        dCat = [];
        dPad = [];
    case 3
        dPad = [];
end

if isempty(dCat)
    dCat = find(dEqual, 1, 'first'); 
end % Cat along first equal dimension
if isempty(dPad)
    if all(dEqual)
        dPad = 2; 
        dEqual(dPad) = false;
    else
        dPad = find(~dEqual);
    end
end
if isempty(L)
    L = max(cellfun(@(c) size(c,dPad), C, 'uni', 1)); % Length for padding
end % Length for padding

if (dPad ~= find(~dEqual))
        error('Unequal dimension different from user-specified nanpad dimension');
end


% ---- Function ----
sizePad = siz(1,:); 
sizePad(dPad) = L;
sizeEach = cellfun(@(c) sizePad - size(c) + sizePad.*dEqual, C, 'uni', 0);
nanc = cellfun(@(c,s) cat(dPad, c, nan(s)), C, sizeEach, 'uni', 0);

shape = ones(1, max([dims(1), dCat]));
shape(dCat) = length(C);
A = cell2mat(reshape(nanc, shape));

