function getFPos(fig)

if nargin==0
    fig = gcf;
end

oldUnits = get(fig, 'units');
set(fig, 'units','normalized');
pos = get(fig,'outerposition');
set(fig,'units',oldUnits);

fprintf(1,'Fig Position: [');
fprintf(1,'%.2f ',pos);
fprintf(1,'\b]\n');
fprintf(1, 'set(gcf,''units'',''normalized'',''outerposition'',[');
fprintf(1,'%.2f ',pos);
fprintf(1,'\b]);\n');
