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
        @() probarRutinasPredefinidas(robot), 'Rutinas predefinidas del desplegable');
    [total, fallidas, mensajes] = comprobar(total, fallidas, mensajes, ...
        @() probarSeleccionCodo(robot), 'Seleccion explicita de codo');
    [total, fallidas, mensajes] = comprobar(total, fallidas, mensajes, ...
        @() probarTiempoMinimo(robot), 'Ajuste automatico de tiempo LSPB');
    [total, fallidas, mensajes] = comprobar(total, fallidas, mensajes, ...
        @() probarUmbralDensificacion(robot), 'Umbral de densificacion articular');
    [total, fallidas, mensajes] = comprobar(total, fallidas, mensajes, ...
        @() probarDependenciasDensificacion(robot), 'Dependencias de densificacion automatica');
    [total, fallidas, mensajes] = comprobar(total, fallidas, mensajes, ...
        @() probarPuntoInvalido(robot), 'Rechazo de punto invalido');
    [total, fallidas, mensajes] = comprobar(total, fallidas, mensajes, ...
        @() probarRecorridosArticulares(robot), 'Recorridos articulares y limites');
    [total, fallidas, mensajes] = comprobar(total, fallidas, mensajes, ...
        @() probarTrayectoriaArticularExtendida(robot), 'Trayectoria articular extendida');
    [total, fallidas, mensajes] = comprobar(total, fallidas, mensajes, ...
        @() probarDenavitHartenberg(robot), 'Matrices Denavit-Hartenberg');
    [total, fallidas, mensajes] = comprobar(total, fallidas, mensajes, ...
        @() probarInfraestructuraSTL(robot), 'Infraestructura STL sin archivos');

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
    resumen.velocidadMaxima = max(abs(resultado.trayectoria.dQ), [], 1);
    resumen.aceleracionMaxima = max(abs(resultado.trayectoria.ddQ), [], 1);
    resumen.mensajes = mensajes;

    fprintf('\nResumen de pruebas Robot 3 GDL\n');
    fprintf('Pruebas superadas: %d\n', resumen.pruebasSuperadas);
    fprintf('Pruebas fallidas: %d\n', resumen.pruebasFallidas);
    fprintf('Error maximo de reconstruccion: %.6g mm\n', resumen.errorMaxReconstruccion);
    fprintf('Presencia de NaN o Inf: %d\n', resumen.tieneNaNInf);
    fprintf('Violaciones de limites: %d\n', resumen.violacionesLimites);
    fprintf('Saltos maximos entre muestras [q1 q2 q3]: [%.4f %.4f %.4f] deg\n', resumen.saltosMaximos);
    fprintf('max(abs(dQ(:,1))) = %.6f deg/s\n', resumen.velocidadMaxima(1));
    fprintf('max(abs(dQ(:,2))) = %.6f deg/s\n', resumen.velocidadMaxima(2));
    fprintf('max(abs(dQ(:,3))) = %.6f deg/s\n', resumen.velocidadMaxima(3));
    fprintf('max(abs(ddQ(:,1))) = %.6f deg/s^2\n', resumen.aceleracionMaxima(1));
    fprintf('max(abs(ddQ(:,2))) = %.6f deg/s^2\n', resumen.aceleracionMaxima(2));
    fprintf('max(abs(ddQ(:,3))) = %.6f deg/s^2\n', resumen.aceleracionMaxima(3));
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

function probarSeleccionCodo(robot)
    P = [430, 0, 600];
    [qArriba, dArriba] = robot3gdl.seleccionarSolucion(P, robot, 'auto', [], 'arriba');
    [qAbajo, dAbajo] = robot3gdl.seleccionarSolucion(P, robot, 'auto', [], 'abajo');

    assert(strcmp(dArriba.config, 'arriba'), 'Config arriba no fue respetada en modo auto.');
    assert(strcmp(dAbajo.config, 'abajo'), 'Config abajo no fue respetada en modo auto.');
    assert(norm(qArriba - qAbajo) > 10, 'Las ramas arriba y abajo no estan diferenciadas.');

    tabla = {
        'Inicio arriba', P(1), P(2), P(3), 'arriba'
        'Fin abajo',    P(1), P(2), P(3), 'abajo'
    };
    resultado = robot3gdl.resolverRutina(tabla, robot, 'auto');
    assert(strcmp(resultado.detalles(1).config, 'arriba'), 'resolverRutina no respeto codo arriba.');
    assert(strcmp(resultado.detalles(2).config, 'abajo'), 'resolverRutina no respeto codo abajo.');
end

function probarRutinasPredefinidas(robot)
    [items, ids] = robot3gdl.listarEjemplos();
    assert(numel(items) == 4, 'La lista debe exponer cuatro ejemplos.');
    assert(numel(ids) == numel(items), 'Items e IDs de ejemplos no coinciden.');
    assert(strcmp(ids{1}, 'profesor'), 'El primer ejemplo debe ser el del profesor.');
    assert(strcmp(ids{2}, 'estrella'), 'El segundo ejemplo debe ser la estrella.');

    for i = 1:numel(ids)
        rutina = robot3gdl.rutinaEjemplo(robot, ids{i});
        assert(height(rutina) >= 2, 'Cada ejemplo debe tener al menos dos puntos.');
        assert(all(ismember({'Nombre', 'X', 'Y', 'Z', 'Config'}, rutina.Properties.VariableNames)), ...
            'La rutina no conserva el formato esperado.');
    end
end

function probarTiempoMinimo(robot)
    Q = [0 0 0; 120 0 0];
    robot.tfNominal = 2;
    robot.aMax = 100;
    tray = robot3gdl.generarTrayectoriaLSPB(Q, robot);
    assert(size(tray.Qpuntos, 1) > size(Q, 1), 'No se densifico un tramo no factible con FControl.');
    assert(all(abs(tray.tiemposTramo - robot.tfNominal) < 1e-9), 'La densificacion debe conservar tf nominal por subtramo.');
    assert(~any(~isfinite(tray.Q(:))), 'La trayectoria ajustada contiene valores no finitos.');
    assert(max(abs(tray.dQ(:,1))) <= robot.vMax(1) + 1e-6, 'La trayectoria supera vMax en q1.');
    assert(tray.diagnostico(1).tc(1) >= robot.tLinealMin - 1e-9, 'No se garantizo tramo lineal visible.');
end

function probarUmbralDensificacion(robot)
    robot.deltaMaxDensificacion = 100;

    trayMenor = robot3gdl.generarTrayectoriaLSPB([0 0 0; 99.9 0 0], robot);
    assert(size(trayMenor.Qpuntos, 1) == 2, 'No debe densificar si el mayor desplazamiento es menor a 100 deg.');
    assert(all(trayMenor.densificacion.divisiones == 1), 'Division inesperada por debajo del umbral.');

    trayIgual = robot3gdl.generarTrayectoriaLSPB([0 0 0; 100 0 0], robot);
    assert(size(trayIgual.Qpuntos, 1) == 2, 'No debe densificar si el mayor desplazamiento es exactamente 100 deg.');
    assert(all(trayIgual.densificacion.divisiones == 1), 'Division inesperada en el umbral.');

    trayMayor = robot3gdl.generarTrayectoriaLSPB([0 0 0; 100.1 0 0], robot);
    assert(size(trayMayor.Qpuntos, 1) > 2, 'Debe densificar si el mayor desplazamiento supera 100 deg.');
    assert(any(trayMayor.densificacion.divisiones > 1), 'No se registro division por encima del umbral.');
end

function probarDependenciasDensificacion(robot)
    robot.deltaMaxDensificacion = 'auto';
    robot.aMax = 100;
    robot.tfNominal = 2;
    robot.tLinealMin = 0.30;

    [deltaBase, detalleBase] = robot3gdl.calcularDeltaMaxDensificacion(robot);
    deltaEsperado = robot.aMax*(robot.tfNominal^2 - robot.tLinealMin^2)/4;
    assert(all(abs(deltaBase - deltaEsperado) < 1e-9), 'Delta automatico base incorrecto.');
    assert(abs(detalleBase.deltaTriangular - 100) < 1e-9, 'Delta triangular de referencia incorrecto.');
    assert(deltaBase(1) < detalleBase.deltaTriangular, 'El tramo lineal minimo debe reducir el delta util.');

    trayMenor = robot3gdl.generarTrayectoriaLSPB([0 0 0; deltaBase(1)-0.01 0 0], robot);
    assert(size(trayMenor.Qpuntos, 1) == 2, 'No debe densificar por debajo del delta automatico.');

    trayMayor = robot3gdl.generarTrayectoriaLSPB([0 0 0; deltaBase(1)+0.01 0 0], robot);
    assert(size(trayMayor.Qpuntos, 1) > 2, 'Debe densificar por encima del delta automatico.');

    robotLento = robot;
    robotLento.aMax = 50;
    deltaLento = robot3gdl.calcularDeltaMaxDensificacion(robotLento);
    assert(all(deltaLento < deltaBase), 'Reducir aMax debe reducir el barrido automatico.');

    robotMasTiempo = robot;
    robotMasTiempo.tfNominal = 3;
    deltaMasTiempo = robot3gdl.calcularDeltaMaxDensificacion(robotMasTiempo);
    assert(all(deltaMasTiempo > deltaBase), 'Aumentar tfNominal debe aumentar el barrido automatico.');

    robotVelLimitada = robot;
    robotVelLimitada.vMax = [30 40 50];
    deltaVelLimitada = robot3gdl.calcularDeltaMaxDensificacion(robotVelLimitada);
    assert(deltaVelLimitada(1) < deltaBase(1), 'vMax baja debe reducir el barrido de q1.');
    assert(deltaVelLimitada(1) < deltaVelLimitada(2) && deltaVelLimitada(2) < deltaVelLimitada(3), ...
        'El barrido automatico debe respetar vMax por articulacion.');
end

function probarPuntoInvalido(robot)
    try
        robot3gdl.seleccionarSolucion([5000 0 5000], robot, 'auto', [], 'auto');
    catch
        return;
    end
    error('Se acepto un punto claramente fuera de alcance.');
end

function probarRecorridosArticulares(robot)
    casos = [
          0,   10
         10,    0
         20,   20
          0,  100
          0,  120
        160, -160
       -160,  160
    ];

    fprintf('\nPruebas de recorrido q1\n');
    for i = 1:size(casos, 1)
        r = robot3gdl.resolverRecorridoArticular(casos(i,1), casos(i,2), robot.qMin(1), robot.qMax(1), 'q1');
        fprintf(['Caso %d: q=[%.1f -> %.1f], deltaDirecto=%.1f, deltaCorto=%.1f, ', ...
                 'deltaUsado=%.1f, admisible=%d, motivo=%s\n'], ...
            i, r.qInicial, r.qFinal, r.deltaDirecto, r.deltaCortoEquivalente, ...
            r.delta, r.esAdmisible, r.motivo);
        assert(r.esAdmisible, 'Recorrido admisible rechazado.');
        assert(r.qInicial >= robot.qMin(1) && r.qFinal <= robot.qMax(1), 'Extremos fuera de limites.');
    end

    r = robot3gdl.resolverRecorridoArticular(160, -160, robot.qMin(1), robot.qMax(1), 'q1');
    assert(r.caminoCortoDescartado, 'No se descarto el camino corto por zona prohibida.');
    assert(abs(r.delta + 320) < 1e-9, 'El recorrido fisico esperado para 160 -> -160 debe ser -320 deg.');
end

function probarTrayectoriaArticularExtendida(robot)
    Q = [
          0,    0,    0
         10,    5,   -5
          0,    5,   -5
          0,    5,   -5
        100,   80,  100
        130,  110,  125
        160,   90,   60
       -160,  -60, -120
        160,   30,   80
    ];

    tray = robot3gdl.generarTrayectoriaLSPB(Q, robot);
    robot3gdl.validarTrayectoria(tray, robot);

    fprintf('\nPrueba articular extendida\n');
    for i = 1:numel(tray.diagnostico)
        d = tray.diagnostico(i);
        vmax = max(abs(tray.dQ), [], 1);
        amax = max(abs(tray.ddQ), [], 1);
        fprintf(['Tramo %d: q_i=[%.1f %.1f %.1f], q_f=[%.1f %.1f %.1f], ', ...
                 'dq=[%.1f %.1f %.1f], tf=%.3f, vmax=[%.1f %.1f %.1f], ', ...
                 'amax=[%.1f %.1f %.1f], estado=%s, obs=%s\n'], ...
            d.tramo, d.qi, d.qf, d.delta, d.tfUsado, vmax, amax, d.estado, d.observaciones);
    end

    assert(all(all(tray.Q >= robot.qMin - 1e-9)), 'La trayectoria cae debajo de algun limite.');
    assert(all(all(tray.Q <= robot.qMax + 1e-9)), 'La trayectoria supera algun limite.');
    assert(all(max(abs(tray.dQ), [], 1) <= robot.vMax + 1e-6), 'La trayectoria supera vMax.');
    assert(all(max(abs(tray.ddQ), [], 1) <= robot.aMax + 1e-6), 'La trayectoria supera aMax.');
    assert(~isfield(tray, 'tEventosGrafica'), 'No deben generarse eventos graficos verticales.');
    assert(~isfield(tray, 'tEventos'), 'No deben generarse eventos verticales.');
    assert(size(tray.Qpuntos, 1) > size(Q, 1), 'La trayectoria extendida debe densificar tramos grandes.');
    assert(all(abs(tray.tiemposTramo - robot.tfNominal) < 1e-9), 'Los subtramos deben conservar tf nominal.');
    for i = 1:numel(tray.diagnostico)
        d = tray.diagnostico(i);
        for j = 1:3
            if abs(d.delta(j)) > 1e-12
                assert(d.tc(j) >= robot.tLinealMin - 1e-9, 'Tramo lineal menor al minimo visible.');
            end
        end
    end
    assert(any([tray.diagnostico.tramo] == 7), 'Diagnostico incompleto.');
end

function probarInfraestructuraSTL(robot)
    modelo = robot3gdl.cargarModeloSTL(fullfile(robot.stl.carpeta, 'archivo_inexistente.stl'));
    assert(~modelo.disponible, 'Un STL inexistente no debe marcarse disponible.');
    assert(isfield(modelo, 'vertices') && isfield(modelo, 'faces'), 'Modelo STL incompleto.');

    [faces, vertices] = robot3gdl.crearPrismaEslabon(100, 10, 10);
    assert(size(vertices, 2) == 3 && size(faces, 2) == 3, 'Prisma provisional invalido.');

    q = [35, 25, 40];
    puntos = robot3gdl.cinematicaDirecta(q, robot);
    T = robot3gdl.transformacionesRobot(q, robot);
    pHombro = transformarPunto(T.q1*T.q2, [0 0 0]);
    pCodo = transformarPunto(T.q1*T.q2*T.q3, [0 0 0]);
    pExtremo = transformarPunto(T.q1*T.q2*T.q3*T.efector, [0 0 0]);
    assert(norm(pHombro - puntos(2,:)) < 1e-9, 'Transformacion hombro no coincide con CD.');
    assert(norm(pCodo - puntos(3,:)) < 1e-9, 'Transformacion codo no coincide con CD.');
    assert(norm(pExtremo - puntos(4,:)) < 1e-9, 'Transformacion extremo no coincide con CD.');
end

function probarDenavitHartenberg(robot)
    casos = [
          0,   0,    0
         35,  25,   40
        -80,  60,  -30
        120, -20,   95
    ];

    for i = 1:size(casos, 1)
        q = casos(i,:);
        dh = robot3gdl.denavitHartenberg(q, robot);
        puntosDH = dh.puntos;
        puntosFormula = cinematicaDirectaFormula(q, robot);
        assert(max(abs(puntosDH(:) - puntosFormula(:))) < 1e-9, ...
            'DH no coincide con la formula cerrada historica.');

        T = robot3gdl.transformacionesRobot(q, robot);
        T03Jerarquico = T.q1 * T.q2 * T.q3 * T.efector;
        assert(max(abs(T03Jerarquico(:) - dh.T03(:))) < 1e-9, ...
            'La jerarquia de animacion no coincide con T03 DH.');
    end
end

function puntos = cinematicaDirectaFormula(q, robot)
    q1 = q(1);
    q2 = q(2);
    q3 = q(3);

    P0 = [0, 0, 0];
    P1 = [0, 0, robot.L1];
    P2 = [
        robot.L2*cosd(q2)*cosd(q1), ...
        robot.L2*cosd(q2)*sind(q1), ...
        robot.L1 + robot.L2*sind(q2)
    ];
    P3 = [
        P2(1) + robot.L3*cosd(q2 - q3)*cosd(q1), ...
        P2(2) + robot.L3*cosd(q2 - q3)*sind(q1), ...
        P2(3) + robot.L3*sind(q2 - q3)
    ];
    puntos = [P0; P1; P2; P3];
end

function p = transformarPunto(T, pLocal)
    p4 = T * [pLocal(:); 1];
    p = p4(1:3).';
end
