function [out,idx] = getEpoch(S,epoch)
% Returns all elements of structure S from given epoch
% S has to have a field called epoch
% epoch has to be numeric, can be a vector of multiple epochs

se = [S(:).epoch];
out = S(ismember(se,epoch));
idx = find(se);
