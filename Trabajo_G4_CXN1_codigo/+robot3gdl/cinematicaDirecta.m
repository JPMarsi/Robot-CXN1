function puntos = cinematicaDirecta(q, robot)
% CINEMATICADIRECTA Devuelve base, hombro, codo y extremo para q en grados.
%
% La aplicacion resuelve la cinematica directa mediante las matrices
% Denavit-Hartenberg definidas explicitamente en:
%
%   +robot3gdl/denavitHartenberg.m

    dh = robot3gdl.denavitHartenberg(q, robot);
    puntos = dh.puntos;
end
