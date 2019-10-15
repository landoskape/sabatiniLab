function getVarSize(varname)

if ischar(varname)
    varInfo = evalin('base',['whos(''',varname,''');']);
    name = varname;
else
    varInfo = whos('varname');
    name = inputname(1);
end

bytes = varInfo.bytes;

extScale = [0 3 6 9 12];
extNames = {'bytes','KB','MB','GB','TB'};
extIndex = find(log10(bytes)>extScale,1,'last');

fprintf('%s is %.3f %s\n',name,bytes/(10^(extScale(extIndex))),extNames{extIndex});

