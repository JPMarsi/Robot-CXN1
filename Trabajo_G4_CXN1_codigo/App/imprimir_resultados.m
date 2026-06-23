function imprimir_resultados(rutina, Q, infoCI)
% IMPRIMIR_RESULTADOS Muestra tabla de puntos y ángulos articulares.

    fprintf('====================================================\n');
    fprintf(' RESULTADOS DE CINEMÁTICA INVERSA\n');
    fprintf('====================================================\n');
    fprintf('%-4s %-34s %10s %10s %10s %10s %10s %10s %-8s\n', ...
            'N', 'Punto', 'Px', 'Py', 'Pz', 'theta1', 'theta2', 'theta3', 'Codo');
    fprintf('%s\n', repmat('-', 1, 118));

    for i = 1:size(Q,1)
        P = rutina.puntos(i,:);
        info = infoCI{i};

        fprintf('%-4d %-34s %10.2f %10.2f %10.2f %10.3f %10.3f %10.3f %-8s\n', ...
                i, rutina.nombres{i}, P(1), P(2), P(3), ...
                Q(i,1), Q(i,2), Q(i,3), info.codoDetectado);
    end
end
