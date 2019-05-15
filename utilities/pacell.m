function c = pacell(dimCell,dimArray,type)
% c = pacell(dimCell,dimArray,type)
%
% preallocate cell with uniform array
% 
% dimCell  - gives dimensions of cell (e.g. [2 5] makes a 2x5 cell)
% dimArray - gives dimensions of array (e.g. [10 2] makes a 10 x 2array in 
%            each cell)
% type     - optional, defines what kind array to make
%          - default is 'zeros'
%          - can be {'zeros','ones','nan'} or {0, 1, ~}
% 
% c) Andrew Landau, May 2019

if nargin < 3, type = 'zeros'; end % default is to make a zeros array
switch type
    case {'zeros',0}
        cellEntry = zeros(dimArray);
    case {'ones',1}
        cellEntry = ones(dimArray);
    case {'nan'}
        cellEntry = nan(dimArray);
    otherwise
        % Use some other kind of array
        if ischar(type)
            % Possibilities: false/true/eye/rabd/...
            eval([type,'(dimArray)']);
        elseif isnumeric(type)
            % If type is a number, make a double array with all that #
            cellEntry = type*ones(dimArray);
        else
            error('type not recognized...');
        end
end
        
c = cellfun(@(c) cellEntry, cell(dimCell),'uni',0);
