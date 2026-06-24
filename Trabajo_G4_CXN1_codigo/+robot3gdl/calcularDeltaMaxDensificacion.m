function [deltaMax, detalle] = calcularDeltaMaxDensificacion(robot)
% CALCULARDELTAMAXDENSIFICACION Barrido maximo nominal por articulacion.
%
% Para un perfil LSPB con aceleracion a, tiempo total tf y tramo lineal
% minimo tc, el mayor desplazamiento que entra sin aumentar tf es:
%
%   Delta = a*tb*(tf - tb), con tb = (tf - tc)/2
%
% Si tc = 0, se recupera el limite triangular clasico:
%
%   Delta = a*tf^2/4

    if isfield(robot, 'deltaMaxDensificacion')
        valor = robot.deltaMaxDensificacion;
        if isnumeric(valor) && ~isempty(valor) && all(isfinite(valor(:))) && all(valor(:) > 0)
            deltaMax = double(valor(:)).';
            if isscalar(deltaMax)
                deltaMax = repmat(deltaMax, 1, 3);
            end
            if numel(deltaMax) ~= 3
                error('deltaMaxDensificacion debe ser escalar, vector 1x3 o ''auto''.');
            end
            detalle = detalleManual(deltaMax);
            return;
        end
    end

    aMax = robot.aMax;
    tf = robot.tfNominal;
    tLinealMin = obtenerCampo(robot, 'tLinealMin', 0);
    vMax = obtenerCampo(robot, 'vMax', [Inf Inf Inf]);
    vMax = vMax(:).';
    if isscalar(vMax)
        vMax = repmat(vMax, 1, 3);
    end

    if tf <= tLinealMin
        error('tfNominal debe ser mayor que tLinealMin para calcular el barrido maximo automatico.');
    end

    tbVisible = (tf - tLinealMin)/2;
    tbPorVelocidad = vMax ./ aMax;
    tb = min(tbVisible, tbPorVelocidad);
    deltaMax = aMax .* tb .* (tf - tb);

    detalle = struct();
    detalle.modo = 'auto';
    detalle.aMax = aMax;
    detalle.tfNominal = tf;
    detalle.tLinealMin = tLinealMin;
    detalle.vMax = vMax;
    detalle.tbMax = tb;
    detalle.deltaTriangular = aMax*tf^2/4;
    detalle.deltaVisibleSinLimiteVelocidad = aMax*(tf^2 - tLinealMin^2)/4;
    detalle.deltaMax = deltaMax;
end

function detalle = detalleManual(deltaMax)
    detalle = struct();
    detalle.modo = 'manual';
    detalle.aMax = NaN;
    detalle.tfNominal = NaN;
    detalle.tLinealMin = NaN;
    detalle.vMax = [NaN NaN NaN];
    detalle.tbMax = [NaN NaN NaN];
    detalle.deltaTriangular = NaN;
    detalle.deltaVisibleSinLimiteVelocidad = NaN;
    detalle.deltaMax = deltaMax;
end

function valor = obtenerCampo(s, nombre, defecto)
    if isfield(s, nombre)
        valor = s.(nombre);
    else
        valor = defecto;
    end
end
