include(CTest)
if(BUILD_TESTING)
  add_subdirectory(tests)
endif()

if(sleigh_BUILD_DOCUMENTATION)
  include(cmake/docs.cmake)
endif()

option(ENABLE_COVERAGE "Enable coverage support separate from CTest's" OFF)
if(ENABLE_COVERAGE)
  include(cmake/coverage.cmake)
endif()
