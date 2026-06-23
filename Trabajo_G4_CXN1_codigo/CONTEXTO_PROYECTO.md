# Contexto del proyecto Robot 3 GDL

Este archivo documenta la estructura usada por la primera version funcional.
El pedido original mencionaba `CONTEXTO_PROYECTO.md`, pero en la carpeta solo se encontro `App/Contexto.md` vacio, por lo que se deja este contexto consolidado.

## Estructura activa

- `iniciarRobot3GDL.m`: comando unico de inicio.
- `Robot3GDLApp.m`: clase `handle` responsable de interfaz, callbacks y estado.
- `+robot3gdl/`: paquete activo de calculo numerico.
- `tests/ejecutarPruebas.m`: pruebas numericas basicas.
- `README.md`: instrucciones de uso.

## Convencion cinematica

Se conserva la convencion ya presente en `App/cinematica_directa.m` y `Modelos/SingularidadesIdeales.m`:

```text
x = (L2*cosd(q2) + L3*cosd(q2 - q3))*cosd(q1)
y = (L2*cosd(q2) + L3*cosd(q2 - q3))*sind(q1)
z = L1 + L2*sind(q2) + L3*sind(q2 - q3)
```

`q1` se calcula con `atan2d(y, x)`. `q3` positivo reduce el angulo absoluto del tercer eslabon respecto de `q2`.

## Codigo previo

Las carpetas `App` y `Primer modelado` conservan la implementacion anterior como referencia. La aplicacion nueva no las elimina ni las sobrescribe; usa funciones nuevas con paquete para evitar conflictos de nombres.
