function cdCell

global meta
if isempty(meta)
    clear meta
    fprintf('No cell in workspace.\n');
    return
end

cd(meta.dpath);
