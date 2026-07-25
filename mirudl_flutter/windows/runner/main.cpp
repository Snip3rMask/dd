#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include "win32_window.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *cmd, _In_ int show) {
  FlutterDartProject project(L"data");
  FlutterViewController controller(project);
  Win32Window window;
  window.Create(L"dd", &controller);
  return window.Run();
}
