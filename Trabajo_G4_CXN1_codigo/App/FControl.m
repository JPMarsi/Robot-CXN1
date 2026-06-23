function [y, w, g, x] = FControl(A, robot)
% FCONTROL Control cinemático trapezoidal/LSPB para una articulación.
%
% Entrega:
%   y -> posición articular muestreada [deg]
%   w -> velocidad articular [deg/s]
%   g -> aceleración articular [deg/s^2]
%   x -> tiempo [s]
%
% Entrada:
%   A     -> vector de posiciones articulares por punto [deg]
%   robot -> estructura con a, tf, tdesc y tm
%
% La velocidad inicial y final de cada tramo se toman iguales a cero.
% Si un tramo no puede realizarse en tf con la aceleración dada,
% se informa error para que se modifique el punto o el tiempo.

    if nargin < 2
        robot.a = 100;
        robot.tf = 2.0;
        robot.tdesc = 0.2;
        robot.tm = 0.02;
    end

    a = robot.a;
    tf = robot.tf;
    tdesc = robot.tdesc;
    tm = robot.tm;

    A = A(:)';
    N = length(A) - 1;

    if N < 1
        error('FControl necesita al menos dos posiciones articulares.');
    end

    y = [];
    w = [];
    g = [];
    x = [];

    tiempoAcumulado = 0;
    desplazamientoMaximo = a*(tf^2)/4;

    for km = 1:N
        qi = A(km);
        qf = A(km+1);
        dq = qf - qi;
        ys = abs(dq);

        if ys > desplazamientoMaximo + 1e-9
            error(['Tramo %d imposible con a = %.3f deg/s^2 y tf = %.3f s. ', ...
                   'Desplazamiento = %.3f deg, máximo permitido = %.3f deg. ', ...
                   'Debe aumentar tf, aumentar a o elegir puntos intermedios.'], ...
                   km, a, tf, ys, desplazamientoMaximo);
        end

        if abs(dq) < 1e-12
            signo = 0;
            tc = tf/2;
            vmax = 0;
        else
            signo = sign(dq);
            tc = 0.5*tf - 0.5*sqrt(tf^2 - 4*ys/a);
            vmax = signo*a*tc;
        end

        tlocal = 0:tm:(tf + tdesc);

        % Evita duplicar la primera muestra entre tramos consecutivos.
        if km > 1
            tlocal = tlocal(2:end);
        end

        yseg = zeros(size(tlocal));
        wseg = zeros(size(tlocal));
        gseg = zeros(size(tlocal));
        xseg = tiempoAcumulado + tlocal;

        for k = 1:length(tlocal)
            tau = tlocal(k);

            if tau <= tc
                % Aceleración
                yseg(k) = qi + 0.5*signo*a*tau^2;
                wseg(k) = signo*a*tau;
                gseg(k) = signo*a;

            elseif tau <= (tf - tc)
                % Velocidad constante
                yseg(k) = qi + 0.5*signo*a*tc^2 + vmax*(tau - tc);
                wseg(k) = vmax;
                gseg(k) = 0;

            elseif tau <= tf
                % Frenado
                tiempoRestante = tf - tau;
                yseg(k) = qf - 0.5*signo*a*tiempoRestante^2;
                wseg(k) = signo*a*tiempoRestante;
                gseg(k) = -signo*a;

            else
                % Tiempo muerto
                yseg(k) = qf;
                wseg(k) = 0;
                gseg(k) = 0;
            end
        end

        y = [y, yseg];
        w = [w, wseg];
        g = [g, gseg];
        x = [x, xseg];

        tiempoAcumulado = tiempoAcumulado + tf + tdesc;
    end
end
