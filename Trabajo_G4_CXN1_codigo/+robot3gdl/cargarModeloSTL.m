function modelo = cargarModeloSTL(rutaArchivo, opciones)
% CARGARMODELOSTL Carga STL si existe y devuelve vertices/caras para patch.

    if nargin < 2
        opciones = struct();
    end

    [~, nombre, ext] = fileparts(rutaArchivo);
    modelo = struct();
    modelo.vertices = zeros(0, 3);
    modelo.faces = zeros(0, 3);
    modelo.disponible = false;
    modelo.ruta = rutaArchivo;
    modelo.nombre = [nombre ext];
    modelo.mensaje = '';

    if ~isfile(rutaArchivo)
        modelo.mensaje = sprintf('No existe %s.', rutaArchivo);
        return;
    end

    try
        datos = stlread(rutaArchivo);
        if isa(datos, 'triangulation')
            modelo.vertices = datos.Points;
            modelo.faces = datos.ConnectivityList;
        elseif isstruct(datos)
            if isfield(datos, 'Points') && isfield(datos, 'ConnectivityList')
                modelo.vertices = datos.Points;
                modelo.faces = datos.ConnectivityList;
            elseif isfield(datos, 'vertices') && isfield(datos, 'faces')
                modelo.vertices = datos.vertices;
                modelo.faces = datos.faces;
            elseif isfield(datos, 'Vertices') && isfield(datos, 'Faces')
                modelo.vertices = datos.Vertices;
                modelo.faces = datos.Faces;
            else
                error('Formato struct de stlread no reconocido.');
            end
        elseif iscell(datos) && numel(datos) >= 2
            modelo.faces = datos{1};
            modelo.vertices = datos{2};
        else
            error('Formato devuelto por stlread no reconocido.');
        end

        modelo.vertices = double(modelo.vertices);
        modelo.faces = double(modelo.faces);
        if size(modelo.vertices, 2) ~= 3 || size(modelo.faces, 2) ~= 3
            error('El STL no contiene vertices Nx3 y caras Mx3.');
        end

        modelo.disponible = true;
        modelo.mensaje = 'OK';

        escala = obtenerCampo(opciones, 'escala', 1);
        tamano = max(modelo.vertices, [], 1) - min(modelo.vertices, [], 1);
        fprintf('STL %s | tamano [X Y Z] = [%.3f %.3f %.3f] | escala = %.6g\n', ...
            modelo.nombre, tamano(1), tamano(2), tamano(3), escala);
        if max(tamano) < 1 || max(tamano) > 5000
            warning('Robot3GDL:STLSize', ...
                'Tamano posiblemente incompatible para %s: max %.3f mm.', modelo.nombre, max(tamano));
        end
    catch ME
        modelo.disponible = false;
        modelo.mensaje = sprintf('Error leyendo %s: %s', rutaArchivo, ME.message);
    end
end

function valor = obtenerCampo(s, nombre, defecto)
    if isfield(s, nombre)
        valor = s.(nombre);
    else
        valor = defecto;
    end
end
