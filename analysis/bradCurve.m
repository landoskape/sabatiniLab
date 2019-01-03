function concentration = bradCurve(absorbance, wavelength, fitFlag)
% concentration = bradCurve(absorbance, wavelength, fitFlag)
%
% bradCurve takes an absorbance read out, a wavelength, and an optional
% argument "fitFlag"
% 
% it computes the concentration of a protein in µg/mL based on a standard
% curve of a bradford assay measured on 180418, options are at 550nm and
% 620nm. 
%
% fitFlag is a logical used to identify which readings on the standard
% curve to make a linear fit with. default is to use all but 1500µg/mL

% Andrew Landau, 180427


if (nargin < 3)
    fitFlag = logical([0 1 1 1 1 1 1 1]); % Omit 1500µg/ml
end

conc = [1500 1000 750 500 250 125 25 0];

% 1st row: 550 nm
% 2nd row: 620 nm
sc = [499 490 461 448 418 396 390 382;
      575 541 486 451 404 368 350 336];

switch wavelength
    case 550
        sFluor = sc(1,:);
    case 620 
        sFluor = sc(2,:);
    otherwise
        error('Fluorescence must be 550 or 620');
end

fit = [conc(fitFlag)' ones(sum(fitFlag),1)] \ sFluor(fitFlag)';

slope = fit(1);
intercept = fit(2);

concentration = (absorbance - intercept) ./ slope;

