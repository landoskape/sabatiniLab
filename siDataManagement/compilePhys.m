function phys = compilePhys(names)
% the waves need to be loaded as global variables

NA = length(names);
phys = cell(1,NA);
for a = 1:NA
    phys{a} = getfield(names{a},'data'); %#ok stop it
end
phys = cellfun(@(c) c(:), phys, 'uni', 0); % make sure they're all column vectors
phys = cell2mat(phys);


  

