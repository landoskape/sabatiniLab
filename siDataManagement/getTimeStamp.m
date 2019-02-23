function ts = getTimeStamp(wv,channel)
% wv must be a wave object
% channel is optional, refers to which channel to grab minInCellFrom
%       - default is to use minimum

if ischar(wv)
    try
        wv = evalin('base', wv);
    catch
        error('wv name provided could not be found in base directory');
    end
end

carriageReturn = char(13); % readability

if ~isfield(wv.UserData,'headerString')    
    error('argin1 must be structure with userdata field containing header string');
end

hs = wv.UserData.headerString;
idx = strfind(hs,'minInCell');
NM = length(idx);
mic = zeros(1,NM);
mchan = zeros(1,NM);
for m = 1:NM
    eIdx = strfind(hs(idx(m):end),'='); % find equal sign
    rIdx = strfind(hs(idx(m):end),carriageReturn); % find next carriage return
    minuteString = hs(idx(m)-1 + (eIdx(1)+1:rIdx(1)-1)); % get whatevers after the equal sign
    mic(m) = str2double(minuteString); % convert to double
    mchan(m) = str2double(hs(idx(m)+eIdx(1)-2));
end

if nargin==2 && ~isempty(channel)
    cidx = mchan==channel;
    if isempty(cidx)
        error('channel requested does not exist. NOTE: channel on 0 indexing');
    end
    ts = mic(cidx);
else
    ts = min(mic); % always be accurate unless multiple cells recorded
end





