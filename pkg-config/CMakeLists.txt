INCLUDE (PkgConfigCommonRules)

SET (PkgConfigLibs "-L\${libdir}")
IF (WIN32)
  SET (PkgConfigLibs "${PkgConfigLibs} -l${PROJECT_LOWERCASE_NAME}-${MAJOR}")
  SET (PkgConfigLibs "${PkgConfigLibs} -l${PROJECT_LOWERCASE_NAME}-iface-${MAJOR}")
  SET (PkgConfigLibs "${PkgConfigLibs} -l${PROJECT_LOWERCASE_NAME}-conv-${MAJOR}")
ELSE (WIN32)
  SET (PkgConfigLibs "${PkgConfigLibs} -l${PROJECT_LOWERCASE_NAME}.so.${MAJOR}")
  SET (PkgConfigLibs "${PkgConfigLibs} -l${PROJECT_LOWERCASE_NAME}-iface.so.${MAJOR}")
  SET (PkgConfigLibs "${PkgConfigLibs} -l${PROJECT_LOWERCASE_NAME}-conv.so.${MAJOR}")
ENDIF (WIN32)

CONFIGURE_FILE (
  "${CMAKE_SOURCE_DIR}/cmake/backbone/templates/pkg-config.pc.in"
  "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_LOWERCASE_NAME}-${MAJOR}.pc"
)
