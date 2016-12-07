SET (BinName conv_test)
FILE (GLOB_RECURSE BinSources RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} ConvTest.vala)
SET (BinPackages gee-0.8 gio-2.0)
SET (BinCustomVapis ${CMAKE_BINARY_DIR}/src/conv/${PROJECT_LOWERCASE_NAME}-conv-${MAJOR}.vapi)
SET (BinLinkLibs ${PROJECT_LOWERCASE_NAME}-conv)
INCLUDE_DIRECTORIES ("${CMAKE_BINARY_DIR}/src/conv")
INCLUDE (ValaBinCommonRules)

## Parse tests
#MACRO (do_parse_test testname table_path etalon_path regexp)
#  IF ("${etalon_path}" STREQUAL "")
#    SET (extra_args "")
#  ELSE ()
#    SET (extra_args --etalon ${etalon_path})
#  ENDIF ()
#  ADD_TEST (ParseTest-${testname} ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/parse_test --table ${table_path} ${extra_args})
#  SET_TESTS_PROPERTIES (ParseTest-${testname}
#  PROPERTIES PASS_REGULAR_EXPRESSION ${regexp}
#             FAIL_REGULAR_EXPRESSION "CRITICAL;WARNING")
#ENDMACRO (do_parse_test)
#
## test throttle.tex
#do_parse_test (throttleList ${PROJECT_SOURCE_DIR}/test/tex/throttle.tex ""
#"list all objects
#LAviewText
#LAviewTableLongtable
#LAviewText
#LAviewTableTabular
#LAviewText
#end of objects
#
#")
#SET_TESTS_PROPERTIES(ParseTest-throttleList PROPERTIES ENVIRONMENT "LANG=en")
#
## enable testing
#ENABLE_TESTING ()
