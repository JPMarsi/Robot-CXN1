function rutina = rutinaEjemplo(robot, ejemplo)
% RUTINAEJEMPLO Devuelve una rutina cartesiana de ejemplo validada.

    if nargin < 1
        robot = robot3gdl.parametrosRobot();
    end
    if nargin < 2 || isempty(ejemplo)
        ejemplo = 'profesor';
    end

    ejemplo = lower(strtrim(char(ejemplo)));
    switch ejemplo
        case {'profesor', 'profe', 'default'}
            rutina = rutinaProfesor(robot);
        case 'estrella'
            rutina = rutinaEstrella(robot);
        case {'aleatorio1', 'random1'}
            rutina = rutinaAleatoria(robot, 11, 'Aleatorio 1');
        case {'aleatorio2', 'random2'}
            rutina = rutinaAleatoria(robot, 29, 'Aleatorio 2');
        otherwise
            error('Ejemplo desconocido: %s.', ejemplo);
    end
end

function rutina = rutinaProfesor(robot)
% Rutina entregada por el profesor.
    nombres = {
        'Home inicial'
        'Q1 codo arriba'
        'Q4 codo arriba'
        'Q2 codo abajo'
        'Q3 codo arriba'
        'Q2 alto codo abajo'
        'Home final'
    };

    puntos = [
         675.0,    0.0,  492.0
         483.5,  338.6,  595.3
         311.0, -444.2,  379.4
         -15.5,  177.2, 1049.5
        -185.0, -320.4,   58.3
        -262.8,  220.6,  983.3
         675.0,    0.0,  492.0
    ];

    config = {'arriba'; 'arriba'; 'arriba'; 'abajo'; 'arriba'; 'abajo'; 'arriba'};
    rutina = construirTabla(nombres, puntos, config);
    validarRutina(rutina, robot, 'manual');
end

function rutina = rutinaEstrella(robot)
% Pentagrama horizontal dentro del espacio alcanzable del robot.
    radio = 430;
    zPlano = 600;
    angulos = [90, 234, 18, 162, 306, 90];

    puntos = zeros(numel(angulos) + 2, 3);
    nombres = cell(size(puntos, 1), 1);
    puntos(1,:) = [675, 0, 492];
    nombres{1} = 'Home inicial';

    for i = 1:numel(angulos)
        ang = angulos(i);
        puntos(i+1,:) = [radio*cosd(ang), radio*sind(ang), zPlano];
        nombres{i+1} = sprintf('Estrella %02d', i);
    end

    puntos(end,:) = puntos(1,:);
    nombres{end} = 'Home final';

    config = repmat({'auto'}, size(puntos, 1), 1);
    rutina = construirTabla(nombres, puntos, config);
    validarRutina(rutina, robot, 'auto');
end

function rutina = rutinaAleatoria(robot, semilla, nombreBase)
% Rutina pseudoaleatoria reproducible generada desde puntos articulares validos.
    rng(semilla, 'twister');

    nIntermedios = 6;
    q = zeros(nIntermedios + 2, 3);
    q(1,:) = [0, 0, 0];
    q(end,:) = [0, 0, 0];

    for i = 2:nIntermedios+1
        q(i,1) = -125 + 250*rand();
        q(i,2) = -35 + 115*rand();
        q(i,3) = -95 + 205*rand();
    end

    puntos = zeros(size(q));
    for i = 1:size(q, 1)
        cd = robot3gdl.cinematicaDirecta(q(i,:), robot);
        puntos(i,:) = cd(end,:);
    end

    nombres = cell(size(q, 1), 1);
    nombres{1} = 'Home inicial';
    for i = 2:nIntermedios+1
        nombres{i} = sprintf('%s %02d', nombreBase, i-1);
    end
    nombres{end} = 'Home final';

    config = repmat({'auto'}, size(puntos, 1), 1);
    rutina = construirTabla(nombres, puntos, config);
    validarRutina(rutina, robot, 'auto');
end

function rutina = construirTabla(nombres, puntos, config)
    rutina = table(nombres(:), puntos(:,1), puntos(:,2), puntos(:,3), config(:), ...
        'VariableNames', {'Nombre', 'X', 'Y', 'Z', 'Config'});
end

function validarRutina(rutina, robot, modo)
    qAnterior = [];
    for i = 1:height(rutina)
        P = [rutina.X(i), rutina.Y(i), rutina.Z(i)];
        [q, ~] = robot3gdl.seleccionarSolucion(P, robot, modo, qAnterior, rutina.Config{i});
        qAnterior = q;
    end
end
