
# Copyright (c) 2012 Stefan Eilemann <Stefan.Eilemann@epfl.ch>

# write in-source FindPackages.cmake
function(USE_EXTERNAL_DEPS name)
  string(TOUPPER ${name} NAME)
  if(${NAME}_SKIPFIND OR NOT ${NAME}_DEPENDS)
    return()
  endif()

  set(_depsIn "${CMAKE_CURRENT_BINARY_DIR}/${name}FindPackages.cmake")
  set(_depsOut "${${NAME}_SOURCE}/CMake/FindPackages.cmake")
  set(_scriptdir ${CMAKE_CURRENT_BINARY_DIR}/${name})
  set(DEPMODE)

  file(WRITE ${_depsIn}
    "# generated by Buildyard, do not edit.\n\n"
    "include(System)\n"
    "set(FIND_PACKAGES_FOUND \${SYSTEM} \${FIND_PACKAGES_FOUND_EXTRA})\n\n")
  foreach(_dep ${${NAME}_DEPENDS})
    if(${_dep} STREQUAL "OPTIONAL")
      set(DEPMODE)
    elseif(${_dep} STREQUAL "REQUIRED")
      set(DEPMODE " REQUIRED")
    else()
      string(TOUPPER ${_dep} _DEP)
      set(COMPONENTS)
      if(${NAME}_${_DEP}_COMPONENTS)
        if(DEPMODE)
          set(COMPONENTS " ${${NAME}_${_DEP}_COMPONENTS}")
        else()
          set(COMPONENTS " COMPONENTS ${${NAME}_${_DEP}_COMPONENTS}")
        endif()
      endif()
      if(${_DEP}_CMAKE_INCLUDE)
        set(${_DEP}_CMAKE_INCLUDE "${${_DEP}_CMAKE_INCLUDE} ")
      endif()
      if(NOT ${_DEP}_SKIPFIND)
        set(DEFDEP "${NAME}_USE_${_DEP}")
        string(REGEX REPLACE "-" "_" DEFDEP ${DEFDEP})
        file(APPEND ${_depsIn}
          "find_package(${_dep} ${${_DEP}_PACKAGE_VERSION}${DEPMODE}${COMPONENTS})\n"
          "if(${_dep}_FOUND)\n"
          "  set(${_dep}_name ${_dep})\n"
          "elseif(${_DEP}_FOUND)\n"
          "  set(${_dep}_name ${_DEP})\n"
          "endif()\n"
          "if(${_dep}_name)\n"
          "  list(APPEND FIND_PACKAGES_FOUND ${DEFDEP})\n"
          "  link_directories(\${\${${_dep}_name}_LIBRARY_DIRS})\n"
          "  include_directories(${${_DEP}_CMAKE_INCLUDE}\${\${${_dep}_name}_INCLUDE_DIRS})\n"
          "endif()\n\n"
          )
      endif()
    endif()
  endforeach()

  file(APPEND ${_depsIn} "\n"
    "# Write defines.h and options.cmake\n"
    "if(NOT FIND_PACKAGES_INCLUDE)\n"
    "  set(FIND_PACKAGES_INCLUDE\n"
    "    \"\${CMAKE_BINARY_DIR}/include/\${CMAKE_PROJECT_NAME}/defines\${SYSTEM}.h\")\n"
    "endif()\n"
    "if(NOT OPTIONS_CMAKE)\n"
    "  set(OPTIONS_CMAKE \${CMAKE_BINARY_DIR}/options.cmake)\n"
    "endif()\n"
    "set(DEFINES_FILE \${FIND_PACKAGES_INCLUDE})\n"
    "set(DEFINES_FILE_IN \${DEFINES_FILE}.in)\n"
    "file(WRITE \${DEFINES_FILE_IN}\n"
    "  \"// generated by Buildyard, do not edit.\\n\\n\"\n"
    "  \"#ifndef \${CMAKE_PROJECT_NAME}_DEFINES_\${SYSTEM}_H\\n\"\n"
    "  \"#define \${CMAKE_PROJECT_NAME}_DEFINES_\${SYSTEM}_H\\n\\n\")\n"
    "file(WRITE \${OPTIONS_CMAKE} \"# Optional modules enabled during build\\n\")\n"
    "foreach(DEF \${FIND_PACKAGES_FOUND})\n"
    "  add_definitions(-D\${DEF})\n"
    "  file(APPEND \${DEFINES_FILE_IN}\n"
    "  \"#ifndef \${DEF}\\n\"\n"
    "  \"#  define \${DEF}\\n\"\n"
    "  \"#endif\\n\")\n"
    "if(NOT DEF STREQUAL SYSTEM)\n"
    "  file(APPEND \${OPTIONS_CMAKE} \"set(\${DEF} ON)\\n\")\n"
    "endif()\n"
    "endforeach()\n"
    "file(APPEND \${DEFINES_FILE_IN}\n"
    "  \"\\n#endif\\n\")\n\n"
    "include(UpdateFile)\n"
    "update_file(\${DEFINES_FILE_IN} \${DEFINES_FILE})\n"
    )

  file(WRITE ${_scriptdir}/writeDeps.cmake
    "list(APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/CMake)\n"
    "include(UpdateFile)\n"
    "update_file(${_depsIn} ${_depsOut})")

  setup_scm(${name})
  ExternalProject_Add_Step(${name} rmFindPackages
    COMMENT "Resetting FindPackages"
    COMMAND ${SCM_RESET} CMake/FindPackages.cmake || ${SCM_STATUS}
    WORKING_DIRECTORY "${${NAME}_SOURCE}"
    DEPENDEES mkdir DEPENDERS download ALWAYS 1
    )

  ExternalProject_Add_Step(${name} FindPackages
    COMMENT "Updating ${_depsOut}"
    COMMAND ${CMAKE_COMMAND} -DBUILDYARD:PATH=${CMAKE_SOURCE_DIR}
            -P ${_scriptdir}/writeDeps.cmake
    DEPENDEES update DEPENDERS configure DEPENDS ${${NAME}_CONFIGFILE}
    )
endfunction()
