function compileData
% This function will compile the data and state structures returned from
% the retrieveData function. There are associated GUIs that allow you to
% look at the data and say if it is good etc. 

global meta
global state
global data
global exp
global gh

% ---
% loop through epochs and ask the user what kind of file it is
% ---

for e = 1:meta.NE
    % Retrieve data specific to this epoch
    edata = getEpoch(data, e);
    
    % Get indices for physiology / imaging acquisitions
    phidx = ([edata(:).ph] == 1); 
    imidx = ([edata(:).im] == 1); 
    
    % Physiology
    if sum(phidx)>0
        plotpavg = 1; % Can averages be plotted?
        pconsist = 1; % Same kind of recording?
        if (std(cellfun(@length, {edata(phidx).pt}, 'uni', 1)) ~= 0), plotpavg = 0; end
        if (std([edata(phidx).pmode]) ~= 0), pconsist = 0; end
        
        if plotpavg && pconsist
            ptime = edata(find(phidx,1)).pt; % Time vector for physiology
            pdata = cat(1, edata(phidx).pdata); % Phys data
            pavg = mean(pdata,1); % Physiology average
        elseif plotpavg
            ptime = edata(find(phidx,1)).pt; % Time vector for physiology
            pdata = cat(1, edata(phidx).pdata); % Phys data
        else
            ptime = {edata(phidx).pt};
            pdata = {edata(phidx).pdata};
        end
    end
    
    % Imaging
    if sum(imidx)>0
        plotiavg = 1; % Can averages be plotted?
        iconsist = 1; % Same channels/ROIs?
        
        ich = cellfun(@(s) size(s,1), {edata(imidx).idata}, 'uni', 1); % Channels in imaging
        irg = cellfun(@(s) size(s,3), {edata(imidx).idata}, 'uni', 1); % ROIs in imaging
        if (std(cellfun(@length, {edata(imidx).it}, 'uni', 1)) ~= 0), plotiavg = 0; end
        if (std(ich) ~= 0) || (std(irg) ~= 0), iconsist = 0; end % Channels/ROIs consistent
    
        if plotiavg && iconsist
            itime = edata(find(imidx,1)).it;
            idata = cat(4, edata(imidx).idata);
            iavg = mean(idata,4);
            ich = max(ich);
            irg = max(irg);
        elseif iconsist
            ich = max(ich);
            irg = max(irg);
            itime = {edata(imidx).it};
            idata = {edata(imidx).idata};
        end
    end
    
    % Plot physiology
    if plotpavg && pconsist
        gh.physFig = figure(1); clf;
        set(gcf,'units','normalized','outerposition',[0    0.2675    0.5000    0.7037]);
        hold on;
        plot(ptime, pdata, 'color', [0.7 0.7 0.7],'linewidth',0.5);
        plot(ptime, pavg, 'color','k','linewidth',2);
    elseif pconsist
        gh.physFig = figure(1); clf;
        set(gcf,'units','normalized','outerposition',[0    0.2675    0.5000    0.7037]);
        hold on; 
        for p = 1:length(pdata)
            plot(ptime{p}, pdata{p}, 'color', [0.5 0.5 0.5], 'linewidth',0.5);
        end
    elseif plotpavg
        gh.physFig = figure(1); clf; 
        set(gcf,'units','normalized','outerposition',[0    0.2675    0.5000    0.7037]);
        hold on; 
        
        ccidx = ([edata(:).pmode] == 1);
        subplot(2,1,1);
        hold on;
        plot(ptime, pdata(ccidx,:), 'color', [0.5 0.5 0.5], 'linewidth',0.5);
        plot(ptime, mean(pdata(ccidx,:),1), 'color','k','linewidth',2);
        ylabel('Current Clamp');
        
        vcidx = ([edata(:).pmode] == 0);
        subplot(2,1,1);
        hold on;
        plot(ptime, pdata(vcidx,:), 'color', [0.5 0.5 0.5], 'linewidth',0.5);
        plot(ptime, mean(pdata(vcidx,:),1), 'color','k','linewidth',2);
        ylabel('Voltage Clamp');
    end
    
    % Plot imaging
    if plotiavg && iconsist
        gh.imagFig = figure(2); clf;
        set(gcf,'units','normalized','outerposition',[0.5000    0.3312    0.5000    0.7037]);
        for r = 1:irg
            for c = 1:ich
                subplot(irg,ich, 2*(r-1)+c);
                hold on;
                plot(itime, squeeze(idata(c,:,r,:)), 'color', [0.7 0.7 0.7], 'linewidth',0.5);
                plot(itime, iavg(c,:,r), 'color','k','linewidth', 2);
                
                % Labels
                if (c == 1) && (r == 1), title('Channel 1'); ylabel('ROI 1'); end
                if (c == 1) && (r == 2), ylabel('ROI 2'); end
                if (r == 1) && (c == 2), title('Channel 2'); end
            end
        end
    elseif iconsist
        gh.imagFig = figure(2); clf;
        set(gcf,'units','normalized','outerposition',[0.5000    0.3312    0.5000    0.7037]);
        for i = 1:length(idata)
            for r = 1:irg
                for c = 1:ich
                    subplot(irg,ich, 2*(r-1)+c);
                    hold on;
                    plot(itime{i}, squeeze(idata{i}(c,:,r)), 'color', [0.7 0.7 0.7], 'linewidth',0.2);

                    % Labels
                    if (c == 1) && (r == 1), title('Channel 1'); ylabel('ROI 1'); end
                    if (c == 1) && (r == 2), ylabel('ROI 2'); end
                    if (r == 1) && (c == 2), title('Channel 2'); end
                end
            end
        end
    end
    
    meta.phys = (sum(phidx)>0);
    meta.imag = (sum(imidx)>0);
    epipe.selectionGui;
    
    
    
 














