#define WIN32_LEAN_AND_MEAN
#define NOMINMAX
#include <windows.h>
#include <sanitizer/asan_interface.h>
#include <cstring>
#include <cwchar>

namespace {
constexpr DWORD path_capacity = 32768;
wchar_t report_path[path_capacity]{};

void save_report(const char* report)
{
    const HANDLE file = CreateFileW(report_path, GENERIC_WRITE, FILE_SHARE_READ,
                                    nullptr, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, nullptr);
    if (file == INVALID_HANDLE_VALUE) return;
    auto remaining = std::strlen(report);
    while (remaining != 0) {
        const DWORD chunk = remaining > MAXDWORD ? MAXDWORD : static_cast<DWORD>(remaining);
        DWORD written = 0;
        if (!WriteFile(file, report, chunk, &written, nullptr) || written == 0) break;
        report += written;
        remaining -= written;
    }
    CloseHandle(file);
}
}

bool configure_asan_reporting()
{
    const DWORD length = GetModuleFileNameW(nullptr, report_path, path_capacity);
    if (length == 0 || length >= path_capacity) return false;
    wchar_t* name = std::wcsrchr(report_path, L'\\');
    if (!name) return false;
    ++name;
    if (wcscpy_s(name, path_capacity - static_cast<size_t>(name - report_path), L"asan.txt") != 0) return false;

    // Start each run with a fresh log; the callback also keeps ASan's normal output.
    const HANDLE file = CreateFileW(report_path, GENERIC_WRITE, FILE_SHARE_READ,
                                    nullptr, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, nullptr);
    if (file == INVALID_HANDLE_VALUE) return false;
    CloseHandle(file);
    __asan_set_error_report_callback(save_report);
    return true;
}
