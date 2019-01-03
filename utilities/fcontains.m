function tf = fcontains(str1,str2)
% fast version of contains - does str1 contains str2 anywhere
tf = ~isempty(strfind(str1,str2));%#ok - for some reason matlab doesn't get that this is faster
