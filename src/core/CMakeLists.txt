SET (LibName ${PROJECT_LOWERCASE_NAME})
FILE (GLOB_RECURSE LibSources RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} *.vala)
SET (LibPackages laview-latex-struct-0 gobject-plugin-iface-0 gobject-plugin-loader-0 gee-0.8 gio-2.0 gmodule-2.0 posix)
SET (LibCustomVapis
     ${CMAKE_BINARY_DIR}/src/core-iface/${PROJECT_LOWERCASE_NAME}-iface-${MAJOR}.vapi
     ${CMAKE_BINARY_DIR}/src/conv/${PROJECT_LOWERCASE_NAME}-conv-${MAJOR}.vapi
     ${CMAKE_SOURCE_DIR}/config/Config.vapi)
INCLUDE_DIRECTORIES ("${CMAKE_BINARY_DIR}/config")
SET (LibLinkLibs ${PROJECT_LOWERCASE_NAME}-iface ${PROJECT_LOWERCASE_NAME}-conv)
INCLUDE_DIRECTORIES ("${CMAKE_BINARY_DIR}/src/core-iface")
INCLUDE_DIRECTORIES ("${CMAKE_BINARY_DIR}/src/conv")
SET (LibPkgModules laview-latex-struct-0 gobject-plugin-0 gee-0.8 gio-2.0 gmodule-2.0)
SET (LibInstall ON)
SET (LibExtraSources ${CMAKE_CURRENT_BINARY_DIR}/library_constructor.c)
SET (LC_RELATIVE_PREFIX "..")
CONFIGURE_FILE ( "${CMAKE_SOURCE_DIR}/cmake/backbone/templates/library_constructor.c.in" "${LibExtraSources}")
INCLUDE (ValaLibCommonRules)
