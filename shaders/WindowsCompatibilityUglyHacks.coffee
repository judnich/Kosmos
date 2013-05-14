# Copyright (C) 2013 John Judnich
# Released under The MIT License - see "LICENSE" file for details.

# For some reason, Windows messes with GLSL shaders and sometimes, unexpectedly, with NO WARNING,
# NO ERROR, and NO reason whatsoever -- just fails to output anything from the shader.
#
# The hilarious part: What seems to make it work just fine is removing one of the GLSL uniforms
# definitions and replacing it with constants. It can't be that we're exceeding the max uniforms
# because *we only use one vec3 and one vec2* at MOST, for the planet map generation shaders.
# So there really is no way of knowing what's going on under the hood of WebGL GLSL running on
# windows without directly debugging the browsers (and we have issues on every browser on Windows.)
#
# A prime suspect is Google's ANGLE "compatibility layer" for Windows only, which changes OpenGL
# calls into Direct3D calls, and recompiles GLSL code into HLSL code. I suspect that's (ANGLE) where 
# things are going horribly, horribly wrong in Chrome, but I'm still unsure why Firefox also suffers
# these issues.
#
# In any case, the fix is unfortunate: We have to disable randomSeed on Windows entirely. What does this
# mean? It means that on Windows, you only get three types of planets (one from each unique height function),
# instead of an trillions that you get on Mac and Linux. :(
#
# That is, until Firefox/Chrome or whoever is responsible fixes the broken GLSL compiler on Windows.
# There's nothing else that can be done really other than recompiling the shader for EACH planet, which
# would have prohibitively bad performance.

root = exports ? this
root.windowsCompatibilityUglyHacks = {}

is_windows = (if (navigator.appVersion.indexOf("Win") != -1) then true else false)
root.windowsCompatibilityUglyHacks.randomSeedDefString = if not is_windows then "uniform vec3 randomSeed;" else "const vec3 randomSeed = vec3(0.75, 0.5, 0.25);"

