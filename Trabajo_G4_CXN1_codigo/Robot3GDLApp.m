classdef Robot3GDLApp < handle
    properties
        Fig
        Tabs
        Ax3D
        AxQ
        AxDQ
        AxDDQ
        TabConfig
        TabAnim
        TabQ
        TabDQ
        TabDDQ
        TablaRutina
        TablaResultados
        StatusArea
        ModoDropDown
        TiempoLabel
        FieldL1
        FieldL2
        FieldL3
        FieldAMax
        FieldTfNominal
        FieldTMuestreo
        FieldTMuerto
        FieldRenderStep
        FieldRenderDelay
        LimMinFields = cell(1, 3)
        LimMaxFields = cell(1, 3)
        Robot
        Resultado = []
        Anim = struct()
    end

    methods
        function app = Robot3GDLApp()
            app.Robot = robot3gdl.parametrosRobot();
            app.Anim.pausado = false;
            app.Anim.detener = false;
            app.Anim.indice = 1;
            app.construirUI();
            app.cargarEjemplo();
            app.log('Aplicacion lista. Valide o calcule la rutina para comenzar.');
        end

        function construirUI(app)
            app.Fig = uifigure('Name', 'Robot antropomorfico 3 GDL', 'Position', [80 60 1220 760]);
            app.Fig.CloseRequestFcn = @(~,~) app.cerrar();

            raiz = uigridlayout(app.Fig, [1 1]);
            raiz.Padding = [8 8 8 8];

            app.Tabs = uitabgroup(raiz);
            app.TabConfig = uitab(app.Tabs, 'Title', 'Configuracion y rutina');
            app.TabAnim = uitab(app.Tabs, 'Title', 'Animacion 3D');
            app.TabQ = uitab(app.Tabs, 'Title', 'Posicion articular');
            app.TabDQ = uitab(app.Tabs, 'Title', 'Velocidad articular');
            app.TabDDQ = uitab(app.Tabs, 'Title', 'Aceleracion articular');

            app.construirTabConfig(app.TabConfig);
            app.construirTabAnim(app.TabAnim);
            app.AxQ = app.crearEjesSeries(app.TabQ, 'Posicion articular', 'q [deg]');
            app.AxDQ = app.crearEjesSeries(app.TabDQ, 'Velocidad articular', 'dq [deg/s]');
            app.AxDDQ = app.crearEjesSeries(app.TabDDQ, 'Aceleracion articular', 'ddq [deg/s^2]');
        end

        function construirTabConfig(app, parent)
            layout = uigridlayout(parent, [1 2]);
            layout.ColumnWidth = {360, '1x'};
            layout.RowHeight = {'1x'};

            panel = uipanel(layout, 'Title', 'Parametros');
            pg = uigridlayout(panel, [18 3]);
            pg.RowHeight = repmat({28}, 1, 18);
            pg.ColumnWidth = {130, '1x', 70};
            pg.Padding = [8 8 8 8];

            app.FieldL1 = app.campoNumerico(pg, 'L1', app.Robot.L1, 'mm', 1);
            app.FieldL2 = app.campoNumerico(pg, 'L2', app.Robot.L2, 'mm', 2);
            app.FieldL3 = app.campoNumerico(pg, 'L3', app.Robot.L3, 'mm', 3);
            app.FieldAMax = app.campoNumerico(pg, 'Aceleracion max.', app.Robot.aMax, 'deg/s^2', 4);
            app.FieldTfNominal = app.campoNumerico(pg, 'Tiempo nominal', app.Robot.tfNominal, 's', 5);
            app.FieldTMuestreo = app.campoNumerico(pg, 'Muestreo', app.Robot.tMuestreo, 's', 6);
            app.FieldTMuerto = app.campoNumerico(pg, 'Tiempo muerto', app.Robot.tMuerto, 's', 7);

            uilabel(pg, 'Text', 'Limites q min/max', 'FontWeight', 'bold');
            uilabel(pg, 'Text', 'Min');
            uilabel(pg, 'Text', 'Max');
            for i = 1:3
                uilabel(pg, 'Text', sprintf('q%d [deg]', i));
                app.LimMinFields{i} = uieditfield(pg, 'numeric', 'Value', app.Robot.qMin(i));
                app.LimMaxFields{i} = uieditfield(pg, 'numeric', 'Value', app.Robot.qMax(i));
            end

            uilabel(pg, 'Text', 'Seleccion CI');
            app.ModoDropDown = uidropdown(pg, 'Items', {'auto', 'manual'}, 'Value', 'auto');
            uilabel(pg, 'Text', '');

            btnEjemplo = uibutton(pg, 'Text', 'Cargar ejemplo', 'ButtonPushedFcn', @(~,~) app.cargarEjemplo());
            btnAgregar = uibutton(pg, 'Text', 'Agregar punto', 'ButtonPushedFcn', @(~,~) app.agregarPunto());
            btnEliminar = uibutton(pg, 'Text', 'Eliminar ultimo', 'ButtonPushedFcn', @(~,~) app.eliminarPunto());
            btnValidar = uibutton(pg, 'Text', 'Validar', 'ButtonPushedFcn', @(~,~) app.validarRutina());
            btnCalcular = uibutton(pg, 'Text', 'Calcular', 'ButtonPushedFcn', @(~,~) app.calcular());
            btnCalcular.FontWeight = 'bold';
            uilabel(pg, 'Text', '');

            app.StatusArea = uitextarea(pg, 'Editable', 'off');
            app.StatusArea.Layout.Row = [16 18];
            app.StatusArea.Layout.Column = [1 3];

            derecha = uigridlayout(layout, [2 1]);
            derecha.RowHeight = {'2x', '1x'};
            app.TablaRutina = uitable(derecha);
            app.TablaRutina.ColumnName = {'Nombre', 'X', 'Y', 'Z', 'Config'};
            app.TablaRutina.ColumnEditable = [true true true true true];
            app.TablaRutina.ColumnFormat = {'char', 'numeric', 'numeric', 'numeric', {'auto', 'arriba', 'abajo'}};

            app.TablaResultados = uitable(derecha);
            app.TablaResultados.ColumnName = {'Punto', 'q1 [deg]', 'q2 [deg]', 'q3 [deg]', 'Config', 'Error [mm]'};
        end

        function construirTabAnim(app, parent)
            layout = uigridlayout(parent, [2 1]);
            layout.RowHeight = {'1x', 46};
            app.Ax3D = uiaxes(layout);
            title(app.Ax3D, 'Robot 3 GDL');
            xlabel(app.Ax3D, 'X [mm]');
            ylabel(app.Ax3D, 'Y [mm]');
            zlabel(app.Ax3D, 'Z [mm]');
            grid(app.Ax3D, 'on');
            view(app.Ax3D, 45, 25);
            axis(app.Ax3D, 'equal');

            barra = uigridlayout(layout, [1 11]);
            barra.ColumnWidth = {82, 82, 82, 82, 82, 90, 70, 90, 70, '1x', 150};
            uibutton(barra, 'Text', 'Iniciar', 'ButtonPushedFcn', @(~,~) app.iniciarAnimacion());
            uibutton(barra, 'Text', 'Pausar', 'ButtonPushedFcn', @(~,~) app.pausarAnimacion());
            uibutton(barra, 'Text', 'Continuar', 'ButtonPushedFcn', @(~,~) app.continuarAnimacion());
            uibutton(barra, 'Text', 'Detener', 'ButtonPushedFcn', @(~,~) app.detenerAnimacion());
            uibutton(barra, 'Text', 'Reiniciar', 'ButtonPushedFcn', @(~,~) app.reiniciarAnimacion());
            uilabel(barra, 'Text', 'Paso render');
            app.FieldRenderStep = uieditfield(barra, 'numeric', 'Value', 4, 'Limits', [1 Inf], 'RoundFractionalValues', 'on');
            uilabel(barra, 'Text', 'Retardo [s]');
            app.FieldRenderDelay = uieditfield(barra, 'numeric', 'Value', 0.005, 'Limits', [0 Inf]);
            uilabel(barra, 'Text', '');
            app.TiempoLabel = uilabel(barra, 'Text', 't = 0.00 s');
        end

        function axesSerie = crearEjesSeries(~, parent, titulo, etiquetaY)
            layout = uigridlayout(parent, [3 1]);
            layout.RowHeight = {'1x', '1x', '1x'};
            layout.Padding = [8 8 8 8];
            axesSerie = cell(1, 3);
            for i = 1:3
                axesSerie{i} = uiaxes(layout);
                title(axesSerie{i}, sprintf('%s - q%d', titulo, i));
                xlabel(axesSerie{i}, 't [s]');
                ylabel(axesSerie{i}, etiquetaY);
                grid(axesSerie{i}, 'on');
            end
        end

        function campo = campoNumerico(~, parent, texto, valor, unidad, fila)
            uilabel(parent, 'Text', texto);
            campo = uieditfield(parent, 'numeric', 'Value', valor);
            uilabel(parent, 'Text', unidad);
            campo.Layout.Row = fila;
            campo.Layout.Column = 2;
        end

        function cargarEjemplo(app)
            try
                app.actualizarRobotDesdeUI();
                rutina = robot3gdl.rutinaEjemplo(app.Robot);
                app.TablaRutina.Data = table2cell(rutina);
                app.Resultado = [];
                app.limpiarGraficos();
                app.log('Rutina de ejemplo cargada y validada.');
            catch ME
                app.alerta(ME);
            end
        end

        function agregarPunto(app)
            datos = app.datosRutinaComoCeldas();
            if isempty(datos)
                datos = {'Nuevo punto', 675, 0, 492, 'arriba'};
            else
                datos(end+1,:) = datos(end,:);
                datos{end,1} = sprintf('Punto %d', size(datos, 1));
            end
            app.TablaRutina.Data = datos;
        end

        function eliminarPunto(app)
            datos = app.datosRutinaComoCeldas();
            if size(datos, 1) > 2
                datos(end,:) = [];
                app.TablaRutina.Data = datos;
            else
                uialert(app.Fig, 'La rutina debe conservar al menos dos puntos.', 'Rutina invalida');
            end
        end

        function validarRutina(app)
            try
                app.actualizarRobotDesdeUI();
                resultado = robot3gdl.resolverRutina(app.TablaRutina.Data, app.Robot, get(app.ModoDropDown, 'Value'));
                app.Resultado = resultado;
                app.actualizarTablaResultados();
                app.log(sprintf('Rutina valida: %d puntos, %.2f s de trayectoria.', ...
                    size(resultado.rutina, 1), resultado.trayectoria.t(end)));
            catch ME
                app.alerta(ME);
            end
        end

        function calcular(app)
            app.validarRutina();
            if isempty(app.Resultado)
                return;
            end
            app.graficarSeries();
            app.prepararEscena3D(1);
            tramos = find(app.Resultado.trayectoria.tramosAjustados);
            if ~isempty(tramos)
                app.log(sprintf('Tiempo aumentado automaticamente en tramos: %s.', mat2str(tramos(:).')));
            end
            app.Tabs.SelectedTab = app.TabQ;
        end

        function actualizarRobotDesdeUI(app)
            app.Robot.L1 = app.valorCampo(app.FieldL1);
            app.Robot.L2 = app.valorCampo(app.FieldL2);
            app.Robot.L3 = app.valorCampo(app.FieldL3);
            app.Robot.aMax = app.valorCampo(app.FieldAMax);
            app.Robot.tfNominal = app.valorCampo(app.FieldTfNominal);
            app.Robot.tMuestreo = app.valorCampo(app.FieldTMuestreo);
            app.Robot.tMuerto = app.valorCampo(app.FieldTMuerto);
            app.Robot.qMin = [
                app.valorCampo(app.LimMinFields{1}), ...
                app.valorCampo(app.LimMinFields{2}), ...
                app.valorCampo(app.LimMinFields{3})
            ];
            app.Robot.qMax = [
                app.valorCampo(app.LimMaxFields{1}), ...
                app.valorCampo(app.LimMaxFields{2}), ...
                app.valorCampo(app.LimMaxFields{3})
            ];

            if any([app.Robot.L1 app.Robot.L2 app.Robot.L3 app.Robot.aMax app.Robot.tfNominal app.Robot.tMuestreo] <= 0)
                error('Longitudes, aceleracion, tiempo nominal y muestreo deben ser positivos.');
            end
            if any(app.Robot.qMin >= app.Robot.qMax)
                error('Cada limite minimo debe ser menor que su limite maximo.');
            end
            if app.Robot.tMuerto < 0
                error('El tiempo muerto no puede ser negativo.');
            end
        end

        function datos = datosRutinaComoCeldas(app)
            datos = app.TablaRutina.Data;
            if istable(datos)
                datos = table2cell(datos);
            elseif isnumeric(datos)
                datos = num2cell(datos);
            elseif isstring(datos)
                datos = cellstr(datos);
            end
        end

        function valor = valorCampo(~, campo)
            valor = get(campo, 'Value');
        end

        function actualizarTablaResultados(app)
            n = size(app.Resultado.Qpuntos, 1);
            datos = cell(n, 6);
            for i = 1:n
                datos{i,1} = app.Resultado.rutina.Nombre{i};
                datos{i,2} = app.Resultado.Qpuntos(i,1);
                datos{i,3} = app.Resultado.Qpuntos(i,2);
                datos{i,4} = app.Resultado.Qpuntos(i,3);
                datos{i,5} = app.Resultado.detalles(i).config;
                datos{i,6} = app.Resultado.detalles(i).error;
            end
            app.TablaResultados.Data = datos;
        end

        function graficarSeries(app)
            tray = app.Resultado.trayectoria;
            app.plotSeriesSeparadas(app.AxQ, tray.t, tray.Q, tray.tPuntos, tray.Qpuntos, 'q [deg]', 'Posicion');
            app.plotSeriesSeparadas(app.AxDQ, tray.t, tray.dQ, tray.tPuntos, zeros(size(tray.Qpuntos)), 'dq [deg/s]', 'Velocidad');
            app.plotSeriesSeparadas(app.AxDDQ, tray.t, tray.ddQ, tray.tPuntos, zeros(size(tray.Qpuntos)), 'ddq [deg/s^2]', 'Aceleracion');
        end

        function plotSeriesSeparadas(~, axesSerie, t, Y, tPuntos, Ypuntos, etiqueta, titulo)
            colores = [0 0.4470 0.7410; 0.8500 0.3250 0.0980; 0.9290 0.6940 0.1250];
            for j = 1:3
                ax = axesSerie{j};
                cla(ax);
                plot(ax, t, Y(:,j), 'Color', colores(j,:), 'LineWidth', 1.3);
                hold(ax, 'on');
                plot(ax, tPuntos, Ypuntos(:,j), 'o', 'Color', colores(j,:), 'MarkerFaceColor', colores(j,:), 'MarkerSize', 4);
                hold(ax, 'off');
                grid(ax, 'on');
                xlabel(ax, 't [s]');
                ylabel(ax, etiqueta);
                title(ax, sprintf('%s q%d', titulo, j));
            end
        end

        function prepararEscena3D(app, idx)
            if isempty(app.Resultado)
                return;
            end
            tray = app.Resultado.trayectoria;
            app.precalcularAnimacion();
            idx = min(max(idx, 1), size(tray.Q, 1));
            frame = app.indiceFrameMasCercano(idx);
            puntos = app.Anim.puntosRobot(:,:,frame);
            alcance = app.Robot.L2 + app.Robot.L3 + 120;

            cla(app.Ax3D);
            hold(app.Ax3D, 'on');
            grid(app.Ax3D, 'on');
            axis(app.Ax3D, 'equal');
            xlim(app.Ax3D, [-alcance alcance]);
            ylim(app.Ax3D, [-alcance alcance]);
            zlim(app.Ax3D, [0 app.Robot.L1 + app.Robot.L2 + app.Robot.L3 + 120]);
            view(app.Ax3D, 45, 25);
            xlabel(app.Ax3D, 'X [mm]');
            ylabel(app.Ax3D, 'Y [mm]');
            zlabel(app.Ax3D, 'Z [mm]');

            rutina = app.Resultado.rutina;
            plot3(app.Ax3D, rutina.X, rutina.Y, rutina.Z, 'ko', 'MarkerSize', 5, 'LineWidth', 1);
            app.Anim.hRobot = plot3(app.Ax3D, puntos(:,1), puntos(:,2), puntos(:,3), 'o-', 'LineWidth', 3, 'MarkerSize', 6);
            app.Anim.hTraza = plot3(app.Ax3D, puntos(end,1), puntos(end,2), puntos(end,3), '-', 'LineWidth', 1.2);
            app.Anim.indice = idx;
            app.Anim.frame = frame;
            app.actualizarFrame(frame);
            hold(app.Ax3D, 'off');
        end

        function iniciarAnimacion(app)
            try
                if isempty(app.Resultado)
                    app.calcular();
                end
                if isempty(app.Resultado)
                    return;
                end
                app.Tabs.SelectedTab = app.TabAnim;
                app.Anim.detener = false;
                app.Anim.pausado = false;
                if ~isfield(app.Anim, 'hRobot') || ~isvalid(app.Anim.hRobot)
                    app.prepararEscena3D(app.Anim.indice);
                end
                app.bucleAnimacion();
            catch ME
                app.alerta(ME);
            end
        end

        function bucleAnimacion(app)
            nFrames = size(app.Anim.puntosRobot, 3);
            frame = min(max(app.Anim.frame, 1), nFrames);
            retardo = max(0, app.valorCampo(app.FieldRenderDelay));

            while frame <= nFrames && isvalid(app.Fig) && ~app.Anim.detener
                if app.Anim.pausado
                    app.Anim.frame = frame;
                    drawnow limitrate nocallbacks;
                    continue;
                end

                app.actualizarFrame(frame);
                app.Anim.frame = frame;
                app.Anim.indice = app.Anim.renderIndices(frame);
                drawnow limitrate nocallbacks;
                if frame >= nFrames
                    break;
                end
                frame = frame + 1;
                if retardo > 0
                    ticRetardo = tic;
                    while toc(ticRetardo) < retardo && isvalid(app.Fig) && ~app.Anim.detener
                        drawnow limitrate nocallbacks;
                    end
                end
            end
        end

        function actualizarFrame(app, frame)
            tray = app.Resultado.trayectoria;
            frame = min(max(frame, 1), size(app.Anim.puntosRobot, 3));
            puntos = app.Anim.puntosRobot(:,:,frame);
            set(app.Anim.hRobot, 'XData', puntos(:,1), 'YData', puntos(:,2), 'ZData', puntos(:,3));

            extremos = app.Anim.extremos(1:frame, :);
            set(app.Anim.hTraza, 'XData', extremos(:,1), 'YData', extremos(:,2), 'ZData', extremos(:,3));
            i = app.Anim.renderIndices(frame);
            set(app.TiempoLabel, 'Text', sprintf('t = %.2f / %.2f s | frame %d/%d', tray.t(i), tray.t(end), frame, size(app.Anim.puntosRobot, 3)));
            title(app.Ax3D, sprintf('q = [%.1f, %.1f, %.1f] deg', tray.Q(i,1), tray.Q(i,2), tray.Q(i,3)));
        end

        function precalcularAnimacion(app)
            tray = app.Resultado.trayectoria;
            paso = max(1, round(app.valorCampo(app.FieldRenderStep)));
            indices = 1:paso:size(tray.Q, 1);
            if indices(end) ~= size(tray.Q, 1)
                indices(end+1) = size(tray.Q, 1);
            end

            nFrames = numel(indices);
            puntosRobot = zeros(4, 3, nFrames);
            extremos = zeros(nFrames, 3);
            for k = 1:nFrames
                puntosRobot(:,:,k) = robot3gdl.cinematicaDirecta(tray.Q(indices(k),:), app.Robot);
                extremos(k,:) = puntosRobot(4,:,k);
            end

            app.Anim.renderStep = paso;
            app.Anim.renderIndices = indices;
            app.Anim.puntosRobot = puntosRobot;
            app.Anim.extremos = extremos;
            app.log(sprintf('Animacion preparada: %d muestras -> %d cuadros renderizados (paso %d).', ...
                size(tray.Q, 1), nFrames, paso));
        end

        function frame = indiceFrameMasCercano(app, indiceTrayectoria)
            if ~isfield(app.Anim, 'renderIndices') || isempty(app.Anim.renderIndices)
                frame = 1;
                return;
            end
            [~, frame] = min(abs(app.Anim.renderIndices - indiceTrayectoria));
        end

        function pausarAnimacion(app)
            app.Anim.pausado = true;
        end

        function continuarAnimacion(app)
            app.Anim.pausado = false;
        end

        function detenerAnimacion(app)
            app.Anim.detener = true;
        end

        function reiniciarAnimacion(app)
            app.Anim.detener = true;
            app.Anim.pausado = false;
            app.Anim.indice = 1;
            app.Anim.frame = 1;
            app.prepararEscena3D(1);
        end

        function limpiarGraficos(app)
            if ~isempty(app.Ax3D) && isvalid(app.Ax3D)
                cla(app.Ax3D);
            end
            if ~isempty(app.AxQ)
                for i = 1:3
                    if isvalid(app.AxQ{i})
                        cla(app.AxQ{i});
                        cla(app.AxDQ{i});
                        cla(app.AxDDQ{i});
                    end
                end
            end
            app.TablaResultados.Data = {};
        end

        function log(app, mensaje)
            marca = datestr(now, 'HH:MM:SS');
            actual = get(app.StatusArea, 'Value');
            if ischar(actual)
                actual = {actual};
            end
            set(app.StatusArea, 'Value', [{sprintf('[%s] %s', marca, mensaje)}; actual(:)]);
        end

        function alerta(app, ME)
            mensaje = app.formatearError(ME);
            app.log(mensaje);
            uialert(app.Fig, mensaje, 'Robot 3 GDL');
        end

        function mensaje = formatearError(~, ME)
            mensaje = ME.message;
            if ~isempty(ME.stack)
                s = ME.stack(1);
                mensaje = sprintf('%s\n\nOrigen: %s, linea %d', ME.message, s.name, s.line);
            end
        end

        function cerrar(app)
            app.Anim.detener = true;
            delete(app.Fig);
        end
    end
end
