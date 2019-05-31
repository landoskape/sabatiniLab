function [t,y,dy] = eulerapp(ode,tspan,initState,dt,ds,outputFlag)
% [t,y,dy] = eulerapp(ode,tspan,initState,dt,ds)
% 
% t - time vector
% y - values
% dy - derivatives
%
% ode is an inline function 
% tspan is the start and end point (will truncate if not multiple of dt)
% initState is initial state of function
% dt is time step used
% ds is a downsample factor for having a highres time step but not stupidly
%    large data sizes - works simply (1:ds:end)
% outputFlag is a boolean, default 0, do we print update to screen?

if nargin<5, ds = 1; outputFlag = 1; end
if nargin<6, outputFlag = 1; end
if rem(tspan(2),dt*ds)~=0, error('time vector must be chosen perfectly'); end

t = tspan(1):dt*ds:tspan(2); % time vector
NT = length(t); % number of data points
NV = length(initState); % number of values in function

% preallocate
y = zeros(NT,NV);
dy = zeros(NT-1,NV);

% setup initial state
initState = initState(:)';
y(1,:) = initState;
tempy = initState;

if outputFlag
    % Report progress to screen
    fprintf(1,'| euclidean approximation working... ');
    msg = '';
    counter = 0;
    percentage = 10 - 9*(NT*ds>=1e7); % 10% if fast, 1% if slow
end

% loop through and perform euclidean approximation
for i = 1:NT-1, ctime = t(i);
    if outputFlag
        % Progress report
        if 100*i/NT > counter
            fprintf(1,repmat('\b',1,length(msg)-1));
            msg = sprintf('%d%%%%',counter);
            fprintf(1,msg);
            counter = counter+percentage;
        end
    end
    
    % Loop through each sub-time point
    for j = 1:ds, computeTime = ctime + dt*(j-1);
        tempdy = ode(computeTime,tempy);
        tempy = tempy + tempdy(:)'*dt;
    end
    y(i+1,:) = tempy;
    dy(i,:) = tempdy;
end

if outputFlag
    fprintf(1,repmat('\b',1,length(msg)-1));
    fprintf(1,' finished.\n');
end





