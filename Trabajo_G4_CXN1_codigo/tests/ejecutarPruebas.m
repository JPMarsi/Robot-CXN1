function resumen = ejecutarPruebas()
% EJECUTARPRUEBAS Pruebas numericas basicas del proyecto Robot 3 GDL.

    raiz = fileparts(fileparts(mfilename('fullpath')));
    addpath(raiz);

    total = 0;
    fallidas = 0;
    mensajes = {};

    robot = robot3gdl.parametrosRobot();

    [total, fallidas, mensajes] = comprobar(total, fallidas, mensajes, ...
        @() probarRutina(robot), 'Rutina ejemplo completa');
    [total, fallidas, mensajes] = comprobar(total, fallidas, mensajes, ...
        @() probarTiempoMinimo(robot), 'Ajuste automatico de tiempo LSPB');
    [total, fallidas, mensajes] = comprobar(total, fallidas, mensajes, ...
        @() probarPuntoInvalido(robot), 'Rechazo de punto invalido');

    rutina = robot3gdl.rutinaEjemplo(robot);
    resultado = robot3gdl.resolverRutina(rutina, robot, 'auto');
    resumenNumerico = robot3gdl.resumenPruebas(resultado, robot);

    resumen = struct();
    resumen.pruebasSuperadas = total - fallidas;
    resumen.pruebasFallidas = fallidas;
    resumen.errorMaxReconstruccion = resumenNumerico.errorMaxReconstruccion;
    resumen.tieneNaNInf = resumenNumerico.tieneNaNInf;
    resumen.violacionesLimites = resumenNumerico.violacionesLimites;
    resumen.saltosMaximos = resumenNumerico.saltosMaximos;
    resumen.mensajes = mensajes;

    fprintf('\nResumen de pruebas Robot 3 GDL\n');
    fprintf('Pruebas superadas: %d\n', resumen.pruebasSuperadas);
    fprintf('Pruebas fallidas: %d\n', resumen.pruebasFallidas);
    fprintf('Error maximo de reconstruccion: %.6g mm\n', resumen.errorMaxReconstruccion);
    fprintf('Presencia de NaN o Inf: %d\n', resumen.tieneNaNInf);
    fprintf('Violaciones de limites: %d\n', resumen.violacionesLimites);
    fprintf('Saltos maximos entre muestras [q1 q2 q3]: [%.4f %.4f %.4f] deg\n', resumen.saltosMaximos);
    for i = 1:numel(mensajes)
        fprintf('%s\n', mensajes{i});
    end

    if fallidas > 0
        error('Hay pruebas fallidas. Revise el resumen anterior.');
    end
end

function [total, fallidas, mensajes] = comprobar(total, fallidas, mensajes, fn, nombre)
    total = total + 1;
    try
        fn();
        mensajes{end+1} = sprintf('[OK] %s', nombre); %#ok<AGROW>
    catch ME
        fallidas = fallidas + 1;
        mensajes{end+1} = sprintf('[FALLO] %s: %s', nombre, ME.message); %#ok<AGROW>
    end
end

function probarRutina(robot)
    rutina = robot3gdl.rutinaEjemplo(robot);
    resultado = robot3gdl.resolverRutina(rutina, robot, 'auto');
    resumen = robot3gdl.resumenPruebas(resultado, robot);
    assert(resumen.errorMaxReconstruccion < 1e-4, 'Reconstruccion cartesiana fuera de tolerancia.');
    assert(~resumen.tieneNaNInf, 'La trayectoria contiene NaN o Inf.');
    assert(resumen.violacionesLimites == 0, 'La trayectoria viola limites.');
    assert(all(abs(resultado.trayectoria.dQ(1,:)) < 1e-9), 'La trayectoria no inicia con velocidad cero.');
    assert(all(abs(resultado.trayectoria.dQ(end,:)) < 1e-9), 'La trayectoria no termina con velocidad cero.');
end

function probarTiempoMinimo(robot)
    Q = [0 0 0; 120 0 0];
    robot.tfNominal = 2;
    robot.aMax = 100;
    tray = robot3gdl.generarTrayectoriaLSPB(Q, robot);
    assert(tray.tiemposTramo(1) > 2, 'No se aumento el tiempo de un tramo no factible.');
    assert(~any(~isfinite(tray.Q(:))), 'La trayectoria ajustada contiene valores no finitos.');
end

function probarPuntoInvalido(robot)
    try
        robot3gdl.seleccionarSolucion([5000 0 5000], robot, 'auto', [], 'auto');
    catch
        return;
    end
    error('Se acepto un punto claramente fuera de alcance.');
end
