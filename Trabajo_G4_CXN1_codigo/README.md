# Robot antropomorfico 3 GDL

Primera version funcional en MATLAB R2024 construida solo con archivos `.m`.

## Inicio

```matlab
app = iniciarRobot3GDL;
```

La aplicacion abre una interfaz con cinco pestanas: configuracion y rutina, animacion 3D, posicion articular, velocidad articular y aceleracion articular.

## Convencion cinematica

Se conserva la convencion existente del proyecto:

```text
r = L2*cosd(q2) + L3*cosd(q2 - q3)
z = L1 + L2*sind(q2) + L3*sind(q2 - q3)
q1 = atan2d(y, x)
```

Con esta definicion, `q3` positivo resta orientacion al tercer eslabon respecto de `q2`.

## Arquitectura

- `iniciarRobot3GDL.m`: punto de entrada unico.
- `Robot3GDLApp.m`: clase de interfaz grafica con `uifigure`, `uigridlayout`, `uitabgroup`, `uitable` y `uiaxes`.
- `+robot3gdl/`: paquete con matematica, validacion, rutina de ejemplo y trayectoria LSPB.
- `tests/ejecutarPruebas.m`: pruebas numericas basicas.

## Trayectorias

La trayectoria usa LSPB por tramos, con velocidad cero al inicio y fin de cada tramo. Si el tiempo nominal no alcanza para respetar la aceleracion maxima o la velocidad maxima `robot.vMax`, se calcula el tiempo minimo factible y se sincroniza el tramo para las tres articulaciones.

Antes de generar cada tramo se evalua el recorrido articular admisible. Para q1, un cambio cercano a `+170` hacia `-170` no usa automaticamente el camino angular corto por `+-180`, porque esa zona esta fuera de los limites mecanicos. En ese caso se usa el recorrido continuo dentro de `[-170, 170]`, se aumenta el tiempo si hace falta y se informa en Command Window.

Las velocidades y aceleraciones se calculan analiticamente desde el perfil LSPB; no se derivan con `diff`. Las lineas verticales de referencia de las graficas usan un unico estilo centralizado.

## Animacion 3D

La pestana de animacion incluye dos controles de fluidez:

- `Paso render`: usa una de cada N muestras de trayectoria para dibujar. Un valor mayor mejora la fluidez y reduce detalle visual.
- `Retardo [s]`: tiempo minimo entre cuadros renderizados. Un valor bajo acelera la animacion; un valor alto la hace mas lenta y facil de inspeccionar.

La geometria de la animacion se precalcula al preparar la escena y luego solo se actualizan `XData`, `YData` y `ZData`.

## Modelo 3D STL

La pestana `Modelo 3D STL` prepara la visualizacion con piezas importadas desde Fusion sin reemplazar la animacion alambrica. Si no existen los STL, la app inicia igual y muestra geometrias provisionales.

Los archivos se buscan en `modelos_stl`, con nombres configurados en `+robot3gdl/parametrosRobot.m`. Cada pieza tiene escala, rotacion inicial, traslacion inicial y matriz local configurable. La convencion inicial es que el eje longitudinal del STL apunte en `+X` local y las unidades esten en milimetros.

Al copiar los STL reales en la carpeta, use `Recargar STL` en la pestana sin reiniciar MATLAB.

## Pruebas

```matlab
addpath(fullfile(pwd, 'tests'));
resumen = ejecutarPruebas;
```

## Codigo previo

Las funciones existentes en `App` y `Primer modelado` se conservaron como referencia. La nueva aplicacion usa el paquete `+robot3gdl` para evitar dos implementaciones activas con la misma responsabilidad.
