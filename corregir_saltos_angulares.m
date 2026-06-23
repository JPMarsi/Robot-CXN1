function Qcorr = corregir_saltos_angulares(Q)
% CORREGIR_SALTOS_ANGULARES Evita saltos artificiales por cambio de rama.
%
% Ejemplo:
%   179 -> -179 se corrige como 179 -> 181.
%
% Esto mejora el control articular, porque FControl trabaja sobre
% trayectorias angulares continuas.

    Qcorr = Q;

    for j = 1:size(Q, 2)
        for i = 2:size(Q, 1)
            delta = Qcorr(i, j) - Qcorr(i-1, j);

            while delta > 180
                Qcorr(i:end, j) = Qcorr(i:end, j) - 360;
                delta = Qcorr(i, j) - Qcorr(i-1, j);
            end

            while delta < -180
                Qcorr(i:end, j) = Qcorr(i:end, j) + 360;
                delta = Qcorr(i, j) - Qcorr(i-1, j);
            end
        end
    end
end
