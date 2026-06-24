clc;
clear;
close all;

%% ============================================================
%  VOLUMEN DE TRABAJO IDEAL DEL ROBOT DE 3 GDL
%
%  q1: giro de la base
%  q2: giro del hombro
%  q3: giro relativo del codo
%
%  Hipotesis:
%  - Sin limites articulares
%  - Sin colisiones
%  - Sin restricciones de cableado
%  - Giro completo de la base
%% ============================================================

%% 1. Dimensiones del robot [mm]

L1 = 492;
L2 = 365;
L3 = 310;

%% 2. Resolucion angular

paso_q1 = 4;    % grados
paso_q2 = 4;    % grados
paso_q3 = 4;    % grados

q1 = 0:paso_q1:360;
q2 = -180:paso_q2:180;
q3 = -180:paso_q3:180;

%% 3. Preasignacion aproximada

cantidad_maxima = length(q1) * length(q2) * length(q3);

X = zeros(cantidad_maxima,1);
Y = zeros(cantidad_maxima,1);
Z = zeros(cantidad_maxima,1);

indice = 0;

%% 4. Muestreo del espacio articular

for i = 1:length(q1)

    theta1 = q1(i);

    for j = 1:length(q2)

        theta2 = q2(j);

        for k = 1:length(q3)

            theta3 = q3(k);

            % ----------------------------------------------------
            % Cinematica directa
            %
            % Se adopta theta3 como angulo relativo entre L2 y L3.
            % La orientacion absoluta de L3 es theta2 + theta3.
            % ----------------------------------------------------

            radio_horizontal = ...
                L2*cosd(theta2) + ...
                L3*cosd(theta2 + theta3);

            px = radio_horizontal*cosd(theta1);
            py = radio_horizontal*sind(theta1);

            pz = L1 ...
               + L2*sind(theta2) ...
               + L3*sind(theta2 + theta3);

            indice = indice + 1;

            X(indice) = px;
            Y(indice) = py;
            Z(indice) = pz;

        end
    end
end

%% 5. Eliminar posiciones no utilizadas

X = X(1:indice);
Y = Y(1:indice);
Z = Z(1:indice);

%% 6. Reducir puntos repetidos

% Se redondea a 1 mm para evitar graficar muchas posiciones iguales.

P = round([X,Y,Z],0);
P = unique(P,'rows');

X = P(:,1);
Y = P(:,2);
Z = P(:,3);

%% 7. Datos teoricos del volumen ideal

radio_exterior = L2 + L3;
radio_interior = abs(L2 - L3);

volumen_exterior = (4*pi/3)*radio_exterior^3;
volumen_interior = (4*pi/3)*radio_interior^3;
volumen_ideal = volumen_exterior - volumen_interior;

fprintf('\n=================================================\n');
fprintf('VOLUMEN DE TRABAJO IDEAL\n');
fprintf('=================================================\n');
fprintf('Radio exterior : %.2f mm\n', radio_exterior);
fprintf('Radio interior : %.2f mm\n', radio_interior);
fprintf('Altura del hombro: %.2f mm\n', L1);
fprintf('Volumen ideal aproximado: %.3e mm^3\n', volumen_ideal);
fprintf('Volumen ideal aproximado: %.3f m^3\n', volumen_ideal/1e9);
fprintf('Cantidad de puntos graficados: %d\n', size(P,1));
fprintf('=================================================\n\n');

%% 8. Grafico tridimensional

figure('Name','Volumen de trabajo ideal');

scatter3(X,Y,Z,4,Z,'filled');

hold on;

% Base del robot
plot3(0,0,0,'ks','MarkerSize',10,'MarkerFaceColor','k');

% Columna vertical
plot3([0,0],[0,0],[0,L1], ...
      'k','LineWidth',4);

% Articulacion del hombro
plot3(0,0,L1,'ko', ...
      'MarkerSize',8, ...
      'MarkerFaceColor','k');

axis equal;
grid on;
box on;

xlabel('X [mm]');
ylabel('Y [mm]');
zlabel('Z [mm]');

title('Volumen de trabajo ideal del robot');

view(45,25);

limite_xy = radio_exterior + 50;

xlim([-limite_xy, limite_xy]);
ylim([-limite_xy, limite_xy]);
zlim([L1-radio_exterior-50, L1+radio_exterior+50]);

colorbar;
colormap parula;

%% 9. Seccion vertical teorica

figure('Name','Seccion vertical del volumen ideal');

angulo = linspace(0,2*pi,600);

r_exterior = radio_exterior*cos(angulo);
z_exterior = L1 + radio_exterior*sin(angulo);

r_interior = radio_interior*cos(angulo);
z_interior = L1 + radio_interior*sin(angulo);

plot(r_exterior,z_exterior,'LineWidth',2);
hold on;
plot(r_interior,z_interior,'LineWidth',2);

plot(0,L1,'ko', ...
     'MarkerFaceColor','k', ...
     'MarkerSize',8);

plot([0,0],[0,L1],'k','LineWidth',3);

axis equal;
grid on;
box on;

xlabel('Radio horizontal r [mm]');
ylabel('Z [mm]');

title('Seccion vertical del volumen de trabajo ideal');

legend( ...
    'Limite exterior: L2 + L3', ...
    'Limite interior: |L2 - L3|', ...
    'Hombro', ...
    'Columna', ...
    'Location','best');

xlim([-radio_exterior-50, radio_exterior+50]);
ylim([L1-radio_exterior-50, L1+radio_exterior+50]);