function rutina = rutinaEjemplo(robot)
% RUTINAEJEMPLO Rutina validada que recorre varios cuadrantes y vuelve a Home.

    if nargin < 1
        robot = robot3gdl.parametrosRobot();
    end

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

    for i = 1:size(puntos, 1)
        robot3gdl.seleccionarSolucion(puntos(i,:), robot, 'manual', [], config{i});
    end

    rutina = table(nombres, puntos(:,1), puntos(:,2), puntos(:,3), config, ...
        'VariableNames', {'Nombre', 'X', 'Y', 'Z', 'Config'});
end
