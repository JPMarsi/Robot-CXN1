function reporte = validarTrayectoria(tray, robot)
% VALIDARTRAYECTORIA Valida coherencia numerica y fisica de una trayectoria.

    tol = 1e-7;
    reporte = struct();
    reporte.ok = true;
    reporte.mensajes = {};

    campos = {'t', 'Q', 'dQ', 'ddQ'};
    for i = 1:numel(campos)
        valor = tray.(campos{i});
        if any(~isfinite(valor(:))) || any(~isreal(valor(:)))
            error('Trayectoria invalida: %s contiene NaN, Inf o complejos.', campos{i});
        end
    end

    n = numel(tray.t);
    if size(tray.Q,1) ~= n || size(tray.dQ,1) ~= n || size(tray.ddQ,1) ~= n
        error('Trayectoria invalida: longitudes inconsistentes entre t, Q, dQ y ddQ.');
    end

    if any(diff(tray.t) <= robot.tolTiempo)
        error('Trayectoria invalida: el tiempo no es estrictamente creciente.');
    end

    robot3gdl.validarLimites(tray.Q, robot, 'Trayectoria muestreada');

    if any(abs(tray.ddQ(:)) > robot.aMax + 1e-6)
        error('Trayectoria invalida: aceleracion supera aMax.');
    end

    mascaraAceleracion = abs(tray.ddQ) < 1e-6 | abs(abs(tray.ddQ) - robot.aMax) < 1e-6;
    if any(~mascaraAceleracion(:))
        error('Trayectoria invalida: la aceleracion debe ser exclusivamente -aMax, 0 o +aMax.');
    end

    for j = 1:3
        if max(abs(tray.dQ(:,j))) > robot.vMax(j) + 1e-6
            error('Trayectoria invalida: la articulacion q%d supera su velocidad maxima.', j);
        end
    end

    if any(abs(tray.dQ(1,:)) > robot.tolVelocidad) || any(abs(tray.dQ(end,:)) > robot.tolVelocidad)
        error('Trayectoria invalida: velocidad inicial o final distinta de cero.');
    end

    for i = 1:numel(tray.indicesPuntos)
        idx = tray.indicesPuntos(i);
        if any(abs(tray.dQ(idx,:)) > 1e-5)
            error('Trayectoria invalida: velocidad no nula en parada %d.', i);
        end
        if max(abs(tray.Q(idx,:) - tray.Qpuntos(i,:))) > 1e-5
            error('Trayectoria invalida: punto objetivo %d no coincide con muestra final.', i);
        end
    end

    if isfield(tray, 'rangosDescanso')
        for k = 1:size(tray.rangosDescanso, 1)
            rango = tray.rangosDescanso(k,1):tray.rangosDescanso(k,2);
            if any(any(abs(tray.dQ(rango,:)) > tol))
                error('Trayectoria invalida: velocidad no nula durante descanso %d.', k);
            end
            if any(any(abs(tray.ddQ(rango,:)) > tol))
                error('Trayectoria invalida: aceleracion no nula durante descanso %d.', k);
            end
        end
    end

    if isfield(tray, 'diagnostico') && isfield(robot, 'tLinealMin')
        for i = 1:numel(tray.diagnostico)
            d = tray.diagnostico(i);
            idxInicio = buscarIndiceTiempo(tray.t, d.inicio, robot.tolTiempo);
            idxLlegada = buscarIndiceTiempo(tray.t, d.llegada, robot.tolTiempo);
            if isempty(idxInicio) || isempty(idxLlegada)
                error('Trayectoria invalida: tramo %d no tiene muestras exactas de inicio y llegada.', i);
            end

            if max(abs(tray.Q(idxInicio,:) - d.qi)) > 1e-5
                error('Trayectoria invalida: q(inicio) no coincide en tramo %d.', i);
            end
            if max(abs(tray.Q(idxLlegada,:) - d.qf)) > 1e-5
                error('Trayectoria invalida: q(final) no coincide en tramo %d.', i);
            end
            if any(abs(tray.dQ(idxInicio,:)) > 1e-5) || any(abs(tray.dQ(idxLlegada,:)) > 1e-5)
                error('Trayectoria invalida: dq(inicio) o dq(final) no es cero en tramo %d.', i);
            end

            rangoTramo = idxInicio:idxLlegada;
            tau = tray.t(rangoTramo) - d.inicio;
            for j = 1:3
                if abs(d.delta(j)) > 1e-12 && d.tc(j) < robot.tLinealMin - 1e-9
                    error('Trayectoria invalida: tramo %d q%d no respeta tc >= tLinealMin.', i, j);
                end
                esperado = aceleracionEsperadaTramo(tau, d, j, robot.aMax, robot.tolTiempo);
                errorAcel = max(abs(tray.ddQ(rangoTramo,j) - esperado));
                if errorAcel > 1e-6
                    error('Trayectoria invalida: ddq desfasada o incorrecta en tramo %d q%d.', i, j);
                end
            end
        end
    end
end

function idx = buscarIndiceTiempo(t, objetivo, tol)
    idx = find(abs(t - objetivo) <= max(tol, 1e-9), 1, 'first');
end

function ddq = aceleracionEsperadaTramo(tau, d, j, aMax, tolTiempo)
    ddq = zeros(size(tau));
    if abs(d.delta(j)) <= 1e-12
        return;
    end

    signo = sign(d.delta(j));
    tb = d.tb(j);
    tLinealFin = d.tb(j) + d.tc(j);
    tf = d.tfUsado;
    tol = max(tolTiempo, 1e-8);
    tau(abs(tau - tb) <= tol) = tb;
    tau(abs(tau - tLinealFin) <= tol) = tLinealFin;
    tau(abs(tau - tf) <= tol) = tf;

    ddq(tau < tb) = signo*aMax;
    ddq(tau >= tLinealFin & tau < tf) = -signo*aMax;
end
