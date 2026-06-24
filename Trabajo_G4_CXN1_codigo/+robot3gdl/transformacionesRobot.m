function T = transformacionesRobot(q, robot)
% TRANSFORMACIONESROBOT Transformaciones jerarquicas basadas en DH.
%
% La cadena DH completa esta definida en robot3gdl.denavitHartenberg.
% Esta funcion entrega transformaciones relativas para hgtransform, de modo
% que la animacion pueda conservar su jerarquia:
%
%   base -> q1 -> q2 -> q3 -> efector
%
% Con esta descomposicion:
%
%   T.q1 * T.q2 * T.q3 * T.efector == dh.T03

    q = q(:).';
    dh = robot3gdl.denavitHartenberg(q, robot);

    T = struct();
    T.base = eye(4);
    T.q1 = makehgtform('zrotate', deg2rad(q(1)));
    T.q2 = makehgtform('translate', [0 0 robot.L1]) * ...
        makehgtform('xrotate', pi/2) * ...
        makehgtform('zrotate', deg2rad(q(2)));
    T.q3 = makehgtform('translate', [robot.L2 0 0]) * ...
        makehgtform('zrotate', deg2rad(-q(3)));
    T.efector = makehgtform('translate', [robot.L3 0 0]);

    T.DH = dh;
end
