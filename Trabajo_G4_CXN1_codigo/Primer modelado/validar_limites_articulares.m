function validar_limites_articulares(Q, robot, nombreEtapa)
% VALIDAR_LIMITES_ARTICULARES
% Comprueba que q1, q2 y q3 permanezcan dentro de sus límites físicos.
%
% Entrada:
%   Q           matriz Nx3 de posiciones articulares [deg]
%   robot       estructura de parámetros
%   nombreEtapa texto utilizado en los mensajes de error
%
% Ejemplo:
%   validar_limites_articulares(Q, robot, 'Cinemática inversa');

    if nargin < 3
        nombreEtapa = 'Trayectoria articular';
    end

    if size(Q,2) ~= 3
        error('Q debe ser una matriz Nx3: [q1 q2 q3].');
    end

    tolerancia = 1e-9;

    for i = 1:size(Q,1)

        for j = 1:3

            valor = Q(i,j);
            limiteInferior = robot.qMin(j);
            limiteSuperior = robot.qMax(j);

            if valor < limiteInferior - tolerancia || ...
               valor > limiteSuperior + tolerancia

                error([ ...
                    '%s: límite articular incumplido.\n' ...
                    'Punto o muestra: %d\n' ...
                    'Articulación: %s\n' ...
                    'Valor calculado: %.3f°\n' ...
                    'Límite permitido: [%.3f°, %.3f°].'], ...
                    nombreEtapa, ...
                    i, ...
                    robot.nombreArticulacion{j}, ...
                    valor, ...
                    limiteInferior, ...
                    limiteSuperior);
            end
        end
    end
end