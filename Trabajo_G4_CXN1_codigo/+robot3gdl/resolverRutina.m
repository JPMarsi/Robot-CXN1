function resultado = resolverRutina(tabla, robot, modoSeleccion)
% RESOLVERRUTINA Valida puntos cartesianos, calcula CI y trayectoria LSPB.

    if nargin < 3
        modoSeleccion = 'auto';
    end

    tabla = normalizarTabla(tabla);
    n = size(tabla, 1);
    if n < 2
        error('La rutina necesita al menos dos puntos.');
    end

    Q = zeros(n, 3);
    detalles = [];
    qAnterior = [];

    for i = 1:n
        P = [tabla.X(i), tabla.Y(i), tabla.Z(i)];
        [q, detalle] = robot3gdl.seleccionarSolucion(P, robot, modoSeleccion, qAnterior, tabla.Config{i});
        Q(i,:) = q;
        if isempty(detalles)
            detalles = repmat(detalle, n, 1);
        else
            detalles(i) = detalle;
        end
        qAnterior = q;
    end

    robot3gdl.validarLimites(Q, robot, 'Puntos articulares');
    tray = robot3gdl.generarTrayectoriaLSPB(Q, robot);
    robot3gdl.validarLimites(tray.Q, robot, 'Trayectoria muestreada');

    resultado.rutina = tabla;
    resultado.Qpuntos = Q;
    resultado.detalles = detalles;
    resultado.trayectoria = tray;
end

function tabla = normalizarTabla(datos)
    if istable(datos)
        nombresEsperados = {'Nombre', 'X', 'Y', 'Z', 'Config'};
        if all(ismember(nombresEsperados, datos.Properties.VariableNames))
            tabla = datos(:, nombresEsperados);
            tabla.Nombre = normalizarTexto(tabla.Nombre, 'Punto');
            tabla.X = normalizarNumeros(tabla.X, 'X');
            tabla.Y = normalizarNumeros(tabla.Y, 'Y');
            tabla.Z = normalizarNumeros(tabla.Z, 'Z');
            tabla.Config = normalizarConfig(tabla.Config);
            return;
        end
        datos = table2cell(datos);
    end

    if isempty(datos)
        error('La tabla de rutina esta vacia.');
    end

    if isnumeric(datos)
        if size(datos, 2) < 3
            error('Una rutina numerica debe tener columnas X, Y, Z.');
        end
        n = size(datos, 1);
        nombres = arrayfun(@(i) sprintf('Punto %d', i), (1:n).', 'UniformOutput', false);
        xyz = datos(:, 1:3);
        config = repmat({'auto'}, n, 1);
    else
        if ~iscell(datos)
            datos = cellstr(string(datos));
        end
        if size(datos, 2) < 5
            error('La rutina debe tener columnas Nombre, X, Y, Z y Config.');
        end
        nombres = normalizarTexto(datos(:, 1), 'Punto');
        xyz = [
            normalizarNumeros(datos(:, 2), 'X'), ...
            normalizarNumeros(datos(:, 3), 'Y'), ...
            normalizarNumeros(datos(:, 4), 'Z')
        ];
        config = normalizarConfig(datos(:, 5));
    end

    tabla = table(nombres, xyz(:,1), xyz(:,2), xyz(:,3), config, ...
        'VariableNames', {'Nombre', 'X', 'Y', 'Z', 'Config'});
end

function valores = normalizarNumeros(columna, nombre)
    if isnumeric(columna)
        valores = double(columna(:));
        return;
    end

    if iscell(columna)
        valores = zeros(numel(columna), 1);
        for i = 1:numel(columna)
            item = columna{i};
            if isnumeric(item)
                valores(i) = double(item);
            elseif isstring(item) || ischar(item)
                valores(i) = str2double(strrep(char(item), ',', '.'));
            else
                valores(i) = NaN;
            end
        end
    else
        valores = str2double(strrep(cellstr(string(columna(:))), ',', '.'));
    end

    if any(~isfinite(valores))
        error('La columna %s contiene valores no numericos.', nombre);
    end
end

function textos = normalizarTexto(columna, prefijo)
    if iscell(columna)
        textos = columna(:);
    else
        textos = cellstr(string(columna(:)));
    end

    for i = 1:numel(textos)
        if isnumeric(textos{i})
            textos{i} = num2str(textos{i});
        elseif isstring(textos{i})
            textos{i} = char(textos{i});
        elseif ~ischar(textos{i})
            textos{i} = char(string(textos{i}));
        end
        if isempty(strtrim(textos{i}))
            textos{i} = sprintf('%s %d', prefijo, i);
        end
    end
end

function config = normalizarConfig(columna)
    if iscell(columna)
        config = columna(:);
    else
        config = cellstr(string(columna(:)));
    end
    validas = {'auto', 'arriba', 'abajo'};
    for i = 1:numel(config)
        item = config{i};
        if isstring(item)
            item = char(item);
        elseif isnumeric(item)
            item = num2str(item);
        elseif ~ischar(item)
            item = char(string(item));
        end
        valor = lower(strtrim(item));
        if isempty(valor)
            valor = 'auto';
        end
        if ~ismember(valor, validas)
            error('Configuracion invalida en fila %d: %s. Use auto, arriba o abajo.', i, config{i});
        end
        config{i} = valor;
    end
end
