function c = pacell(dimCell,dimArray,type)
% preallocate cell
% dimensions of cell is from dimCell: array, e.g. [2 5]
% dimensions of each cell element is from dimArray: array, e.g. [10 100]
% type is optional, default is zeros but you can put nan or ones etc.
if nargin<3
    c = cellfun(@(c) zeros(dimArray), cell(dimCell), 'uni', 0);
else
    entry = eval([type,'(dimArray)']);
    c = cellfun(@(c) entry, cell(dimCell),'uni',0);
end





