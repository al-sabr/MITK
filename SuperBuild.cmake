
#-----------------------------------------------------------------------------
# Convenient macro allowing to download a file
#-----------------------------------------------------------------------------

macro(downloadFile url dest)
  file(DOWNLOAD ${url} ${dest} STATUS status)
  list(GET status 0 error_code)
  list(GET status 1 error_msg)
  if(error_code)
    message(FATAL_ERROR "error: Failed to download ${url} - ${error_msg}")
  endif()
endmacro()

#-----------------------------------------------------------------------------
# MITK Prerequisites
#-----------------------------------------------------------------------------

if(UNIX AND NOT APPLE)

  include(mitkFunctionCheckPackageHeader)

  # Check for libxt-dev
  mitkFunctionCheckPackageHeader(StringDefs.h libxt-dev /usr/include/X11/)

  # Check for libtiff4-dev
  mitkFunctionCheckPackageHeader(tiff.h libtiff4-dev)

  # Check for libwrap0-dev
  mitkFunctionCheckPackageHeader(tcpd.h libwrap0-dev)

endif()


#-----------------------------------------------------------------------------
# ExternalProjects
#-----------------------------------------------------------------------------

set(external_projects
  VTK
  GDCM
  CableSwig
  ITK
  Boost
  DCMTK
  CTK
  OpenCV
  SOFA
  MITKData
  )

set(MITK_USE_CableSwig ${MITK_USE_Python})
set(MITK_USE_GDCM 1)
set(MITK_USE_ITK 1)
set(MITK_USE_VTK 1)

foreach(proj VTK GDCM CableSwig ITK DCMTK CTK OpenCV SOFA)
  if(MITK_USE_${proj})
    set(EXTERNAL_${proj}_DIR "${${proj}_DIR}" CACHE PATH "Path to ${proj} build directory")
    mark_as_advanced(EXTERNAL_${proj}_DIR)
    if(EXTERNAL_${proj}_DIR)
      set(${proj}_DIR ${EXTERNAL_${proj}_DIR})
    endif()
  endif()
endforeach()

if(MITK_USE_Boost)
  set(EXTERNAL_BOOST_ROOT "${BOOST_ROOT}" CACHE PATH "Path to Boost directory")
  mark_as_advanced(EXTERNAL_BOOST_ROOT)
  if(EXTERNAL_BOOST_ROOT)
    set(BOOST_ROOT ${EXTERNAL_BOOST_ROOT})
  endif()
endif()

if(BUILD_TESTING)
  set(EXTERNAL_MITK_DATA_DIR "${MITK_DATA_DIR}" CACHE PATH "Path to the MITK data directory")
  mark_as_advanced(EXTERNAL_MITK_DATA_DIR)
  if(EXTERNAL_MITK_DATA_DIR)
    set(MITK_DATA_DIR ${EXTERNAL_MITK_DATA_DIR})
  endif()
endif()

# Look for git early on, if needed
if((BUILD_TESTING AND NOT EXTERNAL_MITK_DATA_DIR) OR
   (MITK_USE_CTK AND NOT EXTERNAL_CTK_DIR))
  find_package(Git REQUIRED)
endif()

#-----------------------------------------------------------------------------
# External project settings
#-----------------------------------------------------------------------------

include(ExternalProject)

set(ep_base "${CMAKE_BINARY_DIR}/CMakeExternals")
set_property(DIRECTORY PROPERTY EP_BASE ${ep_base})

set(ep_install_dir ${ep_base}/Install)
#set(ep_build_dir ${ep_base}/Build)
set(ep_source_dir ${ep_base}/Source)
#set(ep_parallelism_level)
set(ep_build_shared_libs ON)
set(ep_build_testing OFF)

if(NOT MITK_THIRDPARTY_DOWNLOAD_PREFIX_URL)
  set(MITK_THIRDPARTY_DOWNLOAD_PREFIX_URL http://mitk.org/download/thirdparty)
endif()

# Compute -G arg for configuring external projects with the same CMake generator:
if(CMAKE_EXTRA_GENERATOR)
  set(gen "${CMAKE_EXTRA_GENERATOR} - ${CMAKE_GENERATOR}")
else()
  set(gen "${CMAKE_GENERATOR}")
endif()

# Use this value where semi-colons are needed in ep_add args:
set(sep "^^")

##

if(MSVC90 OR MSVC10)
  set(ep_common_C_FLAGS "${CMAKE_C_FLAGS} /bigobj /MP")
  set(ep_common_CXX_FLAGS "${CMAKE_CXX_FLAGS} /bigobj /MP")
endif()

set(ep_common_args
  -DBUILD_TESTING:BOOL=${ep_build_testing}
  -DCMAKE_INSTALL_PREFIX:PATH=${ep_install_dir}
  -DBUILD_SHARED_LIBS:BOOL=ON
  -DCMAKE_BUILD_TYPE:STRING=${CMAKE_BUILD_TYPE}
  -DCMAKE_C_COMPILER:FILEPATH=${CMAKE_C_COMPILER}
  -DCMAKE_CXX_COMPILER:FILEPATH=${CMAKE_CXX_COMPILER}
  -DCMAKE_C_FLAGS:STRING=${ep_common_C_FLAGS}
  -DCMAKE_CXX_FLAGS:STRING=${ep_common_CXX_FLAGS}
  #debug flags
  -DCMAKE_CXX_FLAGS_DEBUG:STRING=${CMAKE_CXX_FLAGS_DEBUG}
  -DCMAKE_C_FLAGS_DEBUG:STRING=${CMAKE_C_FLAGS_DEBUG}
  #release flags
  -DCMAKE_CXX_FLAGS_RELEASE:STRING=${CMAKE_CXX_FLAGS_RELEASE}
  -DCMAKE_C_FLAGS_RELEASE:STRING=${CMAKE_C_FLAGS_RELEASE}
  #relwithdebinfo
  -DCMAKE_CXX_FLAGS_RELWITHDEBINFO:STRING=${CMAKE_CXX_FLAGS_RELWITHDEBINFO}
  -DCMAKE_C_FLAGS_RELWITHDEBINFO:STRING=${CMAKE_C_FLAGS_RELWITHDEBINFO}
)

# Include external projects
foreach(p ${external_projects})
  include(CMakeExternals/${p}.cmake)
endforeach()

#-----------------------------------------------------------------------------
# Set superbuild boolean args
#-----------------------------------------------------------------------------

set(mitk_cmake_boolean_args
  BUILD_SHARED_LIBS
  WITH_COVERAGE
  BUILD_TESTING

  MITK_USE_QT
  MITK_BUILD_ALL_PLUGINS
  MITK_BUILD_ALL_APPS
  MITK_BUILD_TUTORIAL # Deprecated. Use MITK_BUILD_EXAMPLES instead
  MITK_BUILD_EXAMPLES
  MITK_USE_Boost
  MITK_USE_SYSTEM_Boost
  MITK_USE_BLUEBERRY
  MITK_USE_CTK
  MITK_USE_DCMTK
  MITK_DCMTK_BUILD_SHARED_LIBS
  MITK_USE_OpenCV
  MITK_USE_SOFA
  MITK_USE_Python
  MITK_USE_OpenCL
  )

#-----------------------------------------------------------------------------
# Create the final variable containing superbuild boolean args
#-----------------------------------------------------------------------------

set(mitk_superbuild_boolean_args)
foreach(mitk_cmake_arg ${mitk_cmake_boolean_args})
  list(APPEND mitk_superbuild_boolean_args -D${mitk_cmake_arg}:BOOL=${${mitk_cmake_arg}})
endforeach()

if(MITK_BUILD_ALL_PLUGINS)
  list(APPEND mitk_superbuild_boolean_args -DBLUEBERRY_BUILD_ALL_PLUGINS:BOOL=ON)
endif()

#-----------------------------------------------------------------------------
# MITK Utilities
#-----------------------------------------------------------------------------

set(proj MITK-Utilities)
ExternalProject_Add(${proj}
  DOWNLOAD_COMMAND ""
  CONFIGURE_COMMAND ""
  BUILD_COMMAND ""
  INSTALL_COMMAND ""
  DEPENDS
    # Mandatory dependencies
    ${VTK_DEPENDS}
    ${ITK_DEPENDS}
    # Optionnal dependencies
    ${Boost_DEPENDS}
    ${CTK_DEPENDS}
    ${DCMTK_DEPENDS}
    ${OpenCV_DEPENDS}
    ${SOFA_DEPENDS}
    ${MITK-Data_DEPENDS}
)

#-----------------------------------------------------------------------------
# MITK Configure
#-----------------------------------------------------------------------------

if(MITK_INITIAL_CACHE_FILE)
  set(mitk_initial_cache_arg -C "${MITK_INITIAL_CACHE_FILE}")
endif()

set(mitk_optional_cache_args )
foreach(type RUNTIME ARCHIVE LIBRARY)
  if(DEFINED CTK_PLUGIN_${type}_OUTPUT_DIRECTORY)
    list(APPEND mitk_optional_cache_args -DCTK_PLUGIN_${type}_OUTPUT_DIRECTORY:PATH=${CTK_PLUGIN_${type}_OUTPUT_DIRECTORY})
  endif()
endforeach()

set(proj MITK-Configure)

ExternalProject_Add(${proj}
  LIST_SEPARATOR ^^
  DOWNLOAD_COMMAND ""
  CMAKE_GENERATOR ${gen}
  CMAKE_CACHE_ARGS
    ${ep_common_args}
    ${mitk_superbuild_boolean_args}
    ${mitk_optional_cache_args}
    -DMITK_USE_SUPERBUILD:BOOL=OFF
    -DMITK_CMAKE_LIBRARY_OUTPUT_DIRECTORY:PATH=${MITK_CMAKE_LIBRARY_OUTPUT_DIRECTORY}
    -DMITK_CMAKE_RUNTIME_OUTPUT_DIRECTORY:PATH=${MITK_CMAKE_RUNTIME_OUTPUT_DIRECTORY}
    -DMITK_CMAKE_ARCHIVE_OUTPUT_DIRECTORY:PATH=${MITK_CMAKE_ARCHIVE_OUTPUT_DIRECTORY}
    -DCTEST_USE_LAUNCHERS:BOOL=${CTEST_USE_LAUNCHERS}
    -DMITK_CTEST_SCRIPT_MODE:STRING=${MITK_CTEST_SCRIPT_MODE}
    -DMITK_SUPERBUILD_BINARY_DIR:PATH=${MITK_BINARY_DIR}
    -DQT_QMAKE_EXECUTABLE:FILEPATH=${QT_QMAKE_EXECUTABLE}
    -DMITK_KWSTYLE_EXECUTABLE:FILEPATH=${MITK_KWSTYLE_EXECUTABLE}
    -DMITK_MODULES_TO_BUILD:INTERNAL=${MITK_MODULES_TO_BUILD}
    -DCTK_DIR:PATH=${CTK_DIR}
    -DDCMTK_DIR:PATH=${DCMTK_DIR}
    -DVTK_DIR:PATH=${VTK_DIR}     # FindVTK expects VTK_DIR
    -DITK_DIR:PATH=${ITK_DIR}     # FindITK expects ITK_DIR
    -DOpenCV_DIR:PATH=${OpenCV_DIR}
    -DSOFA_DIR:PATH=${SOFA_DIR}
    -DGDCM_DIR:PATH=${GDCM_DIR}
    -DBOOST_ROOT:PATH=${BOOST_ROOT}
    -DMITK_USE_Boost_LIBRARIES:STRING=${MITK_USE_Boost_LIBRARIES}
    -DMITK_DATA_DIR:PATH=${MITK_DATA_DIR}
    -DMITK_ACCESSBYITK_INTEGRAL_PIXEL_TYPES:STRING=${MITK_ACCESSBYITK_INTEGRAL_PIXEL_TYPES}
    -DMITK_ACCESSBYITK_FLOATING_PIXEL_TYPES:STRING=${MITK_ACCESSBYITK_FLOATING_PIXEL_TYPES}
    -DMITK_ACCESSBYITK_COMPOSITE_PIXEL_TYPES:STRING=${MITK_ACCESSBYITK_COMPOSITE_PIXEL_TYPES}
    -DMITK_ACCESSBYITK_DIMENSIONS:STRING=${MITK_ACCESSBYITK_DIMENSIONS}
  CMAKE_ARGS
    ${mitk_initial_cache_arg}

  SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}
  BINARY_DIR ${CMAKE_BINARY_DIR}/MITK-build
  BUILD_COMMAND ""
  INSTALL_COMMAND ""
  DEPENDS
    MITK-Utilities
  )


#-----------------------------------------------------------------------------
# MITK
#-----------------------------------------------------------------------------

if(CMAKE_GENERATOR MATCHES ".*Makefiles.*")
  set(mitk_build_cmd "$(MAKE)")
else()
  set(mitk_build_cmd ${CMAKE_COMMAND} --build ${CMAKE_CURRENT_BINARY_DIR}/MITK-build --config ${CMAKE_CFG_INTDIR})
endif()

if(NOT DEFINED SUPERBUILD_EXCLUDE_MITKBUILD_TARGET OR NOT SUPERBUILD_EXCLUDE_MITKBUILD_TARGET)
  set(MITKBUILD_TARGET_ALL_OPTION "ALL")
else()
  set(MITKBUILD_TARGET_ALL_OPTION "")
endif()

add_custom_target(MITK-build ${MITKBUILD_TARGET_ALL_OPTION}
  COMMAND ${mitk_build_cmd}
  WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/MITK-build
  DEPENDS MITK-Configure
  )

#-----------------------------------------------------------------------------
# Custom target allowing to drive the build of the MITK project itself
#-----------------------------------------------------------------------------

add_custom_target(MITK
  COMMAND ${mitk_build_cmd}
  WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/MITK-build
)

