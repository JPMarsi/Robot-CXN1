function tray = generar_trayectorias(Q, robot)
% GENERAR_TRAYECTORIAS

    fprintf('\nGenerando trayectorias articulares con FControl...\n');

    % Validación antes de densificar
    validar_limites_articulares( ...
        Q, robot, 'Puntos articulares originales');

    Q_original = Q;

    % División de movimientos mayores al máximo permitido
    Q = densificar_tramos_articulares(Q, robot);

    % Validación de puntos intermedios
    validar_limites_articulares( ...
        Q, robot, 'Puntos articulares densificados');

    if size(Q,1) > size(Q_original,1)
        fprintf('Se agregaron %d puntos articulares intermedios.\n', ...
                size(Q,1) - size(Q_original,1));
    end

    [tray.q1, tray.w1, tray.g1, tray.t] = ...
        FControl(Q(:,1), robot);

    [tray.q2, tray.w2, tray.g2, ~] = ...
        FControl(Q(:,2), robot);

    [tray.q3, tray.w3, tray.g3, ~] = ...
        FControl(Q(:,3), robot);

    tray.Q_original = Q_original;
    tray.Q_usada = Q;

    % Validar todas las muestras generadas
    Qtray = [tray.q1(:), tray.q2(:), tray.q3(:)];

    validar_limites_articulares( ...
        Qtray, robot, 'Trayectoria completa');

    fprintf('Trayectorias generadas correctamente.\n');
end