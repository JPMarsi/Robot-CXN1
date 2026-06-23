function graficar_articulacion(tray, articulacion)
% GRAFICAR_ARTICULACION Grafica posición, velocidad y aceleración
% de una articulación seleccionada.
%
% Entrada:
%   tray         -> estructura de trayectorias
%   articulacion -> 1, 2 o 3

    if articulacion == 1
        q = tray.q1;
        w = tray.w1;
        g = tray.g1;
        nombre = 'Articulación 1 - Base';
    elseif articulacion == 2
        q = tray.q2;
        w = tray.w2;
        g = tray.g2;
        nombre = 'Articulación 2 - Hombro';
    elseif articulacion == 3
        q = tray.q3;
        w = tray.w3;
        g = tray.g3;
        nombre = 'Articulación 3 - Codo';
    else
        error('La articulación debe ser 1, 2 o 3.');
    end

    figure('Name', ['Graficas ', nombre]);

    subplot(3,1,1);
    plot(tray.t, q, 'LineWidth', 1.5);
    grid on;
    xlabel('Tiempo [s]');
    ylabel('q [deg]');
    title(['Posición - ', nombre]);

    subplot(3,1,2);
    plot(tray.t, w, 'LineWidth', 1.5);
    grid on;
    xlabel('Tiempo [s]');
    ylabel('w [deg/s]');
    title(['Velocidad - ', nombre]);

    subplot(3,1,3);
    plot(tray.t, g, 'LineWidth', 1.5);
    grid on;
    xlabel('Tiempo [s]');
    ylabel('a [deg/s^2]');
    title(['Aceleración - ', nombre]);
end