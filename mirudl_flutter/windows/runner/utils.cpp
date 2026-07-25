#include "utils.h"
#include <windows.h>

std::string GetExecutableDirectory() {
  char path[MAX_PATH];
  GetModuleFileNameA(nullptr, path, MAX_PATH);
  std::string str(path);
  return str.substr(0, str.find_last_of("\\"));
}
