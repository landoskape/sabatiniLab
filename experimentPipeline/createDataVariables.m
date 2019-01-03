function [pdata,ptime,idata,itime] = createDataVariables(wnames,wid)

pdata = [];
ptime = [];
idata = [];
itime = [];

if sum(wid(:,1)==1)==1
    pdata = getfield(wnames{wid(:,1)==1},'data'); %#ok doesn't work for top field
    xscale = getfield(wnames{wid(:,1)==1},'xscale'); %#ok doesn't work for top field
    ptime = xscale(1):xscale(2):xscale(1)+length(pdata)*xscale(2)-xscale(2);
end

if any(wid(:,2))
    L = length(getfield(wnames{find(wid(:,2)==1,1)},'data')); %#ok doesn't work for top field
    NC = max(wid(:,2));
    NR = max(wid(:,3));
    idata = zeros(L,NC,NR); % Pre allocate
    for c = 1:NC
        for r = 1:NR
            idata(:,c,r) = getfield(wnames{wid(:,2)==c & wid(:,3)==r},'data'); %#ok doesn't work for top field
        end
    end
    xscale = getfield(wnames{find(wid(:,2)==1,1)},'xscale'); %#ok doesn't work for top field
    itime = xscale(1):xscale(2):xscale(1)+L*xscale(2)-xscale(2);
end
    
    
    
    









