#ifndef RUNNER_WIN32_WINDOW_H_
#define RUNNER_WIN32_WINDOW_H_
#include <windows.h>
#include <flutter/flutter_view_controller.h>

class Win32Window {
 public:
  Win32Window();
  ~Win32Window();
  bool Create(const std::wstring &title, FlutterViewController *controller);
  int Run();
 private:
  HWND hwnd_;
  FlutterViewController *controller_;
  static LRESULT CALLBACK WndProc(HWND, UINT, WPARAM, LPARAM);
};
#endif
