function dh = denavitHartenberg(q, robot)
% DENAVITHARTENBERG Matrices DH explicitas para el robot antropomorfico 3 GDL.
%
% Convencion DH estandar usada:
%
%   A_i = Rz(theta_i) * Tz(d_i) * Tx(a_i) * Rx(alpha_i)
%
% Tabla DH equivalente a la cinematica ya validada del proyecto:
%
%   i | theta      | d        | a        | alpha
%   1 | q1         | L1       | 0        | +90 deg
%   2 | q2         | 0        | L2       |   0 deg
%   3 | -q3        | 0        | L3       |   0 deg
%
% El signo -q3 conserva la convencion funcional del proyecto:
%
%   r = L2*cos(q2) + L3*cos(q2 - q3)
%   z = L1 + L2*sin(q2) + L3*sin(q2 - q3)
%
% Salida:
%   dh.tabla  -> tabla numerica [theta d a alpha] en grados/mm
%   dh.A01    -> matriz DH de base a hombro
%   dh.A12    -> matriz DH de hombro a codo
%   dh.A23    -> matriz DH de codo a extremo
%   dh.T01    -> transformacion acumulada base-hombro
%   dh.T02    -> transformacion acumulada base-codo
%   dh.T03    -> transformacion acumulada base-extremo
%   dh.puntos -> [base; hombro; codo; extremo] en mm

    q = q(:).';
    if numel(q) ~= 3
        error('q debe ser [q1 q2 q3].');
    end

    tabla = tablaDHRobot3GDL(q, robot);

    A01 = matrizDH(tabla(1,1), tabla(1,2), tabla(1,3), tabla(1,4));
    A12 = matrizDH(tabla(2,1), tabla(2,2), tabla(2,3), tabla(2,4));
    A23 = matrizDH(tabla(3,1), tabla(3,2), tabla(3,3), tabla(3,4));

    T01 = A01;
    T02 = T01 * A12;
    T03 = T02 * A23;

    dh = struct();
    dh.tabla = tabla;
    dh.A01 = A01;
    dh.A12 = A12;
    dh.A23 = A23;
    dh.T01 = T01;
    dh.T02 = T02;
    dh.T03 = T03;
    dh.puntos = [
        0, 0, 0
        extraerPunto(T01)
        extraerPunto(T02)
        extraerPunto(T03)
    ];
end

function tabla = tablaDHRobot3GDL(q, robot)
% TABLADHROBOT3GDL Devuelve [theta d a alpha] con angulos en grados.
    tabla = [
         q(1), robot.L1,       0, 90
         q(2),        0, robot.L2,  0
        -q(3),        0, robot.L3,  0
    ];
end

function A = matrizDH(thetaDeg, d, a, alphaDeg)
% MATRIZDH Matriz homogenea DH estandar.
    ct = cosd(thetaDeg);
    st = sind(thetaDeg);
    ca = cosd(alphaDeg);
    sa = sind(alphaDeg);

    A = [
        ct, -st*ca,  st*sa, a*ct
        st,  ct*ca, -ct*sa, a*st
         0,     sa,     ca,    d
         0,      0,      0,    1
    ];
end

function p = extraerPunto(T)
    p = T(1:3, 4).';
end
