function robot = parametrosRobot()
% PARAMETROSROBOT Parametros por defecto del robot antropomorfico de 3 GDL.

    robot.L1 = 492;
    robot.L2 = 365;
    robot.L3 = 310;

    robot.qMin = [-170, -80, -130];
    robot.qMax = [ 170, 120,  130];

    robot.aMax = 100;
    robot.vMax = [100, 100, 100];
    robot.tfNominal = 2.0;
    robot.tLinealMin = 0.30;
    robot.deltaMaxDensificacion = 'auto';
    robot.tMuestreo = 0.02;
    robot.tMuerto = 0.2;
    robot.agregarTiempoMuertoFinal = false;
    robot.margenTiempo = 1e-9;

    robot.tol = 1e-8;
    robot.tolTiempo = 1e-9;
    robot.tolVelocidad = 1e-7;
    robot.tolReconstruccion = 1e-5;
    robot.tolSingularidad = 1e-3;
    robot.nombresArticulaciones = {'q1 - Base', 'q2 - Hombro', 'q3 - Codo'};

    raizProyecto = fileparts(fileparts(mfilename('fullpath')));
    robot.stl.habilitado = true;
    robot.stl.carpeta = fullfile(raizProyecto, 'modelos_stl');
    robot.stl.archivos.base = 'base.stl';
    robot.stl.archivos.eslabon1 = 'eslabon1.stl';
    robot.stl.archivos.eslabon2 = 'eslabon2.stl';
    robot.stl.archivos.eslabon3 = 'eslabon3.stl';
    robot.stl.archivos.efector = 'efector.stl';

    piezas = {'base', 'eslabon1', 'eslabon2', 'eslabon3', 'efector'};
    for i = 1:numel(piezas)
        pieza = piezas{i};
        robot.stl.escala.(pieza) = 1;
        robot.stl.rotacionInicial.(pieza) = [0 0 0];
        robot.stl.traslacionInicial.(pieza) = [0 0 0];
        robot.stl.transformacionLocal.(pieza) = eye(4);
    end
end
