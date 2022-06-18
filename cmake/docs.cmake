find_package(Doxygen REQUIRED COMPONENTS dot)

set(
  DOXYGEN_OUTPUT_DIRECTORY "${PROJECT_BINARY_DIR}/docs"
  CACHE PATH "Path for the generated Doxygen documentation"
)
# Always run this target because we have no source file tracking for incremental builds
add_custom_target(docs
  COMMAND "${CMAKE_COMMAND}" -E remove_directory "${DOXYGEN_OUTPUT_DIRECTORY}/html"
  COMMAND Doxygen::doxygen Doxyfile
  COMMAND "${CMAKE_COMMAND}" -E copy_directory "${library_root}/../doc" "${DOXYGEN_OUTPUT_DIRECTORY}"
  COMMENT "sleigh: Generating the Doxygen documentation"
  WORKING_DIRECTORY "${library_root}"
  VERBATIM
)
