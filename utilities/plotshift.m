function ax = plotshift(varargin)
% handle = plotshift(varargin)
% first handle can be axis
% plotshift(ax,t,data,scale)
% plotshift(t,data,scale)
% plots columns of data with vertical shift so you can see them all


estimateScale = 1;
if ishandle(varargin{1})
    axis(varargin{1});
    ax = gca;
    t = varargin{2};
    data = varargin{3};
    if length(varargin)>=4
        estimateScale = 0;
        scale = varargin{4};
    end
    if length(varargin)>4
        mod = varargin{5:end};
    end
elseif length(varargin)>1
    t = varargin{1};
    data = varargin{2};
    if length(varargin)>=3
        estimateScale = 0;
        scale = varargin{3};
    end
    if length(varargin)>=4
        mod = varargin{4:end};
    end
else
    data = varargin{1};
    t = 1:size(data,1);
end

width = max(data,[],1) - min(data,[],1);
if estimateScale
    scale = 1.05;
end

hold on;
shift = [0, cumsum(width*scale)];
for c = 1:size(data,2)
    if exist('mod','var')
        plot(t,data(:,c)+shift(c),mod{:});
    else
        plot(t,data(:,c)+shift(c));
    end
end


if (nargout == 0)
    clear handle
end

    


