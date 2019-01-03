function spineData = dbProcessSpineData(header, data)
    % load data into spine structure
    % either directly load if simple
    % or use the processField local function to do some processing
    % data is (NS x numHeaderFields) large
    % spineData is a (NS x 1) structure
    
    NF = numel(header);
    NS = size(data,1);
    spineData = struct(); % preallocate
    spineData(NS).spine = nan;
    for s = 1:NS
        for f = 1:NF
            % Process field data
            [fieldName,fieldData,msg] = processField(header{f}, data{s,f});

            % If there's an error, stop operations and print to screen
            if strcmp(fieldName,'error')
                error('Error:%s : at %s of Cell %d%s-S%d',msg,header{f},data{s,1},data{s,2},data{s,3});
            end

            % Iterate through field names and load data into cellField
            for ff = 1:numel(fieldName)
                spineData(s).(fieldName{ff}) = fieldData{ff};
            end
        end
    end
end


% -- here's the lifting --
function [name,data,msg] = processField(name,data)
    msg = 'completed';
    if isnan(data)
        if ~iscell(name)
            name = {name};
        end
        if ~iscell(data)
            data = {data};
        end
        return
    end
    idx = isstrprop(name,'upper');
    name(idx) = lower(name(idx));
    switch name
        case 'wavelengths'
            name = 'wavelengths';
            data = str2double(strsplsim(data,','));
        case 'epochs'
            if isnumeric(data)
                data = num2str(data);
            end
            name = 'epochs';
            data = str2double(strsplsim(data,','));
        case 'experiments'
            if isnumeric(data)
                data = num2str(data);
            end
            eachExperiment = strsplsim(data,',');
            NE = numel(eachExperiment);
            name = {'experiment','variation','addedDrugs','concentration'};
            data = cell(1,4);
            data{1} = nan(NE,1);
            data{2} = nan(NE,1);
            data{3} = cell(NE,1);
            data{4} = cell(NE,1);
            for e = 1:NE
                cExperiment = eachExperiment{e};
                cData = strsplsim(cExperiment,'-');
                addedDrugs = contains(cData,'D:');
                expVar = cellfun(@(c) all(isstrprop(c,'digit')), cData, 'uni', 1);
                % - check validity of organization -
                lastNum = find(expVar,1,'last');
                if lastNum>2 || ~all(expVar(1:lastNum)) || (~expVar(end) && ~all(addedDrugs(lastNum+1:end)))
                    % the first or first-two need to be numeric 
                    % everything else (if exists) must start with 'D:'
                    msg = 'experiment organization is incorrect';
                    name = 'error';
                    data = 'error';
                    return
                end
                data{1}(e) = str2double(cData{1});
                if lastNum==2 
                    data{2}(e) = str2double(cData{2});
                end
                ND = numel(cData)-lastNum;
                addedDrugs = cell(ND,1);
                concentration = zeros(ND,1);
                for d = 1:ND
                    cDrug = strsplsim(cData{d+lastNum},':');
                    addedDrugs{d} = cDrug{2};
                    if any(~isstrprop(cDrug{3}(1:end-1),'digit')) || ~contains(cDrug{3}(end),{'n','u','m'})
                        msg = sprintf('concentration denoted wrong for %s ',cDrug{2});
                        name = 'error';
                        data = 'error';
                        return
                    end
                    [~,unitIdx] = ismember(cDrug{3}(end),{'m','u','n'}); % Probably not using Molar concentrations...
                    concentration(d) = str2double(cDrug{3}(1:end-1)) * (1e-3 ^ unitIdx); % concentration in Molar
                end
                data{3}{e} = addedDrugs;
                data{4}{e} = concentration;
            end
        case 'drugs'
            name = {'drugs','concentration'};
            items = strsplsim(data,',');
            items = cellfun(@(c) c(c~=' '), items, 'uni', 0);
            items = cellfun(@(c) strsplsim(c,':'),items,'uni',0);
            NS = numel(items);
            data = cell(1,2);
            data{1} = cell(NS,1);
            data{2} = zeros(NS,1);
            for s = 1:NS
                data{1}{s} = items{s}{1};
                data{2}(s) = str2double(items{s}{2});
            end
        otherwise
            % name and data go straight out
    end
    if ~iscell(name)
        name = {name};
    end
    if ~iscell(data)
        data = {data};
    end
end



