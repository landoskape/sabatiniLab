function unpackStruct(stName)
% unpackStruct(stName)
%
% stName is a string of a structure in the base workspace
% this function creates variables that are equal to the first layer of
% fields in stName
%
% Andrew Landau - May 2019

stFields = evalin('base',sprintf('fields(%s);',stName)); % grab the structure fields
for f = 1:length(stFields)
    % Put each field into it's own new variable with the field name
    evalin('base',sprintf('%s = %s.%s;',stFields{f},stName,stFields{f})); 
end
