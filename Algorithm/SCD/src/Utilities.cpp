#include <string>
#include <iostream>
#include <fstream>
#include <sstream>
#include <vector>
#include <algorithm>
#include <cmath>
#include "Polar_Decoder.h"
#include "Utilities.h"

using namespace std;

// Read input LLR list
void ReadLLR(vector<double>& LLRs, int& N, int& K, char* fileName) {
    fstream fin;
    fin.open(fileName, ios::in);
    if (!fin) {
        cerr << endl;
        cerr << fileName << " can not be opened! " << endl;
        throw;
    }

    stringstream ss;
    fin >> K >> N;
    int it = 0;
    vector<double> LLR_row;
    while (!fin.eof()) {
        string s;
        double llr;
        fin >> s;
        ss << s;
        ss >> llr;
        LLR_row.push_back(llr);
        ss.str("");
        ss.clear();
        it++;
        if (it == 16) {
            std::reverse(LLR_row.begin(), LLR_row.end());
            LLRs.insert(LLRs.end(), LLR_row.begin(), LLR_row.end());
            LLR_row.clear();
            it = 0;
        }
    }
    return;
}

// Read corresponding reliability sequence
void ReadReliabilities(vector<int>& reliabilities, int N) {
    fstream fin;
    stringstream ss_convert;
    stringstream ss;
    ss_convert << "./data/reliability_" << N << ".txt";
    string fileString = ss_convert.str();
    const char* fileName = fileString.c_str();
    
    fin.open(fileName, ios::in);
    if (!fin) {
        cerr << endl;
        cerr << fileName << " can not be opened! " << endl;
        throw;
    }

    while(!fin.eof()) {
        string s;
        int index;
        fin >> s;
        ss << s;
        ss >> index;
        reliabilities.push_back(index);
        ss.str("");
        ss.clear();
    }
    return;
}

// sgn(x)
double sgn(double x) {
    if (x < 0) 
        return -1;
    else if (x > 0)
        return 1;
    else 
        return 0;
}

// SCD f(y1, y2) = sgn(y1)*sgn(y2)*min(abs(y1), abs(y2))
double f(double y1, double y2) {
    double y1_abs = abs(y1);
    double y2_abs = abs(y2);
    return sgn(y1) * sgn(y2) * min(y1_abs, y2_abs);
}

// SCD g(y1, y2, u1) = y1(1-2*u1) + y2
double g(double y1, double y2, bit u1) {
    int u = (u1 == true) ? 1 : 0;
    return y1 * (1 - 2 * u) + y2;
}

// hard decision if llr < 0, u = 1 ; llr >= 0, u = 0
bit hard_decision(double llr) {
    return (llr < 0) ? 1 : 0;
}