function app = iniciarRobot3GDL()
% INICIARROBOT3GDL Punto de entrada unico de la aplicacion.

    raiz = fileparts(mfilename('fullpath'));
    addpath(raiz);

    app = Robot3GDLApp();
end
