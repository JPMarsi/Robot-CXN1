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

La trayectoria usa LSPB por tramos, con velocidad cero al inicio y fin de cada tramo. Si el tiempo nominal no alcanza para respetar la aceleracion maxima, se calcula el tiempo minimo factible y se sincroniza el tramo para las tres articulaciones.

## Animacion 3D

La pestana de animacion incluye dos controles de fluidez:

- `Paso render`: usa una de cada N muestras de trayectoria para dibujar. Un valor mayor mejora la fluidez y reduce detalle visual.
- `Retardo [s]`: tiempo minimo entre cuadros renderizados. Un valor bajo acelera la animacion; un valor alto la hace mas lenta y facil de inspeccionar.

La geometria de la animacion se precalcula al preparar la escena y luego solo se actualizan `XData`, `YData` y `ZData`.

## Pruebas

```matlab
addpath(fullfile(pwd, 'tests'));
resumen = ejecutarPruebas;
```

## Codigo previo

Las funciones existentes en `App` y `Primer modelado` se conservaron como referencia. La nueva aplicacion usa el paquete `+robot3gdl` para evitar dos implementaciones activas con la misma responsabilidad.
