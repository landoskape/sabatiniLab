function dataID = getDataID(name)

if contains(name,'AD')
    dataID = name(1:3);
else
    dataID = name(strfind(name,'c'):strfind(name,'_')-1);
end



