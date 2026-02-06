%% VCRS with Ejector Pin
clc; clearvars; 

% Input Parameters
Refrigerant = 'Ammonia';        
T_evap = 261.15;        % Evaporator Temperature (Kelvin)
T_cond = 300.15;        % Condenser Temperature (Kelvin)
Q_target = 36750;       % Cooling Capacity (Watts)
eta_isen = 1;           % Isentropic Efficiency
eta_n = 0.85;           % Nozzle efficiency
PLR = 1.08;             % Pressure Lifting ratio      
dT_superheat = 0;       % Degree of Superheat [Kelvin]
dT_subcooling = 6;      % Degree of Subcooling [Kelvin]
omega = 1;              % Entrainment Ratio (m_evap / m_comp)

% STATE 4: Evaporator Exit 
P(4) = py.CoolProp.CoolProp.PropsSI('P', 'T', T_evap, 'Q', 1, Refrigerant);
if dT_superheat > 0
    T(4) = T_evap + dT_superheat;
    h(4) = py.CoolProp.CoolProp.PropsSI('H', 'P', P(4), 'T', T(4), Refrigerant);
    s(4) = py.CoolProp.CoolProp.PropsSI('S', 'P', P(4), 'T', T(4), Refrigerant);
else
    T(4) = T_evap;
    h(4) = py.CoolProp.CoolProp.PropsSI('H', 'T', T_evap, 'Q', 1, Refrigerant);
    s(4) = py.CoolProp.CoolProp.PropsSI('S', 'T', T_evap, 'Q', 1, Refrigerant);
end

P(5) = P(4) * PLR;

% STATE 6 & 7: Expansion Inlet & Exit 
P(6) = P(5);
h(6) = py.CoolProp.CoolProp.PropsSI('H', 'P', P(6), 'Q', 0, Refrigerant);
T(6) = py.CoolProp.CoolProp.PropsSI('T', 'P', P(6), 'Q', 0, Refrigerant);
s(6) = py.CoolProp.CoolProp.PropsSI('S', 'P', P(6), 'Q', 0, Refrigerant);

P(7) = P(4);
h(7) = h(6); 
T(7) = py.CoolProp.CoolProp.PropsSI('T', 'P', P(7), 'H', h(7), Refrigerant);
s(7) = py.CoolProp.CoolProp.PropsSI('S', 'P', P(7), 'H', h(7), Refrigerant);

% Mass Flow Calculations
m_evap = Q_target / (h(4) - h(7));
m_comp = m_evap / omega; 

% STATE 1: Separator Vapor (Compressor Inlet) 
P(1) = P(5);
h(1) = py.CoolProp.CoolProp.PropsSI('H', 'P', P(1), 'Q', 1, Refrigerant);
T(1) = py.CoolProp.CoolProp.PropsSI('T', 'P', P(1), 'Q', 1, Refrigerant);
s(1) = py.CoolProp.CoolProp.PropsSI('S', 'P', P(1), 'Q', 1, Refrigerant);

% STATE 2: Compressor Exit 
P_cond_sat = py.CoolProp.CoolProp.PropsSI('P', 'T', T_cond, 'Q', 0, Refrigerant);
P(2) = P_cond_sat; 
s2s = s(1);
h2s = py.CoolProp.CoolProp.PropsSI('H', 'P', P(2), 'S', s2s, Refrigerant);
h(2) = h(1) + (h2s - h(1)) / eta_isen;
T(2) = py.CoolProp.CoolProp.PropsSI('T', 'P', P(2), 'H', h(2), Refrigerant);
s(2) = py.CoolProp.CoolProp.PropsSI('S', 'P', P(2), 'H', h(2), Refrigerant);

% STATE 3: Condenser Exit 
P(3) = P(2);
if dT_subcooling > 0
    T(3) = T_cond - dT_subcooling;
    h(3) = py.CoolProp.CoolProp.PropsSI('H', 'P', P(3), 'T', T(3), Refrigerant);
    s(3) = py.CoolProp.CoolProp.PropsSI('S', 'P', P(3), 'T', T(3), Refrigerant);
else
    T(3) = T_cond;
    h(3) = py.CoolProp.CoolProp.PropsSI('H', 'P', P(3), 'Q', 0, Refrigerant);
    s(3) = py.CoolProp.CoolProp.PropsSI('S', 'P', P(3), 'Q', 0, Refrigerant);
end

% Ejector Internal Energy Balance 
h(5) = (h(3) + omega * h(4)) / (1 + omega);
T(5) = py.CoolProp.CoolProp.PropsSI('T', 'P', P(5), 'H', h(5), Refrigerant);
s(5) = py.CoolProp.CoolProp.PropsSI('S', 'P', P(5), 'H', h(5), Refrigerant);

% RESULTS 
W_comp = m_comp * (h(2) - h(1));
COP = Q_target / W_comp;

fprintf('Input Cooling Capacity: %.3f W\n', Q_target);
fprintf('Calculated m_evap:      %.3f kg/s\n', m_evap);
fprintf('Calculated m_comp:      %.3f kg/s\n', m_comp);
fprintf('Compressor Work:        %.3f W\n', W_comp);
fprintf('COP:                    %.3f\n', COP);


