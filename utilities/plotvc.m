function handle = plotvc(t,data,fig,specs,pointFlag)
% plots data by columns and varys color with varycolor

if nargin == 1
    data = t;
    t = 1:size(data,1);
end

if size(data,2) == length(t) && size(data,1)~=1 && size(data,1)~=length(t)
    data = data';
end

if (nargin > 4) && pointFlag
    if ~isvector(data)
        error('if points flag is on then data must be a vector');
    end
    NC = length(data); 
else
    NC = size(data,2);
end
cmap = varycolor(NC);

if (nargin < 3)
    fig = [];
end

specFlag = 0;
if (nargin >= 4) && ~isempty(specFlag)
    specFlag = 1;
    idxNumeric = cellfun(@isnumeric, specs, 'uni', 1);
    specs(idxNumeric) = cellfun(@num2str,specs(idxNumeric),'uni',0);
    specs = cellfun(@(s) strcat(',',s), specs, 'uni',0);
    specs = cat(2, specs{:});
end

if isempty(fig)
    handle = figure;
else
    handle = figure(fig);
end

hold on;
for c = 1:NC
    if specFlag
        if (nargin > 4) && pointFlag
            cmd = sprintf('plot(t(c),data(c),''color'',cmap(c,:)%s);',specs);
        else
            cmd = sprintf('plot(t,data(:,c),''color'',cmap(c,:)%s);',specs);
        end
        eval(cmd);
    else
        if (nargin > 4) && pointFlag
            plot(t(c),data(c),'color',cmap(c,:));
        else
            plot(t,data(:,c),'color',cmap(c,:));
        end
    end
end

if (nargout == 0)
    clear handle
end


%% --- uses this ---
function ColorSet=varycolor(NumberOfPlots)
% VARYCOLOR Produces colors with maximum variation on plots with multiple
% lines.
%
%     VARYCOLOR(X) returns a matrix of dimension X by 3.  The matrix may be
%     used in conjunction with the plot command option 'color' to vary the
%     color of lines.  
%
%     Yellow and White colors were not used because of their poor
%     translation to presentations.
% 
%     Example Usage:
%         NumberOfPlots=50;
%
%         ColorSet=varycolor(NumberOfPlots);
% 
%         figure
%         hold on;
% 
%         for m=1:NumberOfPlots
%             plot(ones(20,1)*m,'Color',ColorSet(m,:))
%         end

%Created by Daniel Helmick 8/12/2008


%Take care of the anomolies
if NumberOfPlots<1
    ColorSet=[];
elseif NumberOfPlots==1
    ColorSet=[0 1 0];
elseif NumberOfPlots==2
    ColorSet=[0 1 0; 0 1 1];
elseif NumberOfPlots==3
    ColorSet=[0 1 0; 0 1 1; 0 0 1];
elseif NumberOfPlots==4
    ColorSet=[0 1 0; 0 1 1; 0 0 1; 1 0 1];
elseif NumberOfPlots==5
    ColorSet=[0 1 0; 0 1 1; 0 0 1; 1 0 1; 1 0 0];
elseif NumberOfPlots==6
    ColorSet=[0 1 0; 0 1 1; 0 0 1; 1 0 1; 1 0 0; 0 0 0];

else %default and where this function has an actual advantage

    %we have 5 segments to distribute the plots
    EachSec=floor(NumberOfPlots/5); 
    
    %how many extra lines are there? 
    ExtraPlots=mod(NumberOfPlots,5); 
    
    %initialize our vector
    ColorSet=zeros(NumberOfPlots,3);
    
    %This is to deal with the extra plots that don't fit nicely into the
    %segments
    Adjust=zeros(1,5);
    for m=1:ExtraPlots
        Adjust(m)=1;
    end
    
    SecOne   =EachSec+Adjust(1);
    SecTwo   =EachSec+Adjust(2);
    SecThree =EachSec+Adjust(3);
    SecFour  =EachSec+Adjust(4);
    SecFive  =EachSec;

    for m=1:SecOne
        ColorSet(m,:)=[0 1 (m-1)/(SecOne-1)];
    end

    for m=1:SecTwo
        ColorSet(m+SecOne,:)=[0 (SecTwo-m)/(SecTwo) 1];
    end
    
    for m=1:SecThree
        ColorSet(m+SecOne+SecTwo,:)=[(m)/(SecThree) 0 1];
    end
    
    for m=1:SecFour
        ColorSet(m+SecOne+SecTwo+SecThree,:)=[1 0 (SecFour-m)/(SecFour)];
    end

    for m=1:SecFive
        ColorSet(m+SecOne+SecTwo+SecThree+SecFour,:)=[(SecFive-m)/(SecFive) 0 0];
    end
    
end

    


