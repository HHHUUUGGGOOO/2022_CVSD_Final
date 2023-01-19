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
void ReadLLR(Vvd& LLRss, vector<int>& Ns, vector<int>& Ks, int& pack_num, char* fileName) {
    fstream fin;
    fin.open(fileName, ios::in);
    if (!fin) {
        cerr << endl;
        cerr << fileName << " can not be opened! " << endl;
        throw;
    }

    stringstream ss;

    // global 
    int row; 
    bool next = false; 
    vector<double> one_pat_llrs; 

    // packet number 
    fin >> pack_num;  

    while (!fin.eof()) {
        // read N, K 
        int K_tmp, N_tmp; 
        fin >> K_tmp >> N_tmp; 
        Ks.push_back(K_tmp); 
        Ns.push_back(N_tmp); 

        // read LLR 
        int it = 0;
        vector<double> LLR_row;
        next = false; 
        while (!next) {
            string s;
            double llr;
            fin >> s;
            ss << s;
            ss >> llr;
            // common step 
            ss.str("");
            ss.clear();
            it++;
            // skip empty row 
            if (((N_tmp == 128) && (row >= 8)) || ((N_tmp == 256) && (row >= 16)) || ((N_tmp == 512) && (row >= 32))) {
                if (it == 16) { 
                    it = 0; 
                    ++row; 
                }
            }
            else {
                LLR_row.push_back(llr);
                if (it == 16) {
                    std::reverse(LLR_row.begin(), LLR_row.end());
                    one_pat_llrs.insert(LLRs.end(), LLR_row.begin(), LLR_row.end());
                    LLR_row.clear();
                    it = 0;
                    ++row; 
                }
            }
            // done 
            if (row == 32) { 
                LLRss.push_back(one_pat_llrs); 
                next = true; 
                row = 0; 
            }
        }
    }
    
    return;
}

// Read corresponding reliability sequence
void ReadReliabilities(Vvi& reliabilitiess) {
    vector<string> files = ["./data/reliability_128.txt", "./data/reliability_256.txt", "./data/reliability_512.txt"]; 
    vector<int> one_pat_reliability; 
    for (int i = 0 ; i < 3 ; ++i) {
        fstream fin;
        stringstream ss_convert;
        stringstream ss;
        ss_convert << files[i];
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
            one_pat_reliability.push_back(index);
            ss.str("");
            ss.clear();
        }
        reliabilitiess.push_back(one_pat_reliability); 
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