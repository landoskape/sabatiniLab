function saveCell()

global meta state data exp

if any([isempty(meta) isempty(state) isempty(data) isempty(exp)])
    error('Experimental variables are not present. Finish analyze script.');
end

save(fullfile(meta.dpath,'xfiles.mat'),'meta','state','data','exp');

fprintf(1,'Cell xFiles saved in: %s.\n',meta.dpath);
