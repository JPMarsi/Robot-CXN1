% ================================================================
% TRABAJO INTEGRADOR G4 - CXN1
% Robot antropomorfo de 3 GDL - Control cinemático articular
%
% Flujo del programa:
%   Puntos cartesianos -> Cinemática inversa -> FControl
%   -> Cinemática directa -> Animación y gráficas
%
% Unidades:
%   Longitudes: mm
%   Ángulos: grados
%   Tiempo: segundos
% ================================================================

clc;
clear;
close all;

% ---------------------------------------------------------------
% 1) Datos del robot y rutina de trabajo
% ---------------------------------------------------------------
robot = datos_robot();
rutina = rutina_puntos();

nPuntos = size(rutina.puntos, 1);
Q = zeros(nPuntos, 3);      % [theta1 theta2 theta3] por cada punto
infoCI = cell(nPuntos, 1);  % información adicional de cinemática inversa

fprintf('\n====================================================\n');
fprintf(' TRABAJO INTEGRADOR G4 - CXN1\n');
fprintf('====================================================\n');
fprintf('L1 = %.1f mm | L2 = %.1f mm | L3 = %.1f mm\n', robot.L1, robot.L2, robot.L3);
fprintf('a = %.1f deg/s^2 | tf = %.2f s | tdesc = %.2f s\n\n', robot.a, robot.tf, robot.tdesc);

% ---------------------------------------------------------------
% 2) Cinemática inversa para cada punto de la rutina
% ---------------------------------------------------------------
fprintf('Calculando cinemática inversa punto por punto...\n\n');

qAnterior = [];

for i = 1:nPuntos
    P = rutina.puntos(i, :);
    config = rutina.config{i};

    validar_punto(P, robot);

    [q, info] = cinematica_inversa(P, robot, config, qAnterior);

    Q(i, :) = q;
    infoCI{i} = info;
    qAnterior = q;
end

% Evita saltos artificiales tipo 179 -> -179 grados.
%Q = corregir_saltos_angulares(Q);
validar_limites_articulares( ...
    Q, robot, 'Resultados de cinemática inversa');

% ---------------------------------------------------------------
% 3) Verificación con cinemática directa
% ---------------------------------------------------------------
verificar_Q_con_CD(rutina.puntos, Q, robot);

% ---------------------------------------------------------------
% 4) Mostrar resultados articulares por punto alcanzado
% ---------------------------------------------------------------
imprimir_resultados(rutina, Q, infoCI);

% ---------------------------------------------------------------
% 5) Generar trayectorias articulares con control trapezoidal
% ---------------------------------------------------------------
fprintf('\nGenerando trayectorias articulares con FControl...\n');
tray = generar_trayectorias(Q, robot);
graficar_todas_articulaciones(tray, robot);
fprintf('Trayectorias generadas correctamente.\n');
Qtray = [tray.q1(:), tray.q2(:), tray.q3(:)];
resumenSubtramos = verificar_subtramos( ...
    tray.Q_usada, robot);
fprintf('\nRESUMEN DE LIMITES ARTICULARES\n');
fprintf('============================================\n');

for j = 1:3
    qMinReal = min(Qtray(:,j));
    qMaxReal = max(Qtray(:,j));

    fprintf(['q%d: mínimo = %8.3f° | máximo = %8.3f° ' ...
             '| permitido = [%7.1f°, %7.1f°]\n'], ...
             j, ...
             qMinReal, ...
             qMaxReal, ...
             robot.qMin(j), ...
             robot.qMax(j));
end
% ---------------------------------------------------------------
% 6) Animación alámbrica del robot
% ---------------------------------------------------------------
fprintf('\nIniciando animación...\n');
animar_robot(tray, robot, rutina, 25, 1);
% ---------------------------------------------------------------
% 7) Gráficas de posición, velocidad y aceleración
% ---------------------------------------------------------------
articulacion = 1;  % cambiar a 2 o 3 si se desea graficar otra articulación
graficar_articulacion(tray, articulacion);
fprintf('\nTiempo total logico de la trayectoria = %.2f s\n', tray.t(end));
fprintf('Cantidad de puntos originales = %d\n', size(tray.Q_original, 1));
fprintf('Cantidad de puntos usados = %d\n', size(tray.Q_usada, 1));
fprintf('Cantidad de tramos usados = %d\n', size(tray.Q_usada, 1) - 1);
fprintf('\nPrograma finalizado.\n');
