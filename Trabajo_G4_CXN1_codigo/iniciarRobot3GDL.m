function app = iniciarRobot3GDL()
% INICIARROBOT3GDL Punto de entrada unico de la aplicacion.
    close all force;
    clear app;
    clear classes;
    rehash;
    raiz = fileparts(mfilename('fullpath'));
    addpath(raiz);

    app = Robot3GDLApp();
end
