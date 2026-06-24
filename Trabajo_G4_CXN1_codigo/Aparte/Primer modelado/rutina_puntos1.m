function rutina = rutina_puntos1()
% RUTINA_PUNTOS
% Rutina cartesiana para escribir la palabra "GAY".
%
% Plano de escritura:
%   X = 500 mm
%
% Movimientos de traslado:
%   X = 560 mm
%
% La herramienta dibuja en el plano X = 500 mm y se aleja
% del plano para pasar de una letra a otra.

    %% Parámetros generales

    xEscritura = 500;
    xTraslado  = 560;
    zTraslado  = 700;

    puntos = [];
    nombres = {};
    config = {};

    %% Función auxiliar para agregar puntos

    function agregarPunto(P, nombre)
        puntos(end+1,:) = P;
        nombres{end+1,1} = nombre;
        config{end+1,1} = 'arriba';
    end

    %% Home inicial

    agregarPunto( ...
        [675, 0, 492], ...
        'Home inicial');

    %% =========================================================
    %  LETRA G
    % ==========================================================

    centroYG = -210;
    centroZG = 475;

    radioYG = 75;
    radioZG = 150;

    angulosG = linspace(45, 315, 13);

    puntosG = zeros(length(angulosG), 3);

    for k = 1:length(angulosG)

        angulo = angulosG(k);

        puntosG(k,:) = [
            xEscritura, ...
            centroYG + radioYG*cosd(angulo), ...
            centroZG + radioZG*sind(angulo)
        ];
    end

    % Acercamiento con herramienta levantada
    agregarPunto( ...
        [xTraslado, puntosG(1,2), zTraslado], ...
        'Traslado hacia G');

    % Inicio de G
    agregarPunto( ...
        puntosG(1,:), ...
        'G - Inicio');

    % Contorno de G
    for k = 2:size(puntosG,1)

        agregarPunto( ...
            puntosG(k,:), ...
            sprintf('G - Contorno %d', k));
    end

    % Barra interior de G
    agregarPunto( ...
        [xEscritura, centroYG + radioYG, centroZG], ...
        'G - Barra exterior');

    agregarPunto( ...
        [xEscritura, centroYG + 10, centroZG], ...
        'G - Barra interior');

    %% Levantar herramienta después de G

    agregarPunto( ...
        [xTraslado, centroYG + 10, zTraslado], ...
        'Levantar herramienta después de G');

    %% =========================================================
    %  LETRA A
    % ==========================================================

    puntosA = [
        xEscritura,  -70, 300;
        xEscritura,    0, 650;
        xEscritura,   70, 300;
        xEscritura,   35, 475;
        xEscritura,  -35, 475
    ];

    agregarPunto( ...
        [xTraslado, puntosA(1,2), zTraslado], ...
        'Traslado hacia A');

    agregarPunto( ...
        puntosA(1,:), ...
        'A - Inicio inferior izquierdo');

    agregarPunto( ...
        puntosA(2,:), ...
        'A - Vértice superior');

    agregarPunto( ...
        puntosA(3,:), ...
        'A - Inferior derecho');

    agregarPunto( ...
        puntosA(4,:), ...
        'A - Barra derecha');

    agregarPunto( ...
        puntosA(5,:), ...
        'A - Barra transversal');

    %% Levantar herramienta después de A

    agregarPunto( ...
        [xTraslado, puntosA(end,2), zTraslado], ...
        'Levantar herramienta después de A');

    %% =========================================================
    %  LETRA Y
    % ==========================================================

    puntosY = [
        xEscritura, 130, 650;
        xEscritura, 200, 480;
        xEscritura, 270, 650;
        xEscritura, 200, 480;
        xEscritura, 200, 300
    ];

    agregarPunto( ...
        [xTraslado, puntosY(1,2), zTraslado], ...
        'Traslado hacia Y');

    agregarPunto( ...
        puntosY(1,:), ...
        'Y - Extremo superior izquierdo');

    agregarPunto( ...
        puntosY(2,:), ...
        'Y - Unión central');

    agregarPunto( ...
        puntosY(3,:), ...
        'Y - Extremo superior derecho');

    agregarPunto( ...
        puntosY(4,:), ...
        'Y - Regreso al centro');

    agregarPunto( ...
        puntosY(5,:), ...
        'Y - Extremo inferior');

    %% Levantar herramienta y volver a Home

    agregarPunto( ...
        [xTraslado, puntosY(end,2), zTraslado], ...
        'Levantar herramienta final');

    agregarPunto( ...
        [675, 0, 492], ...
        'Home final');

    %% Salida

    rutina.puntos = puntos;
    rutina.nombres = nombres;
    rutina.config = config;
end