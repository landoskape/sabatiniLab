function anum = acqNum(wname)

if iscell(wname)
    N = length(wname);
    anum = zeros(size(wname)); 
    for n = 1:N
        anum(n) = acqNum(wname{n});
    end
    return
end

if ~ischar(wname)
    fprintf(2, 'Requires wave name as string.');
end

if contains(wname, '.mat')
    wname = wname(1:strfind(wname,'.mat')-1);
end

try 
    anum = str2double(wname(strfind(wname, '_')+1:end));
catch
    disp('here');
end

