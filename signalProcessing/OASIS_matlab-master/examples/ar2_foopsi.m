%% test modulate for all oasis functions. 
col = {[0 114 178],[0 158 115], [213 94 0],[230 159 0],...
    [86 180 233], [204 121 167], [64 224 208], [240 228 66]}; % colors
plot_cvx = false; 

%% example 2: foopsi, AR2 model 
g = [1.7, -0.712];         % AR coefficient 
noise = 1; 
T = 300; 
framerate = 30;     
firerate = 0.2; 
b = 0;              % baseline 
N = 1;              % number of trials 
seed = 1;          % seed for genrating random variables 
[Y, trueC, trueS] = gen_data(g, noise, T, framerate, firerate, b, N, seed); 


plot(trueC)

%%


y = Y(1,:); 
true_c = trueC(1,:);  %#ok<*NASGU>
true_s = trueS(1,:); 
% case 1: all parameters are known 
lambda = 25; 
[c_oasis, s_oasis] = deconvolveCa(y, 'ar2', g, 'foopsi', 'lambda', lambda);  %#ok<*ASGLU>

figure('name', 'FOOPSI, AR2, known: g, lambda', 'papersize', [15, 4]); 
show_results; 

% case 2: know lambda
lambda = 2.5; 
[c_oasis, s_oasis, options] = deconvolveCa(y, 'ar2', 'sn', noise, 'foopsi', 'lambda',...
    lambda); 
fprintf('true gamma:        %.3f\t %.3f\n', g(1), g(2)); 
fprintf('estimated gamma:   %.3f\t %.3f\n', options.pars(1),  options.pars(2)); 

figure('name', 'FOOPSI, AR2, known:lambda, estimated: g', 'papersize', [15, 4]); 
show_results; 

%%%%%%%%%%%%%%  END %%%%%%%%%%%%%%%%%%
