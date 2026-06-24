%% ==============================================================
%  SINGULARIDADES DE UN ROBOT ANTROPOMORFICO DE 3 GDL
%
%  Articulaciones:
%       theta1: cintura
%       theta2: hombro
%       theta3: codo
%
%  Convencion cinematica:
%       x = (L2*cos(theta2) + L3*cos(theta2-theta3))*cos(theta1)
%       y = (L2*cos(theta2) + L3*cos(theta2-theta3))*sin(theta1)
%       z = L1 + L2*sin(theta2) + L3*sin(theta2-theta3)
%
%  Condicion de singularidad:
%       det(J) = L2*L3*r*sin(theta3)
%
%       r = L2*cos(theta2) + L3*cos(theta2-theta3)
%
%  Compatible con MATLAB y GNU Octave
%% ==============================================================

clear;
clc;
close all;

%% 1. DIMENSIONES DEL ROBOT

L1 = 492;     % Altura del hombro [mm]
L2 = 365;     % Longitud del brazo [mm]
L3 = 310;     % Longitud del antebrazo [mm]

%% 2. LIMITES ARTICULARES IDEALES

% Estos límites pueden modificarse cuando se definan
% las restricciones mecánicas reales del robot.

theta1_min = -180;
theta1_max =  180;

theta2_min = -180;
theta2_max =  180;

theta3_min = -180;
theta3_max =  180;

%% 3. GENERACION DE UNA NUBE DEL VOLUMEN DE TRABAJO

% Se utilizan puntos aleatorios para no sobrecargar la figura.

cantidad_puntos = 40000;

theta1 = theta1_min + ...
         (theta1_max - theta1_min)*rand(cantidad_puntos,1);

theta2 = theta2_min + ...
         (theta2_max - theta2_min)*rand(cantidad_puntos,1);

theta3 = theta3_min + ...
         (theta3_max - theta3_min)*rand(cantidad_puntos,1);

% Conversión a radianes

t1 = theta1*pi/180;
t2 = theta2*pi/180;
t3 = theta3*pi/180;

% Distancia radial del extremo respecto del eje Z

r = L2*cos(t2) + L3*cos(t2 - t3);

% Cinemática directa

x = r.*cos(t1);
y = r.*sin(t1);
z = L1 + L2*sin(t2) + L3*sin(t2 - t3);

%% 4. SUPERFICIE SINGULAR: BRAZO COMPLETAMENTE EXTENDIDO

% theta3 = 0 grados
%
% En esta situación:
%       radio = L2 + L3

theta1_s = linspace(theta1_min,theta1_max,181)*pi/180;
theta2_s = linspace(theta2_min,theta2_max,181)*pi/180;

[T1,T2] = meshgrid(theta1_s,theta2_s);

R_exterior = L2 + L3;

X_extendido = R_exterior*cos(T2).*cos(T1);
Y_extendido = R_exterior*cos(T2).*sin(T1);
Z_extendido = L1 + R_exterior*sin(T2);

%% 5. SUPERFICIE SINGULAR: BRAZO COMPLETAMENTE PLEGADO

% theta3 = +/-180 grados
%
% En esta situación:
%       radio = abs(L2 - L3)

R_interior = abs(L2 - L3);

X_plegado = R_interior*cos(T2).*cos(T1);
Y_plegado = R_interior*cos(T2).*sin(T1);
Z_plegado = L1 + R_interior*sin(T2);

%% 6. SINGULARIDAD SOBRE EL EJE DE LA BASE

% Para r = 0:
%
%       x = 0
%       y = 0
%
% El extremo solamente puede alcanzar puntos del eje Z cuya
% distancia al hombro se encuentre entre:
%
%       abs(L2-L3) y L2+L3

z_eje_inferior = linspace( ...
    L1 - (L2 + L3), ...
    L1 - abs(L2 - L3), ...
    300);

z_eje_superior = linspace( ...
    L1 + abs(L2 - L3), ...
    L1 + (L2 + L3), ...
    300);

x_eje_inferior = zeros(size(z_eje_inferior));
y_eje_inferior = zeros(size(z_eje_inferior));

x_eje_superior = zeros(size(z_eje_superior));
y_eje_superior = zeros(size(z_eje_superior));

%% 7. GRAFICO TRIDIMENSIONAL

figure('Name','Singularidades del robot antropomorfico 3 GDL');

hold on;
grid on;
axis equal;
view(45,25);

% Volumen de trabajo aproximado

h_volumen = scatter3( ...
    x,y,z, ...
    3, ...
    [0.65 0.65 0.65], ...
    'filled');

% Superficie singular exterior: theta3 = 0 grados

h_extendido = surf( ...
    X_extendido, ...
    Y_extendido, ...
    Z_extendido, ...
    'FaceColor',[0.85 0.15 0.15], ...
    'EdgeColor','none', ...
    'FaceAlpha',0.25);

% Superficie singular interior: theta3 = +/-180 grados

h_plegado = surf( ...
    X_plegado, ...
    Y_plegado, ...
    Z_plegado, ...
    'FaceColor',[0.10 0.35 0.90], ...
    'EdgeColor','none', ...
    'FaceAlpha',0.65);

% Singularidad r = 0 sobre el eje Z

h_eje = plot3( ...
    x_eje_inferior, ...
    y_eje_inferior, ...
    z_eje_inferior, ...
    'k', ...
    'LineWidth',5);

plot3( ...
    x_eje_superior, ...
    y_eje_superior, ...
    z_eje_superior, ...
    'k', ...
    'LineWidth',5);

% Hombro

plot3(0,0,L1, ...
    'ko', ...
    'MarkerFaceColor','y', ...
    'MarkerSize',8);

% Base vertical

plot3([0 0],[0 0],[0 L1], ...
    'k--', ...
    'LineWidth',1.5);

xlabel('X [mm]');
ylabel('Y [mm]');
zlabel('Z [mm]');

title({ ...
    'Singularidades del robot antropomórfico de 3 GDL'; ...
    'det(J) = L_2 L_3 r sin(\theta_3)'});

legend( ...
    [h_volumen,h_extendido,h_plegado,h_eje], ...
    { ...
    'Volumen de trabajo', ...
    '\theta_3 = 0°: brazo extendido', ...
    '\theta_3 = \pm180°: brazo plegado', ...
    'r = 0: extremo sobre el eje Z'}, ...
    'Location','bestoutside');

% Límites de visualización

alcance_maximo = L2 + L3;

xlim([-alcance_maximo alcance_maximo]);
ylim([-alcance_maximo alcance_maximo]);
zlim([L1-alcance_maximo L1+alcance_maximo]);

rotate3d on;

%% 8. COMPROBACION NUMERICA DEL DETERMINANTE DEL JACOBIANO

% Se fija theta1 porque el determinante no depende de su valor.
% Se representa det(J) en función de theta2 y theta3.

theta2_mapa = linspace(theta2_min,theta2_max,361);
theta3_mapa = linspace(theta3_min,theta3_max,361);

[THETA2,THETA3] = meshgrid(theta2_mapa,theta3_mapa);

Q2 = THETA2*pi/180;
Q3 = THETA3*pi/180;

R = L2*cos(Q2) + L3*cos(Q2 - Q3);

DET_J = L2*L3.*R.*sin(Q3);

% Normalización para facilitar la interpretación

DET_J_normalizado = abs(DET_J)/(L2*L3*(L2+L3));

figure('Name','Determinante del Jacobiano');

surf( ...
    THETA2, ...
    THETA3, ...
    DET_J_normalizado, ...
    'EdgeColor','none');

grid on;
view(45,30);

xlabel('\theta_2 [grados]');
ylabel('\theta_3 [grados]');
zlabel('|det(J)| normalizado');

title('Proximidad a las singularidades');

colorbar;

%% 9. GRAFICO DE LAS REGIONES CASI SINGULARES

% Una configuración se considera próxima a una singularidad
% cuando el determinante normalizado es menor que la tolerancia.

tolerancia = 0.015;

casi_singular = DET_J_normalizado < tolerancia;

figure('Name','Regiones singulares en el espacio articular');

scatter( ...
    THETA2(casi_singular), ...
    THETA3(casi_singular), ...
    5, ...
    DET_J_normalizado(casi_singular), ...
    'filled');

grid on;

xlabel('\theta_2 [grados]');
ylabel('\theta_3 [grados]');

title(['Regiones con |det(J)| normalizado < ', ...
       num2str(tolerancia)]);

colorbar;

%% 10. INFORMACION EN LA CONSOLA

fprintf('\n');
fprintf('====================================================\n');
fprintf(' SINGULARIDADES DEL ROBOT ANTROPOMORFICO DE 3 GDL\n');
fprintf('====================================================\n');

fprintf('\nDimensiones:\n');
fprintf('L1 = %.1f mm\n',L1);
fprintf('L2 = %.1f mm\n',L2);
fprintf('L3 = %.1f mm\n',L3);

fprintf('\nSingularidades de codo:\n');
fprintf('theta3 = 0 grados\n');
fprintf('theta3 = +/-180 grados\n');

fprintf('\nSingularidad de cintura:\n');
fprintf('r = L2*cos(theta2) + L3*cos(theta2-theta3) = 0\n');

fprintf('\nRadios singulares ideales:\n');
fprintf('Radio exterior = L2 + L3 = %.1f mm\n',R_exterior);
fprintf('Radio interior = abs(L2-L3) = %.1f mm\n',R_interior);

fprintf('\nTramos singulares sobre el eje Z:\n');
fprintf('Tramo inferior: %.1f mm <= z <= %.1f mm\n', ...
        L1-(L2+L3),L1-abs(L2-L3));

fprintf('Tramo superior: %.1f mm <= z <= %.1f mm\n', ...
        L1+abs(L2-L3),L1+(L2+L3));

fprintf('====================================================\n');