#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>
#include <string>

#include "flutter_window.h"
#include "utils.h"

namespace {
void RegisterDownloadProtocol() {
  wchar_t path[MAX_PATH];
  const DWORD path_length = ::GetModuleFileNameW(nullptr, path, MAX_PATH);
  if (path_length == 0 || path_length >= MAX_PATH) return;
  HKEY root = nullptr;
  if (::RegCreateKeyExW(HKEY_CURRENT_USER,
                        L"Software\\Classes\\stream-mediary", 0, nullptr, 0,
                        KEY_SET_VALUE | KEY_CREATE_SUB_KEY, nullptr, &root,
                        nullptr) != ERROR_SUCCESS) return;
  const wchar_t description[] = L"URL:Mediary Download Protocol";
  const wchar_t empty[] = L"";
  ::RegSetValueExW(root, nullptr, 0, REG_SZ,
                   reinterpret_cast<const BYTE*>(description), sizeof(description));
  ::RegSetValueExW(root, L"URL Protocol", 0, REG_SZ,
                   reinterpret_cast<const BYTE*>(empty), sizeof(empty));
  HKEY command = nullptr;
  if (::RegCreateKeyExW(root, L"shell\\open\\command", 0, nullptr, 0,
                        KEY_SET_VALUE, nullptr, &command,
                        nullptr) == ERROR_SUCCESS) {
    const std::wstring value = std::wstring(L"\"") + path + L"\" \"%1\"";
    ::RegSetValueExW(command, nullptr, 0, REG_SZ,
                     reinterpret_cast<const BYTE*>(value.c_str()),
                     static_cast<DWORD>((value.size() + 1) * sizeof(wchar_t)));
    ::RegCloseKey(command);
  }
  ::RegCloseKey(root);
}
}  // namespace

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);
  RegisterDownloadProtocol();

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"Mediary", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
