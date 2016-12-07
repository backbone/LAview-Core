SET (CONTACT "backbone@backbone.ws")
SET (DEBIAN_DEPENDENCIES "laview-latex-struct-0 (>= 0.1.0), gobject-plugin-0 (>= 0.1.0)")
SET (DEBIAN_SECTION "Libraries")
SET (REDHAT_DEPENDENCIES "laview-latex-struct-0 >= 0.1.0, gobject-plugin-0 >= 0.1.0")
SET (REDHAT_SECTION "Applications/Text")
SET (LICENSE "LGPLv3+")
SET (WIN32_UNINSTALL_NAME "LAvCore") # <= 8 symbols for the name
SET (CPACK_NSIS_MENU_LINKS "https://redmine.backbone.ws/projects/laview-core"
                           "Homepage for ${PROJECT_DESCRIPTION}")
INCLUDE (CPackCommonRules)
