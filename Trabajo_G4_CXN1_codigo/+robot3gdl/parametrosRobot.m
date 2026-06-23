function robot = parametrosRobot()
% PARAMETROSROBOT Parametros por defecto del robot antropomorfico de 3 GDL.

    robot.L1 = 492;
    robot.L2 = 365;
    robot.L3 = 310;

    robot.qMin = [-170, -80, -130];
    robot.qMax = [ 170, 120,  130];

    robot.aMax = 100;
    robot.tfNominal = 2.0;
    robot.tMuestreo = 0.02;
    robot.tMuerto = 0.2;
    robot.agregarTiempoMuertoFinal = false;

    robot.tol = 1e-8;
    robot.tolReconstruccion = 1e-5;
    robot.tolSingularidad = 1e-3;
    robot.nombresArticulaciones = {'q1 - Base', 'q2 - Hombro', 'q3 - Codo'};
end
