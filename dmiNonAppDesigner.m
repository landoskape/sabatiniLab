classdef dmi < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                  matlab.ui.Figure
        redData                   matlab.ui.control.UIAxes
        tif                       matlab.ui.control.UIAxes
        greenData                 matlab.ui.control.UIAxes
        plotManager               matlab.ui.container.Panel
        roiSelector1              matlab.ui.control.DropDown
        plotAverage               matlab.ui.control.Button
        plotTrials                matlab.ui.control.Button
        plotInputs                matlab.ui.control.Button
        SCANSLabel                matlab.ui.control.Label
        TIFLabel                  matlab.ui.control.Label
        tifChannel                matlab.ui.control.DropDown
        tifType                   matlab.ui.control.DropDown
        downsampleEditFieldLabel  matlab.ui.control.Label
        downsampleFactor          matlab.ui.control.NumericEditField
        maxTrialsPlot             matlab.ui.control.NumericEditField
        gmaxEditFieldLabel        matlab.ui.control.Label
        gmax                      matlab.ui.control.NumericEditField
        holdLUT                   matlab.ui.control.CheckBox
        acquisitions              matlab.ui.container.ButtonGroup
        acqlist                   matlab.ui.control.ListBox
        avgout                    matlab.ui.control.Button
        plotacq                   matlab.ui.control.Button
        avginbutton               matlab.ui.control.Button
        avginANum                 matlab.ui.control.NumericEditField
        roiOnly                   matlab.ui.control.CheckBox
        showsButton               matlab.ui.control.Button
        tifLUT                    matlab.ui.container.Panel
        minLUT                    matlab.ui.control.Slider
        maxLUT                    matlab.ui.control.Slider
        roiAnalyzer               matlab.ui.container.Panel
        roiSelector2              matlab.ui.control.DropDown
        updateROI                 matlab.ui.control.Button
        propagateROI              matlab.ui.control.CheckBox
        physData                  matlab.ui.control.UIAxes
        averageName               matlab.ui.control.EditField
        exitAndSaveButton         matlab.ui.control.Button
    end

    
    properties (Access = private)
        % === Average Contents ===
        pavg % Phys average
        pdata % Phys acquisitions
        gavg % Green average - [numData x numROIs]
        gdata % Green acquisitions - {numROIs x 1} - [numData x numAcquisitions]
        ravg % Red Average 
        rdata % Red acquisitions
        tifData % {numAcqs x 2(frame,linescan) x 2(green,red)}, [numLines x numPixelsPerLine]
        pxval
        ixval
        tifAxisLimit % caxis of tif used for fast changes
        
        % === meta data describing avg-in avg-out operations ===
        pacqInclusion % must be separate from imaging acquisition because of roi only button
        acqInclusion % {numRoi x 2} -- initialList, newList
        roiUpdates % {numRoi x 1} [numAcqusitions x 2] nan if no change, [startIndex stopIndex] if updated
        roiData % {numROI x 1} [numAcquisitions x 2]
        tifAcqList % Index of acquisitions for tifData array
        validTemp % 1 if there's a valid acquisition currently in temp
        needUpdates % 0 until we made some changes that need updating
        showDeltaHandle % to store handle of deltas report
        
        % === temp for acquisition possibly avg'd in ===
        tempAcqNum
        tempPhys
        tempGreen
        tempRed
        tempTif        
        tempState
        tempROI
        tempNewROI
        
        % === metadata describing current average ===
        fpath
        avgid
        epoch
        pulse
        cellname
        stateData % {numROI} [.blaster .pointScan]
        cMap % list of color strings
        currentColor % string describing current color for roi
        
        avgContentList % Defined in startupFcn, just has list of all these properties
    end
    
    % Internal functions used in this app
    methods (Access = private)
        % Function to get meta data for an average
        function app = identifyAverage(app,varargin)
            % Handle varargin
            app.fpath = cd; 
            app.epoch = []; 
            app.pulse = []; % Defaults
            if (length(varargin)>=4)
                fprintf(2, 'Only first 3 inputs are used, ignoring fourth input...\n'); 
            end
            if (length(varargin)>=3) && exist(varargin{3},'file')==7
                % what() to make sure full path
                fp = what(varargin{3}); 
                app.fpath = fp.path; 
            end 
            if (length(varargin)>=2) && isnumeric(varargin{2})
                app.pulse = varargin{2}; 
            end
            if (length(varargin)>=1) && isnumeric(varargin{1})
                % Try to use varargin to identify average
                app.epoch = varargin{1}; 
                d = dir(fullfile(app.fpath,sprintf('*e%dp%d*.mat',app.epoch,app.pulse))); % Get directory with all information available
                dname = {d(:).name}; % names of files
                if sum(cellfun(@(c) contains(c, 'AD0'), dname, 'uni', 1))~=1 || isempty(d)
                    badAverage = errordlg('Could not find average from specified input. Select manually...');
                    uiwait(badAverage);
                    avgName = manuallySelectAverage(app);
                end                
                avgName = dname{1}; % first name for the getPulse function
            else 
                % Otherwise manually select average
                avgName = manuallySelectAverage(app); 
            end
            if avgName==0, return, end % This means user pressed cancel
            
            if (length(varargin)<2) || isempty(varargin{2})
                app.pulse = getPulse(app,avgName); % Put in pulse number if it wasn't provided
            end
            app.avgid = sprintf('e%dp%d',app.epoch,app.pulse); % Do we ever use this?
            [~,app.cellname] = fileparts(app.fpath); % Need for header
        end
    
        function avgName = manuallySelectAverage(app)
            [avgName,app.fpath] = uigetfile(fullfile(app.fpath,'*.mat')); % Have user select a file
            if avgName==0
                return
            end
            if ~contains(avgName,'avg')
                badAverage = errordlg('You did not select an average wave file. Select again...');
                uiwait(badAverage);
                manuallySelectAverage(app);
                return
            end
            if strcmp(app.fpath(end),'/')
                app.fpath = app.fpath(1:end-1); % remove '/' 
            end 
            
            % Get epoch
            eidx = strfind(avgName,'e');
            pidx = strfind(avgName,'p');
            app.epoch = str2double(avgName(eidx+1:pidx-1));
        end

        % Function to load average and organize all contents
        function app = loadAverage(app)
            
            avgDirectory = dir(fullfile(app.fpath,sprintf('*%s*.mat',app.avgid)));
            avgNames = cellfun(@(c) c(1:strfind(c,'.mat')-1), {avgDirectory(:).name}, 'uni', 0);
            
            % Create waveID - descriptive table of all components in average
            idxPhys = cellfun(@(c) contains(c,'AD0'),avgNames,'uni',1);
            imagChs = cellfun(@(c) str2double(c(strfind(c,'c')+1:strfind(c,'r')-1)), avgNames,'uni', 1);
            imagRoi = cellfun(@(c) str2double(c(strfind(c,'r')+1:strfind(c,'_')-1)), avgNames,'uni', 1);
            wid = cat(2, idxPhys(:), imagChs(:), imagRoi(:));
            
            % Get Phys Data
            pname = avgNames{wid(:,1)==1}; % Name of phys average wave
            loadWaveo(fullfile(app.fpath,pname)); % load wave (makes a global)
            app.pavg(:,1) = getfield(pname,'data'); %#ok get data field
            pxscale = getfield(pname,'xscale'); %#ok Get xscale field
            [app.pdata,pacqList,app.stateData] = loadAcquisitions(app,pname,[1 0]); % Load acquisitions, acquisition list, and stateData
            app.pacqInclusion = {pacqList,pacqList}; % Initialize assuming none removed
            clearvars('-global',pname);
            app.pxval = pxscale(1):pxscale(2):(pxscale(2)*size(app.pavg,1)-pxscale(2)); % Phys x axis
            
            % Get Imaging Data
            NR = max(wid(:,3));
            if isnan(NR)
                fprintf(2,'the average you selected has no imaging data.\n');
                beep
                if ishandle(app.showDeltaHandle), delete(app.showDeltaHandle); end
                delete(app);
                return;
            end
            app.acqInclusion = cell(NR,2); % Index (nr,1) is what we started with, (nr,2) is what we ended with
            for nr = 1:NR
                gname = avgNames{wid(:,2)==1 & wid(:,3)==nr}; % Name of green average
                loadWaveo(fullfile(app.fpath,gname)); % load green average wave
                app.gavg(:,nr) = getfield(gname,'data'); %#ok - green data average
                if nr==1, ixscale = getfield(gname,'xscale'); end %#ok - xscale field of imaging
                [app.gdata{nr},cAcqList,acqROI] = loadAcquisitions(app,gname,[0 1]); % load green acquisitions, acqList, and acqROIs
                app.acqInclusion(nr,[1 2]) = {cAcqList,cAcqList}; % Assume none removed
                app.roiUpdates{nr} = nan(length(cAcqList),2); % Initialize assuming no changes
                app.roiData{nr} = cell2mat(acqROI); % Put these here for plotting the TIF
                clearvars('-global',gname); % clear out
                
                rname = avgNames{wid(:,2)==2 & wid(:,3)==nr}; % Same for red
                loadWaveo(fullfile(app.fpath,rname));
                app.ravg(:,nr) = getfield(rname,'data'); %#ok
                app.rdata{nr} = loadAcquisitions(app,rname);
                clearvars('-global',rname);
            end
            app.ixval = ixscale(1):ixscale(2):(ixscale(2)*size(app.gavg,1)-ixscale(2)); % Imaging x axis
            
            % Get Tif Data
            allAcqs = unique(cell2mat(cellfun(@(c) c(:)', app.acqInclusion(:,1)', 'uni', 0))); % All acquisitions from the imaging averages
            app.tifAcqList = allAcqs; % Acquisition list to indicate indices of tif files
            NT = length(allAcqs); 
            for nt = 1:NT
                % Get tif of data scan "linescan"
                cacq = allAcqs(nt);
                ctif = tifread(fullfile(app.fpath,strcat(app.cellname,num2str3(app,cacq),'.tif'))); % Get Tif
                gtif = ctif(:,:,1:3:end); % green data
                rtif = ctif(:,:,2:3:end); % red data
                
                app.tifData{nt,2,1} = double(fixFrame(app,gtif)); % turn to double and remove 3rd dimension
                app.tifData{nt,2,2} = double(fixFrame(app,rtif));
                
                % Get tif of frame scan
                cacq = cacq-1;
                ctif = tifread(fullfile(app.fpath,strcat(app.cellname,num2str3(app,cacq),'.tif')));
                gtif = ctif(:,:,1:3:end);
                rtif = ctif(:,:,2:3:end);
                
                app.tifData{nt,1,1} = double(fixFrame(app,gtif)); 
                app.tifData{nt,1,2} = double(fixFrame(app,rtif));
            end
            
            % Number of ROIs in current average
            roiSelectorItems = cellfun(@(c) sprintf('ROI %d',c), num2cell(1:NR),'uni',0);
            app.roiSelector1.Items = roiSelectorItems;
            app.roiSelector2.Items = roiSelectorItems;
            app.roiSelector1.ItemsData = 1:size(app.gavg,2);
            app.roiSelector2.ItemsData = 1:size(app.gavg,2);
            
            roiSelectorCallback(app); % this callback creates the list in acquisition list
        end
    
        function [acqData,acqList,extraOut] = loadAcquisitions(app,name,flag)
            if nargin<3, flag = [0 0]; end
            acl = avgComponentList(name); % Average component list
            acqList = cellfun(@(c) str2double(c(strfind(c,'_')+1:end)), acl); % Acquisition numbers
            NA = length(acl);
            acqs = cell(1,NA);
            acqData = cell(1,NA);
            if flag(1), extraOut = struct(); extraOut(NA).blaster = []; end
            if flag(2), extraOut = cell(NA,1); end
            for a = 1:length(acl)
                acqs{a} = loadWaveo(fullfile(app.fpath,strcat(acl{a},'.mat')));
                acqData{a} = getfield(acqs{a},'data'); %#ok
                if flag(1) 
                    % Get State for blaster and point scan
                    state = makeState(app,acqs{a}.UserData.headerString);
                    %state = makeState(app,acqs{a});
                    extraOut(a).acq = state.acq;
                    extraOut(a).blaster = state.blaster;
                    if isfield(state,'pointScan')
                        extraOut(a).pointScan = state.pointScan;
                    end
                end
                if flag(2) 
                    % Get ROIDef
                    ud = getfield(acqs{a},'UserData'); %#ok
                    extraOut{a} = getfield(ud,'ROIDef'); %#ok
                    extraOut{a} = extraOut{a}(:)'; % Make sure it's horizontal
                end
            end
            acqData = cell2mat(cellfun(@(c) c(:), acqData, 'uni', 0));
            clearvars('-global',acl{:});
        end
            
        function removeAcq(app,roi,acqNum)
            cidx = app.acqInclusion{roi,2}==acqNum;
            
            % Remove acquisition
            app.gdata{roi}(:,cidx) = [];
            app.rdata{roi}(:,cidx) = [];
            % Update meta data
            app.acqInclusion{roi,2}(cidx) = [];
            app.roiUpdates{roi}(cidx,:) = [];
            app.roiData{roi}(cidx,:) = [];
            % Make new averages
            app.gavg(:,roi) = mean(app.gdata{roi},2);
            app.ravg(:,roi) = mean(app.rdata{roi},2);
        end
        
        % Function to retrieve pulse number from average name
        function pulse = getPulse(~,name)
            switch name(1)
                case 'e' % this is an imaging average of format e#p#c#r#_avg
                    pulse = str2double(name(strfind(name,'p')+1:strfind(name,'c')-1));
                otherwise % this is a phys average of format AD#_e#p#avg
                    pulse = str2double(name(strfind(name,'p')+1:strfind(name,'avg')-1));
            end
        end
    
        function strcode = num2str3(~,num)
            strcode = '000';
            str = num2str(num);
            strcode(end-length(str)+1:end)=str;
        end
    
        function tif = fixFrame(~,tif)
            % basically calls tif(:,:), but permutes first because order of
            % indexing is transposed out of scanImage
            tif = reshape(permute(tif,[2 1 3]), size(tif,2), size(tif,1)*size(tif,3),1)'; 
        end
    
        function state = makeState(~,headerString)
            if isfield(headerString,'UserData') && isfield(headerString.UserData,'headerString') % This should be a wave file
                headerString = headerString.UserData.headerString;
                stateStrings = splitlines(headerString);
            elseif ischar(headerString) % This is hopefully the explicit headerString from a wave
                stateStrings = splitlines(headerString);
            else
                error('input must be wave with headerString, or headerString as char...');
            end
        
            lstate = length(stateStrings); % Number of stateStrings
            
            % ## NOTE: Each stateString is like: 'state.files.pth='/./.'
            % this literally evaluates each line to recreate the struct
            state = struct();
            for lst = 1:lstate
                if isempty(stateStrings{lst}), continue; end % for some reason it finds empties
                cString = stateStrings{lst}(7:end); % everything after 'state.'
                eqidx = strfind(cString,'='); % index where value is set
                name = cString(1:eqidx(1)-1); % everything in between 'state.' and '='
                post = cString(eqidx(1)+1:end); % value 
                if ~isempty(post) && strcmp(post(end),','), post = post(1:end-1); end % comma generates output to workspace and is unnecessary
                if isempty(post), post = '[]'; end % Make sure we have a valid value, even if empty
        
                % Make sure eval command is rendered correctly
                if isempty(strfind(post,',')) %#ok - contains is slower
                    % No commas in post, just set it directly
                    eval(strcat('state.',name,'=',post,';')); 
                else
                    % lists of numbers are delimited by commas in headerString
                    postElements = strsplsim(post,',');
                    eval(strcat('state.',name,'=',strcat('[',sprintf('%s ',postElements{:}),']'),';')); % This stupid shit is the only way
                end
            end
        end
    
        function roiSelectorCallback(app)
            app.validTemp = 0; % validTemp only when we're currently plotting temp, this function is always followed by replotting trials
            
            croi = app.roiSelector1.Value; % Current roi
            cacqList = app.acqInclusion{croi,2}; % Current list of acquisitions
            NA = length(cacqList);
            app.acqlist.ItemsData = 1:NA;
            if app.acqlist.Value > NA % Make sure we have a valid acqlist value, i.e. if previous ROI had more acquisitions than current
                app.acqlist.Value = NA;
            end
            app.acqlist.Items = cellfun(@(c) sprintf('ACQ: %d',c), num2cell(cacqList), 'uni', 0); % Remake ROI dropdown list
            
            % Update colors to match current roi
            app.currentColor = app.cMap(croi);
            app.roiSelector1.FontColor = app.currentColor;
            app.roiSelector2.FontColor = app.currentColor;
            app.acqlist.FontColor = app.currentColor;
            app.plotTrials.FontColor = app.currentColor;
        end
    
        function newROI = acquireNewROI(app)
            % New figure b/c drawrectangle doesn't work on UIFigures
            updateFig = figure; 
            updateAx = gca;
            if app.validTemp, plotTempTif(app,updateAx); else, plotTif(app,updateAx); end % Plot tif on the new axis
            
            % Ask for user input on rectangle
            h = drawrectangle(updateAx,'Color',[0.5 0.5 0.5],'FaceAlpha',0.1);
            if any(h.Position([2 4])==0), newROI = []; return, end % Abort and output empty if it didn't work

            % Get position then close figure
            newROI = [round(h.Position(1)) round(h.Position(1)+h.Position(3))];
            if newROI(2) < newROI(1), newROI = fliplr(newROI); end
            close(updateFig);
        end
    
        function updateROIData(app,cacq,croi,newROI)
            cacqNum = app.acqInclusion{croi,2}(cacq);
            pIdx = app.pacqInclusion{2}==cacqNum;
            tIdx = app.tifAcqList==cacqNum;
            
            % Get PMT Offsets (offsetPerBin * numberOfBinsPerPixel)
            pmtOffsets = [app.stateData(pIdx).acq.pmtOffsetChannel1 app.stateData(pIdx).acq.pmtOffsetChannel2];
            pmtOffsets = pmtOffsets * app.stateData(pIdx).acq.binFactor;
            
            % These assumptions based on my usual practice!!!
            % Baseline from 1:50 & G/Rbase and R/Rbase
            newGreen = mean(app.tifData{tIdx,2,1}(:,newROI(1):newROI(2))-pmtOffsets(1),2);
            newRed = mean(app.tifData{tIdx,2,2}(:,newROI(1):newROI(2))-pmtOffsets(2),2);
            rBase = mean(newRed(1:50));
            app.gdata{croi}(:,cacq) = newGreen/rBase;  
            app.rdata{croi}(:,cacq) = newRed/rBase;
            app.gavg(:,croi) = mean(app.gdata{croi},2);
            app.ravg(:,croi) = mean(app.rdata{croi},2);
            
            % Add new roi data
            app.roiData{croi}(cacq,:) = newROI;
            app.roiUpdates{croi}(cacq,:) = newROI;
        end
    
        function showUpdatesFigure(app,lastUpdate)
            if nargin<2, lastUpdate = 0; end % default is that this isn't the last update
            aiPhys = app.pacqInclusion{2}(~ismember(app.pacqInclusion{2},app.pacqInclusion{1})); % phys trials avg'd in
            aoPhys = app.pacqInclusion{1}(~ismember(app.pacqInclusion{1},app.pacqInclusion{2})); % phys trials avg'd out
            NR = size(app.gavg,2);
            aiImag = cell(NR,1);
            aoImag = cell(NR,1);
            roiUpdate = cell(NR,1);
            for nr = 1:NR
                % For each roi..
                aiImag{nr} = app.acqInclusion{nr,2}(~ismember(app.acqInclusion{nr,2},app.acqInclusion{nr,1})); % imaging trials avg'd in
                aoImag{nr} = app.acqInclusion{nr,1}(~ismember(app.acqInclusion{nr,1},app.acqInclusion{nr,2})); % imaging trials avg'd out
                roiUpdate{nr} = find(all(~isnan(app.roiUpdates{nr}),2)); % imaging trials with new ROI
            end
            
            % Setup showUpdates figure
            if isempty(app.showDeltaHandle) || ~ishandle(app.showDeltaHandle)
                app.showDeltaHandle = figure; % If it doesn't exist, make it
                set(app.showDeltaHandle,'units','normalized','outerposition',[0.3902 0.6368 0.3938 0.3424]);
                if ~lastUpdate
                    app.showDeltaHandle.CloseRequestFcn = @showDeltaCallback; % If it's not the last update, include the return to UIFigure callback
                end
            else
                % If it exists, make sure it has correct closereq
                if lastUpdate
                    app.showDeltaHandle.CloseRequestFcn = closereq;
                else
                    app.showDeltaHandle.CloseRequestFcn = @showDeltaCallback;
                end
                clf(app.showDeltaHandle); % clear figure to plot new updates
            end
            physText = annotation(app.showDeltaHandle,'textbox','Position',[0.05 0.79 0.9 0.18],'FontSize',16); % text box for phys updates
            physTextString = cell(3,1);
            physTextString{1} = 'Physiology Updates:';
            if ~isempty(aiPhys)
                physTextString{2} = ['avgin: ',sprintf('%d, ',aiPhys)];
            else
                physTextString{2} = ['avgin: ','--'];
            end
            if ~isempty(aoPhys)
                physTextString{3} = ['avgout: ',sprintf('%d, ',aoPhys)];
            else
                physTextString{3} = ['avgout: ','--'];
            end
            physText.String = physTextString;
            
            roiText = cell(1,NR);
            for nr = 1:NR
                % Text boxes for each imaging roi updates
                roiText{nr} = annotation(app.showDeltaHandle,'textbox','Position',[0.05 0.79-nr*0.22 0.9 0.22],'FontSize',16);
                roiTextString = cell(4,1); 
                roiTextString{1} = sprintf('Imaging ROI %d/%d:',nr,NR);
                if ~isempty(aiImag{nr})
                    roiTextString{2} = ['-- avgin: ',sprintf('%d, ',aiImag{nr})];
                else
                    roiTextString{2} = ['-- avgin: ','--'];
                end
                if ~isempty(aoImag{nr})
                    roiTextString{3} = ['-- avgout: ',sprintf('%d, ',aoImag{nr})];
                else
                    roiTextString{3} = ['-- avgout: ','--'];
                end
                if ~isempty(roiUpdate{nr})
                    roiTextString{4} = ['-- ',app.showsButton.Text(6),'roidef: ',sprintf('%d, ',app.acqInclusion{nr,2}(roiUpdate{nr}))];
                else
                    roiTextString{4} = ['-- ',app.showsButton.Text(6),'roidef: ','--'];
                end
                roiText{nr}.String = roiTextString;
            end
            figure(app.showDeltaHandle); % make sure it is current figure after it is made
            
            function showDeltaCallback(~,~)
                % If not last update, go back to main app and close window
                figure(app.UIFigure); 
                closereq;
            end
        end
    
        function loadTempData(app)
            cacqNum = app.avginANum.Value;
            % Get Phys
            try loadWaveo(fullfile(app.fpath,sprintf('AD0_%d.mat',cacqNum))); catch, error('couldn''t find phys (AD0) for acq: %d',cacqNum); end
            % Get Green
            for nr = 1:size(app.gavg,2)
                try loadWaveo(fullfile(app.fpath,sprintf('c1r%d_%d.mat',nr,cacqNum))); catch, error('couldn''t find green data for acq: %d, roi: %d',cacqNum,nr); end
                try loadWaveo(fullfile(app.fpath,sprintf('c2r%d_%d.mat',nr,cacqNum))); catch, error('couldn''t find red data for acq: %d, roi: %d',cacqNum,nr); end
            end
            try % Get Tif
                cLinescan = tifread(fullfile(app.fpath,strcat(app.cellname,num2str3(app,cacqNum),'.tif'))); % "linescan"
                cFrame = tifread(fullfile(app.fpath,strcat(app.cellname,num2str3(app,cacqNum-1),'.tif'))); % "frame"
            catch, error('couldn''t find tif for acq: %d',cacqNum); 
            end
            
            % If all data loaded successfully, add to temp
            app.tempAcqNum = cacqNum;
            
            % Add phys to temp
            app.tempPhys = getfield(sprintf('AD0_%d',cacqNum),'data');
            ud = getfield(sprintf('AD0_%d',cacqNum),'UserData');
            state = makeState(app,ud.headerString);
            app.tempState.acq = state.acq;
            app.tempState.blaster = state.blaster;
            if isfield(state,'pointScan')
                app.tempState.pointScan = state.pointScan;
            end
            clearvars('-global',sprintf('AD0_%d',cacqNum));
            
            % Add imaging to temp
            app.tempNewROI = cellfun(@(c) nan(1,2), num2cell(1:size(app.gavg,2)), 'uni', 0); % default for adding nans to app.roiUpdates
            app.tempROI = cell(1,size(app.gavg,2));
            for nr = 1:size(app.gavg,2)
                app.tempGreen(:,nr) = getfield(sprintf('c1r%d_%d',nr,cacqNum),'data');
                app.tempRed(:,nr) = getfield(sprintf('c2r%d_%d',nr,cacqNum),'data');
                ud = getfield(sprintf('c1r%d_%d',nr,cacqNum),'UserData');
                app.tempROI{nr} = ud.ROIDef;
                clearvars('-global',sprintf('c1r%d_%d',nr,cacqNum));
                clearvars('-global',sprintf('c2r%d_%d',nr,cacqNum));
            end
            
            % Add tif
            app.tempTif{2} = cLinescan;
            app.tempTif{1} = cFrame;
            
            % Indicate that temp was successfully added
            app.validTemp = 1;
        end
    
        function plotTempData(app)
            if app.gmax.Value~=0, ggmax = app.gmax.Value; else, ggmax = 1; end % Gmax if you want it
            
            darkenRatio = 0.5; % How much should we darken the average plots to distinguish them from tempData?
            
            % Plot Averages as backdrop
            NR = size(app.gavg,2);
            % Plot Green Data
            cla(app.greenData);
            hold(app.greenData,'on');
            for nr = 1:NR
                p = plot(app.greenData,app.ixval,app.gavg(:,nr)./ggmax,'color',app.cMap(nr),'linewidth',1.5);
                p.Color = p.Color*darkenRatio/(darkenRatio+1);
            end
            xlim(app.greenData,[app.ixval(1) app.ixval(end)]);
            % Plot Red Data
            cla(app.redData);
            hold(app.redData,'on');
            for nr = 1:NR
                p = plot(app.redData,app.ixval,app.ravg(:,nr),'color',app.cMap(nr),'linewidth',1.5);
                p.Color = p.Color*darkenRatio/(darkenRatio+1);
            end
            xlim(app.redData,[app.ixval(1) app.ixval(end)]);
            % Plot phys data
            cla(app.physData);
            hold(app.physData,'on');
            plot(app.physData,app.pxval,app.pavg,'color','k','linewidth',1.5);
            xlim(app.physData,[app.pxval(1) app.pxval(end)]);
            
            % Plot new phys trial
            hold(app.physData,'on');
            plot(app.physData,app.pxval,app.tempPhys,'color','k','linewidth',1.5,'linestyle',':');
            % Plot new green data
            hold(app.greenData,'on');
            for nr = 1:size(app.gavg,2)
                plot(app.greenData,app.ixval,app.tempGreen(:,nr)./ggmax,'color',app.cMap(nr),'linewidth',1.5);
            end
            % Plot new red data
            hold(app.redData,'on');
            for nr = 1:size(app.gavg,2)
                plot(app.redData,app.ixval,app.tempRed(:,nr),'color',app.cMap(nr),'linewidth',1.5);
            end
        end
    
        function addTempData(app,croi)
            croiIdx = length(app.acqInclusion{croi,2})+1; % Start by getting new index for tempData
            
            % validate #Acqs in this ROI with # in app.acqInclusions
            checkNumberOfAcqs = [size(app.gdata{croi},2)~=croiIdx-1 size(app.rdata{croi},2)~=croiIdx-1 size(app.roiUpdates{croi},1)~=croiIdx-1 size(app.roiData{croi},1)~=croiIdx-1];
            if any(checkNumberOfAcqs)
                output = {'GData','RData','roiUpdates','roiData';checkNumberOfAcqs(1),checkNumberOfAcqs(2),checkNumberOfAcqs(3),checkNumberOfAcqs(4)};
                disp(output);
                error('ROI %d does not have the correct number of data points.');
            end
            
            % Add imaging data for current acquisition
            app.acqInclusion{croi,2}(croiIdx)=app.tempAcqNum; % Add current acquisition to acqInclusion list
            app.gdata{croi}(:,croiIdx) = app.tempGreen(:,croi); % Add current acquisition of current ROI to green data
            app.gavg(:,croi) = mean(app.gdata{croi},2); % Update Average
            app.rdata{croi}(:,croiIdx) = app.tempRed(:,croi);
            app.ravg(:,croi) = mean(app.rdata{croi},2);
            
            % Add ROI Data
            app.roiUpdates{croi}(croiIdx,:) = app.tempNewROI{croi}; % Create new field in roiUpdates for this acquisition
            app.roiData{croi}(croiIdx,:) = app.tempROI{croi}; % same
        end
    
        function plotTif(app,ax)
            if nargin<2, ax = app.tif; end
            cChannel = app.tifChannel.Value;
            cType = app.tifType.Value;
            croi = app.roiSelector1.Value;
            cacq = app.acqlist.Value; % Current acquisition index
            cacqNum = app.acqInclusion{croi,2}(cacq); % Current acquisition value
            tacqIdx = app.tifAcqList==cacqNum; % Index for tif acquisition
            
            ctif = app.tifData{tacqIdx,cType,cChannel};
            imagesc(ax,ctif);
            xlim(ax,[1 size(ctif,2)]);
            ylim(ax,[1 size(ctif,1)]);
            colormap(ax,'gray');
            if isequal(ax,app.tif)
                app.tifAxisLimit = [min(ctif(:)) max(ctif(:))]; % put this there for quick axis in other functions
                if ~app.holdLUT.Value
                    % Reset lookup table
                    caxis(ax,app.tifAxisLimit);
                    app.minLUT.Value = 0;
                    app.maxLUT.Value = 1;
                else
                    % Keep same relative values
                    limitExtent = diff(app.tifAxisLimit);
                    minValue = app.minLUT.Value * limitExtent + app.tifAxisLimit(1);
                    maxValue = app.maxLUT.Value * limitExtent + app.tifAxisLimit(1);
                    caxis(ax,[minValue maxValue]);
                end
            else
                cAxis = caxis(app.tif);
                caxis(ax,cAxis);
            end
            
            sacqIdx = app.pacqInclusion{2}==cacqNum; % State data idx (linked to phys acquisition list)
            if isfield(app.stateData,'pointScan') && ~isempty(app.stateData(sacqIdx).pointScan) && app.stateData(sacqIdx).pointScan.pointScanActive
                if app.tifType.Value==1
                    % Only plot PS position if its active and its a framescan
                    linkedPosition = app.stateData(sacqIdx).pointScan.blasterPosition;
                    rois = [app.stateData(sacqIdx).blaster.indexXList(linkedPosition), app.stateData(sacqIdx).blaster.indexYList(linkedPosition)]; 
                    roiRadius = 0.5;
                    ppm=10;  %approximate for 256x256, 20x zoom....
                    NOP=100;
                    radius=roiRadius*ppm; %ppm=pixels per micron
                    THETA=linspace(0,2*pi,NOP);                  
                    RHO=ones(1,NOP)*radius;
                    [X,Y] = pol2cart(THETA,RHO);
                    X=X+rois(1);
                    Y=Y+rois(2);
                    line(ax,X, Y, 'color',app.cMap(1),'linewidth',1.5);
                end
            else
                for nr = 1:size(app.gdata,2)
                    idxROI = app.acqInclusion{nr,2}==cacqNum;
                    if any(idxROI)
                        croi = app.roiData{nr}(idxROI,:);
                        line(ax,[croi(1) croi(2)],[size(ctif,1)/2 size(ctif,1)/2],'linewidth',2,'color',app.cMap(nr));
                    end
                end
            end
        end
    
        function plotTempTif(app,ax)
            if nargin<2, ax = app.tif; end
            % Plot tif
            ctif = fixFrame(app,app.tempTif{app.tifType.Value}(:,:,app.tifChannel.Value:3:end));
            
            imagesc(ax,ctif);
            xlim(ax,[1 size(ctif,2)]);
            ylim(ax,[1 size(ctif,1)]);
            colormap(ax,'gray');
            if isequal(ax,app.tif)
                app.tifAxisLimit = [min(ctif(:)) max(ctif(:))]; % put this there for quick axis in other functions
                if ~app.holdLUT.Value
                    % Reset lookup table
                    caxis(ax,app.tifAxisLimit);
                    app.minLUT.Value = 0;
                    app.maxLUT.Value = 1;
                else
                    % Keep same relative values
                    limitExtent = diff(app.tifAxisLimit);
                    minValue = app.minLUT.Value * limitExtent + app.tifAxisLimit(1);
                    maxValue = app.maxLUT.Value * limitExtent + app.tifAxisLimit(1);
                    caxis(ax,[minValue maxValue]);
                end
            else
                cAxis = caxis(app.tif);
                caxis(ax,cAxis);
            end
            
            
            if isfield(app.tempState,'pointScan') && app.tempState.pointScan.pointScanActive
                if app.tifType.Value==1
                    % Only plot PS position if its active and its a framescan
                    linkedPosition = app.tempState.pointScan.blasterPosition;
                    rois = [app.tempState.blaster.indexXList(linkedPosition), app.tempState.blaster.indexYList(linkedPosition)]; 
                    roiRadius = 0.5;
                    ppm=10;  %approximate for 256x256, 20x zoom....
                    NOP=100;
                    radius=roiRadius*ppm; %ppm=pixels per micron
                    THETA=linspace(0,2*pi,NOP);                  
                    RHO=ones(1,NOP)*radius;
                    [X,Y] = pol2cart(THETA,RHO);
                    X=X+rois(1);
                    Y=Y+rois(2);
                    line(ax,X, Y, 'color',app.cMap(1),'linewidth',1.5);
                end
            else
                rois = app.tempROI;
                for nr = 1:length(rois)
                    line(ax,[rois{nr}(1) rois{nr}(2)],[size(ctif,1)/2 size(ctif,1)/2],'linewidth',2,'color',app.cMap(nr));
                end
            end
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, varargin)
            app.UIFigure.Visible = 'off';
            app.needUpdates = 0;
            app.avgContentList = {'pavg','pdata','gavg','gdata','ravg','rdata','gtifData','rtifData','pxval','ixval','pacqInclusion','acqInclusion','roiUpdates','tifAcqList'};
            app.cMap = 'bmcyrgkkkkkkkkkk'; % colormap used lots of places
            
            app = identifyAverage(app,varargin{:}); % Get fpath, epoch, pulse and avgid
            if isempty(app.cellname)
                % This is the case if the user canceled a manual select
                if ishandle(app.showDeltaHandle)
                    delete(app.showDeltaHandle); 
                end
                delete(app); 
                return; 
            end
            app = loadAverage(app); % Load Average
            
            [enclosingDir,cellName] = fileparts(app.fpath);
            [~,experimentFolder] = fileparts(enclosingDir);
            app.averageName.Value = sprintf('%s, %s, Epoch: %d, Pulse: %d',experimentFolder,cellName,app.epoch,app.pulse);
            
            % Initialize Some Components that the App Designer can't handle
            app.tifChannel.ItemsData = [1 2]; % Make numeric so we can pull it out as index
            app.tifType.ItemsData = [1 2];
            app.tifChannel.Value = 2; % Initialize to red channel
            app.tifType.Value = 1; % Initialize to frame scan
            
            plotAverageButtonPushed(app);
            plotTif(app);
            
            allProps = properties(app);
            for ap = 1:length(allProps)
                if isprop(app.(allProps{ap}),'Tooltip')
                    app.(allProps{ap}).Tooltip = '';
                end
            end
            
            app.UIFigure.Visible = 'on';
        end

        % Button pushed function: plotAverage
        function plotAverageButtonPushed(app, event)
            % Reset validTemp and acquisition list if it's on
            if app.validTemp
                app.validTemp = 0;
                app.acqlist.Items = app.acqlist.Items(1:end-1);
                app.acqlist.Value = length(app.acqlist.Items);
            end
            
            if app.gmax.Value~=0, ggmax = app.gmax.Value; else, ggmax = 1; end % Gmax if you want it
            
            app.acqlist.FontColor = 'k';
            app.plotTrials.FontColor = 'k';
            app.roiSelector1.FontColor = 'k';
            app.roiSelector2.FontColor = 'k';
            
            NR = size(app.gavg,2);
            % Plot Green Data
            cla(app.greenData);
            hold(app.greenData,'on');
            for nr = 1:NR
                plot(app.greenData,app.ixval,app.gavg(:,nr)./ggmax,'color',app.cMap(nr),'linewidth',1.5);
            end
            xlim(app.greenData,[app.ixval(1) app.ixval(end)]);
            % Plot Red Data
            cla(app.redData);
            hold(app.redData,'on');
            for nr = 1:NR
                plot(app.redData,app.ixval,app.ravg(:,nr),'color',app.cMap(nr),'linewidth',1.5);
            end
            xlim(app.redData,[app.ixval(1) app.ixval(end)]);
            % Plot phys data
            cla(app.physData);
            hold(app.physData,'on');
            plot(app.physData,app.pxval,app.pavg,'color','k','linewidth',1.5);
            xlim(app.physData,[app.pxval(1) app.pxval(end)]);
        end

        % Button pushed function: plotTrials
        function plotTrialsButtonPushed(app, event)
            croi = app.roiSelector1.Value; % Current roi value
            cacq = app.acqlist.Value; % Current acquisition index
            cacqNum = app.acqInclusion{croi,2}(cacq); % Current acquisition value
            
            if app.validTemp
                app.validTemp = 0;
                app.acqlist.Items = app.acqlist.Items(1:length(app.acqInclusion{croi,2}));
                app.acqlist.Value = length(app.acqlist.Items);
            end
            
            if app.gmax.Value~=0, ggmax = app.gmax.Value; else, ggmax = 1; end % Gmax if you want it
            
            numTrials = min([app.maxTrialsPlot.Value length(app.acqInclusion{croi,2})-1]); % Don't plot more than the maximum trials edit box says to
            if numTrials>1
                trialsToPlot = randperm(length(app.acqInclusion{croi,2})-1,numTrials); % Randomly generate trials to plot (necessary if total greater than max)
                trialsToPlot(trialsToPlot==cacq) = length(app.acqInclusion{croi,2}); % Make sure selected trial isn't in background
                acqsPlotting = app.acqInclusion{croi,2}; % Actual acquisition numbers that were chosen to be plotted
                [~,idxPhysToPlot] = ismember(acqsPlotting,app.pacqInclusion{2}); % Index of those acquisitions in phys
                if any(~idxPhysToPlot), fprintf(2,'%d in imaging but not in phys...\n\n',acqsPlotting(~idxPhysToPlot)); return, end
                
                % Setup some other trials to plot as background to current trial
                greenBackground = app.gdata{croi}(:,trialsToPlot)./ggmax;
                redBackground = app.rdata{croi}(:,trialsToPlot);
                physBackground = app.pdata(:,idxPhysToPlot);
            else
                
                % We're plotting the average as the backdrop
                greenBackground = app.gavg(:,croi);
                redBackground = app.ravg(:,croi);
                physBackground = app.pavg;
            end
            idxPhysCurrent = app.pacqInclusion{2}==cacqNum; % Currently selected acquisition index in phys
            
            % Plot Green Data
            cla(app.greenData);
            hold(app.greenData,'on');
            plot(app.greenData,app.ixval,greenBackground,'color','k','linewidth',1);
            plot(app.greenData,app.ixval,app.gdata{croi}(:,cacq)./ggmax,'color',app.cMap(croi),'linewidth',1.5);
            xlim(app.greenData,[app.ixval(1) app.ixval(end)]);
            % Plot Red Data
            cla(app.redData);
            hold(app.redData,'on');
            plot(app.redData,app.ixval,redBackground,'color','k','linewidth',1);
            plot(app.redData,app.ixval,app.rdata{croi}(:,cacq),'color',app.cMap(croi),'linewidth',1.5);
            xlim(app.redData,[app.ixval(1) app.ixval(end)]);
            % Plot phys data
            cla(app.physData);
            hold(app.physData,'on');
            plot(app.physData,app.pxval,physBackground,'color','k','linewidth',1);
            plot(app.physData,app.pxval,app.pdata(:,idxPhysCurrent),'color',app.cMap(croi),'linewidth',1.5);
            xlim(app.physData,[app.pxval(1) app.pxval(end)]);
            
            % Update colors everywhere
            app.acqlist.FontColor = app.cMap(croi);
            app.plotTrials.FontColor = app.cMap(croi);
            app.roiSelector1.FontColor = app.cMap(croi);
            app.roiSelector2.FontColor = app.cMap(app.roiSelector2.Value); % This stays what it was...
        end

        % Value changed function: acqlist
        function acqlistValueChanged(app, event)
            if app.validTemp
                app.validTemp = 0;
                app.acqlist.Items = app.acqlist.Items(1:end-1);
                app.acqlist.Value = length(app.acqlist.Items);
            end
            plotTrialsButtonPushed(app);
            plotTif(app);
        end

        % Value changed function: roiSelector1
        function roiSelector1ValueChanged(app, event)
            app.roiSelector2.Value = app.roiSelector1.Value; % Force roi analyzer's roi selector to be same
            roiSelectorCallback(app);
            
            % Plot trials
            plotTrialsButtonPushed(app,1);
        end

        % Value changed function: roiSelector2
        function roiSelector2ValueChanged(app, event)
            app.roiSelector2.FontColor = app.cMap(app.roiSelector2.Value);
        end

        % Value changed function: tifChannel
        function tifChannelValueChanged(app, event)
            if app.validTemp
                plotTempTif(app);
            else
                plotTif(app);
            end
        end

        % Value changed function: tifType
        function tifTypeValueChanged(app, event)
            if app.validTemp
                plotTempTif(app);
            else
                plotTif(app);
            end
        end

        % Callback function: minLUT, minLUT
        function minLUTValueChanging(app, event)
            changingValue = event.Value; % Current value
            cAxis = caxis(app.tif); % Get current axis for the maximum
            limitExtent = diff(app.tifAxisLimit); % Difference of axis limits
            newMinimum = min([changingValue*limitExtent + app.tifAxisLimit(1) cAxis(2)-1]); % Don't let minimum be bigger than maximum
            newLUTVal = (newMinimum-app.tifAxisLimit(1))/limitExtent; % New minimum axis value
            app.minLUT.Value = newLUTVal; % make sure the app has updated given above constraints
            caxis(app.tif,[newMinimum cAxis(2)]); % set the new axis
        end

        % Callback function: maxLUT, maxLUT
        function maxLUTValueChanging(app, event)
            changingValue = event.Value; % Same as minLUTValueChanging(app,event)
            cAxis = caxis(app.tif);
            limitExtent = diff(app.tifAxisLimit);
            newMaximum = max([cAxis(1)+1 changingValue*limitExtent+app.tifAxisLimit(1)]);
            newLUTVal = (newMaximum-app.tifAxisLimit(1))/limitExtent;
            app.maxLUT.Value = newLUTVal;
            caxis(app.tif,[cAxis(1) newMaximum]);
        end

        % Button pushed function: avgout
        function avgoutButtonPushed(app, event)
            if app.validTemp
                avginActive = errordlg('Cannot avgout when a prospective avgin acquisition is selected.');
                uiwait(avginActive);
                figure(app.UIFigure);
                return
            end
            croi = app.roiSelector1.Value; % Current roi value
            cacq = app.acqlist.Value; % Current acquisition index
            cacqNum = app.acqInclusion{croi,2}(cacq); % Current acquisition value
            if app.roiOnly.Value
                removeAcq(app,croi,cacqNum);
            else
                for r = 1:size(app.gavg,2), removeAcq(app,r,cacqNum); end
            end
            allAcqs = cell2mat(cellfun(@(c) c(:), app.acqInclusion(:,2),'uni',0));
            if ~any(allAcqs==cacqNum) % Acquisition has been vanquished
                % Remove from phys
                pidx = app.pacqInclusion{2}==cacqNum;
                app.pacqInclusion{2}(pidx) = [];
                app.pdata(:,pidx) = [];
                app.pavg = mean(app.pdata,2); 
                app.stateData(pidx) = [];
                % Remove from tifs
                tidx = app.tifAcqList==cacqNum;
                app.tifAcqList(tidx) = [];
                app.tifData(tidx,:,:) = [];
            end
            app.acqlist.Value = min([app.acqlist.Value, size(app.gdata{croi},2)]); % increase or make max possible
            roiSelectorCallback(app); % this makes a new acqlist and replots things
            plotTrialsButtonPushed(app); % replot the trials
            plotTif(app);
            app.needUpdates = 1;
            app.exitAndSaveButton.Enable = 'on';
        end

        % Button pushed function: avginbutton
        function avginbuttonButtonPushed(app, event)
            if ~app.validTemp
                noTemp = errordlg('No new acquisition has been selected, can''t average in.','!!!');
                uiwait(noTemp);
                figure(app.UIFigure);
                return
            end
            % Move data from temp to main data, udpate acqInclusion list
            aiacq = app.tempAcqNum;
            croi = app.roiSelector1.Value;
            if app.roiOnly.Value
                % Just checking validity of this ROI
                if any(app.acqInclusion{croi,2}==aiacq)
                    alreadyIncluded = errordlg('this acquisition was already added!');
                    uiwait(alreadyIncluded);
                    return
                end
                addTempData(app,croi); % Add this ROIs tempData to internal data
            else
                indexToAdd = cellfun(@(c) ~any(c==aiacq), app.acqInclusion(:,2), 'uni', 1); % Index of rois without this acquisition
                if ~any(indexToAdd)
                    alreadyIncluded = errordlg('this acquisition was already added in every ROI!');
                    uiwait(alreadyIncluded);
                    return
                end
                % Add for every ROI that is still missing this acquisition
                for croi = find(indexToAdd(:)')
                    addTempData(app,croi);
                end
            end
            
            % Add to phys if not present regardless of ROI only
            if ~any(app.pacqInclusion{2}==aiacq)
                pIdx = length(app.pacqInclusion{2})+1;
                checkPhysAndState = [size(app.pdata,2)~=pIdx-1 numel(app.stateData)~=pIdx-1];
                if any(checkPhysAndState)
                    output = {'physData','stateData';checkPhysAndState(1),checkPhysAndState(2)};
                    disp(output);
                    error(['phys inclusion list not consistent with physdata or state data.\n',...
                        'Note that acquisition already added to imaging, you should exit without saving and figure out why that happened.']);
                end
                app.pacqInclusion{2}(pIdx)=aiacq;
                app.pdata(:,pIdx) = app.tempPhys;
                app.pavg = mean(app.pdata,2);
                app.stateData(pIdx) = app.tempState;
            end
            
            % Add TIF Data if not present
            if ~any(app.tifAcqList==aiacq)
                tifIdx = length(app.tifAcqList)+1;
                
                % Validate the size of tifData
                if size(app.tifData,1)~=tifIdx-1
                    error(['tifInclusionList not consistent with tifData.\n',...
                        'Note that acquisition already added to phys and imaging, you should exit without saving and figure out why that happened.']);
                end
                
                % Add Data
                app.tifAcqList(tifIdx) = aiacq;
                app.tifData{tifIdx,1,1} = fixFrame(app,double(app.tempTif{1}(:,:,1:3:end))); % Frame - Green
                app.tifData{tifIdx,1,2} = fixFrame(app,double(app.tempTif{1}(:,:,2:3:end))); % Frame - Red
                app.tifData{tifIdx,2,1} = fixFrame(app,double(app.tempTif{2}(:,:,1:3:end))); % Linescan - Green
                app.tifData{tifIdx,2,2} = fixFrame(app,double(app.tempTif{2}(:,:,2:3:end))); % Linescan - Red
            end
            
            roiSelectorCallback(app); % this turns app.validTemp off
            plotTrialsButtonPushed(app); 
            app.acqlist.Value = length(app.acqlist.Items);
            acqlistValueChanged(app,1);
            app.needUpdates = 1;
            app.exitAndSaveButton.Enable = 'on';
        end

        % Button pushed function: plotacq
        function plotacqButtonPushed(app, event)
            if app.avginANum.Value==0, badUse = errordlg('To plot acquisition, a valid acquisition number must be entered in the edit box'); uiwait(badUse); end
            if app.validTemp && app.avginANum.Value==app.tempAcqNum, return; end % This will do nothing except take time
            
            app.validTemp = 0; % Assume we'll fail until we succeed
            loadTempData(app); % Load new temp data into app.temp properties (toggles app.validTemp if successfull)
            if ~app.validTemp, return; end % If we could load temp, don't do anything else
            plotTempData(app);
            plotTempTif(app);
            
            % Indicate that we aren't plotting a specific ROI
            app.acqlist.FontColor = [0.5 0.5 0.5]; 
            app.plotTrials.FontColor = 'k';
            app.roiSelector1.FontColor = 'k';
            app.roiSelector2.FontColor = 'k';
            
            % Indicate that we're looking at a new acq
            app.acqlist.Items = [app.acqlist.Items, sprintf('new acq: %d',app.tempAcqNum)];
            app.acqlist.ItemsData = 1:length(app.acqlist.Items);
            app.acqlist.Value = length(app.acqlist.Items);
        end

        % Button pushed function: updateROI
        function updateROIButtonPushed(app, event)
            % Indicate that we're updating ROI
            app.updateROI.Text = 'updating...';
            newROI = acquireNewROI(app);
            app.updateROI.Text = 'update ROI';
            if isempty(newROI)
                failROI = errordlg('newROI was not valid, aborting...');
                uiwait(failROI);
                return
            end
            
            croi = app.roiSelector2.Value; % Use roiSelector2 because this one can be independent of the one in plotManager
            if app.validTemp
                if app.propagateROI.Value, fprintf(1,'Note: ignoring propagate value since we''re updating ROI on new acq.\n'); end
                % Get PMT Offsets
                pmtOffsets = [app.tempState.acq.pmtOffsetChannel1 app.tempState.acq.pmtOffsetChannel2];
                pmtOffsets = pmtOffsets * app.tempState.acq.binFactor;
                
                % Assumptions based on what I've always done
                % Baseline from 1:50 & G/Rbase and R/Rbase
                tempGreenTif = double(fixFrame(app,app.tempTif{2}(:,:,1:3:end)));
                tempRedTif = double(fixFrame(app,app.tempTif{2}(:,:,2:3:end)));
                
                % Update data and ROI info
                newGreen = mean(tempGreenTif(:,newROI(1):newROI(2))./pmtOffsets(1),2);
                newRed = mean(tempRedTif(:,newROI(1):newROI(2))./pmtOffsets(2),2);
                rBase = mean(newRed(1:50));
                app.tempGreen(:,croi) = newGreen/rBase;
                app.tempRed(:,croi) = newRed/rBase;
                app.tempROI{croi} = newROI;
                app.tempNewROI{croi} = newROI;
                
                % Plot new data and tif (with corrected ROI) 
                plotTempData(app);
                plotTempTif(app);
                
            elseif app.propagateROI.Value
                for na = 1:length(app.acqInclusion{croi,2})
                    updateROIData(app,na,croi,newROI); % Update for all acquisitions of this ROI
                end
            else
                updateROIData(app,app.acqlist.Value,croi,newROI); % Update just this acquisition
            end
            
            % Replot new data
            if app.validTemp
                plotTempData(app);
                plotTempTif(app);
            else
                plotTrialsButtonPushed(app);
                plotTif(app);
                % Enable saving if updated ROI is in current average
                app.needUpdates = 1; 
                app.exitAndSaveButton.Enable = 'on';
            end
            figure(app.UIFigure); % Go back to dmi2 figure
        end

        % Button pushed function: showsButton
        function showsButtonPushed(app, event)
            showUpdatesFigure(app,0); % Plot updates figure, indicate that it isn't the last update
        end

        % Button pushed function: exitAndSaveButton
        function exitAndSaveButtonPushed(app, event)
            app.UIFigure.Visible = 'off';
            showUpdatesFigure(app,1); % Plot updates figure, indicate that this is the last update
            
            % avgin for phys
            aiPhysIdx = app.pacqInclusion{2}(~ismember(app.pacqInclusion{2},app.pacqInclusion{1}));
            for ai = aiPhysIdx(:)'
                acqName = sprintf('AD0_%d',ai);
                avgName = sprintf('AD0_e%dp%davg',app.epoch,app.pulse);
                loadWaveo(fullfile(app.fpath,sprintf('%s.mat',acqName)));
                loadWaveo(fullfile(app.fpath,sprintf('%s.mat',avgName)));
                evalin('base', sprintf('avgin(''%s'',''%s'');',acqName,avgName));
                evalin('base', sprintf('save(''%s'',''%s'');',fullfile(app.fpath,avgName),avgName));
                clearvars('-global',acqName,avgName);
            end
            
            % avgout for phys
            aoPhysIdx = app.pacqInclusion{1}(~ismember(app.pacqInclusion{1},app.pacqInclusion{2}));
            for ao = aoPhysIdx(:)'
                acqName = sprintf('AD0_%d',ao);
                avgName = sprintf('AD0_e%dp%davg',app.epoch,app.pulse);
                loadWaveo(fullfile(app.fpath,sprintf('%s.mat',acqName)));
                loadWaveo(fullfile(app.fpath,sprintf('%s.mat',avgName)));
                evalin('base', sprintf('avgout(''%s'',''%s'');',acqName,avgName));
                evalin('base', sprintf('save(''%s'',''%s'');',fullfile(app.fpath,avgName),avgName));
                clearvars('-global',acqName,avgName);
            end
            
            for nr = 1:size(app.gavg,2)
                % avgin for imaging
                aiImagIdx = app.acqInclusion{nr,2}(~ismember(app.acqInclusion{nr,2},app.acqInclusion{nr,1}));
                for ai = aiImagIdx(:)'
                    for channel = [1 2]
                        acqName = sprintf('c%dr%d_%d',channel,nr,ai);
                        avgName = sprintf('e%dp%dc%dr%d_avg',app.epoch,app.pulse,channel,nr);
                        loadWaveo(fullfile(app.fpath,sprintf('%s.mat',acqName)));
                        loadWaveo(fullfile(app.fpath,sprintf('%s.mat',avgName)));
                        evalin('base', sprintf('avgin(''%s'',''%s'');',acqName,avgName));
                        evalin('base', sprintf('save(''%s'',''%s'');',fullfile(app.fpath,avgName),avgName));
                        clearvars('-global',acqName,avgName);
                    end
                end
                % avgout for imaging
                aoImagIdx = app.acqInclusion{nr,1}(~ismember(app.acqInclusion{nr,1},app.acqInclusion{nr,2}));
                for ao = aoImagIdx(:)'
                    for channel = [1 2]
                        acqName = sprintf('c%dr%d_%d',channel,nr,ao);
                        avgName = sprintf('e%dp%dc%dr%d_avg',app.epoch,app.pulse,channel,nr);
                        loadWaveo(fullfile(app.fpath,sprintf('%s.mat',acqName)));
                        loadWaveo(fullfile(app.fpath,sprintf('%s.mat',avgName)));
                        evalin('base', sprintf('avgout(''%s'',''%s'');',acqName,avgName));
                        evalin('base', sprintf('save(''%s'',''%s'');',fullfile(app.fpath,avgName),avgName));
                        clearvars('-global',acqName,avgName);
                    end
                end
                
                % update rois for imaging
                roiIdx = find(all(~isnan(app.roiUpdates{nr}),2));
                for cacq = roiIdx(:)'
                    cacqNum = app.acqInclusion{nr,2}(cacq);
                    pIdx = app.pacqInclusion{2}==cacqNum;
                    tIdx = app.tifAcqList==cacqNum;
                    newROI = app.roiUpdates{nr}(cacq,:);
                    
                    pmtOffsets = [app.stateData(pIdx).acq.pmtOffsetChannel1 app.stateData(pIdx).acq.pmtOffsetChannel2];
                    pmtOffsets = pmtOffsets * app.stateData(pIdx).acq.binFactor;
                    
                    % Assume baseline 1:50 and G/R, R/R
                    rBase =  mean(mean(app.tifData{tIdx,2,2}(1:50,newROI(1):newROI(2))-pmtOffsets(2),2),1);
                    newGreen = mean(app.tifData{tIdx,2,1}(:,newROI(1):newROI(2))-pmtOffsets(1),2)/rBase;
                    newRed = mean(app.tifData{tIdx,2,2}(:,newROI(1):newROI(2))-pmtOffsets(2),2)/rBase;
                    newData = {newGreen,newRed};
                    
                    for channel = [1 2]
                        acqName = sprintf('c%dr%d_%d',channel,nr,cacqNum);
                        avgName = sprintf('e%dp%dc%dr%d_avg',app.epoch,app.pulse,channel,nr);
                        loadWaveo(fullfile(app.fpath,sprintf('%s.mat',acqName)));
                        loadWaveo(fullfile(app.fpath,sprintf('%s.mat',avgName)));
                        
                        evalin('base', sprintf('avgout(''%s'',''%s'');',acqName,avgName)); % Remove acquisition with bad ROI from average
                        eval(sprintf('global %s',acqName)); % Bring it here
                        setWave(acqName,'data',newData{channel}(:)'); % Set new data
                        eval(sprintf('%s.UserData.ROIDef = [%d %d];',acqName,newROI(1),newROI(2))); % Update ROI
                        save(fullfile(app.fpath,acqName),acqName); % Save acquisition
                        
                        evalin('base',sprintf('avgin(''%s'',''%s'');',acqName,avgName));
                        evalin('base', sprintf('save(''%s'',''%s'');',fullfile(app.fpath,avgName),avgName));
                        
                        clearvars('-global',acqName,avgName);
                    end
                end
            end

            if ishandle(app.showDeltaHandle), figure(app.showDeltaHandle); end % In if statement in case user deletes it immediately
            delete(app);
        end

        % Close request function: UIFigure
        function UIFigureCloseRequest(app, event)
            if ~app.needUpdates
                if ishandle(app.showDeltaHandle), delete(app.showDeltaHandle); end
                delete(app);
                commandwindow;
                return
            end
            
            userAnswer = questdlg('Save changes?','!!!','Yes','No','Cancel','Yes');
            if strcmp(userAnswer,'Cancel')
                figure(app.UIFigure);
                return
            elseif strcmp(userAnswer,'Yes')
                exitAndSaveButtonPushed(app);
                return
            end
            
            if ishandle(app.showDeltaHandle), delete(app.showDeltaHandle); end
            commandwindow;
            delete(app);
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 600 1324 591];
            app.UIFigure.Name = 'UI Figure';
            app.UIFigure.CloseRequestFcn = createCallbackFcn(app, @UIFigureCloseRequest, true);

            % Create redData
            app.redData = uiaxes(app.UIFigure);
            title(app.redData, 'red data')
            xlabel(app.redData, 'time (ms)')
            ylabel(app.redData, '')
            app.redData.Position = [405 1 380 294];

            % Create tif
            app.tif = uiaxes(app.UIFigure);
            title(app.tif, 'tif')
            xlabel(app.tif, '')
            ylabel(app.tif, '')
            app.tif.XTick = [];
            app.tif.YTick = [];
            app.tif.Position = [793 26 532 554];

            % Create greenData
            app.greenData = uiaxes(app.UIFigure);
            title(app.greenData, 'green data')
            xlabel(app.greenData, '')
            ylabel(app.greenData, '')
            app.greenData.Position = [405 298 380 294];

            % Create plotManager
            app.plotManager = uipanel(app.UIFigure);
            app.plotManager.TitlePosition = 'centertop';
            app.plotManager.Title = 'plot manager';
            app.plotManager.FontWeight = 'bold';
            app.plotManager.FontSize = 16;
            app.plotManager.Position = [1 436 396 93];

            % Create roiSelector1
            app.roiSelector1 = uidropdown(app.plotManager);
            app.roiSelector1.Items = {'roi 1', 'roi 2'};
            app.roiSelector1.ValueChangedFcn = createCallbackFcn(app, @roiSelector1ValueChanged, true);
            app.roiSelector1.Tooltip = {'select ROI to plot'; ' perform avgout/avgin operations'; ' and update ROIs'; 'color of text follows ROI selected and indicated on tif'};
            app.roiSelector1.Position = [240 39 78 22];
            app.roiSelector1.Value = 'roi 1';

            % Create plotAverage
            app.plotAverage = uibutton(app.plotManager, 'push');
            app.plotAverage.ButtonPushedFcn = createCallbackFcn(app, @plotAverageButtonPushed, true);
            app.plotAverage.Tooltip = {'plot average data for selected ROI'};
            app.plotAverage.Position = [57 39 88 22];
            app.plotAverage.Text = 'plot average';

            % Create plotTrials
            app.plotTrials = uibutton(app.plotManager, 'push');
            app.plotTrials.ButtonPushedFcn = createCallbackFcn(app, @plotTrialsButtonPushed, true);
            app.plotTrials.Tooltip = {'plot trials for selected ROI with current acquisition highlighted'};
            app.plotTrials.Position = [148 39 59 22];
            app.plotTrials.Text = 'plot trials';

            % Create plotInputs
            app.plotInputs = uibutton(app.plotManager, 'push');
            app.plotInputs.Enable = 'off';
            app.plotInputs.Tooltip = {'plot inputs (independent variables) for current average -- disabled until new functionality exists in scanImage'};
            app.plotInputs.Position = [324 39 67 22];
            app.plotInputs.Text = 'plot inputs';

            % Create SCANSLabel
            app.SCANSLabel = uilabel(app.plotManager);
            app.SCANSLabel.FontWeight = 'bold';
            app.SCANSLabel.Position = [8 39 50 22];
            app.SCANSLabel.Text = 'SCANS:';

            % Create TIFLabel
            app.TIFLabel = uilabel(app.plotManager);
            app.TIFLabel.FontWeight = 'bold';
            app.TIFLabel.Position = [31 9 27 22];
            app.TIFLabel.Text = 'TIF:';

            % Create tifChannel
            app.tifChannel = uidropdown(app.plotManager);
            app.tifChannel.Items = {'green', 'red'};
            app.tifChannel.ValueChangedFcn = createCallbackFcn(app, @tifChannelValueChanged, true);
            app.tifChannel.Tooltip = {'select which color channel to plot tif'};
            app.tifChannel.Position = [57 9 88 22];
            app.tifChannel.Value = 'green';

            % Create tifType
            app.tifType = uidropdown(app.plotManager);
            app.tifType.Items = {'frame', 'linescan'};
            app.tifType.ValueChangedFcn = createCallbackFcn(app, @tifTypeValueChanged, true);
            app.tifType.Tooltip = {'"frame" plots tif collected in previous acquisition'; ' "linescan" plots tif collected in current acquisition'};
            app.tifType.Position = [148 9 88 22];
            app.tifType.Value = 'frame';

            % Create downsampleEditFieldLabel
            app.downsampleEditFieldLabel = uilabel(app.plotManager);
            app.downsampleEditFieldLabel.HorizontalAlignment = 'right';
            app.downsampleEditFieldLabel.FontSize = 10;
            app.downsampleEditFieldLabel.Enable = 'off';
            app.downsampleEditFieldLabel.Position = [298 68 66 22];
            app.downsampleEditFieldLabel.Text = 'downsample:';

            % Create downsampleFactor
            app.downsampleFactor = uieditfield(app.plotManager, 'numeric');
            app.downsampleFactor.UpperLimitInclusive = 'off';
            app.downsampleFactor.Limits = [1 Inf];
            app.downsampleFactor.Editable = 'off';
            app.downsampleFactor.Enable = 'off';
            app.downsampleFactor.Tooltip = {'optional- downsamples data in phys'; ' green'; ' and red'};
            app.downsampleFactor.Position = [367 72 25 17];
            app.downsampleFactor.Value = 1;

            % Create maxTrialsPlot
            app.maxTrialsPlot = uieditfield(app.plotManager, 'numeric');
            app.maxTrialsPlot.UpperLimitInclusive = 'off';
            app.maxTrialsPlot.Limits = [0 Inf];
            app.maxTrialsPlot.RoundFractionalValues = 'on';
            app.maxTrialsPlot.Tooltip = {'limit of number of trials to plot if plotTrials button selected - reduces clutter'};
            app.maxTrialsPlot.Position = [212 39 24 22];
            app.maxTrialsPlot.Value = 10;

            % Create gmaxEditFieldLabel
            app.gmaxEditFieldLabel = uilabel(app.plotManager);
            app.gmaxEditFieldLabel.HorizontalAlignment = 'right';
            app.gmaxEditFieldLabel.Position = [323 9 39 22];
            app.gmaxEditFieldLabel.Text = 'gmax:';

            % Create gmax
            app.gmax = uieditfield(app.plotManager, 'numeric');
            app.gmax.Limits = [0 Inf];
            app.gmax.Tooltip = {'gmax: optional field'; ' if >0 then green data divided by value'};
            app.gmax.Position = [364 9 27 22];

            % Create holdLUT
            app.holdLUT = uicheckbox(app.plotManager);
            app.holdLUT.Tooltip = {'if checked the relative lookup table values will stay the same upon plotting new tifs'; ''};
            app.holdLUT.Text = 'hold LUT';
            app.holdLUT.Position = [240 9 71 22];
            app.holdLUT.Value = true;

            % Create acquisitions
            app.acquisitions = uibuttongroup(app.UIFigure);
            app.acquisitions.TitlePosition = 'centertop';
            app.acquisitions.Title = 'acquisitions';
            app.acquisitions.FontWeight = 'bold';
            app.acquisitions.FontSize = 16;
            app.acquisitions.Position = [1 290 167 144];

            % Create acqlist
            app.acqlist = uilistbox(app.acquisitions);
            app.acqlist.Items = {'acquisitions'};
            app.acqlist.ValueChangedFcn = createCallbackFcn(app, @acqlistValueChanged, true);
            app.acqlist.Tooltip = {'select acquisition to highlight from current ROI'; ' enables avgout of that acquisition'; 'color of text follows ROI selected and indicated on tif'};
            app.acqlist.FontColor = [0 0 1];
            app.acqlist.Position = [6 5 158 57];
            app.acqlist.Value = 'acquisitions';

            % Create avgout
            app.avgout = uibutton(app.acquisitions, 'push');
            app.avgout.ButtonPushedFcn = createCallbackFcn(app, @avgoutButtonPushed, true);
            app.avgout.Tooltip = {'avgout currently selected acquisition'};
            app.avgout.Position = [5 92 47 22];
            app.avgout.Text = 'avgout';

            % Create plotacq
            app.plotacq = uibutton(app.acquisitions, 'push');
            app.plotacq.ButtonPushedFcn = createCallbackFcn(app, @plotacqButtonPushed, true);
            app.plotacq.Tooltip = {'plot new acquisition from current folder defined by textbox to the right'};
            app.plotacq.Position = [5 66 59 22];
            app.plotacq.Text = 'plot acq';

            % Create avginbutton
            app.avginbutton = uibutton(app.acquisitions, 'push');
            app.avginbutton.ButtonPushedFcn = createCallbackFcn(app, @avginbuttonButtonPushed, true);
            app.avginbutton.Tooltip = {'avgin newly plotted acquisition- only enabled if that acquisition is currently being plotted'};
            app.avginbutton.Position = [55 92 44 22];
            app.avginbutton.Text = 'avgin';

            % Create avginANum
            app.avginANum = uieditfield(app.acquisitions, 'numeric');
            app.avginANum.Limits = [0 Inf];
            app.avginANum.Tooltip = {'type acquisition number then press plot acq to plot that acquisitions data'};
            app.avginANum.Position = [67 66 30 22];

            % Create roiOnly
            app.roiOnly = uicheckbox(app.acquisitions);
            app.roiOnly.Tooltip = {'if checked'; ' avgout and avgin will only do so for the selected roi'};
            app.roiOnly.Text = 'roi only';
            app.roiOnly.FontWeight = 'bold';
            app.roiOnly.FontColor = [1 0 0];
            app.roiOnly.Position = [103 66 64 22];

            % Create showsButton
            app.showsButton = uibutton(app.acquisitions, 'push');
            app.showsButton.ButtonPushedFcn = createCallbackFcn(app, @showsButtonPushed, true);
            app.showsButton.Tooltip = {'make new figure that shows all changes you''ve made'};
            app.showsButton.Position = [102 92 60 22];
            app.showsButton.Text = 'show ?s';

            % Create tifLUT
            app.tifLUT = uipanel(app.UIFigure);
            app.tifLUT.TitlePosition = 'centertop';
            app.tifLUT.Title = 'tif lookup table';
            app.tifLUT.BackgroundColor = [1 1 1];
            app.tifLUT.FontWeight = 'bold';
            app.tifLUT.FontSize = 16;
            app.tifLUT.Position = [170 356 227 78];

            % Create minLUT
            app.minLUT = uislider(app.tifLUT);
            app.minLUT.Limits = [0 1];
            app.minLUT.MajorTicks = [];
            app.minLUT.ValueChangedFcn = createCallbackFcn(app, @minLUTValueChanging, true);
            app.minLUT.ValueChangingFcn = createCallbackFcn(app, @minLUTValueChanging, true);
            app.minLUT.Position = [14 35 200 3];

            % Create maxLUT
            app.maxLUT = uislider(app.tifLUT);
            app.maxLUT.Limits = [0 1];
            app.maxLUT.MajorTicks = [];
            app.maxLUT.ValueChangedFcn = createCallbackFcn(app, @maxLUTValueChanging, true);
            app.maxLUT.ValueChangingFcn = createCallbackFcn(app, @maxLUTValueChanging, true);
            app.maxLUT.MinorTicks = [];
            app.maxLUT.Position = [14 14 200 3];
            app.maxLUT.Value = 1;

            % Create roiAnalyzer
            app.roiAnalyzer = uipanel(app.UIFigure);
            app.roiAnalyzer.TitlePosition = 'centertop';
            app.roiAnalyzer.Title = 'roi analyzer';
            app.roiAnalyzer.FontWeight = 'bold';
            app.roiAnalyzer.FontSize = 16;
            app.roiAnalyzer.Position = [170 290 227 62];

            % Create roiSelector2
            app.roiSelector2 = uidropdown(app.roiAnalyzer);
            app.roiSelector2.Items = {'roi 1', 'roi 2'};
            app.roiSelector2.ItemsData = {'1', '2', ''};
            app.roiSelector2.ValueChangedFcn = createCallbackFcn(app, @roiSelector2ValueChanged, true);
            app.roiSelector2.Tooltip = {'this dropdown indicates which ROI to update with updateROI button '; 'color of text follows ROI selected and indicated on tif'};
            app.roiSelector2.Position = [4 8 63 22];
            app.roiSelector2.Value = '1';

            % Create updateROI
            app.updateROI = uibutton(app.roiAnalyzer, 'push');
            app.updateROI.ButtonPushedFcn = createCallbackFcn(app, @updateROIButtonPushed, true);
            app.updateROI.Tooltip = {'interactive ROI updater- select new ROI on current tif'};
            app.updateROI.Position = [70 8 76 22];
            app.updateROI.Text = 'update ROI';

            % Create propagateROI
            app.propagateROI = uicheckbox(app.roiAnalyzer);
            app.propagateROI.Tooltip = {'update ROI definition for every acquisition of this ROI'; ' this field ignored if updating ROI of new acquisition'};
            app.propagateROI.Text = 'propagate';
            app.propagateROI.Position = [149 8 77 22];

            % Create physData
            app.physData = uiaxes(app.UIFigure);
            title(app.physData, 'phys data')
            xlabel(app.physData, 'time (ms)')
            ylabel(app.physData, '')
            app.physData.Position = [1 1 396 282];

            % Create averageName
            app.averageName = uieditfield(app.UIFigure, 'text');
            app.averageName.Editable = 'off';
            app.averageName.HorizontalAlignment = 'center';
            app.averageName.Position = [7 563 386 22];
            app.averageName.Value = 'average name';

            % Create exitAndSaveButton
            app.exitAndSaveButton = uibutton(app.UIFigure, 'push');
            app.exitAndSaveButton.ButtonPushedFcn = createCallbackFcn(app, @exitAndSaveButtonPushed, true);
            app.exitAndSaveButton.FontColor = [1 0 0];
            app.exitAndSaveButton.Enable = 'off';
            app.exitAndSaveButton.Tooltip = {'perform avgin avgout and ROI updates on saved data'; 'enabled when updates have been made'};
            app.exitAndSaveButton.Position = [7 536 386 22];
            app.exitAndSaveButton.Text = 'exit and save';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = dmi(varargin)

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @(app)startupFcn(app, varargin{:}))

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end