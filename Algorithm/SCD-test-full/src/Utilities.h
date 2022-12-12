#ifndef _UTILITIES_H_
#define _UTILITIES_H_
#include "Polar_Decoder.h"
using namespace std;

// Read input LLR list
void ReadLLR(Vvd& LLRs, vector<int>& N, vector<int>& K, int& pack_num, char* fileName);

// Read corresponding reliability sequence
void ReadReliabilities(Vvi& reliabilities, vector<int> N);

// SCD f(y1, y2) = sgn(y1)*sgn(y2)*min(abs(y1), abs(y2))
double f(double y1, double y2);

// SCD g(y1, y2, u1) = y1(1-2*u1) + y2
double g(double y1, double y2, bit u1);

// sgn(x)
double sgn(double x);

// hard decision if llr < 0, u = 1 ; llr >= 0, u = 0
bit hard_decision(double llr);






#endif