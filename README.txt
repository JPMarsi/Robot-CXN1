TRABAJO INTEGRADOR G4 - CXN1
=============================

Carpeta de código para Matlab/Octave.

Archivo principal:
    main.m

Orden de ejecución:
    1) Abrir Matlab u Octave.
    2) Colocar la carpeta Trabajo_G4_CXN1_codigo como Current Folder.
    3) Ejecutar main.

Estructura lógica:
    puntos cartesianos -> cinemática inversa -> FControl
    -> cinemática directa -> animación y gráficas

Archivos importantes:
    datos_robot.m              Parámetros L1, L2, L3 y tiempos de control.
    rutina_puntos.m            Puntos Px, Py, Pz y codo arriba/abajo.
    cinematica_inversa.m       Cálculo de theta1, theta2 y theta3.
    cinematica_directa.m       Cálculo de base, hombro, codo y extremo.
    FControl.m                 Control trapezoidal/LSPB para una articulación.
    generar_trayectorias.m     Aplica FControl a las tres articulaciones.
    animar_robot.m             Animación alámbrica.
    graficar_articulacion.m    Gráficas q, w, g de una articulación.

Notas:
    - Longitudes en mm.
    - Ángulos en grados.
    - El programa usa atan2d para evitar errores de cuadrante.
    - Se validan puntos fuera del volumen de trabajo.
    - Se detectan singularidades básicas: eje de base, brazo extendido y brazo plegado.
    - Si FControl informa que un tramo es imposible, hay que aumentar tf, aumentar a
      o agregar puntos intermedios.
