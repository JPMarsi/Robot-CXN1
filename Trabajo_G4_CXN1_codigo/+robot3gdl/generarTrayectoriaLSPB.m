function tray = generarTrayectoriaLSPB(Qpuntos, robot)
% GENERARTRAYECTORIALSPB Genera LSPB trapezoidal sincronizado por tramo.

    if size(Qpuntos, 2) ~= 3
        error('Qpuntos debe ser Nx3.');
    end
    if size(Qpuntos, 1) < 2
        error('Qpuntos debe tener al menos dos filas.');
    end

    a = robot.aMax;
    vMax = robot.vMax(:).';
    dt = robot.tMuestreo;
    tfNom = robot.tfNominal;
    tDead = robot.tMuerto;
    tLinealMin = robot.tLinealMin;
    margenTiempo = robot.margenTiempo;
    QpuntosOriginal = Qpuntos;
    [Qpuntos, indicesOriginales, infoDensificacion] = densificarPuntosFControl(QpuntosOriginal, robot);

    t = [];
    Q = [];
    dQ = [];
    ddQ = [];
    tiemposTramo = zeros(size(Qpuntos, 1)-1, 1);
    ajustados = false(size(tiemposTramo));
    tiempoActual = 0;
    tPuntos = zeros(size(Qpuntos, 1), 1);
    tInicioTramo = zeros(size(Qpuntos, 1)-1, 1);
    tParabolicoLineal = NaN(size(Qpuntos, 1)-1, 3);
    tLinealParabolico = NaN(size(Qpuntos, 1)-1, 3);
    indicesPuntos = zeros(size(Qpuntos, 1), 1);
    indicesPuntos(1) = 1;
    rangosDescanso = zeros(0, 2);
    diagnostico = repmat(crearDiagnosticoVacio(), size(Qpuntos, 1)-1, 1);

    for s = 1:numel(tiemposTramo)
        qi = Qpuntos(s,:);
        qf = Qpuntos(s+1,:);
        recorridos = [];
        delta = zeros(1, 3);
        for j = 1:3
            recorrido = robot3gdl.resolverRecorridoArticular( ...
                qi(j), qf(j), robot.qMin(j), robot.qMax(j), robot.nombresArticulaciones{j});
            if isempty(recorridos)
                recorridos = repmat(recorrido, 1, 3);
            else
                recorridos(j) = recorrido;
            end
            delta(j) = recorridos(j).delta;
        end

        D = abs(delta);
        [tfMinArt, parametrosMinimos] = tiemposMinimosArticulares(D, a, vMax, tLinealMin);
        [tfMin, idxLimitante] = max(tfMinArt);
        tf = max(tfNom, tfMin + margenTiempo);
        parametros = parametrosParaTiempoComun(D, tf, a, vMax, tLinealMin);
        tf = asegurarTiempoComun(D, tf, a, vMax, tLinealMin, margenTiempo, parametros);
        parametros = parametrosParaTiempoComun(D, tf, a, vMax, tLinealMin);

        if tf > tfNom + 1e-9
            ajustados(s) = true;
        end
        tiemposTramo(s) = tf;
        tInicioTramo(s) = tiempoActual;

        for j = 1:3
            if parametros(j).activo
                tParabolicoLineal(s,j) = tiempoActual + parametros(j).tb;
                tLinealParabolico(s,j) = tiempoActual + parametros(j).tb + parametros(j).tc;
            end
        end

        diagnostico(s) = crearDiagnosticoTramo(s, qi, qf, delta, tfNom, tfMin, tf, ...
            idxLimitante, recorridos, ajustados(s), parametros, parametrosMinimos, tiempoActual, a);

        tLocal = muestrasTramoConTransiciones( ...
    tf, dt, parametros, robot.tolTiempo);
        if ~isempty(t) && abs(tiempoActual + tLocal(1) - t(end)) <= robot.tolTiempo
            tLocal = tLocal(2:end);
        end

        [qSeg, dqSeg, ddqSeg] = perfilSegmento(qi, delta, tf, a, parametros, tLocal);
        t = [t; tiempoActual + tLocal(:)]; %#ok<AGROW>
        Q = [Q; qSeg]; %#ok<AGROW>
        dQ = [dQ; dqSeg]; %#ok<AGROW>
        ddQ = [ddQ; ddqSeg]; %#ok<AGROW>

        tiempoActual = tiempoActual + tf;
        tPuntos(s+1) = tiempoActual;
        indicesPuntos(s+1) = numel(t);

        agregarMuerto = tDead > 0 && (s < numel(tiemposTramo) || robot.agregarTiempoMuertoFinal);
        if agregarMuerto
            tM = muestrasDescanso(tDead, dt, robot.tolTiempo);
            if ~isempty(tM)
                t = [t; tiempoActual + tM(:)]; %#ok<AGROW>
                Q = [Q; repmat(qf, numel(tM), 1)]; %#ok<AGROW>
                dQ = [dQ; zeros(numel(tM), 3)]; %#ok<AGROW>
                ddQ = [ddQ; zeros(numel(tM), 3)]; %#ok<AGROW>
                rangosDescanso(end+1,:) = [numel(t) - numel(tM) + 1, numel(t)]; %#ok<AGROW>
            end
            tiempoActual = tiempoActual + tDead;
        end
    end

    tray.t = t;
    tray.Q = Q;
    tray.dQ = dQ;
    tray.ddQ = ddQ;
    tray.Qpuntos = Qpuntos;
    tray.QpuntosOriginal = QpuntosOriginal;
    tray.tPuntos = tPuntos;
    tray.tPuntosOriginal = tPuntos(indicesOriginales);
    tray.indicesPuntos = indicesPuntos;
    tray.indicesPuntosOriginal = indicesPuntos(indicesOriginales);
    tray.rangosDescanso = rangosDescanso;
    tray.tiemposTramo = tiemposTramo;
    tray.tInicioTramo = tInicioTramo;
    tray.tParabolicoLineal = tParabolicoLineal;
    tray.tLinealParabolico = tLinealParabolico;
    tray.tramosAjustados = ajustados;
    tray.diagnostico = diagnostico;
    tray.densificacion = infoDensificacion;

    robot3gdl.validarTrayectoria(tray, robot);
    imprimirDiagnostico(diagnostico);
end

function [Qd, indicesOriginales, info] = densificarPuntosFControl(Q, robot)
% DENSIFICARPUNTOSFCONTROL Densifica tramos que superan el barrido nominal.
%
% Si el mayor desplazamiento articular del tramo es estrictamente mayor que
% el barrido maximo que puede resolver el perfil FControl con los parametros
% actuales, se agregan puntos intermedios lineales para que cada subtramo
% conserve el perfil parabolico-lineal-parabolico esperado.

    [deltaMax, detalleDelta] = robot3gdl.calcularDeltaMaxDensificacion(robot);

    Qd = Q(1,:);
    indicesOriginales = zeros(size(Q, 1), 1);
    indicesOriginales(1) = 1;
    divisiones = ones(size(Q, 1)-1, 1);

    for i = 1:(size(Q, 1)-1)
        qIni = Q(i,:);
        qFin = Q(i+1,:);
        dq = qFin - qIni;
        excesoPorArticulacion = abs(dq) ./ deltaMax;
        saltoMaximo = max(excesoPorArticulacion);

        if all(abs(dq) <= deltaMax + 1e-9)
            Qd = [Qd; qFin]; %#ok<AGROW>
            divisiones(i) = 1;
        else
            nSubtramos = ceil(saltoMaximo);
            divisiones(i) = nSubtramos;
            fprintf(['Tramo %d dividido en %d subtramos tipo FControl. ', ...
                'dq = [%.2f %.2f %.2f] deg, ', ...
                'deltaMax = [%.2f %.2f %.2f] deg.\n'], ...
                i, nSubtramos, dq(1), dq(2), dq(3), deltaMax(1), deltaMax(2), deltaMax(3));

            for k = 1:nSubtramos
                lambda = k/nSubtramos;
                Qd = [Qd; qIni + lambda*dq]; %#ok<AGROW>
            end
        end
        indicesOriginales(i+1) = size(Qd, 1);
    end

    info = struct();
    info.Qoriginal = Q;
    info.Qcontrol = Qd;
    info.indicesOriginales = indicesOriginales;
    info.divisiones = divisiones;
    info.deltaMax = deltaMax;
    info.detalleDeltaMax = detalleDelta;
end

function tLocal = muestrasTramoConTransiciones(tf, dt, parametros, tol)
% MUESTRASTRAMOCONTRANSICIONES
% Construye el vector temporal incluyendo obligatoriamente:
%
%   t = 0
%   t = tb
%   t = tb + tc
%   t = tf
%
% para las tres articulaciones.
%
% De esta manera los cambios de aceleracion ocurren exactamente
% en los instantes teoricos y no en la muestra posterior.

    % Muestreo regular
    tRegular = 0:dt:tf;

    if isempty(tRegular)
        tRegular = 0;
    end

    % Asegurar el tiempo final exacto
    if abs(tRegular(end) - tf) > tol
        tRegular(end+1) = tf;
    else
        tRegular(end) = tf;
    end

    % Eventos exactos del perfil LSPB
    eventos = [0, tf];

    for j = 1:numel(parametros)
        if parametros(j).activo
            tb = parametros(j).tb;
            tLinealFin = parametros(j).tb + parametros(j).tc;

            eventos(end+1) = tb; %#ok<AGROW>
            eventos(end+1) = tLinealFin; %#ok<AGROW>
        end
    end

    % Combinar muestreo regular y transiciones exactas
    tLocal = sort([tRegular(:); eventos(:)]);

    % Eliminar tiempos repetidos o casi repetidos
    conservar = true(size(tLocal));

    for k = 2:numel(tLocal)
        if abs(tLocal(k) - tLocal(k-1)) <= tol
            conservar(k) = false;
        end
    end

    tLocal = tLocal(conservar);

    % Forzar extremos exactos
    tLocal(1) = 0;
    tLocal(end) = tf;
end

function tM = muestrasDescanso(tDead, dt, tol)
    limite = tDead - tol;
    if limite <= 0
        tM = [];
        return;
    end
    tM = dt:dt:limite;
end

function [tfMinArt, parametrosMinimos] = tiemposMinimosArticulares(D, aMax, vMax, tLinealMin)
    tfMinArt = zeros(1, 3);
    parametrosMinimos = repmat(parametroVacio(), 1, 3);
    for j = 1:3
        [tfMinArt(j), parametrosMinimos(j)] = tiempoMinimoArticulacion(D(j), aMax, vMax(j), tLinealMin);
    end
end

function [tfMin, p] = tiempoMinimoArticulacion(D, aMax, vMax, tLinealMin)
    p = parametroVacio();
    if D < 1e-12
        tfMin = 0;
        return;
    end

    tb = (-tLinealMin + sqrt(tLinealMin^2 + 4*D/aMax))/2;
    vRegimen = aMax*tb;
    if vRegimen <= vMax + 1e-9
        tc = tLinealMin;
    else
        tb = vMax/aMax;
        tc = D/vMax - tb;
        if tc < tLinealMin - 1e-9
            error('No se puede construir perfil trapezoidal visible sin superar vMax.');
        end
        vRegimen = vMax;
    end

    tfMin = 2*tb + tc;
    p.activo = true;
    p.tb = tb;
    p.tc = tc;
    p.tf = tfMin;
    p.vRegimen = vRegimen;
end

function tf = asegurarTiempoComun(D, tf, aMax, vMax, tLinealMin, margen, parametros)
    for intento = 1:100
        cumple = true;
        for j = 1:3
            if D(j) < 1e-12
                continue;
            end
            cumple = cumple && parametros(j).activo ...
                && parametros(j).tb > 0 ...
                && parametros(j).tc >= tLinealMin - 1e-9 ...
                && parametros(j).vRegimen <= vMax(j) + 1e-8;
        end
        if cumple
            return;
        end
        tf = tf + max(margen, 1e-4);
        parametros = parametrosParaTiempoComun(D, tf, aMax, vMax, tLinealMin);
    end
    error('No se pudo ajustar el tiempo comun para obtener perfiles trapezoidales visibles.');
end

function parametros = parametrosParaTiempoComun(D, tf, aMax, vMax, tLinealMin)
    parametros = repmat(parametroVacio(), 1, 3);
    for j = 1:3
        if D(j) < 1e-12
            continue;
        end
        discriminante = tf^2 - 4*D(j)/aMax;
        if discriminante < -1e-9
            continue;
        end
        discriminante = max(discriminante, 0);
        tb = 0.5*(tf - sqrt(discriminante));
        tc = tf - 2*tb;
        vRegimen = aMax*tb;

        parametros(j).activo = true;
        parametros(j).tb = tb;
        parametros(j).tc = tc;
        parametros(j).tf = tf;
        parametros(j).vRegimen = vRegimen;
        parametros(j).valido = tb > 0 ...
            && tc >= tLinealMin - 1e-9 ...
            && vRegimen <= vMax(j) + 1e-8;
    end
end

function p = parametroVacio()
    p = struct('activo', false, 'valido', true, 'tb', 0, 'tc', 0, 'tf', 0, 'vRegimen', 0);
end

function d = crearDiagnosticoVacio()
    d = struct( ...
        'tramo', NaN, ...
        'qi', [NaN NaN NaN], ...
        'qf', [NaN NaN NaN], ...
        'delta', [NaN NaN NaN], ...
        'tfNominal', NaN, ...
        'tfMinimo', NaN, ...
        'tfUsado', NaN, ...
        'tb', [NaN NaN NaN], ...
        'tc', [NaN NaN NaN], ...
        'vRegimen', [NaN NaN NaN], ...
        'inicio', NaN, ...
        'llegada', NaN, ...
        'tipoPerfil', {{'', '', ''}}, ...
        'articulacionLimitante', '', ...
        'estado', '', ...
        'observaciones', '');
end

function d = crearDiagnosticoTramo(tramo, qi, qf, delta, tfNom, tfMin, tf, idxLimitante, recorridos, ajustado, parametros, parametrosMinimos, inicio, aMax)
    d = crearDiagnosticoVacio();
    d.tramo = tramo;
    d.qi = qi;
    d.qf = qf;
    d.delta = delta;
    d.tfNominal = tfNom;
    d.tfMinimo = tfMin;
    d.tfUsado = tf;
    d.inicio = inicio;
    d.llegada = inicio + tf;
    d.articulacionLimitante = sprintf('q%d', idxLimitante);
    d.estado = ternario(ajustado, 'tiempo aumentado', 'nominal');

    for j = 1:3
        if parametros(j).activo
            d.tb(j) = parametros(j).tb;
            d.tc(j) = parametros(j).tc;
            d.vRegimen(j) = sign(delta(j))*parametros(j).vRegimen;
            d.tipoPerfil{j} = 'trapezoidal';
        else
            d.tb(j) = 0;
            d.tc(j) = 0;
            d.vRegimen(j) = 0;
            d.tipoPerfil{j} = 'nulo';
        end
    end

    obs = {};
    for j = 1:numel(recorridos)
        if recorridos(j).caminoCortoDescartado
            obs{end+1} = sprintf('q%d descarta camino corto %.1f deg; usa %.1f deg', ...
                j, recorridos(j).deltaCortoEquivalente, recorridos(j).delta); %#ok<AGROW>
        end
        if parametrosMinimos(j).activo
            vMin = sign(delta(j))*parametrosMinimos(j).vRegimen;
            obs{end+1} = sprintf('q%d min tb=%.3f tc=%.3f v=%.3f', ...
                j, parametrosMinimos(j).tb, parametrosMinimos(j).tc, vMin); %#ok<AGROW>
        end
    end
    if ajustado
        obs{end+1} = sprintf('tf %.3f -> %.3f s', tfNom, tf); %#ok<AGROW>
    end
    if any(abs(delta) > 1e-12)
        obs{end+1} = sprintf('a=%.3f deg/s^2', aMax); %#ok<AGROW>
    end
    if isempty(obs)
        d.observaciones = '-';
    else
        d.observaciones = strjoin(obs, '; ');
    end
end

function imprimirDiagnostico(diagnostico)
    fprintf('\nDiagnostico de trayectoria LSPB tipo FControl\n');
    fprintf(['Tramo | inicio llegada | tf_nom tf_usado | ', ...
             'tb q1 q2 q3 | tc q1 q2 q3 | vreg q1 q2 q3 | estado | observaciones\n']);
    for i = 1:numel(diagnostico)
        d = diagnostico(i);
        fprintf(['%5d | %7.3f %7.3f | %6.3f %8.3f | ', ...
                 '%6.3f %6.3f %6.3f | %6.3f %6.3f %6.3f | ', ...
                 '%8.3f %8.3f %8.3f | %s | %s\n'], ...
            d.tramo, d.inicio, d.llegada, d.tfNominal, d.tfUsado, ...
            d.tb(1), d.tb(2), d.tb(3), d.tc(1), d.tc(2), d.tc(3), ...
            d.vRegimen(1), d.vRegimen(2), d.vRegimen(3), d.estado, d.observaciones);
    end
end

function y = ternario(condicion, verdadero, falso)
    if condicion
        y = verdadero;
    else
        y = falso;
    end
end

function [Q, dQ, ddQ] = perfilSegmento(qi, deltaUsado, tf, a, parametros, tau)
    n = numel(tau);
    Q = zeros(n, 3);
    dQ = zeros(n, 3);
    ddQ = zeros(n, 3);

    for j = 1:3
        delta = deltaUsado(j);
        distancia = abs(delta);
        if distancia < 1e-12
            Q(:,j) = qi(j);
            continue;
        end

        signo = sign(delta);
        p = parametros(j);
        tb = p.tb;
        tc = p.tc;
        tLinealFin = tb + tc;
        qFinalContinuo = qi(j) + delta;
        vRegimen = signo*p.vRegimen;

        for k = 1:n
            tk = tau(k);
            if tk < tb
                Q(k,j) = qi(j) + 0.5*signo*a*tk^2;
                dQ(k,j) = signo*a*tk;
                ddQ(k,j) = signo*a;
            elseif tk < tLinealFin
                Q(k,j) = qi(j) + 0.5*signo*a*tb^2 + vRegimen*(tk - tb);
                dQ(k,j) = vRegimen;
                ddQ(k,j) = 0;
            elseif tk < tf
                tr = tf - tk;
                Q(k,j) = qFinalContinuo - 0.5*signo*a*tr^2;
                dQ(k,j) = signo*a*tr;
                ddQ(k,j) = -signo*a;
            else
                Q(k,j) = qFinalContinuo;
                dQ(k,j) = 0;
                ddQ(k,j) = 0;
            end
        end
    end
end
