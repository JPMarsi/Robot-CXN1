function verificar_Q_con_CD(Pdeseados, Q, robot)
% VERIFICAR_Q_CON_CD Compara puntos deseados contra cinemática directa.

    fprintf('Verificando cinemática directa contra puntos deseados...\n');

    errorMax = 0;

    for i = 1:size(Q,1)
        puntos = cinematica_directa(Q(i,:), robot);
        Pcalc = puntos(4,:);
        err = norm(Pcalc - Pdeseados(i,:));
        errorMax = max(errorMax, err);

        if err > 1e-5
            error('Error alto en punto %d: %.6f mm.', i, err);
        end
    end

    fprintf('Verificación OK. Error máximo = %.8f mm.\n\n', errorMax);
end
