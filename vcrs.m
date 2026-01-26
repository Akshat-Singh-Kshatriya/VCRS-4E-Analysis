%% Vapour Compression Refrigeration System Model
clearvars; clc;
refrigerant = 'R134a';

% Input Parameters
T_evap = 278.15;              % Evaporation Temperature (Kelvin)
T_cond = 303.15;              % Condenser Temperature (Kelvin)
eta_isen = 0.85;              % Isentropic Efficiency
Q_capacity = 4000;            % Cooling Capacity (Watts)
superheat_K = 0;              % Degrees of superheat (Kelvin)
dT_subcool = 0;               % Degrees of subcooling (Kelvin)

% State 1: COMPRESSOR INLET (EVAPORATOR EXIT) 
P1 = py.CoolProp.CoolProp.PropsSI('P','T',T_evap,'Q',1,refrigerant);
if superheat_K > 0
    T1 = T_evap + superheat_K;
    h1 = py.CoolProp.CoolProp.PropsSI('H','P',P1,'T',T1,refrigerant);
    s1 = py.CoolProp.CoolProp.PropsSI('S','P',P1,'T',T1,refrigerant);
else
    T1 = T_evap;
    h1 = py.CoolProp.CoolProp.PropsSI('H','P',P1,'Q',1,refrigerant);
    s1 = py.CoolProp.CoolProp.PropsSI('S','P',P1,'Q',1,refrigerant);
end

% State 2: COMPRESSOR EXIT (CONDENSER INLET) 
P2 = py.CoolProp.CoolProp.PropsSI('P','T',T_cond,'Q',0,refrigerant);
h2s = py.CoolProp.CoolProp.PropsSI('H','P',P2,'S',s1,refrigerant);
h2 = h1 + (h2s - h1) / eta_isen;
T2 = py.CoolProp.CoolProp.PropsSI('T','P',P2,'H',h2,refrigerant);
s2 = py.CoolProp.CoolProp.PropsSI('S','P',P2,'H',h2,refrigerant);

% State 3: CONDENSER EXIT (EXPANSION VALVE INLET) 
P3 = P2;
if dT_subcool > 0
    T3 = T_cond - dT_subcool;
    h3 = py.CoolProp.CoolProp.PropsSI('H','P',P3,'T',T3,refrigerant);
    s3 = py.CoolProp.CoolProp.PropsSI('S','P',P3,'T',T3,refrigerant);
else
    T3 = T_cond;
    h3 = py.CoolProp.CoolProp.PropsSI('H','P',P3,'Q',0,refrigerant);
    s3 = py.CoolProp.CoolProp.PropsSI('S','P',P3,'Q',0,refrigerant);
end

% State 4: EXPANSION VALVE EXIT (EVAPORATOR INLET) 
P4 = P1;
h4 = h3; 
T4 = py.CoolProp.CoolProp.PropsSI('T','P',P4,'H',h4,refrigerant);
s4 = py.CoolProp.CoolProp.PropsSI('S','P',P4,'H',h4,refrigerant);

% Calculations 
W_comp= h2 - h1;              % (J/kg)
Q_evap= h1 - h4;              % (J/kg)
COP = Q_evap/ W_comp;    
m_dot = Q_capacity / Q_evap;   
W_comp_total = m_dot * W_comp; %(Watts)

% Output
fprintf('Calculated COP: %.3f\n', double(COP));
fprintf('Mass Flow Rate: %.3f kg/s\n', double(m_dot));
fprintf('Specific Compressor Work: %.3f kJ/kg\n', double(W_comp/1000));
fprintf('Total Compressor Work: %.3f Watts\n', double(W_comp_total));


%% Plotting 

% Saturation Dome
T_crit = double(py.CoolProp.CoolProp.PropsSI('Tcrit', refrigerant));
T_d = linspace(230, T_crit-0.05, 400);
h_l = arrayfun(@(t) double(py.CoolProp.CoolProp.PropsSI('H','T',t,'Q',0,refrigerant)), T_d)/1000;
h_v = arrayfun(@(t) double(py.CoolProp.CoolProp.PropsSI('H','T',t,'Q',1,refrigerant)), flip(T_d))/1000;
s_l = arrayfun(@(t) double(py.CoolProp.CoolProp.PropsSI('S','T',t,'Q',0,refrigerant)), T_d)/1000;
s_v = arrayfun(@(t) double(py.CoolProp.CoolProp.PropsSI('S','T',t,'Q',1,refrigerant)), flip(T_d))/1000;
P_l = arrayfun(@(t) double(py.CoolProp.CoolProp.PropsSI('P','T',t,'Q',0,refrigerant)), T_d)/1e5;
P_v = arrayfun(@(t) double(py.CoolProp.CoolProp.PropsSI('P','T',t,'Q',1,refrigerant)), flip(T_d))/1e5;

% Define saturation vapor properties for condenser path
s_sat_v = double(py.CoolProp.CoolProp.PropsSI('S','P',P2,'Q',1,refrigerant));
s_sat_l = double(py.CoolProp.CoolProp.PropsSI('S','P',P2,'Q',0,refrigerant));
s1s_val = double(py.CoolProp.CoolProp.PropsSI('S','T',T_evap,'Q',1,refrigerant));
T2s_val = double(py.CoolProp.CoolProp.PropsSI('T','P',P2,'H',h2s,refrigerant));

% T-s Diagram Plotting 
figure('Color', 'w', 'Name', 'T-s Diagram'); hold on; box on;
set(gca, 'Color', 'w', 'GridColor', 'k', 'GridAlpha', 0.6, 'LineWidth', 1.5, 'XColor', 'k', 'YColor', 'k');
grid on;

% Plot Continuous Dome
plot([s_l, s_v], [T_d, flip(T_d)], 'Color', [0.3 0.3 0.3], 'LineWidth', 1.5);

% Cycle Path
plot([s4, s1s_val, s1, s2, s_sat_v, s_sat_l, s3]/1000, [T4, T_evap, T1, T2, T_cond, T_cond, T3], 'm-', 'LineWidth', 2.5);
plot([s1, s1]/1000, [T1, T2s_val], 'k--', 'LineWidth', 1.2); % Ideal vertical compression
plot([s3, s4]/1000, [T3, T4], 'm:', 'LineWidth', 2.5); % Dotted expansion line

% State Markers
pts_s = [s1s_val, s1, s1, s2, s3, s4]/1000; pts_T = [T_evap, T1, T2s_val, T2, T3, T4];
plot(pts_s, pts_T, 'ko', 'MarkerFaceColor', 'k', 'MarkerSize', 6);

text(pts_s(1), pts_T(1)-3, '1s', 'HorizontalAlignment', 'center', 'VerticalAlignment', 'top', 'FontWeight', 'bold', 'Color', 'k');
text(pts_s(2)+0.01, pts_T(2), '1', 'HorizontalAlignment', 'left', 'VerticalAlignment', 'middle', 'FontWeight', 'bold', 'Color', 'k');
text(pts_s(3), pts_T(3)+4, '2s', 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontWeight', 'bold', 'Color', 'k');
text(pts_s(4)+0.01, pts_T(4)+1, '2', 'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom', 'FontWeight', 'bold', 'Color', 'k');
text(pts_s(5), pts_T(5)+1, '3', 'HorizontalAlignment', 'right', 'VerticalAlignment', 'bottom', 'FontWeight', 'bold', 'Color', 'k');
text(pts_s(6), pts_T(6)-1, '4', 'HorizontalAlignment', 'right', 'VerticalAlignment', 'top', 'FontWeight', 'bold', 'Color', 'k');

xlabel('Entropy, s (kJ/kg-K)', 'FontWeight', 'bold', 'Color', 'k');
ylabel('Temperature, T (K)', 'FontWeight', 'bold', 'Color', 'k');
title('T-s Diagram', 'FontSize', 16, 'FontWeight', 'bold', 'Color', 'k');

% P-h Diagram Plotting 
figure('Color', 'w', 'Name', 'P-h Diagram'); hold on; box on;
set(gca, 'Color', 'w', 'GridColor', 'k', 'GridAlpha', 0.6, 'YScale', 'log', 'LineWidth', 1.5, 'XColor', 'k', 'YColor', 'k');
grid on;

% Plot Dome
plot([h_l, h_v], [P_l, P_v], 'Color', [0.4 0.4 0.4], 'LineWidth', 1.5);

% Cycle Path
h1s_ph = double(py.CoolProp.CoolProp.PropsSI('H','T',T_evap,'Q',1,refrigerant));
plot([h4, h1s_ph, h1, h2, h3, h4]/1000, [P1, P1, P1, P2, P2, P1]/1e5, 'm-', 'LineWidth', 2.5);

% State Markers and Labels
pts_h = [h1s_ph, h1, h2s, h2, h3, h4]/1000; pts_P = [P1, P1, P2, P2, P2, P1]/1e5;
plot(pts_h, pts_P, 'ko', 'MarkerFaceColor', 'k', 'MarkerSize', 6);

% Optimized P-h labels
text(pts_h(1), pts_P(1)*0.82, '1s', 'HorizontalAlignment', 'center', 'VerticalAlignment', 'top', 'FontWeight', 'bold', 'Color', 'k');
text(pts_h(2), pts_P(2)*1.18, '1', 'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom', 'FontWeight', 'bold', 'Color', 'k');
text(pts_h(3), pts_P(3)*1.1, '2s', 'HorizontalAlignment', 'right', 'VerticalAlignment', 'bottom', 'FontWeight', 'bold', 'Color', 'k');
text(pts_h(4), pts_P(4)*1.1, '2', 'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom', 'FontWeight', 'bold', 'Color', 'k');
text(pts_h(5), pts_P(5)*1.1, '3', 'HorizontalAlignment', 'right', 'VerticalAlignment', 'bottom', 'FontWeight', 'bold', 'Color', 'k');
text(pts_h(6), pts_P(6)*0.85, '4', 'HorizontalAlignment', 'right', 'VerticalAlignment', 'top', 'FontWeight', 'bold', 'Color', 'k');

xlabel('Enthalpy, h (kJ/kg)', 'FontWeight', 'bold', 'Color', 'k');
ylabel('Pressure, P (kPa)', 'FontWeight', 'bold', 'Color', 'k');
title('P-h Diagram', 'FontSize', 16, 'FontWeight', 'bold', 'Color', 'k');