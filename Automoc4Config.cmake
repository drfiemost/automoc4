
get_filename_component(_AUTOMOC4_CURRENT_DIR  "${CMAKE_CURRENT_LIST_FILE}" PATH)

# are we in the source tree or already installed ?
if(EXISTS ${_AUTOMOC4_CURRENT_DIR}/kde4automoc.cpp)
   get_target_property(AUTOMOC4_EXECUTABLE automoc4 LOCATION)
   set(_AUTOMOC4_EXECUTABLE_DEP automoc4)
else(EXISTS ${_AUTOMOC4_CURRENT_DIR}/kde4automoc.cpp)
   get_filename_component(_AUTOMOC4_BIN_DIR  "${_AUTOMOC4_CURRENT_DIR}" PATH)
   get_filename_component(_AUTOMOC4_BIN_DIR  "${_AUTOMOC4_BIN_DIR}" PATH)
   find_program(AUTOMOC4_EXECUTABLE automoc4 PATHS  "${_AUTOMOC4_BIN_DIR}/bin" NO_DEFAULT_PATH)
   set(_AUTOMOC4_EXECUTABLE_DEP)
endif(EXISTS ${_AUTOMOC4_CURRENT_DIR}/kde4automoc.cpp)

macro (AUTOMOC4_MOC_HEADERS _target_NAME)
   set (_headers_to_moc)
   foreach (_current_FILE ${ARGN})
      get_filename_component(_suffix "${_current_FILE}" EXT)
      if (".h" STREQUAL "${_suffix}" OR ".hpp" STREQUAL "${_suffix}" OR ".hxx" STREQUAL "${_suffix}" OR ".H" STREQUAL "${_suffix}")
         list(APPEND _headers_to_moc ${_current_FILE})
      else (".h" STREQUAL "${_suffix}" OR ".hpp" STREQUAL "${_suffix}" OR ".hxx" STREQUAL "${_suffix}" OR ".H" STREQUAL "${_suffix}")
         message(STATUS "AUTOMOC4_MOC_HEADERS: ignoring non-header file ${_current_FILE}")
      endif (".h" STREQUAL "${_suffix}" OR ".hpp" STREQUAL "${_suffix}" OR ".hxx" STREQUAL "${_suffix}" OR ".H" STREQUAL "${_suffix}")
   endforeach (_current_FILE)
   # need to create moc_<filename>.cpp file using automoc4
   # and add it to the target
   if(_headers_to_moc)
       set(_automoc4_headers_${_target_NAME} "${_headers_to_moc}")
   endif(_headers_to_moc)
endmacro (AUTOMOC4_MOC_HEADERS)


macro(AUTOMOC4 _target_NAME _SRCS)
   set(_moc_files)
   set(_moc_headers)

   # first list all explicitly set headers
   foreach(_header_to_moc ${_automoc4_headers_${_target_NAME}} )
      get_filename_component(_abs_header ${_header_to_moc} ABSOLUTE)
      list(APPEND _moc_files ${_abs_header})
      list(APPEND _moc_headers ${_abs_header})
   endforeach(_header_to_moc)

   # now add all the sources for the automoc
   foreach (_current_FILE ${${_SRCS}})
      get_filename_component(_abs_current_FILE "${_current_FILE}" ABSOLUTE)
      get_source_file_property(_skip      "${_abs_current_FILE}" SKIP_AUTOMOC)
      get_source_file_property(_generated "${_abs_current_FILE}" GENERATED)

      if(NOT  _generated  AND NOT  _skip)
         get_filename_component(_suffix "${_current_FILE}" EXT)
         # skip every source file that's not C++
         if(_suffix STREQUAL ".cpp" OR _suffix STREQUAL ".cc" OR _suffix STREQUAL ".cxx" OR _suffix STREQUAL ".C")

             get_filename_component(_basename "${_current_FILE}" NAME_WE)
             get_filename_component(_abs_path "${_abs_current_FILE}" PATH)
             set(_header "${_abs_path}/${_basename}.h")
             if(EXISTS "${_header}")
                list(APPEND _moc_headers ${_header})
             endif(EXISTS "${_header}")
             set(_pheader "${_abs_path}/${_basename}_p.h")
             if(EXISTS "${_pheader}")
                list(APPEND _moc_headers ${_pheader})
             endif(EXISTS "${_pheader}")
             list(APPEND _moc_files ${_abs_current_FILE})
         endif(_suffix STREQUAL ".cpp" OR _suffix STREQUAL ".cc" OR _suffix STREQUAL ".cxx" OR _suffix STREQUAL ".C")
      endif(NOT  _generated  AND NOT  _skip)
   endforeach (_current_FILE)

   if(_moc_files)
      set(_automoc_source "${CMAKE_CURRENT_BINARY_DIR}/${_target_NAME}_automoc.cpp")
      get_directory_property(_moc_incs INCLUDE_DIRECTORIES)
      configure_file(${_AUTOMOC4_CURRENT_DIR}/automoc4.files.in ${_automoc_source}.files)
      add_custom_command(OUTPUT ${_automoc_source}
         COMMAND ${AUTOMOC4_EXECUTABLE}
         ${_automoc_source}
         ${CMAKE_CURRENT_SOURCE_DIR}
         ${CMAKE_CURRENT_BINARY_DIR}
         ${QT_MOC_EXECUTABLE}
#         ${CMAKE_COMMAND}
         DEPENDS ${${_SRCS}} ${_moc_headers} ${_automoc_source}.files ${_AUTOMOC4_EXECUTABLE_DEP}
         )
      # the OBJECT_DEPENDS is only necessary when a new moc file has to be generated that is included in a source file
      # problem: the whole target is recompiled when the automoc.cpp file is touched
      # set_source_files_properties(${${_SRCS}} PROPERTIES OBJECT_DEPENDS ${_automoc_source})
      set(${_SRCS} ${_automoc_source} ${${_SRCS}})
   endif(_moc_files)
endmacro(AUTOMOC4)

