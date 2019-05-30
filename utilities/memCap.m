function cm = memCap(area)

specificMembraneCapacitance = 1e-6 * (1/10000)^2; % F/µm2
if nargin==0
    area = 1; 
end
cm = specificMembraneCapacitance * area; % return either specific capacitance or bulk capacitance if area given

