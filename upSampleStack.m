function out = upSampleStack(in,oldZoom,newZoom)

if size(in,1)~=size(in,2), error('in stack wasn''t square!'); end
if newZoom < oldZoom, error('newZoom has to be higher number, can''t fake data!'); end
if mod(newZoom/oldZoom,1)~=0, error('newZoom has to be integer multiple of oldZoom'); end

oldDim = size(in,1);
ratio = newZoom/oldZoom;
newDim = oldDim * ratio;

inClass = class(in);
in = double(in);
out = zeros(newDim);

for d = 1:oldDim
    newIdx = 2*(d-1)+1;
    out(:,newIdx) = interp1(1:oldDim,in(:,d),linspace(1,oldDim,newDim));
end
out(:,end) = out(:,end-1);

for d = 1:newDim
    out(d,:) = interp1(1:2:newDim,out(d,1:2:end),1:newDim);
end

out = cast(out,inClass);

