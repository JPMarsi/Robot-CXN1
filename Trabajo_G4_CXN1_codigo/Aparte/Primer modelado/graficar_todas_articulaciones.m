function graficar_todas_articulaciones(tray, robot)
% GRAFICAR_TODAS_ARTICULACIONES
% Muestra posición, velocidad y aceleración de q1, q2 y q3
% en una sola figura.
%
% Entradas:
%   tray  -> estructura generada por generar_trayectorias
%   robot -> estructura con límites articulares

    t = tray.t(:);

    Q = [
        tray.q1(:), ...
        tray.q2(:), ...
        tray.q3(:)
    ];

    W = [
        tray.w1(:), ...
        tray.w2(:), ...
        tray.w3(:)
    ];

    G = [
        tray.g1(:), ...
        tray.g2(:), ...
        tray.g3(:)
    ];

    nombres = {
        'q_1 - Base'
        'q_2 - Hombro'
        'q_3 - Codo'
    };

    figura = figure( ...
        'Name', 'Trayectorias articulares completas', ...
        'NumberTitle', 'off');

    tiledlayout(figura, 3, 3, ...
        'TileSpacing', 'compact', ...
        'Padding', 'compact');

    for j = 1:3

        %% Posición
        nexttile(j);

        plot(t, Q(:,j), 'LineWidth', 1.4);
        hold on;
        grid on;

        yline(robot.qMin(j), '--', ...
            sprintf('Límite mínimo %.0f°', robot.qMin(j)));

        yline(robot.qMax(j), '--', ...
            sprintf('Límite máximo %.0f°', robot.qMax(j)));

        xlabel('Tiempo [s]');
        ylabel('q [deg]');
        title(['Posición - ', nombres{j}]);

        %% Velocidad
        nexttile(j + 3);

        plot(t, W(:,j), 'LineWidth', 1.4);
        grid on;

        xlabel('Tiempo [s]');
        ylabel('\omega [deg/s]');
        title(['Velocidad - ', nombres{j}]);

        %% Aceleración
        nexttile(j + 6);

        plot(t, G(:,j), 'LineWidth', 1.4);
        hold on;
        grid on;

        yline(robot.a, '--', ...
            sprintf('+%.0f°/s²', robot.a));

        yline(-robot.a, '--', ...
            sprintf('-%.0f°/s²', robot.a));

        xlabel('Tiempo [s]');
        ylabel('\alpha [deg/s²]');
        title(['Aceleración - ', nombres{j}]);
    end

    sgtitle('Trayectorias articulares del robot de 3 GDL');
end