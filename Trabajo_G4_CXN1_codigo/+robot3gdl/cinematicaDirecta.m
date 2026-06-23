function puntos = cinematicaDirecta(q, robot)
% CINEMATICADIRECTA Devuelve base, hombro, codo y extremo para q en grados.
%
% Convencion heredada del proyecto:
%   r = L2*cosd(q2) + L3*cosd(q2 - q3)
%   z = L2*sind(q2) + L3*sind(q2 - q3)
% Por lo tanto q3 positivo resta angulo al tercer eslabon respecto de q2.

    q = q(:).';
    q1 = q(1);
    q2 = q(2);
    q3 = q(3);

    P0 = [0, 0, 0];
    P1 = [0, 0, robot.L1];

    P2 = [
        robot.L2*cosd(q2)*cosd(q1), ...
        robot.L2*cosd(q2)*sind(q1), ...
        robot.L1 + robot.L2*sind(q2)
    ];

    P3 = [
        P2(1) + robot.L3*cosd(q2 - q3)*cosd(q1), ...
        P2(2) + robot.L3*cosd(q2 - q3)*sind(q1), ...
        P2(3) + robot.L3*sind(q2 - q3)
    ];

    puntos = [P0; P1; P2; P3];
end
