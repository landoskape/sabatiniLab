function index = makePointScanOutputIndex(state)

if ~isfield(state.internal,'lengthOfXData')
    lengthOfXData = 250; % default value, will probably never change
else
    lengthOfXData = state.internal.lengthOfXData;
end

L = lengthOfXData * state.acq.linesPerFrame;
% Make index of mirror position for each output sample
if state.pointScan.numberOfValidPoints>0
    if state.pointScan.repeatEachLine
        % If not integer factor, this truncates the last point
        index = repmat(1:state.pointScan.numberOfValidPoints, ...
            ceil(lengthOfXData/(state.pointScan.numberOfValidPoints*state.pointScan.pointFrequency)),  1); ...
        index = index(:);
        index = index(1:lengthOfXData/state.pointScan.pointFrequency); % The last position will always be shorter if it doesn't divide equally.
        index = repmat(index,L/(lengthOfXData/state.pointScan.pointFrequency),1);
    else
        % use frequency dropdown to make consistent frequency of point visits
        % throughout whole trial - not written yet
    end
else
    index = [];
end
index = index(:)';
