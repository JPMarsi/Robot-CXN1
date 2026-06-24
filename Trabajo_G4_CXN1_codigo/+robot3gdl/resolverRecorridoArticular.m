function resultado = resolverRecorridoArticular(qInicial, qFinal, qMin, qMax, nombre)
% RESOLVERRECORRIDOARTICULAR Decide el desplazamiento fisico admisible.
%
% No aplica unwrap global. Para articulaciones con intervalo mecanico
% limitado, la trayectoria admisible debe permanecer dentro de [qMin,qMax].

    if nargin < 5
        nombre = 'q';
    end

    tol = 1e-9;
    resultado = struct();
    resultado.articulacion = nombre;
    resultado.qInicial = qInicial;
    resultado.qFinal = qFinal;
    resultado.qMin = qMin;
    resultado.qMax = qMax;
    resultado.deltaDirecto = qFinal - qInicial;
    resultado.deltaCortoEquivalente = deltaAngularCorto(qInicial, qFinal);
    resultado.delta = resultado.deltaDirecto;
    resultado.sentido = sign(resultado.delta);
    resultado.esAdmisible = true;
    resultado.requiereTiempoExtra = false;
    resultado.motivo = 'Recorrido directo dentro de limites.';
    resultado.puntosIntermedios = [];
    resultado.discontinuidadRepresentacion = abs(resultado.deltaDirecto - resultado.deltaCortoEquivalente) > 180 - tol;
    resultado.caminoCortoAdmisible = false;
    resultado.caminoCortoDescartado = false;
    resultado.movimientoLargoPermitido = false;

    if qInicial < qMin - tol || qInicial > qMax + tol
        resultado.esAdmisible = false;
        resultado.motivo = sprintf('%s inicial %.3f fuera de [%.3f, %.3f].', nombre, qInicial, qMin, qMax);
        error(resultado.motivo);
    end

    if qFinal < qMin - tol || qFinal > qMax + tol
        resultado.esAdmisible = false;
        resultado.motivo = sprintf('%s final %.3f fuera de [%.3f, %.3f].', nombre, qFinal, qMin, qMax);
        error(resultado.motivo);
    end

    qCortoFinalContinuo = qInicial + resultado.deltaCortoEquivalente;
    resultado.caminoCortoAdmisible = intervaloLinealDentroLimites(qInicial, qCortoFinalContinuo, qMin, qMax, tol) && ...
        abs(qCortoFinalContinuo - qFinal) <= tol;

    if abs(resultado.deltaCortoEquivalente) < abs(resultado.deltaDirecto) - tol && ~resultado.caminoCortoAdmisible
        resultado.caminoCortoDescartado = true;
        resultado.movimientoLargoPermitido = true;
        resultado.motivo = sprintf(['Camino angular corto %.3f deg descartado para %s: ', ...
            'atraviesa representacion fuera de limites. Se usa recorrido fisico %.3f deg dentro del intervalo.'], ...
            resultado.deltaCortoEquivalente, nombre, resultado.deltaDirecto);
    end

    if ~intervaloLinealDentroLimites(qInicial, qFinal, qMin, qMax, tol)
        resultado.esAdmisible = false;
        resultado.motivo = sprintf('%s requiere atravesar limites entre %.3f y %.3f.', nombre, qInicial, qFinal);
        error(resultado.motivo);
    end
end

function delta = deltaAngularCorto(qInicial, qFinal)
    delta = mod((qFinal - qInicial) + 180, 360) - 180;
    if abs(delta + 180) < 1e-12
        delta = 180;
    end
end

function ok = intervaloLinealDentroLimites(a, b, qMin, qMax, tol)
    ok = min(a, b) >= qMin - tol && max(a, b) <= qMax + tol;
end
