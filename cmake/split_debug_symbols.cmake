# Generates a separate file with debug symbols while stripping it from the main binary.
# This is needed for Debian packages.
macro(clickhouse_split_debug_symbols)
   set(oneValueArgs TARGET DESTINATION_DIR BINARY_PATH)

   cmake_parse_arguments(STRIP "" "${oneValueArgs}" "" ${ARGN})

   if (NOT DEFINED STRIP_TARGET)
       message(FATAL_ERROR "A target name must be provided for stripping binary")
   endif()

   if (NOT DEFINED STRIP_BINARY_PATH)
       message(FATAL_ERROR "A binary path name must be provided for stripping binary")
   endif()

   if (NOT DEFINED STRIP_DESTINATION_DIR)
       message(FATAL_ERROR "Destination directory for stripped binary must be provided")
   endif()

   add_custom_command(TARGET ${STRIP_TARGET} POST_BUILD
       COMMAND mkdir -p "${STRIP_DESTINATION_DIR}/lib/debug/bin"
       COMMAND mkdir -p "${STRIP_DESTINATION_DIR}/bin"
       # Splits debug symbols into separate file, leaves the binary untouched:
       COMMAND "${OBJCOPY_PATH}" --only-keep-debug "${STRIP_BINARY_PATH}" "${STRIP_DESTINATION_DIR}/lib/debug/bin/${STRIP_TARGET}.debug"
       COMMAND chmod 0644 "${STRIP_DESTINATION_DIR}/lib/debug/bin/${STRIP_TARGET}.debug"
       # Strips binary, sections '.note' & '.comment' are removed in line with Debian's stripping policy: www.debian.org/doc/debian-policy/ch-files.html, section '.clickhouse.hash' is needed for integrity check.
       # Also, after we disabled the export of symbols for dynamic linking, we still to keep a static symbol table for good stack traces.
       COMMAND "${STRIP_PATH}" --strip-debug --remove-section=.comment --remove-section=.note "${STRIP_BINARY_PATH}" -o "${STRIP_DESTINATION_DIR}/bin/${STRIP_TARGET}"
       # Associate stripped binary with debug symbols:
       COMMAND "${OBJCOPY_PATH}" --add-gnu-debuglink "${STRIP_DESTINATION_DIR}/lib/debug/bin/${STRIP_TARGET}.debug" "${STRIP_DESTINATION_DIR}/bin/${STRIP_TARGET}"
       COMMENT "Stripping clickhouse binary" VERBATIM
   )

   install(PROGRAMS ${STRIP_DESTINATION_DIR}/bin/${STRIP_TARGET} DESTINATION ${CMAKE_INSTALL_BINDIR} COMPONENT clickhouse)
   cmake_path(SET DEBUG_PATH NORMALIZE "${CMAKE_INSTALL_LIBDIR}/debug/${CMAKE_INSTALL_FULL_BINDIR}")
   install(FILES ${STRIP_DESTINATION_DIR}/lib/debug/bin/${STRIP_TARGET}.debug DESTINATION ${DEBUG_PATH} COMPONENT clickhouse)
endmacro()


macro(clickhouse_make_empty_debug_info_for_nfpm)
   set(oneValueArgs TARGET BINARY DESTINATION_DIR)
   cmake_parse_arguments(EMPTY_DEBUG "" "${oneValueArgs}" "" ${ARGN})

   if (NOT DEFINED EMPTY_DEBUG_TARGET)
       message(FATAL_ERROR "A target name must be provided for stripping binary")
   endif()
   if (NOT DEFINED EMPTY_DEBUG_BINARY)
       message(FATAL_ERROR "A binary name must be provided for stripping binary")
   endif()
   if (NOT DEFINED EMPTY_DEBUG_DESTINATION_DIR)
       message(FATAL_ERROR "Destination directory for empty debug must be provided")
   endif()

   add_custom_command(TARGET ${EMPTY_DEBUG_TARGET} POST_BUILD
       COMMAND mkdir -p "${EMPTY_DEBUG_DESTINATION_DIR}/lib/debug"
       COMMAND touch "${EMPTY_DEBUG_DESTINATION_DIR}/lib/debug/${EMPTY_DEBUG_BINARY}.debug"
       COMMENT "Adding empty debug info for NFPM" VERBATIM
   )

   cmake_path(SET DEBUG_PATH NORMALIZE "${CMAKE_INSTALL_LIBDIR}/debug/${CMAKE_INSTALL_FULL_BINDIR}")
   install(FILES "${EMPTY_DEBUG_DESTINATION_DIR}/lib/debug/${EMPTY_DEBUG_BINARY}.debug" DESTINATION ${DEBUG_PATH} COMPONENT clickhouse)
endmacro()
