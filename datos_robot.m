function robot = datos_robot()
% DATOS_ROBOT Define parámetros geométricos y de control del robot.

    robot.L1 = 492;
    robot.L2 = 365;
    robot.L3 = 310;

    robot.a = 100;
    robot.tf = 2.0;
    robot.tdesc = 0.2;
    robot.tm = 0.02;

    % Límites físicos articulares [deg]
    robot.qMin = [-170, -80, -130];
    robot.qMax = [ 170, 120,  130];

    % Nombres para mensajes
    robot.nombreArticulacion = {
        'q1 - Base'
        'q2 - Hombro'
        'q3 - Codo'
    };

    robot.tol = 1e-6;
    robot.tolSing = 1e-3;
end