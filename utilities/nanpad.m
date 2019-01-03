function out = nanpad(in, L)
if size(in,1) == 1
    out = [in, nan(1,L-length(in))];
else
    out = [in; nan(L-length(in),1)];
end
