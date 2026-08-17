
//using Q.15 format (int = int_f/(2^15))
#define OVERFLOW 32768
#define _USE_MATH_DEFINES
#include <cmath>
#include <iostream>
#include <cstdint>
#include <bitset>
int main() {
    //std::cout << M_PI << '\n';
    for(int i = 0; i <= 256; i++){
        uint16_t fixed16 = 0;
        double sin_val = std::sin((i/(256.0))*2*(M_PI));
        sin_val *= 32768;    
        //std::cout << (sin_val) << '\n';
        fixed16 = (std::round(sin_val) == OVERFLOW)  ? 32767 :  std::round(sin_val);
        //print out al the bits
        std::cout << std::bitset<16>(fixed16) << '\n';
        }
        return 0;

    }
