function [q, info] = cinematica_inversa(P, robot, config, qAnterior)
% CINEMATICA_INVERSA Resuelve theta1, theta2, theta3 para un punto P.
%
% Convención usada en la cinemática directa:
%   r = L2*cos(theta2) + L3*cos(theta2 - theta3)
%   z = L2*sin(theta2) + L3*sin(theta2 - theta3)
%
% La función calcula las dos soluciones posibles y selecciona:
%   'arriba' -> codo por encima de la recta hombro-extremo
%   'abajo'  -> codo por debajo de la recta hombro-extremo
%   'auto'   -> solución más cercana a qAnterior
%
% Entradas:
%   P         = [Px Py Pz] en mm
%   robot     = estructura de datos del robot
%   config    = 'arriba', 'abajo' o 'auto'
%   qAnterior = solución anterior [theta1 theta2 theta3]
%
% Salidas:
%   q    = [theta1 theta2 theta3] en grados
%   info = estructura con datos de validación

    if nargin < 4
        qAnterior = [];
    end

    px = P(1);
    py = P(2);
    pzAbs = P(3);

    L1 = robot.L1;
    L2 = robot.L2;
    L3 = robot.L3;

    % Coordenadas reducidas al plano vertical del brazo
    r = sqrt(px^2 + py^2);
    z = pzAbs - L1;

    % Cintura. atan2d evita problemas de cuadrante.
    theta1 = atan2d(py, px);

    % Ley del coseno para theta3
    C = (r^2 + z^2 - L2^2 - L3^2)/(2*L2*L3);

    % Corrección de pequeños errores numéricos
    if C > 1 && C < 1 + 1e-9
        C = 1;
    elseif C < -1 && C > -1 - 1e-9
        C = -1;
    end

    if C > 1 || C < -1
        error('No existe solución real para el punto [%.3f %.3f %.3f].', px, py, pzAbs);
    end

    beta = atan2d(z, r);

    % Se calculan ambas ramas. Después se etiqueta por geometría real.
    theta3_pos = acosd(C);
    theta3_neg = -acosd(C);
    candidatosTheta3 = [theta3_pos, theta3_neg];

    candidatos = zeros(2, 3);
    codoValor = zeros(2, 1);
    errorCD = zeros(2, 1);

    for k = 1:2
        theta3 = candidatosTheta3(k);

        % Ángulo auxiliar. Con esta forma se respeta la convención
        % de la cinemática directa usada en este programa.
        alpha = atan2d(L3*sind(theta3), L2 + L3*cosd(theta3));
        theta2 = beta + alpha;

        qk = [theta1, theta2, theta3];
        candidatos(k, :) = qk;

        puntos = cinematica_directa(qk, robot);
        Pcalc = puntos(4, :);
        errorCD(k) = norm(Pcalc - P);

        % Clasificación geométrica de codo.
        % Se mide si el codo queda por arriba o por abajo de la recta
        % hombro-extremo en el plano r-z.
        Pcodo = puntos(3, :);
        rCodo = sqrt(Pcodo(1)^2 + Pcodo(2)^2);
        zCodo = Pcodo(3) - L1;

        if r > robot.tol
            zLinea = z * (rCodo/r);
            codoValor(k) = zCodo - zLinea;
        else
            codoValor(k) = 0;
        end
    end

    config = lower(config);

    if strcmp(config, 'arriba')
        [~, idx] = max(codoValor);
    elseif strcmp(config, 'abajo')
        [~, idx] = min(codoValor);
    elseif strcmp(config, 'auto')
        if isempty(qAnterior)
            [~, idx] = max(codoValor);
        else
            dif = candidatos - qAnterior;
            costo = sqrt(sum(dif.^2, 2));
            [~, idx] = min(costo);
        end
    else
        error('Configuración de codo no reconocida: %s. Use arriba, abajo o auto.', config);
    end

    q = candidatos(idx, :);

    if errorCD(idx) > 1e-5
        error('Error de verificación CD demasiado alto: %.6f mm.', errorCD(idx));
    end

    info.r = r;
    info.z = z;
    info.D = sqrt(r^2 + z^2);
    info.codoValor = codoValor(idx);
    info.errorCD = errorCD(idx);

    if info.codoValor >= 0
        info.codoDetectado = 'arriba';
    else
        info.codoDetectado = 'abajo';
    end
end
