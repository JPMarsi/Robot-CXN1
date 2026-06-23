function tray = generarTrayectoriaLSPB(Qpuntos, robot)
% GENERARTRAYECTORIALSPB Genera LSPB sincronizado por tramo para 3 juntas.

    if size(Qpuntos, 2) ~= 3
        error('Qpuntos debe ser Nx3.');
    end
    if size(Qpuntos, 1) < 2
        error('Qpuntos debe tener al menos dos filas.');
    end

    a = robot.aMax;
    dt = robot.tMuestreo;
    tfNom = robot.tfNominal;
    tDead = robot.tMuerto;

    t = [];
    Q = [];
    dQ = [];
    ddQ = [];
    tiemposTramo = zeros(size(Qpuntos, 1)-1, 1);
    ajustados = false(size(tiemposTramo));
    tiempoActual = 0;
    tPuntos = zeros(size(Qpuntos, 1), 1);

    for s = 1:numel(tiemposTramo)
        qi = Qpuntos(s,:);
        qf = Qpuntos(s+1,:);
        delta = qf - qi;
        dmax = max(abs(delta));
        tfMin = 2*sqrt(max(dmax, 0)/a);
        tf = max(tfNom, tfMin);
        if tf > tfNom + 1e-9
            ajustados(s) = true;
        end
        tiemposTramo(s) = tf;

        tLocal = 0:dt:tf;
        if tLocal(end) < tf
            tLocal(end+1) = tf;
        end
        if s > 1
            tLocal = tLocal(2:end);
        end

        [qSeg, dqSeg, ddqSeg] = perfilSegmento(qi, qf, tf, a, tLocal);
        t = [t; tiempoActual + tLocal(:)]; %#ok<AGROW>
        Q = [Q; qSeg]; %#ok<AGROW>
        dQ = [dQ; dqSeg]; %#ok<AGROW>
        ddQ = [ddQ; ddqSeg]; %#ok<AGROW>

        tiempoActual = tiempoActual + tf;
        tPuntos(s+1) = tiempoActual;

        agregarMuerto = tDead > 0 && (s < numel(tiemposTramo) || robot.agregarTiempoMuertoFinal);
        if agregarMuerto
            tM = dt:dt:tDead;
            if isempty(tM) || tM(end) < tDead
                tM(end+1) = tDead;
            end
            t = [t; tiempoActual + tM(:)]; %#ok<AGROW>
            Q = [Q; repmat(qf, numel(tM), 1)]; %#ok<AGROW>
            dQ = [dQ; zeros(numel(tM), 3)]; %#ok<AGROW>
            ddQ = [ddQ; zeros(numel(tM), 3)]; %#ok<AGROW>
            tiempoActual = tiempoActual + tDead;
        end
    end

    tray.t = t;
    tray.Q = Q;
    tray.dQ = dQ;
    tray.ddQ = ddQ;
    tray.Qpuntos = Qpuntos;
    tray.tPuntos = tPuntos;
    tray.tiemposTramo = tiemposTramo;
    tray.tramosAjustados = ajustados;
end

function [Q, dQ, ddQ] = perfilSegmento(qi, qf, tf, a, tau)
    n = numel(tau);
    Q = zeros(n, 3);
    dQ = zeros(n, 3);
    ddQ = zeros(n, 3);

    for j = 1:3
        delta = qf(j) - qi(j);
        distancia = abs(delta);
        if distancia < 1e-12
            Q(:,j) = qi(j);
            continue;
        end

        signo = sign(delta);
        raiz = max(tf^2 - 4*distancia/a, 0);
        tb = 0.5*(tf - sqrt(raiz));
        vmax = signo*a*tb;

        for k = 1:n
            tk = tau(k);
            if tk <= tb
                Q(k,j) = qi(j) + 0.5*signo*a*tk^2;
                dQ(k,j) = signo*a*tk;
                ddQ(k,j) = signo*a;
            elseif tk <= tf - tb
                Q(k,j) = qi(j) + 0.5*signo*a*tb^2 + vmax*(tk - tb);
                dQ(k,j) = vmax;
                ddQ(k,j) = 0;
            else
                tr = tf - tk;
                Q(k,j) = qf(j) - 0.5*signo*a*tr^2;
                dQ(k,j) = signo*a*tr;
                ddQ(k,j) = -signo*a;
            end
        end
    end
end
