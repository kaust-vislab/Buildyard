
set(TCLAP_PACKAGE_VERSION 1.2)
set(TCLAP_OPTIONAL ON)
set(TCLAP_DEB_DEPENDS doxygen)

find_package(Doxygen QUIET)
if(DOXYGEN_FOUND) # build depends on doxygen
  set(TCLAP_REPO_URL https://github.com/BlueBrain/tclap.git)
  set(TCLAP_REPO_TAG bbp)
  set(TCLAP_AUTOCONF ON)
  set(TCLAP_CONFIGURE_FLAGS "--enable-doxygen")
endif()