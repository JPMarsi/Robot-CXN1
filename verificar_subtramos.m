function resumen = verificar_subtramos(Q, robot)
% VERIFICAR_SUBTRAMOS
% Comprueba que ningún desplazamiento articular de un subtramo
% supere el máximo permitido.
%
% Entrada:
%   Q      -> matriz Nx3 de posiciones articulares densificadas
%   robot  -> estructura del robot
%
% Salida:
%   resumen -> estructura con máximos y estado de validación

    if size(Q,2) ~= 3
        error('Q debe ser una matriz Nx3.');
    end

    dQ = diff(Q, 1, 1);

    % Debe ser el mismo criterio usado en densificar_tramos_articulares
    deltaMaxTeorico = robot.a * robot.tf^2 / 4;
    deltaMaxPermitido = 0.90 * deltaMaxTeorico;

    maximosPorArticulacion = max(abs(dQ), [], 1);
    maximoGlobal = max(abs(dQ(:)));

    [~, indiceLineal] = max(abs(dQ(:)));
    [tramoCritico, articulacionCritica] = ind2sub( ...
        size(dQ), indiceLineal);

    resumen.dQ = dQ;
    resumen.maximos = maximosPorArticulacion;
    resumen.maximoGlobal = maximoGlobal;
    resumen.tramoCritico = tramoCritico;
    resumen.articulacionCritica = articulacionCritica;
    resumen.deltaMaxPermitido = deltaMaxPermitido;
    resumen.esValido = all(abs(dQ(:)) <= deltaMaxPermitido + 1e-9);

    fprintf('\n');
    fprintf('RESUMEN DE SUBTRAMOS ARTICULARES\n');
    fprintf('============================================\n');

    fprintf('Máximo permitido por subtramo: %.3f°\n', ...
        deltaMaxPermitido);

    fprintf('Máximo observado en q1: %.3f°\n', ...
        maximosPorArticulacion(1));

    fprintf('Máximo observado en q2: %.3f°\n', ...
        maximosPorArticulacion(2));

    fprintf('Máximo observado en q3: %.3f°\n', ...
        maximosPorArticulacion(3));

    fprintf('Máximo global: %.3f°\n', maximoGlobal);

    fprintf('Tramo más exigente: %d\n', tramoCritico);
    fprintf('Articulación crítica: q%d\n', articulacionCritica);

    if resumen.esValido
        fprintf('Resultado: todos los subtramos son válidos.\n');
    else
        error([ ...
            'Existe al menos un subtramo que supera %.3f°.\n' ...
            'Tramo crítico: %d\n' ...
            'Articulación crítica: q%d\n' ...
            'Valor observado: %.3f°.'], ...
            deltaMaxPermitido, ...
            tramoCritico, ...
            articulacionCritica, ...
            maximoGlobal);
    end
end