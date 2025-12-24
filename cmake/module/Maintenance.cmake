# Copyright (c) 2023-present The Retardio developers
# Distributed under the MIT software license, see the accompanying
# file COPYING or https://opensource.org/license/mit/.

include_guard(GLOBAL)

function(setup_split_debug_script)
  if(CMAKE_HOST_SYSTEM_NAME STREQUAL "Linux")
    set(OBJCOPY ${CMAKE_OBJCOPY})
    set(STRIP ${CMAKE_STRIP})
    configure_file(
      contrib/devtools/split-debug.sh.in split-debug.sh
      FILE_PERMISSIONS OWNER_READ OWNER_EXECUTE
                       GROUP_READ GROUP_EXECUTE
                       WORLD_READ
      @ONLY
    )
  endif()
endfunction()

function(add_maintenance_targets)
  if(NOT PYTHON_COMMAND)
    return()
  endif()

  foreach(target IN ITEMS retardiod retardio-qt retardio-cli retardio-tx retardio-util retardio-wallet test_bitcoin bench_bitcoin)
    if(TARGET ${target})
      list(APPEND executables $<TARGET_FILE:${target}>)
    endif()
  endforeach()

  add_custom_target(check-symbols
    COMMAND ${CMAKE_COMMAND} -E echo "Running symbol and dynamic library checks..."
    COMMAND ${PYTHON_COMMAND} ${PROJECT_SOURCE_DIR}/contrib/devtools/symbol-check.py ${executables}
    VERBATIM
  )

  add_custom_target(check-security
    COMMAND ${CMAKE_COMMAND} -E echo "Checking binary security..."
    COMMAND ${PYTHON_COMMAND} ${PROJECT_SOURCE_DIR}/contrib/devtools/security-check.py ${executables}
    VERBATIM
  )
endfunction()

function(add_windows_deploy_target)
  if(MINGW AND TARGET retardio-qt AND TARGET retardiod AND TARGET retardio-cli AND TARGET retardio-tx AND TARGET retardio-wallet AND TARGET retardio-util AND TARGET test_bitcoin)
    # TODO: Consider replacing this code with the CPack NSIS Generator.
    #       See https://cmake.org/cmake/help/latest/cpack_gen/nsis.html
    include(GenerateSetupNsi)
    generate_setup_nsi()
    add_custom_command(
      OUTPUT ${PROJECT_BINARY_DIR}/retardio-win64-setup.exe
      COMMAND ${CMAKE_COMMAND} -E make_directory ${PROJECT_BINARY_DIR}/release
      COMMAND ${CMAKE_STRIP} $<TARGET_FILE:retardio-qt> -o ${PROJECT_BINARY_DIR}/release/$<TARGET_FILE_NAME:retardio-qt>
      COMMAND ${CMAKE_STRIP} $<TARGET_FILE:retardiod> -o ${PROJECT_BINARY_DIR}/release/$<TARGET_FILE_NAME:retardiod>
      COMMAND ${CMAKE_STRIP} $<TARGET_FILE:retardio-cli> -o ${PROJECT_BINARY_DIR}/release/$<TARGET_FILE_NAME:retardio-cli>
      COMMAND ${CMAKE_STRIP} $<TARGET_FILE:retardio-tx> -o ${PROJECT_BINARY_DIR}/release/$<TARGET_FILE_NAME:retardio-tx>
      COMMAND ${CMAKE_STRIP} $<TARGET_FILE:retardio-wallet> -o ${PROJECT_BINARY_DIR}/release/$<TARGET_FILE_NAME:retardio-wallet>
      COMMAND ${CMAKE_STRIP} $<TARGET_FILE:retardio-util> -o ${PROJECT_BINARY_DIR}/release/$<TARGET_FILE_NAME:retardio-util>
      COMMAND ${CMAKE_STRIP} $<TARGET_FILE:test_bitcoin> -o ${PROJECT_BINARY_DIR}/release/$<TARGET_FILE_NAME:test_bitcoin>
      COMMAND makensis -V2 ${PROJECT_BINARY_DIR}/retardio-win64-setup.nsi
      DEPENDS generate_nsis_images
      VERBATIM
    )
    add_custom_target(deploy DEPENDS ${PROJECT_BINARY_DIR}/retardio-win64-setup.exe)
  endif()
endfunction()

function(add_macos_deploy_target)
  if(CMAKE_SYSTEM_NAME STREQUAL "Darwin" AND TARGET retardio-qt)
    set(macos_app "Retardio-Qt.app")
    # Populate Contents subdirectory.
    configure_file(${PROJECT_SOURCE_DIR}/share/qt/Info.plist.in ${macos_app}/Contents/Info.plist NO_SOURCE_PERMISSIONS)
    file(CONFIGURE OUTPUT ${macos_app}/Contents/PkgInfo CONTENT "APPL????")
    # Populate Contents/Resources subdirectory.
    file(CONFIGURE OUTPUT ${macos_app}/Contents/Resources/empty.lproj CONTENT "")
    file(CONFIGURE OUTPUT ${macos_app}/Contents/Resources/Base.lproj/InfoPlist.strings
      CONTENT "{ CFBundleDisplayName = \"@CLIENT_NAME@\"; CFBundleName = \"@CLIENT_NAME@\"; }"
    )

    set(bitcoin_icns ${PROJECT_BINARY_DIR}/src/qt/res/rendered_icons/retardio.icns)
    set(bitcoin_icns_dest ${macos_app}/Contents/Resources/retardio.icns)
    add_custom_command(
      OUTPUT ${bitcoin_icns_dest}
      COMMAND ${CMAKE_COMMAND} -E copy ${bitcoin_icns} ${bitcoin_icns_dest}
      DEPENDS generate_icns
      VERBATIM
    )
    add_custom_target(bitcoin_icns_deployed DEPENDS "${bitcoin_icns_dest}")

    add_custom_command(
      OUTPUT ${PROJECT_BINARY_DIR}/${macos_app}/Contents/MacOS/Retardio-Qt
      COMMAND ${CMAKE_COMMAND} --install ${PROJECT_BINARY_DIR} --config $<CONFIG> --component retardio-qt --prefix ${macos_app}/Contents/MacOS --strip
      COMMAND ${CMAKE_COMMAND} -E rename ${macos_app}/Contents/MacOS/bin/$<TARGET_FILE_NAME:retardio-qt> ${macos_app}/Contents/MacOS/Retardio-Qt
      COMMAND ${CMAKE_COMMAND} -E rm -rf ${macos_app}/Contents/MacOS/bin
      COMMAND ${CMAKE_COMMAND} -E rm -rf ${macos_app}/Contents/MacOS/share
      VERBATIM
    )

    string(REPLACE " " "-" osx_volname ${CLIENT_NAME})
    if(CMAKE_HOST_APPLE)
      add_custom_command(
        OUTPUT ${PROJECT_BINARY_DIR}/${osx_volname}.zip
        COMMAND ${PYTHON_COMMAND} ${PROJECT_SOURCE_DIR}/contrib/macdeploy/macdeployqtplus ${macos_app} ${osx_volname} -translations-dir=${QT_TRANSLATIONS_DIR} -zip
        DEPENDS ${PROJECT_BINARY_DIR}/${macos_app}/Contents/MacOS/Retardio-Qt
        VERBATIM
      )
      add_custom_target(deploydir
        DEPENDS ${PROJECT_BINARY_DIR}/${osx_volname}.zip
      )
      add_custom_target(deploy
        DEPENDS ${PROJECT_BINARY_DIR}/${osx_volname}.zip
      )
    else()
      add_custom_command(
        OUTPUT ${PROJECT_BINARY_DIR}/dist/${macos_app}/Contents/MacOS/Retardio-Qt
        COMMAND OBJDUMP=${CMAKE_OBJDUMP} ${PYTHON_COMMAND} ${PROJECT_SOURCE_DIR}/contrib/macdeploy/macdeployqtplus ${macos_app} ${osx_volname} -translations-dir=${QT_TRANSLATIONS_DIR}
        DEPENDS ${PROJECT_BINARY_DIR}/${macos_app}/Contents/MacOS/Retardio-Qt
        VERBATIM
      )
      add_custom_target(deploydir
        DEPENDS ${PROJECT_BINARY_DIR}/dist/${macos_app}/Contents/MacOS/Retardio-Qt
      )

      find_program(ZIP_COMMAND zip REQUIRED)
      add_custom_command(
        OUTPUT ${PROJECT_BINARY_DIR}/dist/${osx_volname}.zip
        WORKING_DIRECTORY dist
        COMMAND ${PROJECT_SOURCE_DIR}/cmake/script/macos_zip.sh ${ZIP_COMMAND} ${osx_volname}.zip
        VERBATIM
      )
      add_custom_target(deploy
        DEPENDS ${PROJECT_BINARY_DIR}/dist/${osx_volname}.zip
      )
    endif()
    add_dependencies(deploydir retardio-qt)
    add_dependencies(deploydir bitcoin_icns_deployed)
    add_dependencies(deploy deploydir)
  endif()
endfunction()
