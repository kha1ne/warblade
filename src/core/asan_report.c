#define WIN32_LEAN_AND_MEAN
#define NOMINMAX
#include <windows.h>
#include <sanitizer/asan_interface.h>
#include <string.h>
#include <wchar.h>
#include "asan_report.h"

enum { REPORT_PATH_CAPACITY = 32768 };
static wchar_t report_path[REPORT_PATH_CAPACITY];

static void SaveReport(const char *report)
{
    HANDLE file = CreateFileW(report_path, GENERIC_WRITE, FILE_SHARE_READ,
                              NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
    size_t remaining = strlen(report);
    if (file == INVALID_HANDLE_VALUE) return;
    while (remaining != 0) {
        DWORD chunk = remaining > MAXDWORD ? MAXDWORD : (DWORD)remaining;
        DWORD written = 0;
        if (!WriteFile(file, report, chunk, &written, NULL) || written == 0) break;
        report += written;
        remaining -= written;
    }
    CloseHandle(file);
}

bool ConfigureAsanReporting(void)
{
    DWORD length = GetModuleFileNameW(NULL, report_path, REPORT_PATH_CAPACITY);
    wchar_t *name;
    HANDLE file;
    if (length == 0 || length >= REPORT_PATH_CAPACITY) return false;
    name = wcsrchr(report_path, L'\\');
    if (!name) return false;
    ++name;
    if (wcscpy_s(name, REPORT_PATH_CAPACITY - (size_t)(name - report_path), L"asan.txt") != 0)
        return false;

    // Start each run with a fresh log; retain ASan's normal diagnostic output.
    file = CreateFileW(report_path, GENERIC_WRITE, FILE_SHARE_READ,
                       NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
    if (file == INVALID_HANDLE_VALUE) return false;
    CloseHandle(file);
    __asan_set_error_report_callback(SaveReport);
    return true;
}
