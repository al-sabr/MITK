#--------------------------------------------------------------------------
#  PCRE (Perl Compatible Regular Expressions)
#--------------------------------------------------------------------------
if(MITK_USE_PCRE)
  if(DEFINED PCRE_DIR AND NOT EXISTS ${PCRE_DIR})
      message(FATAL_ERROR "PCRE_DIR variable is defined but corresponds to non-existing directory")
   endif()
  if(NOT PCRE_DIR)

    set(proj PCRE)
    set(${proj}_DEPENDENCIES "")
    set(PCRE_TARGET_VERSION 8.35)
    set(PCRE_DOWNLOAD_SOURCE_HASH "ed58bcbe54d3b1d59e9f5415ef45ce1c")

    ExternalProject_add(${proj}
      URL http://midas3.kitware.com/midas/api/rest?method=midas.bitstream.download&checksum=${PCRE_DOWNLOAD_SOURCE_HASH}&name=pcre-${PCRE_TARGET_VERSION}.tar.gz
      URL_MD5 "${PCRE_DOWNLOAD_SOURCE_HASH}"
      SOURCE_DIR ${CMAKE_CURRENT_BINARY_DIR}/${proj}-src
      BINARY_DIR ${CMAKE_CURRENT_BINARY_DIR}/${proj}-build
      INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/${proj}-install
      PREFIX ${proj}-cmake
      CONFIGURE_COMMAND <SOURCE_DIR>/./configure
                        CC=${CMAKE_C_COMPILER}${CMAKE_C_COMPILER_ARG1}
                        LDFLAGS=${CMAKE_LINKER_FLAGS} ${CMAKE_LINKER_FLAGS_RELEASE}
                        CXX=${CMAKE_CXX_COMPILER}${CMAKE_CXX_COMPILER_ARG1}
                        --prefix=<INSTALL_DIR>
                        --disable-shared
      DEPENDS "${${proj}_DEPENDENCIES}"
      )

    set(PCRE_DIR ${CMAKE_CURRENT_BINARY_DIR}/${proj}-install)

  else()
    mitkMacroEmptyExternalProject(${proj} "${${proj}_DEPENDENCIES}")
  endif()
endif()
