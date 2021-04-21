#-----------------------------------------------------------------------------
# CTK
#-----------------------------------------------------------------------------

if(MITK_USE_CPPMICROSERVICES)

  # Sanity checks
  if(DEFINED CPPMICROSERVICES_DIR AND NOT EXISTS ${CPPMICROSERVICES_DIR})
    message(FATAL_ERROR "CPPMICROSERVICES_DIR variable is defined but corresponds to non-existing directory")
  endif()

  set(proj CTK)
  set(proj_DEPENDENCIES DCMTK)
  set(CTK_DEPENDS ${proj})

  if(NOT DEFINED CPPMICROSERVICES_DIR)

    set(revision_tag "v3.6.0")

    set(ctk_optional_cache_args )

    FOREACH(type RUNTIME ARCHIVE LIBRARY)
      IF(DEFINED CTK_PLUGIN_${type}_OUTPUT_DIRECTORY)
        LIST(APPEND mitk_optional_cache_args -DCTK_PLUGIN_${type}_OUTPUT_DIRECTORY:PATH=${CTK_PLUGIN_${type}_OUTPUT_DIRECTORY})
      ENDIF()
    ENDFOREACH()

    mitk_query_custom_ep_vars()

    ExternalProject_Add(${proj}
      LIST_SEPARATOR ${sep}
      GIT_REPOSITORY https://github.com/CppMicroServices/CppMicroServices
      GIT_TAG ${revision_tag}
      UPDATE_COMMAND ""
      INSTALL_COMMAND ""
      CMAKE_GENERATOR ${gen}
      CMAKE_GENERATOR_PLATFORM ${gen_platform}
      CMAKE_ARGS
        ${ep_common_args}
        ${ctk_optional_cache_args}
        # The CTK PluginFramework cannot cope with
        # a non-empty CMAKE_DEBUG_POSTFIX for the plugin
        # libraries yet.
        -DCMAKE_DEBUG_POSTFIX:STRING=
        ${${proj}_CUSTOM_CMAKE_ARGS}
      CMAKE_CACHE_ARGS
        ${ep_common_cache_args}
        ${${proj}_CUSTOM_CMAKE_CACHE_ARGS}
      CMAKE_CACHE_DEFAULT_ARGS
        ${ep_common_cache_default_args}
        ${${proj}_CUSTOM_CMAKE_CACHE_DEFAULT_ARGS}
      DEPENDS ${proj_DEPENDENCIES}
     )

    ExternalProject_Get_Property(${proj} binary_dir)
    set(CPPMICROSERVICES_DIR ${binary_dir})

  else()

    mitkMacroEmptyExternalProject(${proj} "${proj_DEPENDENCIES}")

  endif()

endif()
