cmake_minimum_required(VERSION 3.5)

#*******************************************************************************
# Pre-building function, set variables which need to be set before project()
# is called...
#*******************************************************************************
function(pre_build)
  if (APPLE)
    set(CMAKE_OSX_DEPLOYMENT_TARGET "10.9" PARENT_SCOPE)
    set(CMAKE_OSX_ARCHITECTURES "i386" "x86_64" PARENT_SCOPE)
  elseif(MSVC)
    # static linking
    foreach(flag_var CMAKE_CXX_FLAGS CMAKE_CXX_FLAGS_DEBUG CMAKE_CXX_FLAGS_RELEASE CMAKE_CXX_FLAGS_MINSIZEREL CMAKE_CXX_FLAGS_RELWITHDEBINFO)
      if(${flag_var} MATCHES "/MD")
        string(REGEX REPLACE "/MD" "/MT" ${flag_var} "${${flag_var}}")
      endif()
      if(${flag_var} MATCHES "/MDd")
        string(REGEX REPLACE "/MDd" "/MTd" ${flag_var} "${${flag_var}}")
      endif()
    endforeach()
  endif()
endfunction(pre_build)

#*******************************************************************************
# Adds VST SDK to target
#
# @param VST_TARGET The cmake target to which the VST SDK will be added.
#*******************************************************************************
function(add_vstsdk VST_TARGET)
  set(STEINBERG_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../Steinberg)

  set(VST_SOURCE
    ${STEINBERG_DIR}/public.sdk/source/vst2.x/audioeffect.cpp
    ${STEINBERG_DIR}/public.sdk/source/vst2.x/audioeffectx.cpp
    ${STEINBERG_DIR}/public.sdk/source/vst2.x/vstplugmain.cpp
    ${STEINBERG_DIR}/public.sdk/source/vst2.x/aeffeditor.h
    ${STEINBERG_DIR}/public.sdk/source/vst2.x/audioeffect.h
    ${STEINBERG_DIR}/public.sdk/source/vst2.x/audioeffectx.h
  )

  set(VST_INTERFACE
    ${STEINBERG_DIR}/pluginterfaces/vst2.x/aeffect.h
    ${STEINBERG_DIR}/pluginterfaces/vst2.x/aeffectx.h
    ${STEINBERG_DIR}/pluginterfaces/vst2.x/vstfxstore.h
  )

  source_group("vst2.x" FILES ${VST_SOURCE})
  source_group("Interfaces" FILES ${VST_INTERFACE})

  target_sources(${VST_TARGET} PUBLIC ${VST_SOURCE} ${VST_INTERFACE})
  target_include_directories(${VST_TARGET} PUBLIC ${STEINBERG_DIR})

endfunction(add_vstsdk)

#*******************************************************************************
# Create windows .rc resource file
#
# @param PROJECT_IMAGES    List of image paths for the project.
#*******************************************************************************
function(create_resource_file PROJECT_IMAGES)
  set(RESOURCES_LIST)

  foreach (IMAGE_PATH ${PROJECT_IMAGES})
    get_filename_component(IMAGE_FILENAME ${IMAGE_PATH} NAME)
    list(APPEND RESOURCES_LIST "${IMAGE_FILENAME}\tPNG\t\"${IMAGE_PATH}\"\n")
  endforeach(IMAGE_PATH ${PROJECT_IMAGES})

  file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/resource.rc ${RESOURCES_LIST})
endfunction(create_resource_file)

#*******************************************************************************
# Adds VSTGUI to target
#
# @param VST_TARGET        The cmake target to which the VSTGUI libray will be
#                          added.
# @param VST_TARGET_IMAGES The images used in the cmake targets GUI
#*******************************************************************************
function(add_vstgui VST_TARGET VST_TARGET_IMAGES)

  set(VSTGUI_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../vstgui/vstgui)

  set(VSTGUI_SOURCE
    ${VSTGUI_DIR}/plugin-bindings/aeffguieditor.cpp
    ${VSTGUI_DIR}/plugin-bindings/aeffguieditor.h
  )

  if(WIN32)

    list(APPEND VSTGUI_SOURCE ${VSTGUI_DIR}/vstgui_win32.cpp)

    create_resource_file("${VST_TARGET_IMAGES}")
    target_sources(${VST_TARGET} PUBLIC ${CMAKE_CURRENT_BINARY_DIR}/resource.rc)

  elseif(APPLE)
    list(APPEND VSTGUI_SOURCE ${VSTGUI_DIR}/vstgui.cpp)
    list(APPEND VSTGUI_SOURCE ${VSTGUI_DIR}/lib/platform/mac/cgdrawcontext.cpp)
    list(APPEND VSTGUI_SOURCE ${VSTGUI_DIR}/lib/platform/mac/macglobals.cpp)
    list(APPEND VSTGUI_SOURCE ${VSTGUI_DIR}/lib/platform/mac/cgbitmap.cpp)
    list(APPEND VSTGUI_SOURCE ${VSTGUI_DIR}/lib/platform/mac/quartzgraphicspath.cpp)
    list(APPEND VSTGUI_SOURCE ${VSTGUI_DIR}/lib/platform/mac/macfileselector.mm)
    list(APPEND VSTGUI_SOURCE ${VSTGUI_DIR}/lib/platform/mac/macstring.mm)
    list(APPEND VSTGUI_SOURCE ${VSTGUI_DIR}/lib/platform/mac/mactimer.cpp)
    list(APPEND VSTGUI_SOURCE ${VSTGUI_DIR}/lib/platform/mac/cfontmac.mm)
    list(APPEND VSTGUI_SOURCE ${VSTGUI_DIR}/lib/platform/mac/caviewlayer.mm)
    list(APPEND VSTGUI_SOURCE ${VSTGUI_DIR}/lib/platform/mac/macclipboard.mm)
    list(APPEND VSTGUI_SOURCE ${VSTGUI_DIR}/lib/platform/mac/carbon/hiviewframe.cpp)
    list(APPEND VSTGUI_SOURCE ${VSTGUI_DIR}/lib/platform/mac/carbon/hiviewoptionmenu.cpp)
    list(APPEND VSTGUI_SOURCE ${VSTGUI_DIR}/lib/platform/mac/carbon/hiviewtextedit.cpp)
    list(APPEND VSTGUI_SOURCE ${VSTGUI_DIR}/lib/platform/mac/cocoa/autoreleasepool.mm)
    list(APPEND VSTGUI_SOURCE ${VSTGUI_DIR}/lib/platform/mac/cocoa/cocoahelpers.mm)
    list(APPEND VSTGUI_SOURCE ${VSTGUI_DIR}/lib/platform/mac/cocoa/cocoaopenglview.mm)
    list(APPEND VSTGUI_SOURCE ${VSTGUI_DIR}/lib/platform/mac/cocoa/cocoatextedit.mm)
    list(APPEND VSTGUI_SOURCE ${VSTGUI_DIR}/lib/platform/mac/cocoa/nsviewframe.mm)
    list(APPEND VSTGUI_SOURCE ${VSTGUI_DIR}/lib/platform/mac/cocoa/nsviewoptionmenu.mm)

    set_source_files_properties(
      ${VSTGUI_DIR}/lib/platform/mac/cocoa/nsviewframe.mm
      ${VSTGUI_DIR}/lib/platform/mac/carbon/hiviewoptionmenu.cpp
      ${VSTGUI_DIR}/plugin-bindings/aeffguieditor.cpp
      PROPERTIES COMPILE_FLAGS "-Wno-deprecated-declarations")

    set_source_files_properties(
      /lib/platform/mac/carbon/hiviewtextedit.cpp
      PROPERTIES COMPILE_FLAGS "-Wno-\\#warnings")

    find_library(CARBON Carbon)
    find_library(COCOA Cocoa)
    find_library(OPENGL OpenGL)
    find_library(ACCELERATE Accelerate)
    find_library(QUARTZ QuartzCore)
    target_link_libraries(
      ${VST_TARGET} ${CARBON} ${COCOA} ${OPENGL} ${ACCELERATE} ${QUARTZ}
    )
    set_source_files_properties(${VST_TARGET_IMAGES} PROPERTIES
      MACOSX_PACKAGE_LOCATION Resources
    )

  endif(WIN32)

  source_group("vstgui" FILES ${VSTGUI_SOURCE})

  target_sources(${VST_TARGET} PUBLIC ${VSTGUI_SOURCE} ${VST_TARGET_IMAGES})
  target_include_directories(${VST_TARGET} PUBLIC ${VSTGUI_DIR})

endfunction(add_vstgui)

#*******************************************************************************
# Add tests to the project to be run with ctest or make test
#
# @param VST_TARGET        The name of the target to generate
#*******************************************************************************
function(add_tests VST_TARGET)
  if(WIN32)
    if(MSVC)
      if (CMAKE_GENERATOR MATCHES ".*Win64$")
        add_test(
          NAME MrsWatson-${VST_TARGET}-64
          WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/..
          COMMAND bin\\win\\mrswatson64 -p $<SHELL_PATH:$<TARGET_FILE:${VST_TARGET}>> -i media\\input.wav -o out.wav
        )
      else()
        add_test(
          NAME MrsWatson-${VST_TARGET}-32
          WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/..
          COMMAND bin\\win\\mrswatson -p $<SHELL_PATH:$<TARGET_FILE:${VST_TARGET}>> -i media\\input.wav -o out.wav
        )
      endif()
    else()
      message(WARNING "Tests currently not supported for ${CMAKE_GENERATOR}")
    endif()
  elseif(APPLE)
    add_test(
      NAME MrsWatson-${VST_TARGET}-64
      WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/..
      COMMAND bin/osx/mrswatson64 -p $<TARGET_FILE_DIR:${VST_TARGET}>/../.. -i media/input.wav -o out.wav
    )

    add_test(
      NAME MrsWatson-${VST_TARGET}-32
      WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/..
      COMMAND bin/osx/mrswatson -p $<TARGET_FILE_DIR:${VST_TARGET}>/../.. -i media/input.wav -o out.wav
    )
  endif(WIN32)
endfunction(add_tests)


#*******************************************************************************
# Generates a VST cmake target
#
# @param VST_TARGET        The name of the target to generate
# @param VST_TARGET_IMAGES The images used in the targets GUI. If the target
#                          doesn't have a GUI then pass FALSE to disable.
#*******************************************************************************
function(build_vst VST_TARGET VST_TARGET_SOURCES VST_TARGET_IMAGES)

  set(COMMON_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../Common)

  add_library(${VST_TARGET} MODULE ${VST_TARGET_SOURCES})

  add_vstsdk("${VST_TARGET}")
  if (VST_TARGET_IMAGES)
    add_vstgui("${VST_TARGET}" "${VST_TARGET_IMAGES}")
  endif(VST_TARGET_IMAGES)

  if(WIN32)
    target_sources(${VST_TARGET} PUBLIC ${COMMON_DIR}/exports.def)
    add_definitions(-D_CRT_SECURE_NO_DEPRECATE=1)
  elseif(APPLE)
    configure_file(${COMMON_DIR}/bintray-osx.json.in ${CMAKE_CURRENT_SOURCE_DIR}/../bintray-osx.json)

    set(PKG_INFO ${COMMON_DIR}/PkgInfo)
    set_source_files_properties(${COMMON_DIR}/PkgInfo PROPERTIES
      MACOSX_PACKAGE_LOCATION .
    )
    target_sources(${VST_TARGET} PUBLIC ${PKG_INFO} )
    set_target_properties(${VST_TARGET} PROPERTIES
      BUNDLE true
      BUNDLE_EXTENSION vst
      MACOSX_BUNDLE_INFO_PLIST ${COMMON_DIR}/Info.plist.in
    )
    set_property(TARGET ${VST_TARGET} PROPERTY CXX_STANDARD 11)

    install(TARGETS ${VST_TARGET} DESTINATION ~/Library/Audio/Plug-Ins/VST)
  endif(WIN32)
endfunction(build_vst)

#*******************************************************************************
# Convenience function for generating VST cmake targets with guis
#
# @param VST_TARGET         The name of the target to generate
# @param VST_TARGET_SOURCES The source files for the target
# @param VST_TARGET_IMAGES  The images used in the targets GUI
#*******************************************************************************
function(build_vst_gui VST_TARGET VST_TARGET_SOURCES VST_TARGET_IMAGES)

  build_vst("${VST_TARGET}" "${VST_TARGET_SOURCES}" "${VST_TARGET_IMAGES}")
  add_tests("${VST_TARGET}")

endfunction(build_vst_gui)

#*******************************************************************************
# Convenience function for generating VST cmake targets without guis
#
# @param VST_TARGET         The name of the target to generate
# @param VST_TARGET_SOURCES The source files for the target
#*******************************************************************************
function(build_vst_nogui VST_TARGET VST_TARGET_SOURCES)

  build_vst("${VST_TARGET}" "${VST_TARGET_SOURCES}" FALSE)
  add_tests("${VST_TARGET}")

endfunction(build_vst_nogui)