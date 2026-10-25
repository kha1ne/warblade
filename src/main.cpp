#include <iostream>
#include <SDL3/SDL_main.h>

#ifdef WARBLADE_ENABLE_ASAN
bool configure_asan_reporting();
#endif

int main(int, char*[])
{
#ifdef WARBLADE_ENABLE_ASAN
    if (!configure_asan_reporting()) {
        std::cerr << "Could not initialize asan.txt beside the executable.\n";
    }
#endif
    std::cout << "Hello, Warblade!\n";
    return 0;
}
