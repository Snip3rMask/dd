cmake_minimum_required(VERSION 3.10)
project(runner LANGUAGES CXX)

set(BINARY_NAME "dd")
set(APPLICATION_ID "com.mirudl.flutter")

cmake_policy(SET CMP0063 NEW)

set(CMAKE_INSTALL_RPATH "$ORIGIN/lib")

add_subdirectory("${FLUTTER_MANAGED_DIR}" flutter_managed)

add_executable(${BINARY_NAME}
  "my_application.cc"
  "flutter/generated_plugin_registrant.cc"
)

target_link_libraries(${BINARY_NAME} PRIVATE flutter_managed)
target_include_directories(${BINARY_NAME} PRIVATE "${FLUTTER_MANAGED_DIR}")

install(TARGETS ${BINARY_NAME} RUNTIME DESTINATION "${CMAKE_INSTALL_PREFIX}/bin")
