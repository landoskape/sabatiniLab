function idx = gidx(timeVector, time, direction,full)
% idx = gidx(timeVector, time, direction)
% gidx "get idx" just uses find() to get the idx of the first point.
% direction is optimal argument for >= or <=, see below for how to use
    
if (nargin < 3)
    direction = 1; 
end %forward is default (1) backward -1

idx = zeros(size(time));
for i = 1:numel(time)
    if direction == -1
        % Get closest point before 
        idx(i) = find(timeVector <= time(i),1,'last');
    else
        % Get closest point after
        idx(i) = find(timeVector >= time(i),1,'first');
    end
end

