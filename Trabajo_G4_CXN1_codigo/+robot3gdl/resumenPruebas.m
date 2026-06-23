function resumen = resumenPruebas(resultado, robot)
% RESUMENPRUEBAS Calcula metricas numericas basicas de una solucion.

    Q = resultado.trayectoria.Q;
    P = zeros(size(Q, 1), 3);
    for i = 1:size(Q, 1)
        puntos = robot3gdl.cinematicaDirecta(Q(i,:), robot);
        P(i,:) = puntos(4,:);
    end

    errPuntos = zeros(size(resultado.Qpuntos, 1), 1);
    for i = 1:size(resultado.Qpuntos, 1)
        puntos = robot3gdl.cinematicaDirecta(resultado.Qpuntos(i,:), robot);
        objetivo = [resultado.rutina.X(i), resultado.rutina.Y(i), resultado.rutina.Z(i)];
        errPuntos(i) = norm(puntos(4,:) - objetivo);
    end

    resumen.errorMaxReconstruccion = max(errPuntos);
    resumen.tieneNaNInf = any(~isfinite(Q(:))) || any(~isfinite(resultado.trayectoria.dQ(:))) || any(~isfinite(resultado.trayectoria.ddQ(:)));
    resumen.violacionesLimites = sum(any(Q < robot.qMin - 1e-9 | Q > robot.qMax + 1e-9, 2));
    resumen.saltosMaximos = max(abs(diff(Q)), [], 1);
    resumen.posicionesExtremo = P;
end
