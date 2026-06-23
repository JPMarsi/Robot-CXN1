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


robot = datos_robot();
rutina = rutina_puntos();

nPuntos = size(rutina.puntos, 1); %Calcula la cantidad de puntos que el usuario ingreso 
Q = zeros(nPuntos, 3);      % Crea la matriz Q
infoCI = cell(nPuntos, 1);  % Crea la celda de info

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
    %Toma un vector (Px,Py,Pz) y la posicion del codo
    P = rutina.puntos(i, :);
    config = rutina.config{i};
    %Valida que la rutina sea posible
    validar_punto(P, robot);

    [q, info] = cinematica_inversa(P, robot, config, qAnterior);

    Q(i, :) = q;
    infoCI{i} = info;
    qAnterior = q;
end

% Evita saltos artificiales tipo 179 -> -179 grados.
Q = corregir_saltos_angulares(Q);

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
fprintf('Trayectorias generadas correctamente.\n');

% ---------------------------------------------------------------
% 6) Animación alámbrica del robot
% ---------------------------------------------------------------
fprintf('\nIniciando animación...\n');
animar_robot(tray, robot, 5);   % último argumento = salto de muestras

% ---------------------------------------------------------------
% 7) Gráficas de posición, velocidad y aceleración
% ---------------------------------------------------------------
articulacion = 1;  % cambiar a 2 o 3 si se desea graficar otra articulación
graficar_articulacion(tray, articulacion);

fprintf('\nPrograma finalizado.\n');
