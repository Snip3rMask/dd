cmake_minimum_required(VERSION 3.14)
project(dd LANGUAGES CXX)

set(BINARY_NAME "dd")
set(APPLICATION_ID "com.mirudl.flutter")

cmake_policy(SET CMP0063 NEW)

add_subdirectory("${FLUTTER_MANAGED_DIR}" flutter_managed)

set(RUNNER_SOURCES
  "runner/main.cpp"
  "runner/utils.cpp"
  "runner/win32_window.cpp"
)

add_executable(${BINARY_NAME} WIN32 ${RUNNER_SOURCES})
target_link_libraries(${BINARY_NAME} PRIVATE flutter_managed)
target_include_directories(${BINARY_NAME} PRIVATE "${FLUTTER_MANAGED_DIR}")

install(TARGETS ${BINARY_NAME} RUNTIME DESTINATION "${CMAKE_INSTALL_PREFIX}/bin")
