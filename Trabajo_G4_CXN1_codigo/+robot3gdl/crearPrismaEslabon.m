function [faces, vertices] = crearPrismaEslabon(longitud, ancho, alto)
% CREARPRISMAESLABON Prisma rectangular con origen en x=0 y eje largo +X.

    y = ancho/2;
    z = alto/2;
    vertices = [
        0,        -y, -z
        longitud, -y, -z
        longitud,  y, -z
        0,         y, -z
        0,        -y,  z
        longitud, -y,  z
        longitud,  y,  z
        0,         y,  z
    ];

    faces = [
        1 2 3; 1 3 4
        5 8 7; 5 7 6
        1 5 6; 1 6 2
        2 6 7; 2 7 3
        3 7 8; 3 8 4
        4 8 5; 4 5 1
    ];
end
