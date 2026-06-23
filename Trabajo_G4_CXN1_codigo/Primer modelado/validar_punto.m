function validar_punto(P, robot)
%Entrada. P(Px,Py,Pz) y datos de configuracion
% VALIDAR_PUNTO Verifica alcance geométrico y singularidades básicas.
%
% Lanza error si el punto no puede alcanzarse o si tiene una
% indeterminación fuerte para theta1.

    px = P(1);
    py = P(2);
    pz = P(3);

    L1 = robot.L1;
    L2 = robot.L2;
    L3 = robot.L3;

    r = sqrt(px^2 + py^2); %distancia desde el segundo eslabon al punto final
    z = pz - L1;
    D = sqrt(r^2 + z^2); %distancia desde la base al punto final

    if r < robot.tol
        error(['Punto singular: Px y Py son prácticamente cero. ', ...
               'La articulación theta1 queda indeterminada.']);
    end

    if D > (L2 + L3 + robot.tol)
        error('Punto fuera del alcance máximo: D = %.3f mm, L2+L3 = %.3f mm.', D, L2+L3);
    end

    if D < (abs(L2 - L3) - robot.tol)
        error('Punto dentro de zona no alcanzable: D = %.3f mm, |L2-L3| = %.3f mm.', D, abs(L2-L3));
    end

    if abs(D - (L2 + L3)) < robot.tolSing
        warning('Punto cercano a singularidad de brazo extendido.');
    end

    if abs(D - abs(L2 - L3)) < robot.tolSing
        warning('Punto cercano a singularidad de brazo plegado.');
    end
end
