# Copyright (c) 2023-present The Retardio developers
# Distributed under the MIT software license, see the accompanying
# file COPYING or https://opensource.org/license/mit/.

function(generate_setup_nsi)
  set(abs_top_srcdir ${PROJECT_SOURCE_DIR})
  set(abs_top_builddir ${PROJECT_BINARY_DIR})
  set(CLIENT_URL ${PROJECT_HOMEPAGE_URL})
  set(CLIENT_TARNAME "retardio")
  set(RETARDIO_GUI_NAME "retardio-qt")
  set(RETARDIO_DAEMON_NAME "retardiod")
  set(RETARDIO_CLI_NAME "retardio-cli")
  set(RETARDIO_TX_NAME "retardio-tx")
  set(RETARDIO_WALLET_TOOL_NAME "retardio-wallet")
  set(RETARDIO_TEST_NAME "test_bitcoin")
  set(EXEEXT ${CMAKE_EXECUTABLE_SUFFIX})
  configure_file(${PROJECT_SOURCE_DIR}/share/setup.nsi.in ${PROJECT_BINARY_DIR}/retardio-win64-setup.nsi USE_SOURCE_PERMISSIONS @ONLY)
endfunction()
