function phys = compilePhys(names)
% the waves need to be loaded as global variables

NA = length(names);
phys = cell(NA,1);
for a = 1:NA
    phys{a} = getfield(names{a},'data'); %#ok stop it
end
phys = cell2mat(phys);



