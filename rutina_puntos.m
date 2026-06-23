function rutina = rutina_puntos()
% RUTINA_PUNTOS
% Rutina alternativa para comprobar:
% - distintos cuadrantes;
% - codo arriba y codo abajo;
% - límites de q1, q2 y q3;
% - densificación de movimientos articulares grandes;
% - regreso a Home.

    rutina.nombres = {
        'Home inicial';
        'Prueba 1 - Primer cuadrante';
        'Prueba 2 - Cuarto cuadrante';
        'Prueba 3 - Segundo cuadrante';
        'Prueba 4 - Tercer cuadrante';
        'Prueba 5 - Segundo cuadrante alto';
        'Home final'
    };

    rutina.puntos = [
         675.0,    0.0,  492.0;
         483.5,  338.6,  595.3;
         311.0, -444.2,  379.4;
         -15.5,  177.2, 1049.5;
        -185.0, -320.4,   58.3;
        -262.8,  220.6,  983.3;
         675.0,    0.0,  492.0
    ];

    rutina.config = {
        'arriba';
        'arriba';
        'arriba';
        'abajo';
        'arriba';
        'abajo';
        'arriba'
    };
end