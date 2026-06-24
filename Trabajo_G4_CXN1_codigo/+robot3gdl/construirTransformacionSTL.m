function Tlocal = construirTransformacionSTL(escala, rotacionDeg, traslacion)
% CONSTRUIRTRANSFORMACIONSTL Correccion local STL: T * Rz * Ry * Rx * S.

    if numel(escala) == 1
        escala = [escala escala escala];
    end

    rx = deg2rad(rotacionDeg(1));
    ry = deg2rad(rotacionDeg(2));
    rz = deg2rad(rotacionDeg(3));

    Tlocal = makehgtform('translate', traslacion) * ...
        makehgtform('zrotate', rz) * ...
        makehgtform('yrotate', ry) * ...
        makehgtform('xrotate', rx) * ...
        makehgtform('scale', escala);
end
