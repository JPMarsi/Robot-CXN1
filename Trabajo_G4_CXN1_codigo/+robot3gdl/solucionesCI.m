function [soluciones, info] = solucionesCI(P, robot)
% SOLUCIONESCI Calcula todas las soluciones reales y dentro de limites.

    P = P(:).';
    px = P(1);
    py = P(2);
    pz = P(3);

    r = hypot(px, py);
    z = pz - robot.L1;
    D = hypot(r, z);
    q1 = atan2d(py, px);

    info = struct();
    info.r = r;
    info.z = z;
    info.D = D;
    info.alcanceOk = false;
    info.mensaje = '';

    if r < robot.tol
        info.mensaje = 'Px y Py son casi cero; q1 queda indeterminada.';
        soluciones = struct([]);
        return;
    end

    if D > robot.L2 + robot.L3 + robot.tol
        info.mensaje = 'Punto fuera del alcance maximo.';
        soluciones = struct([]);
        return;
    end

    if D < abs(robot.L2 - robot.L3) - robot.tol
        info.mensaje = 'Punto dentro de la zona no alcanzable.';
        soluciones = struct([]);
        return;
    end

    C = (r^2 + z^2 - robot.L2^2 - robot.L3^2)/(2*robot.L2*robot.L3);
    C = min(1, max(-1, C));
    beta = atan2d(z, r);
    q3c = [acosd(C), -acosd(C)];

    candidatos = repmat(struct( ...
        'q', [NaN NaN NaN], ...
        'config', '', ...
        'codoValor', NaN, ...
        'error', NaN, ...
        'limitesOk', false, ...
        'singularidad', NaN), 1, 2);

    for k = 1:2
        q3 = q3c(k);
        alpha = atan2d(robot.L3*sind(q3), robot.L2 + robot.L3*cosd(q3));
        q2 = beta + alpha;
        q = [q1, q2, q3];

        puntos = robot3gdl.cinematicaDirecta(q, robot);
        err = norm(puntos(4,:) - P);
        rc = hypot(puntos(3,1), puntos(3,2));
        zc = puntos(3,3) - robot.L1;
        zLinea = z * rc / max(r, robot.tol);
        codoValor = zc - zLinea;

        candidatos(k).q = q;
        candidatos(k).config = ternario(codoValor >= 0, 'arriba', 'abajo');
        candidatos(k).codoValor = codoValor;
        candidatos(k).error = err;
        candidatos(k).limitesOk = all(q >= robot.qMin - 1e-9) && all(q <= robot.qMax + 1e-9);
        candidatos(k).singularidad = min(abs(sind(q3)), abs(D - (robot.L2 + robot.L3)));
    end

    info.alcanceOk = true;
    soluciones = candidatos([candidatos.limitesOk] & [candidatos.error] <= robot.tolReconstruccion);
    if isempty(soluciones)
        info.mensaje = 'Existen soluciones geometricas, pero ninguna cumple limites articulares.';
    else
        info.mensaje = 'OK';
    end
end

function y = ternario(condicion, valorVerdadero, valorFalso)
    if condicion
        y = valorVerdadero;
    else
        y = valorFalso;
    end
end
