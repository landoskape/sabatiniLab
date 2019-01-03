function fig = callFigs(type,num)

if (nargin == 0)
    fig = figure;
    clf;
    set(gcf,'units','normalized','outerposition',[0 0 1 0.9]);
    return;
end

global gh

if ischar(type)
    switch type
        case 'phys'
            if (nargin == 2)
                gh.physFig = figure(num);
            else
                gh.physFig = figure(1001);
            end
            fig = gh.physFig;
            set(gcf,'units','normalized','outerposition',[0    0.2675    0.5000    0.7037]);
        case {'imag','imaging'}
            if (nargin == 2)
                gh.imagFig = figure(num);
            else
                gh.imagFig = figure(1002);
            end
            fig = gh.imagFig;
            set(gcf,'units','normalized','outerposition',[0.5000    0.3312    0.5000    0.7037]);
    end
else
    fig = figure(type);
    clf;
    set(gcf,'units','normalized','outerposition',[0 0 1 0.9]);
end


