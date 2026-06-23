# CONTEXTO DEL PROYECTO

## Proyecto

Desarrollo en MATLAB de una aplicación gráfica para simular el control cinemático de un robot antropomórfico de 3 grados de libertad.

La aplicación debe estar construida completamente mediante archivos `.m`.

No utilizar:

* App Designer.
* Archivos `.mlapp`.
* Simscape.
* GUIDE.
* Interfaces basadas en `figure` tradicional, salvo que sea estrictamente necesario por compatibilidad.

Utilizar componentes modernos:

* `uifigure`
* `uigridlayout`
* `uitabgroup`
* `uitab`
* `uiaxes`
* `uitable`
* `uibutton`
* `uidropdown`
* `uieditfield`
* `uilabel`
* `uicheckbox`
* `uispinner`
* `uialert`

La aplicación debe ser compatible con MATLAB R2024.

---

# OBJETIVO GENERAL

Construir una aplicación gráfica completa, modular y ejecutable para:

1. Configurar el robot.
2. Cargar o editar una rutina de puntos cartesianos.
3. Resolver la cinemática inversa.
4. Seleccionar configuraciones codo arriba o codo abajo.
5. Validar volumen de trabajo y límites articulares.
6. Generar trayectorias articulares con perfil trapezoidal de velocidad.
7. Animar el robot en tres dimensiones.
8. Mostrar las gráficas de posición, velocidad y aceleración de las tres articulaciones.
9. Mostrar resultados, advertencias y errores de manera clara.

---

# PARÁMETROS DEL ROBOT

Robot antropomórfico de 3 grados de libertad, con tres articulaciones rotacionales.

Longitudes:

* L1 = 492 mm
* L2 = 365 mm
* L3 = 310 mm

Interpretación:

* L1 es la altura vertical desde la base hasta el hombro.
* L2 es la longitud del segundo eslabón.
* L3 es la longitud del tercer eslabón.

Límites articulares:

* q1 ∈ [-170°, 170°]
* q2 ∈ [-80°, 120°]
* q3 ∈ [-130°, 130°]

Condiciones del control cinemático:

* Aceleración nominal máxima: 100 grados/s².
* Tiempo nominal de incursión por tramo: 2 segundos.
* Tiempo muerto entre trayectorias: 0.2 segundos.
* Tiempo de muestreo inicial: 0.02 segundos.

Estos valores deben ser editables desde la interfaz.

---

# CONVENCIÓN CINEMÁTICA

La articulación q1 corresponde al giro de la base alrededor del eje vertical.

Las articulaciones q2 y q3 definen el movimiento del brazo en el plano vertical determinado por q1.

La cinemática directa debe devolver como mínimo:

* posición de la base;
* posición del hombro;
* posición del codo;
* posición del efector final.

La convención angular utilizada debe mantenerse consistente en:

* cinemática directa;
* cinemática inversa;
* animación;
* límites articulares;
* gráficas.

Antes de implementar las ecuaciones definitivas, revisar los archivos existentes del proyecto para identificar la convención ya utilizada.

No cambiar arbitrariamente los signos de q2 o q3.

---

# SOLUCIONES DE CINEMÁTICA INVERSA

Para cada punto cartesiano deben calcularse, cuando existan:

* solución codo arriba;
* solución codo abajo.

La función debe devolver:

* ambas soluciones;
* indicación de cuáles son reales;
* indicación de cuáles respetan límites;
* causa del rechazo de cada solución;
* proximidad a singularidades;
* error de reconstrucción cartesiana.

Para calcular q1 utilizar una función robusta equivalente a:

`atan2d(Py, Px)`

No utilizar solamente `atand(Py/Px)`.

Los argumentos de funciones trigonométricas inversas deben limitarse numéricamente al intervalo [-1, 1] para evitar errores por redondeo.

---

# SELECCIÓN DE CONFIGURACIÓN

Cada punto de la rutina debe permitir elegir:

* Automática
* Codo arriba
* Codo abajo

En modo automático se debe seleccionar una solución válida minimizando, en este orden:

1. cumplimiento de límites;
2. continuidad respecto de la configuración anterior;
3. desplazamiento articular total;
4. cercanía a límites;
5. proximidad a singularidades.

Evitar cambios innecesarios entre codo arriba y codo abajo.

No introducir saltos angulares equivalentes a 360°.

---

# VALIDACIONES

Validar como mínimo:

* formato de la rutina;
* presencia de valores numéricos;
* puntos fuera del volumen geométrico;
* puntos dentro del volumen geométrico pero incompatibles con los límites articulares;
* puntos singulares;
* soluciones complejas;
* valores NaN o Inf;
* tiempo insuficiente para cumplir la aceleración;
* violación de límites durante la trayectoria;
* saltos articulares no físicos;
* rutina vacía;
* rutina con un solo punto;
* botones presionados en un orden inválido.

No cerrar MATLAB ante un error.

Los errores de usuario deben mostrarse mediante `uialert`.

Los errores internos deben capturarse con `try/catch` y mostrar un mensaje útil.

---

# TRAYECTORIA ARTICULAR

Implementar un generador de trayectoria por segmento lineal con transiciones parabólicas.

Para cada tramo debe generarse:

* posición articular q(t);
* velocidad articular dq(t);
* aceleración articular ddq(t);
* vector temporal.

Debe respetar:

* velocidad inicial igual a cero;
* velocidad final igual a cero;
* continuidad de posición;
* continuidad de velocidad;
* aceleración limitada;
* tiempo muerto entre tramos.

Las tres articulaciones deben iniciar y finalizar cada tramo simultáneamente.

Si el tiempo solicitado no permite completar el desplazamiento con la aceleración especificada:

* no generar valores complejos;
* detectar el problema;
* calcular el tiempo mínimo factible;
* permitir usar automáticamente dicho tiempo;
* informar al usuario.

Evitar depender únicamente de la función antigua `FControl`.

Se puede reutilizar su principio matemático, pero debe implementarse una versión moderna, clara, vectorizada y robusta.

---

# ANIMACIÓN

La animación debe realizarse en un `uiaxes`.

Representar:

* base;
* columna vertical;
* hombro;
* brazo L2;
* brazo L3;
* articulaciones;
* efector final;
* trayectoria cartesiana programada;
* trayectoria cartesiana recorrida.

No usar `cla` en cada cuadro.

Crear los objetos gráficos una vez y actualizar sus propiedades:

* `XData`
* `YData`
* `ZData`

Utilizar:

`drawnow limitrate nocallbacks`

La velocidad de reproducción debe ser independiente del tiempo de muestreo.

Agregar controles:

* Simular
* Pausar
* Continuar
* Detener
* Reiniciar
* Velocidad de reproducción

La animación no debe bloquear permanentemente la interfaz.

Durante la animación deben actualizarse:

* tiempo actual;
* tramo actual;
* punto objetivo;
* q1, q2 y q3 actuales;
* posición cartesiana actual;
* barra o indicador de progreso.

---

# INTERFAZ GRÁFICA

La ventana debe construirse mediante una clase MATLAB.

Archivo principal:

`Robot3GDLApp.m`

Clase principal:

`classdef Robot3GDLApp < handle`

La interfaz debe ser redimensionable.

Usar `uigridlayout`.

Evitar posiciones absolutas salvo casos puntuales.

---

# PESTAÑAS

Crear cinco pestañas:

## 1. Configuración y rutina

Debe contener:

### Parámetros geométricos

* L1
* L2
* L3

### Límites articulares

* q1 mínimo y máximo
* q2 mínimo y máximo
* q3 mínimo y máximo

### Parámetros temporales

* aceleración máxima;
* tiempo nominal por tramo;
* tiempo muerto;
* tiempo de muestreo.

### Tabla de rutina

Columnas iniciales:

* Nombre
* X_mm
* Y_mm
* Z_mm
* Configuración
* Habilitado

Funciones:

* Agregar punto
* Eliminar punto
* Subir punto
* Bajar punto
* Cargar rutina
* Guardar rutina
* Cargar ejemplo
* Validar rutina
* Calcular trayectoria
* Limpiar

La tabla debe permitir edición directa.

Mostrar también una tabla de resultados articulares:

* Punto
* q1
* q2
* q3
* Configuración seleccionada
* Estado
* Mensaje

## 2. Animación 3D

Debe contener:

* `uiaxes` principal grande;
* controles de reproducción;
* estado de simulación;
* tiempo;
* tramo;
* punto actual;
* q actual;
* posición cartesiana actual;
* progreso.

Configurar:

* cuadrícula;
* vista tridimensional;
* etiquetas de ejes;
* unidades en milímetros;
* aspecto proporcional;
* límites adecuados para todo el robot.

## 3. Posición articular

Mostrar tres gráficas o una gráfica con selector.

Preferencia inicial:

* tres `uiaxes`, uno para q1, otro para q2 y otro para q3.

Mostrar:

* curva de posición;
* puntos de paso;
* límites articulares;
* etiquetas;
* unidades;
* leyenda;
* cuadrícula.

## 4. Velocidad articular

Mostrar:

* dq1;
* dq2;
* dq3;
* unidades grados/s;
* cuadrícula;
* leyenda;
* valores máximos.

## 5. Aceleración articular

Mostrar:

* ddq1;
* ddq2;
* ddq3;
* unidades grados/s²;
* límites de aceleración;
* cuadrícula;
* leyenda.

---

# ESTADO INTERNO DE LA APLICACIÓN

La clase debe almacenar como propiedades, como mínimo:

* parámetros del robot;
* límites;
* rutina cartesiana;
* soluciones articulares;
* configuraciones elegidas;
* tiempo;
* q;
* dq;
* ddq;
* trayectoria cartesiana;
* estado de reproducción;
* índice actual de animación;
* objetos gráficos;
* indicador de si los cálculos están actualizados.

Evitar variables globales.

---

# ESTRUCTURA DE ARCHIVOS

Crear una estructura modular similar a:

```text
Robot3GDL/
│
├── Robot3GDLApp.m
├── iniciarRobot3GDL.m
├── CONTEXTO_PROYECTO.md
├── README.md
│
├── config/
│   └── parametrosPredeterminados.m
│
├── cinematica/
│   ├── cinematicaDirecta.m
│   ├── cinematicaInversa.m
│   ├── calcularPosicionesEslabones.m
│   ├── seleccionarConfiguracion.m
│   ├── normalizarAngulo.m
│   └── detectarSingularidad.m
│
├── validacion/
│   ├── validarRutina.m
│   ├── validarPunto.m
│   ├── verificarLimitesArticulares.m
│   └── verificarTrayectoriaArticular.m
│
├── trayectoria/
│   ├── generarTrayectoriaArticular.m
│   ├── generarTramoLSPB.m
│   ├── calcularTiempoMinimo.m
│   └── agregarTiempoMuerto.m
│
├── visualizacion/
│   ├── crearRobotGrafico.m
│   ├── actualizarRobotGrafico.m
│   ├── configurarEjesRobot.m
│   └── actualizarGraficasArticulares.m
│
├── datos/
│   ├── rutinaEjemplo.m
│   └── rutinaEvaluacion.m
│
└── tests/
    ├── testCinematicaDirecta.m
    ├── testCinematicaInversa.m
    ├── testTrayectoria.m
    └── ejecutarPruebas.m
```

MATLAB debe agregar automáticamente estas carpetas al path desde el archivo de inicio.

---

# RUTINA DE EJEMPLO

Crear una rutina inicial válida que comience y termine en:

`Home = [675, 0, 492] mm`

Debe incluir puntos en diferentes cuadrantes y configuraciones codo arriba/codo abajo.

No elegir puntos arbitrarios sin validarlos.

Cada punto de ejemplo debe verificarse mediante cinemática inversa antes de incorporarse.

---

# ARCHIVO DE INICIO

Crear:

`iniciarRobot3GDL.m`

Debe:

1. obtener la carpeta raíz del proyecto;
2. agregar las subcarpetas al path;
3. cerrar una instancia anterior de la aplicación si corresponde;
4. crear una nueva instancia de `Robot3GDLApp`;
5. devolver opcionalmente el objeto de aplicación.

Ejemplo de uso esperado:

```matlab
app = iniciarRobot3GDL;
```

---

# REQUISITOS DE CÓDIGO

* Código claro y comentado.
* Nombres descriptivos en español.
* Una responsabilidad principal por función.
* Validación de argumentos con `arguments` cuando sea compatible.
* Preasignar vectores y matrices.
* Evitar bucles innecesarios en cálculos numéricos.
* No usar variables globales.
* No duplicar ecuaciones en varios archivos.
* No depender de toolboxes no esenciales.
* Informar claramente cualquier toolbox utilizado.
* Mantener compatibilidad con MATLAB R2024.
* Evitar funciones introducidas exclusivamente en R2025 o R2026.
* Todas las unidades internas deben estar documentadas.
* Usar grados de manera consistente o convertir explícitamente.
* No mezclar grados y radianes silenciosamente.

---

# PRUEBAS MÍNIMAS

Crear pruebas para verificar:

## Cinemática directa e inversa

Para configuraciones válidas:

1. calcular posición mediante cinemática directa;
2. resolver cinemática inversa;
3. reconstruir la posición mediante cinemática directa;
4. comprobar un error cartesiano pequeño.

## Límites

Probar:

* un punto válido;
* un punto fuera del alcance máximo;
* un punto dentro de la esfera geométrica pero fuera de los límites articulares;
* un punto cercano a singularidad;
* un punto sobre un eje cartesiano;
* un punto con X negativo;
* un punto con Y negativo.

## Trayectoria

Comprobar:

* posición inicial;
* posición final;
* velocidad inicial cero;
* velocidad final cero;
* continuidad;
* aceleración máxima;
* tiempo muerto;
* ausencia de NaN, Inf o valores complejos.

---

# README

Crear un `README.md` explicando:

* objetivo;
* estructura;
* versión de MATLAB;
* cómo iniciar la aplicación;
* convención cinemática;
* unidades;
* cómo cargar rutinas;
* cómo ejecutar las pruebas;
* limitaciones conocidas;
* archivos principales.

---

# CRITERIO DE TERMINACIÓN

El trabajo inicial se considera terminado cuando:

1. `iniciarRobot3GDL` abre la aplicación sin errores.
2. La aplicación tiene las cinco pestañas.
3. La tabla permite editar una rutina.
4. Se puede cargar una rutina de ejemplo.
5. Se puede validar la rutina.
6. Se calculan soluciones articulares.
7. Se genera una trayectoria.
8. Se muestran las gráficas de q, dq y ddq.
9. Se anima el robot.
10. Los controles de pausa, continuación y detención funcionan.
11. Las pruebas principales se ejecutan.
12. No se utilizan archivos `.mlapp`.
