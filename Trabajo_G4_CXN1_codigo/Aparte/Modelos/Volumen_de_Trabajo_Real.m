%% ============================================================
%  12) CORTES PLANOS DEL VOLUMEN DE TRABAJO
% ============================================================
% Estos cortes permiten ver el alcance interno del robot.
% Es decir, no solo hasta donde llega por fuera, sino tambien
% que zonas internas no puede alcanzar por la geometria de L2 y L3
% y por los limites articulares.

espesor = 12;   % mm - espesor del plano de corte

% ------------------------------------------------------------
% Corte vertical XZ: puntos cercanos al plano Y = 0
% ------------------------------------------------------------

idx_XZ = abs(Yv) <= espesor;

figure('Name','Corte vertical XZ - Plano Y = 0');
scatter(Xv(idx_XZ), Zv(idx_XZ), 8, Zv(idx_XZ), 'filled');
grid on;
axis equal;
xlabel('X [mm]');
ylabel('Z [mm]');
title('Corte del volumen en el plano XZ  -  Y = 0');
colorbar;

% ------------------------------------------------------------
% Corte vertical YZ: puntos cercanos al plano X = 0
% ------------------------------------------------------------

idx_YZ = abs(Xv) <= espesor;

figure('Name','Corte vertical YZ - Plano X = 0');
scatter(Yv(idx_YZ), Zv(idx_YZ), 8, Zv(idx_YZ), 'filled');
grid on;
axis equal;
xlabel('Y [mm]');
ylabel('Z [mm]');
title('Corte del volumen en el plano YZ  -  X = 0');
colorbar;

% ------------------------------------------------------------
% Corte horizontal XY: puntos cercanos a una altura Z elegida
% ------------------------------------------------------------
% Elegimos algunas alturas representativas.
% Podes modificarlas segun lo que quieras ver.

z_cortes = [200, 492, 700, 900];   % mm

for i = 1:length(z_cortes)

    z0 = z_cortes(i);

    idx_XY = abs(Zv - z0) <= espesor;

    figure('Name',['Corte horizontal XY - Z = ', num2str(z0), ' mm']);
    scatter(Xv(idx_XY), Yv(idx_XY), 8, sqrt(Xv(idx_XY).^2 + Yv(idx_XY).^2), 'filled');
    grid on;
    axis equal;
    xlabel('X [mm]');
    ylabel('Y [mm]');
    title(['Corte horizontal del volumen en Z = ', num2str(z0), ' mm']);
    colorbar;

end

%% ============================================================
%  13) CORTE MERIDIANO r-Z
% ============================================================
% Este grafico es probablemente el mas claro para ver el hueco interno.
%
% r = distancia radial al eje vertical de la base
% r = sqrt(X^2 + Y^2)
%
% Como theta1 solamente gira el plano del robot, el corte r-Z muestra
% la forma real del alcance del brazo en un plano vertical.

Rv = sqrt(Xv.^2 + Yv.^2);

figure('Name','Corte meridiano r-Z del volumen de trabajo');
scatter(Rv, Zv, 8, Zv, 'filled');
grid on;
axis equal;
xlabel('r = sqrt(X^2 + Y^2) [mm]');
ylabel('Z [mm]');
title('Corte meridiano r-Z del volumen limitado');
colorbar;

%% ============================================================
%  14) ENVOLVENTE INTERNA Y EXTERNA APROXIMADA EN r-Z
% ============================================================
% Este bloque intenta marcar, para cada altura Z, el radio minimo
% y maximo alcanzable. Sirve para visualizar la "semiesfera interna".

nbins = 120;

z_min = min(Zv);
z_max = max(Zv);

bordes_z = linspace(z_min, z_max, nbins + 1);
z_medios = zeros(nbins,1);
r_minimo = nan(nbins,1);
r_maximo = nan(nbins,1);

for k = 1:nbins

    z_inf = bordes_z(k);
    z_sup = bordes_z(k+1);

    idx = Zv >= z_inf & Zv < z_sup;

    if any(idx)
        z_medios(k) = 0.5*(z_inf + z_sup);
        r_minimo(k) = min(Rv(idx));
        r_maximo(k) = max(Rv(idx));
    else
        z_medios(k) = 0.5*(z_inf + z_sup);
    end

end

figure('Name','Envolvente interna y externa r-Z');
hold on;
scatter(Rv, Zv, 3, [0.75 0.75 0.75], 'filled');

plot(r_maximo, z_medios, 'k', 'LineWidth', 2);
plot(r_minimo, z_medios, 'r', 'LineWidth', 2);

grid on;
axis equal;
xlabel('r [mm]');
ylabel('Z [mm]');
title('Envolvente interna y externa del volumen de trabajo');
legend('Puntos alcanzables', 'Borde externo', 'Borde interno', 'Location', 'best');
hold off;
%% ============================================================
%  SOLIDO DEL VOLUMEN DE TRABAJO POR VOXELS
% ============================================================
% En vez de graficar solo puntos, se crea una grilla 3D.
% Cada celda de la grilla se marca como ocupada si hay puntos
% alcanzables cerca.
%
% Luego se genera una superficie cerrada con isosurface.

%% 1) Parametros de resolucion del solido

res = 25;      % mm - tamaño aproximado del voxel
radio_cierre = 2;   % cantidad de voxels para cerrar pequeños huecos

%% 2) Definir grilla cartesiana

x_grid = min(Xv):res:max(Xv);
y_grid = min(Yv):res:max(Yv);
z_grid = min(Zv):res:max(Zv);

[Xg, Yg, Zg] = meshgrid(x_grid, y_grid, z_grid);

ocupado = false(size(Xg));

%% 3) Convertir puntos alcanzables a indices de grilla

ix = round((Xv - min(x_grid)) / res) + 1;
iy = round((Yv - min(y_grid)) / res) + 1;
iz = round((Zv - min(z_grid)) / res) + 1;

% Evitar indices fuera de rango
ix = max(1, min(ix, length(x_grid)));
iy = max(1, min(iy, length(y_grid)));
iz = max(1, min(iz, length(z_grid)));

ind = sub2ind(size(ocupado), iy, ix, iz);
ocupado(ind) = true;

%% 4) Engrosar la nube para transformarla en volumen continuo
% Esto convierte puntos discretos en un volumen mas solido.
% imdilate requiere Image Processing Toolbox.
% Si no tenes esa toolbox, abajo te dejo alternativa.

se = true(2*radio_cierre + 1, 2*radio_cierre + 1, 2*radio_cierre + 1);
ocupado_solido = imdilate(ocupado, se);

%% 5) Cerrar pequeños huecos internos

ocupado_solido = imfill(ocupado_solido, 'holes');

%% 6) Graficar solido con isosurface

figure('Name','Solido del volumen de trabajo');
fv = isosurface(Xg, Yg, Zg, ocupado_solido, 0.5);

p = patch(fv);
p.FaceAlpha = 0.35;
p.EdgeColor = 'none';

grid on;
axis equal;
xlabel('X [mm]');
ylabel('Y [mm]');
zlabel('Z [mm]');
title('Solido aproximado del volumen de trabajo');
view(45,25);
camlight;
lighting gouraud;

%% 7) Agregar ejes de referencia

hold on;
plot3([0 800], [0 0], [0 0], 'r', 'LineWidth', 1.5);
plot3([0 0], [0 800], [0 0], 'g', 'LineWidth', 1.5);
plot3([0 0], [0 0], [0 1000], 'b', 'LineWidth', 1.5);
text(820,0,0,'X');
text(0,820,0,'Y');
text(0,0,1020,'Z');
hold off;