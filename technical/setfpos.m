function setfpos(pos,fig)
% setfpos(pos,fig)
%
% This just calls the following line:
% set(fig,'units','normalized','outerposition',pos)

if nargin<2
    fig = gcf;
end
set(fig,'units','normalized','outerposition',pos);
