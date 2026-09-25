#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>
#include <string>
#include <vector>

#include "flutter_window.h"
#include "utils.h"

namespace {
constexpr ULONG_PTR kDownloadLinkCopyData = 0x4D444C4B;

HWND FindRunningWindow() {
  return ::FindWindowW(L"FLUTTER_RUNNER_WIN32_WINDOW", L"Mediary");
}

bool ForwardToRunningWindow(const std::vector<std::string>& arguments) {
  // The first process may still be creating its window when Chrome launches a
  // second protocol URL. Wait for it instead of opening another Flutter engine.
  for (int attempt = 0; attempt < 150; ++attempt) {
    HWND existing = FindRunningWindow();
    if (existing != nullptr) {
      bool sent = true;
      for (const auto& argument : arguments) {
        const int count = ::MultiByteToWideChar(
            CP_UTF8, MB_ERR_INVALID_CHARS, argument.c_str(), -1,
            nullptr, 0);
        if (count <= 0 || count > 16384) return false;
        std::wstring wide(count, L'\0');
        if (::MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS,
                                  argument.c_str(), -1, wide.data(), count) == 0) {
          return false;
        }
        COPYDATASTRUCT data{ kDownloadLinkCopyData,
                             static_cast<DWORD>(count * sizeof(wchar_t)),
                             wide.data() };
        DWORD_PTR received = 0;
        if (!::SendMessageTimeoutW(existing, WM_COPYDATA, 0,
                                   reinterpret_cast<LPARAM>(&data),
                                   SMTO_ABORTIFHUNG | SMTO_BLOCK, 2000,
                                   &received) || received != TRUE) {
          sent = false;
          break;
        }
      }
      if (sent) {
        ::ShowWindow(existing, ::IsIconic(existing) ? SW_RESTORE : SW_SHOW);
        ::SetForegroundWindow(existing);
        return true;
      }
    }
    ::Sleep(100);
  }
  return false;
}

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

  const auto command_line_arguments = GetCommandLineArguments();
  HANDLE instance_mutex = ::CreateMutexW(
      nullptr, FALSE, L"Local\\StreamMediaryDesktopSingleInstance");
  if (instance_mutex != nullptr && ::GetLastError() == ERROR_ALREADY_EXISTS) {
    const bool forwarded = ForwardToRunningWindow(command_line_arguments);
    ::CloseHandle(instance_mutex);
    ::CoUninitialize();
    return forwarded ? EXIT_SUCCESS : EXIT_FAILURE;
  }

  flutter::DartProject project(L"data");
  project.set_dart_entrypoint_arguments(command_line_arguments);

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"Mediary", origin, size)) {
    if (instance_mutex != nullptr) ::CloseHandle(instance_mutex);
    ::CoUninitialize();
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  if (instance_mutex != nullptr) ::CloseHandle(instance_mutex);
  return EXIT_SUCCESS;
}
