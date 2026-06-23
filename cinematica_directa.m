function puntos = cinematica_directa(q, robot)
% CINEMATICA_DIRECTA Calcula los puntos del robot para animación.
%
% Entrada:
%   q = [theta1 theta2 theta3] en grados
%
% Salida:
%   puntos = matriz 4x3 con:
%       fila 1 -> base
%       fila 2 -> hombro
%       fila 3 -> codo
%       fila 4 -> extremo

    theta1 = q(1);
    theta2 = q(2);
    theta3 = q(3);

    L1 = robot.L1;
    L2 = robot.L2;
    L3 = robot.L3;

    P0 = [0, 0, 0];
    P1 = [0, 0, L1];

    P2 = [
        L2*cosd(theta2)*cosd(theta1), ...
        L2*cosd(theta2)*sind(theta1), ...
        L1 + L2*sind(theta2)
    ];

    P3 = [
        P2(1) + L3*cosd(theta2 - theta3)*cosd(theta1), ...
        P2(2) + L3*cosd(theta2 - theta3)*sind(theta1), ...
        P2(3) + L3*sind(theta2 - theta3)
    ];

    puntos = [P0; P1; P2; P3];
end
