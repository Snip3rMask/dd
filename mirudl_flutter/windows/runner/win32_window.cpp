#include "win32_window.h"

Win32Window::Win32Window() : hwnd_(nullptr), controller_(nullptr) {}
Win32Window::~Win32Window() {}

bool Win32Window::Create(const std::wstring &title, FlutterViewController *controller) {
  controller_ = controller;
  WNDCLASS wc = {0};
  wc.lpfnWndProc = WndProc;
  wc.hInstance = GetModuleHandle(nullptr);
  wc.lpszClassName = L"FlutterWindow";
  RegisterClass(&wc);
  hwnd_ = CreateWindow(wc.lpszClassName, title.c_str(), WS_OVERLAPPEDWINDOW,
    CW_USEDEFAULT, CW_USEDEFAULT, 420, 720, nullptr, nullptr, wc.hInstance, this);
  return hwnd_ != nullptr;
}

int Win32Window::Run() {
  MSG msg;
  while (GetMessage(&msg, nullptr, 0, 0)) {
    TranslateMessage(&msg);
    DispatchMessage(&msg);
  }
  return msg.wParam;
}

LRESULT CALLBACK Win32Window::WndProc(HWND hwnd, UINT msg, WPARAM wp, LPARAM lp) {
  return DefWindowProc(hwnd, msg, wp, lp);
}
