function reporte = validarLimites(Q, robot, etiqueta)
% VALIDARLIMITES Valida matriz Nx3 contra limites articulares.

    if nargin < 3
        etiqueta = 'Valores articulares';
    end

    if size(Q, 2) ~= 3
        error('%s: Q debe ser Nx3.', etiqueta);
    end

    tol = 1e-9;
    debajo = Q < (robot.qMin - tol);
    encima = Q > (robot.qMax + tol);
    violaciones = debajo | encima;

    reporte.ok = ~any(violaciones(:));
    reporte.violaciones = violaciones;
    reporte.indices = find(any(violaciones, 2));

    if ~reporte.ok
        [fila, col] = find(violaciones, 1, 'first');
        error(['%s fuera de limites. Muestra %d, %s = %.3f deg, ', ...
               'limite [%.3f, %.3f] deg.'], ...
            etiqueta, fila, robot.nombresArticulaciones{col}, Q(fila, col), ...
            robot.qMin(col), robot.qMax(col));
    end
end
