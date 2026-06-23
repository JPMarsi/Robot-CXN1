function Qd = densificar_tramos_articulares(Q, robot)

    a = robot.a;
    tf = robot.tf;

    deltaMaxTeorico = a*tf^2/4;
    deltaMax = 0.90*deltaMaxTeorico;

    Qd = Q(1,:);

    for i = 1:(size(Q,1)-1)

        qIni = Q(i,:);
        qFin = Q(i+1,:);

        dq = qFin - qIni;

        [saltoMaximo, articulacionCritica] = max(abs(dq));

        if saltoMaximo <= deltaMax

            Qd = [Qd; qFin];

        else

            nSubtramos = ceil(saltoMaximo/deltaMax);

            fprintf([ ...
                'Tramo %d dividido en %d subtramos.\n' ...
                '  Articulación crítica: %s\n' ...
                '  Desplazamientos: dq = [%.2f, %.2f, %.2f]°\n' ...
                '  Máximo permitido por subtramo: %.2f°\n'], ...
                i, ...
                nSubtramos, ...
                robot.nombreArticulacion{articulacionCritica}, ...
                dq(1), dq(2), dq(3), ...
                deltaMax);

            for k = 1:nSubtramos

                lambda = k/nSubtramos;
                qIntermedio = qIni + lambda*dq;

                Qd = [Qd; qIntermedio];
            end
        end
    end
end