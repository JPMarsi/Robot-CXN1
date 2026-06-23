function [q, detalle] = seleccionarSolucion(P, robot, modo, qAnterior, configManual)
% SELECCIONARSOLUCION Elige una solucion de CI manual o automaticamente.

    if nargin < 4
        qAnterior = [];
    end
    if nargin < 5 || isempty(configManual)
        configManual = 'auto';
    end

    [soluciones, info] = robot3gdl.solucionesCI(P, robot);
    if isempty(soluciones)
        error('Punto [%.3f %.3f %.3f] invalido: %s', P(1), P(2), P(3), info.mensaje);
    end

    modo = lower(string(modo));
    configManual = lower(string(configManual));

    if modo == "manual" && configManual ~= "auto"
        configs = string({soluciones.config});
        idx = find(configs == configManual, 1, 'first');
        if isempty(idx)
            error('El punto [%.3f %.3f %.3f] no tiene solucion valida codo %s.', ...
                P(1), P(2), P(3), configManual);
        end
    else
        costos = calcularCostos(soluciones, robot, qAnterior);
        [~, idx] = min(costos);
    end

    q = soluciones(idx).q;
    detalle = soluciones(idx);
    detalle.info = info;
end

function costos = calcularCostos(soluciones, robot, qAnterior)
    n = numel(soluciones);
    costos = zeros(n, 1);
    for i = 1:n
        q = soluciones(i).q;
        if isempty(qAnterior)
            desplazamiento = 0.05*norm(q);
            cambioConfig = 0;
        else
            desplazamiento = 8*norm(q - qAnterior);
            cambioConfig = 0;
        end

        margenInf = q - robot.qMin;
        margenSup = robot.qMax - q;
        margenNorm = min(margenInf, margenSup) ./ max(robot.qMax - robot.qMin, eps);
        penalLimites = 10*sum(1 ./ max(margenNorm, 0.02));

        penalSing = 30 / max(abs(sind(q(3))), 0.05);
        if ~isempty(qAnterior)
            prevConfig = signoConfig(qAnterior, robot);
            cambioConfig = 80 * double(prevConfig ~= string(soluciones(i).config));
        end

        costos(i) = desplazamiento + penalLimites + cambioConfig + penalSing;
    end
end

function config = signoConfig(q, robot)
    puntos = robot3gdl.cinematicaDirecta(q, robot);
    r = hypot(puntos(4,1), puntos(4,2));
    z = puntos(4,3) - robot.L1;
    rc = hypot(puntos(3,1), puntos(3,2));
    zc = puntos(3,3) - robot.L1;
    valor = zc - z*rc/max(r, robot.tol);
    if valor >= 0
        config = "arriba";
    else
        config = "abajo";
    end
end
