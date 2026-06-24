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
        TabModeloSTL
        TabQ
        TabDQ
        TabDDQ
        AxesModeloSTL
        STLStatusLabel
        STLMostrarEjesCheck
        STLMostrarReferenciaCheck
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
        EjemploDropDown
        LimMinFields = cell(1, 3)
        LimMaxFields = cell(1, 3)
        Robot
        Resultado = []
        Anim = struct()
        ModeloSTLInicializado = false
        STLModelos = struct()
        STLTransforms = struct()
        STLPatches = struct()
        STLLocalAxes = []
        STLReferencia = []
        QActualSTL = [0 0 0]
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
            app.TabModeloSTL = uitab(app.Tabs, 'Title', 'Modelo 3D STL');
            app.TabQ = uitab(app.Tabs, 'Title', 'Posicion articular');
            app.TabDQ = uitab(app.Tabs, 'Title', 'Velocidad articular');
            app.TabDDQ = uitab(app.Tabs, 'Title', 'Aceleracion articular');

            app.construirTabConfig(app.TabConfig);
            app.construirTabAnim(app.TabAnim);
            app.construirTabModeloSTL(app.TabModeloSTL);
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

            [itemsEjemplo, idsEjemplo] = robot3gdl.listarEjemplos();
            app.EjemploDropDown = uidropdown(pg, ...
                'Items', itemsEjemplo, ...
                'ItemsData', idsEjemplo, ...
                'Value', idsEjemplo{1}, ...
                'ValueChangedFcn', @(~,~) app.cargarEjemplo());
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

        function construirTabModeloSTL(app, parent)
            layout = uigridlayout(parent, [3 1]);
            layout.RowHeight = {28, '1x', 28};
            layout.Padding = [8 8 8 8];

            barra = uigridlayout(layout, [1 6]);
            barra.ColumnWidth = {110, 130, 160, 190, '1x', 160};
            uibutton(barra, 'Text', 'Recargar STL', 'ButtonPushedFcn', @(~,~) app.inicializarModeloSTL());
            uibutton(barra, 'Text', 'Restablecer camara', 'ButtonPushedFcn', @(~,~) app.restablecerCamaraSTL());
            app.STLMostrarEjesCheck = uicheckbox(barra, 'Text', 'Mostrar ejes locales', 'Value', false, ...
                'ValueChangedFcn', @(~,~) app.actualizarVisibilidadSTL());
            app.STLMostrarReferenciaCheck = uicheckbox(barra, 'Text', 'Mostrar alambrico ref.', 'Value', true, ...
                'ValueChangedFcn', @(~,~) app.actualizarVisibilidadSTL());
            uilabel(barra, 'Text', '');
            uilabel(barra, 'Text', 'Convencion STL: +X local');

            app.AxesModeloSTL = uiaxes(layout);
            axis(app.AxesModeloSTL, 'equal');
            grid(app.AxesModeloSTL, 'on');
            view(app.AxesModeloSTL, 3);
            xlabel(app.AxesModeloSTL, 'X [mm]');
            ylabel(app.AxesModeloSTL, 'Y [mm]');
            zlabel(app.AxesModeloSTL, 'Z [mm]');
            title(app.AxesModeloSTL, 'Robot 3 GDL con modelos STL');

            app.STLStatusLabel = uilabel(layout, 'Text', 'Modelos STL no inicializados.', ...
                'FontWeight', 'bold');
            app.inicializarModeloSTL();
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
                ejemplo = 'profesor';
                if ~isempty(app.EjemploDropDown)
                    ejemplo = get(app.EjemploDropDown, 'Value');
                end
                rutina = robot3gdl.rutinaEjemplo(app.Robot, ejemplo);
                app.TablaRutina.Data = table2cell(rutina);
                app.Resultado = [];
                app.limpiarGraficos();
                app.log(sprintf('Rutina de ejemplo cargada: %s.', app.nombreEjemploActual()));
            catch ME
                app.alerta(ME);
            end
        end

        function nombre = nombreEjemploActual(app)
            if isempty(app.EjemploDropDown)
                nombre = 'Profesor';
                return;
            end
            items = get(app.EjemploDropDown, 'Items');
            ids = get(app.EjemploDropDown, 'ItemsData');
            valor = get(app.EjemploDropDown, 'Value');
            idx = find(strcmp(ids, valor), 1, 'first');
            if isempty(idx)
                nombre = char(valor);
            else
                nombre = items{idx};
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
                app.Resultado = [];
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
            [tMarcadores, qMarcadores] = app.marcadoresTrayectoria(tray);
            app.plotSeriesSeparadas(app.AxQ, tray.t, tray.Q, tMarcadores, qMarcadores, 'q [deg]', 'Posicion', 'linea');
            app.plotSeriesSeparadas(app.AxDQ, tray.t, tray.dQ, tMarcadores, zeros(size(qMarcadores)), 'dq [deg/s]', 'Velocidad', 'linea');
            app.plotSeriesSeparadas(app.AxDDQ, tray.t, tray.ddQ, tMarcadores, zeros(size(qMarcadores)), 'ddq [deg/s^2]', 'Aceleracion', 'escalon');
        end

        function [tMarcadores, qMarcadores] = marcadoresTrayectoria(~, tray)
            if isfield(tray, 'QpuntosOriginal') && isfield(tray, 'tPuntosOriginal')
                tMarcadores = tray.tPuntosOriginal;
                qMarcadores = tray.QpuntosOriginal;
            else
                tMarcadores = tray.tPuntos;
                qMarcadores = tray.Qpuntos;
            end
        end

        function plotSeriesSeparadas(~, axesSerie, t, Y, tPuntos, Ypuntos, etiqueta, titulo, estilo)
            colores = [0 0.4470 0.7410; 0.8500 0.3250 0.0980; 0.9290 0.6940 0.1250];
            for j = 1:3
                ax = axesSerie{j};
                cla(ax);
                yDatos = [Y(:,j); Ypuntos(:,j)];
                yDatos = yDatos(isfinite(yDatos));
                if isempty(yDatos)
                    yLimActual = [-1 1];
                else
                    yMin = min(yDatos);
                    yMax = max(yDatos);
                    margen = max(1, 0.08*max(abs(yMax - yMin), 1));
                    yLimActual = [yMin - margen, yMax + margen];
                end
                xlim(ax, [t(1), t(end)]);
                ylim(ax, yLimActual);
                hold(ax, 'on');
                if strcmp(estilo, 'escalon')
                    stairs(ax, t, Y(:,j), 'Color', colores(j,:), 'LineWidth', 1.4);
                else
                    plot(ax, t, Y(:,j), 'Color', colores(j,:), 'LineWidth', 1.3);
                end
                plot(ax, tPuntos, Ypuntos(:,j), 'o', 'Color', colores(j,:), 'MarkerFaceColor', colores(j,:), 'MarkerSize', 4);
                grid(ax, 'on');
                xlabel(ax, 't [s]');
                ylabel(ax, etiqueta);
                title(ax, sprintf('%s q%d', titulo, j));
                hold(ax, 'off');
            end
        end

        function inicializarModeloSTL(app)
            try
                app.ModeloSTLInicializado = false;
                ax = app.AxesModeloSTL;
                cla(ax);
                hold(ax, 'on');
                axis(ax, 'equal');
                grid(ax, 'on');
                view(ax, 3);
                xlabel(ax, 'X [mm]');
                ylabel(ax, 'Y [mm]');
                zlabel(ax, 'Z [mm]');
                title(ax, 'Robot 3 GDL con modelos STL');

                if ~isfolder(app.Robot.stl.carpeta)
                    mkdir(app.Robot.stl.carpeta);
                end

                app.STLTransforms = struct();
                app.STLPatches = struct();
                app.STLModelos = struct();
                app.STLLocalAxes = [];
                app.STLReferencia = [];

                app.STLTransforms.base = hgtransform('Parent', ax);
                app.STLTransforms.q1 = hgtransform('Parent', ax);
                app.STLTransforms.eslabon1 = hgtransform('Parent', app.STLTransforms.q1);
                app.STLTransforms.q2 = hgtransform('Parent', app.STLTransforms.q1);
                app.STLTransforms.eslabon2 = hgtransform('Parent', app.STLTransforms.q2);
                app.STLTransforms.q3 = hgtransform('Parent', app.STLTransforms.q2);
                app.STLTransforms.eslabon3 = hgtransform('Parent', app.STLTransforms.q3);
                app.STLTransforms.efector = hgtransform('Parent', app.STLTransforms.q3);

                piezas = {'base', 'eslabon1', 'eslabon2', 'eslabon3', 'efector'};
                faltantes = {};
                for i = 1:numel(piezas)
                    pieza = piezas{i};
                    ruta = fullfile(app.Robot.stl.carpeta, app.Robot.stl.archivos.(pieza));
                    opciones.escala = app.Robot.stl.escala.(pieza);
                    modelo = robot3gdl.cargarModeloSTL(ruta, opciones);
                    if ~modelo.disponible
                        faltantes{end+1} = modelo.nombre; %#ok<AGROW>
                        [modelo.faces, modelo.vertices] = app.geometriaProvisional(pieza);
                    end
                    app.STLModelos.(pieza) = modelo;
                    app.STLPatches.(pieza) = app.crearPatchSTL(pieza, modelo);
                    app.crearEjesLocales(app.STLPatches.(pieza).Parent);
                end

                app.STLReferencia = plot3(ax, 0, 0, 0, 'k-', 'LineWidth', 0.8, ...
                    'HandleVisibility', 'off');
                app.ModeloSTLInicializado = true;
                app.actualizarModeloSTL(app.QActualSTL);
                app.actualizarVisibilidadSTL();
                app.restablecerCamaraSTL();

                try
                    camlight(ax, 'headlight');
                    lighting(ax, 'gouraud');
                catch
                end

                if isempty(faltantes)
                    set(app.STLStatusLabel, 'Text', 'Modelos STL cargados correctamente.');
                else
                    set(app.STLStatusLabel, 'Text', ...
                        sprintf('Modelos STL no encontrados. Geometrias provisionales: %s', strjoin(faltantes, ', ')));
                    fprintf('Modelo STL: faltan archivos, se usan geometrias provisionales: %s\n', strjoin(faltantes, ', '));
                end
                hold(ax, 'off');
            catch ME
                app.ModeloSTLInicializado = false;
                if ~isempty(app.STLStatusLabel) && isvalid(app.STLStatusLabel)
                    set(app.STLStatusLabel, 'Text', ['Fallo STL: ', ME.message]);
                end
                warning('Robot3GDL:STL', 'Fallo inicializando modelo STL: %s', ME.message);
            end
        end

        function actualizarModeloSTL(app, q)
            if ~app.ModeloSTLInicializado || ~isfield(app.STLTransforms, 'q1')
                return;
            end
            if ~isvalid(app.STLTransforms.q1)
                return;
            end

            app.QActualSTL = q(:).';
            T = robot3gdl.transformacionesRobot(app.QActualSTL, app.Robot);

            set(app.STLTransforms.base, 'Matrix', app.matrizLocalSTL('base'));
            set(app.STLTransforms.q1, 'Matrix', T.q1);
            set(app.STLTransforms.q2, 'Matrix', T.q2);
            set(app.STLTransforms.q3, 'Matrix', T.q3);
            set(app.STLTransforms.eslabon1, 'Matrix', ...
                makehgtform('yrotate', -pi/2) * app.matrizLocalSTL('eslabon1'));
            set(app.STLTransforms.eslabon2, 'Matrix', app.matrizLocalSTL('eslabon2'));
            set(app.STLTransforms.eslabon3, 'Matrix', app.matrizLocalSTL('eslabon3'));
            set(app.STLTransforms.efector, 'Matrix', T.efector * app.matrizLocalSTL('efector'));

            if ~isempty(app.STLReferencia) && isvalid(app.STLReferencia)
                puntos = robot3gdl.cinematicaDirecta(app.QActualSTL, app.Robot);
                set(app.STLReferencia, 'XData', puntos(:,1), 'YData', puntos(:,2), 'ZData', puntos(:,3));
            end
        end

        function Tlocal = matrizLocalSTL(app, pieza)
            Tlocal = robot3gdl.construirTransformacionSTL( ...
                app.Robot.stl.escala.(pieza), ...
                app.Robot.stl.rotacionInicial.(pieza), ...
                app.Robot.stl.traslacionInicial.(pieza)) * ...
                app.Robot.stl.transformacionLocal.(pieza);
        end

        function patchObj = crearPatchSTL(app, pieza, modelo)
            colores.base = [0.35 0.35 0.38];
            colores.eslabon1 = [0.20 0.45 0.80];
            colores.eslabon2 = [0.80 0.35 0.20];
            colores.eslabon3 = [0.90 0.65 0.18];
            colores.efector = [0.25 0.65 0.35];
            patchObj = patch( ...
                'Faces', modelo.faces, ...
                'Vertices', modelo.vertices, ...
                'FaceColor', colores.(pieza), ...
                'EdgeColor', 'none', ...
                'FaceAlpha', 1, ...
                'Parent', app.STLTransforms.(pieza), ...
                'HandleVisibility', 'off');
        end

        function [faces, vertices] = geometriaProvisional(app, pieza)
            switch pieza
                case 'base'
                    [faces, vertices] = robot3gdl.crearPrismaEslabon(160, 160, 45);
                    vertices(:,1) = vertices(:,1) - 80;
                    vertices(:,3) = vertices(:,3) + 22.5;
                case 'eslabon1'
                    [faces, vertices] = robot3gdl.crearPrismaEslabon(app.Robot.L1, 45, 45);
                case 'eslabon2'
                    [faces, vertices] = robot3gdl.crearPrismaEslabon(app.Robot.L2, 42, 42);
                case 'eslabon3'
                    [faces, vertices] = robot3gdl.crearPrismaEslabon(app.Robot.L3, 36, 36);
                otherwise
                    [faces, vertices] = robot3gdl.crearPrismaEslabon(80, 28, 28);
            end
        end

        function crearEjesLocales(app, parentTransform)
            L = 70;
            hx = line('XData', [0 L], 'YData', [0 0], 'ZData', [0 0], 'Color', [0.9 0.1 0.1], ...
                'LineWidth', 1, 'Parent', parentTransform, 'HandleVisibility', 'off');
            hy = line('XData', [0 0], 'YData', [0 L], 'ZData', [0 0], 'Color', [0.1 0.7 0.1], ...
                'LineWidth', 1, 'Parent', parentTransform, 'HandleVisibility', 'off');
            hz = line('XData', [0 0], 'YData', [0 0], 'ZData', [0 L], 'Color', [0.1 0.2 0.9], ...
                'LineWidth', 1, 'Parent', parentTransform, 'HandleVisibility', 'off');
            app.STLLocalAxes = [app.STLLocalAxes; hx; hy; hz];
        end

        function actualizarVisibilidadSTL(app)
            if ~isempty(app.STLLocalAxes)
                validos = isvalid(app.STLLocalAxes);
                if any(validos)
                    estado = app.textoVisible(get(app.STLMostrarEjesCheck, 'Value'));
                    set(app.STLLocalAxes(validos), 'Visible', estado);
                end
            end
            if ~isempty(app.STLReferencia) && isvalid(app.STLReferencia)
                set(app.STLReferencia, 'Visible', app.textoVisible(get(app.STLMostrarReferenciaCheck, 'Value')));
            end
        end

        function estado = textoVisible(~, valor)
            if valor
                estado = 'on';
            else
                estado = 'off';
            end
        end

        function restablecerCamaraSTL(app)
            if isempty(app.AxesModeloSTL) || ~isvalid(app.AxesModeloSTL)
                return;
            end
            ax = app.AxesModeloSTL;
            alcance = app.Robot.L2 + app.Robot.L3 + 120;
            axis(ax, 'equal');
            grid(ax, 'on');
            xlim(ax, [-alcance alcance]);
            ylim(ax, [-alcance alcance]);
            zlim(ax, [0 app.Robot.L1 + app.Robot.L2 + app.Robot.L3 + 120]);
            view(ax, 45, 25);
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
                app.validarRutina();
                if isempty(app.Resultado)
                    return;
                end
                app.graficarSeries();
                app.Anim.indice = 1;
                app.Anim.frame = 1;
                app.prepararEscena3D(1);
                app.Tabs.SelectedTab = app.TabAnim;
                app.Anim.detener = false;
                app.Anim.pausado = false;
                app.bucleAnimacion();
            catch ME
                app.alerta(ME);
            end
        end

        function bucleAnimacion(app)
            tray = app.Resultado.trayectoria;
            nFrames = size(app.Anim.puntosRobot, 3);
            frame = min(max(app.Anim.frame, 1), nFrames);
            retardo = max(0.001, app.valorCampo(app.FieldRenderDelay));
            indices = app.Anim.renderIndices;
            tInicioSim = tray.t(indices(frame));
            reloj = tic;
            tiempoPausado = 0;
            pausaTic = [];
            frameAnterior = 0;

            while frame <= nFrames && isvalid(app.Fig) && ~app.Anim.detener
                if app.Anim.pausado
                    app.Anim.frame = frame;
                    if isempty(pausaTic)
                        pausaTic = tic;
                    end
                    drawnow limitrate;
                    pause(retardo);
                    continue;
                end

                if ~isempty(pausaTic)
                    tiempoPausado = tiempoPausado + toc(pausaTic);
                    pausaTic = [];
                end

                tReal = toc(reloj) - tiempoPausado;
                tObjetivo = min(tInicioSim + tReal, tray.t(end));
                frame = find(tray.t(indices) <= tObjetivo + app.Robot.tolTiempo, 1, 'last');
                if isempty(frame)
                    frame = 1;
                end

                if frame ~= frameAnterior || frame >= nFrames
                    app.actualizarFrame(frame);
                    app.Anim.frame = frame;
                    app.Anim.indice = indices(frame);
                    frameAnterior = frame;
                    drawnow limitrate;
                end

                if frame >= nFrames
                    break;
                end

                tSiguiente = tray.t(indices(frame + 1)) - tInicioSim;
                espera = tSiguiente - tReal;
                if espera > 0
                    ticEspera = tic;
                    while toc(ticEspera) < espera && isvalid(app.Fig) && ~app.Anim.detener && ~app.Anim.pausado
                        drawnow limitrate;
                        pause(min(retardo, max(0.001, espera - toc(ticEspera))));
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
            if app.ModeloSTLInicializado
                app.actualizarModeloSTL(tray.Q(i,:));
            end
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
