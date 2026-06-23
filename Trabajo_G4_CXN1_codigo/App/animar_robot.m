function animar_robot(tray, robot, rutina, fps, velocidadReproduccion)
% ANIMAR_ROBOT Animación sincronizada y fluida del robot.
%
% Entradas:
%   tray                   Trayectorias articulares
%   robot                  Parámetros geométricos
%   fps                    Cuadros por segundo de la animación
%   velocidadReproduccion  1 = tiempo real
%                          2 = doble velocidad
%
% Ejemplo:
%   animar_robot(tray, robot, 25, 1);

    if nargin < 3 || isempty(fps)
        fps = 25;
    end

    if nargin < 4 || isempty(velocidadReproduccion)
        velocidadReproduccion = 1;
    end

    if fps <= 0
        error('fps debe ser mayor que cero.');
    end

    if velocidadReproduccion <= 0
        error('velocidadReproduccion debe ser mayor que cero.');
    end

    %% 1. Crear los instantes de visualización

    tiempoFinal = tray.t(end);

    tVisual = 0:(1/fps):tiempoFinal;

    if tVisual(end) < tiempoFinal
        tVisual(end+1) = tiempoFinal;
    end

    nFrames = length(tVisual);

    %% 2. Interpolar los ángulos para la animación

    q1Visual = interp1(tray.t, tray.q1, tVisual, 'linear');
    q2Visual = interp1(tray.t, tray.q2, tVisual, 'linear');
    q3Visual = interp1(tray.t, tray.q3, tVisual, 'linear');

    %% 3. Precalcular toda la geometría antes de animar

    puntosRobot = zeros(4, 3, nFrames);
    extremo = zeros(nFrames, 3);

    fprintf('Preparando %d cuadros de animación...\n', nFrames);

    for i = 1:nFrames
        q = [q1Visual(i), q2Visual(i), q3Visual(i)];

        puntosRobot(:,:,i) = cinematica_directa(q, robot);
        extremo(i,:) = puntosRobot(4,:,i);
    end

    %% 4. Crear la figura

    figura = figure( ...
        'Name', 'Animación alámbrica del robot', ...
        'NumberTitle', 'off', ...
        'Renderer', 'opengl');

    ax = axes('Parent', figura);

    hold(ax, 'on');
    grid(ax, 'on');
    axis(ax, 'equal');

    xlabel(ax, 'X [mm]');
    ylabel(ax, 'Y [mm]');
    zlabel(ax, 'Z [mm]');

    alcance = robot.L2 + robot.L3 + 100;

    xlim(ax, [-alcance, alcance]);
    ylim(ax, [-alcance, alcance]);
    zlim(ax, [0, robot.L1 + robot.L2 + robot.L3 + 100]);

    view(ax, 45, 25);

    % Evita cambios automáticos de escala durante la animación
    ax.XLimMode = 'manual';
    ax.YLimMode = 'manual';
    ax.ZLimMode = 'manual';

    %% 5. Ejes de referencia

    plot3(ax, [0 alcance], [0 0], [0 0], 'k--');
    plot3(ax, [0 0], [0 alcance], [0 0], 'k--');
    plot3(ax, [0 0], [0 0], [0 alcance], 'k--');
%% Puntos originales pedidos por el usuario

puntosOriginales = rutina.puntos;

hOriginales = plot3(ax, ...
    puntosOriginales(:,1), ...
    puntosOriginales(:,2), ...
    puntosOriginales(:,3), ...
    'o', ...
    'MarkerSize', 8, ...
    'LineWidth', 1.5, ...
    'DisplayName', 'Puntos originales');

%% Puntos intermedios generados por densificación

Qusada = tray.Q_usada;
nUsados = size(Qusada, 1);

puntosUsados = zeros(nUsados, 3);

for i = 1:nUsados

    puntosRobotIntermedio = cinematica_directa( ...
        Qusada(i,:), robot);

    puntosUsados(i,:) = puntosRobotIntermedio(4,:);
end

hUsados = plot3(ax, ...
    puntosUsados(:,1), ...
    puntosUsados(:,2), ...
    puntosUsados(:,3), ...
    'x', ...
    'MarkerSize', 7, ...
    'LineWidth', 1.2, ...
    'DisplayName', 'Puntos usados');

legend(ax, [hOriginales, hUsados], ...
    'Location', 'best');
    %% 6. Crear objetos gráficos una sola vez

    hRobot = plot3(ax, ...
        puntosRobot(:,1,1), ...
        puntosRobot(:,2,1), ...
        puntosRobot(:,3,1), ...
        'o-', ...
        'LineWidth', 3, ...
        'MarkerSize', 6);

    hTrayectoria = plot3(ax, ...
        extremo(1,1), ...
        extremo(1,2), ...
        extremo(1,3), ...
        '-', ...
        'LineWidth', 1.2);

    hTitulo = title(ax, '');

    %% 7. Animación sincronizada

    reloj = tic;

    frameMostrado = 0;
    ultimaActualizacionTitulo = -inf;

    while ishandle(figura)

        tiempoReal = toc(reloj);

        % Tiempo lógico correspondiente al reloj real
        tiempoLogico = tiempoReal * velocidadReproduccion;

        if tiempoLogico >= tiempoFinal
            frameObjetivo = nFrames;
        else
            frameObjetivo = floor(tiempoLogico * fps) + 1;
        end

        frameObjetivo = min(max(frameObjetivo, 1), nFrames);

        % Solo actualizar si corresponde mostrar un cuadro nuevo
        if frameObjetivo ~= frameMostrado

            set(hRobot, ...
                'XData', puntosRobot(:,1,frameObjetivo), ...
                'YData', puntosRobot(:,2,frameObjetivo), ...
                'ZData', puntosRobot(:,3,frameObjetivo));

            % Se muestra la trayectoria completa hasta el cuadro actual
            set(hTrayectoria, ...
                'XData', extremo(1:frameObjetivo,1), ...
                'YData', extremo(1:frameObjetivo,2), ...
                'ZData', extremo(1:frameObjetivo,3));

            % Actualizar el título solo cinco veces por segundo
            if tiempoLogico - ultimaActualizacionTitulo >= 0.20 || ...
                    frameObjetivo == nFrames

                qActual = [ ...
                    q1Visual(frameObjetivo), ...
                    q2Visual(frameObjetivo), ...
                    q3Visual(frameObjetivo)];

                hTitulo.String = sprintf( ...
                    't lógico = %.2f s de %.2f s | q = [%.1f, %.1f, %.1f]°', ...
                    tVisual(frameObjetivo), ...
                    tiempoFinal, ...
                    qActual(1), qActual(2), qActual(3));

                ultimaActualizacionTitulo = tiempoLogico;
            end

            % Procesa únicamente el redibujado necesario
            drawnow nocallbacks;

            frameMostrado = frameObjetivo;
        end

        if frameObjetivo >= nFrames
            break;
        end

        % Libera brevemente el procesador
        pause(0.001);
    end

    tiempoRealFinal = toc(reloj);

    fprintf('\nDuración lógica: %.2f s\n', tiempoFinal);
    fprintf('Duración real: %.2f s\n', tiempoRealFinal);
    fprintf('Frecuencia visual configurada: %.1f FPS\n', fps);
end