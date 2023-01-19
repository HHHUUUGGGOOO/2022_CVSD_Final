// ***************************************************************************************************
//  File       [main.cpp]
//  Author     [Wei-Sheng Hsieh]
//  Synopsis   [2022 CVSD Final Polar decoder Successive Cancellation Decoder (SCD) implementation]
// ***************************************************************************************************
#include <string>
#include <iostream>
#include <fstream>
#include <sstream>
#include <vector>
#include <algorithm>
#include "Utilities.h"
#include "Polar_Decoder.h"

using namespace std;

int main(int argc, char* argv[]) {
    Vvd LLRss;
    Vvi reliabilitiess;
    vector<int> Ns;
    vector<int> Ks;
    int pack_num; 

    // read necessary file
    //  - argv[1] : pattern in decimal, e.g. data/baseline/baseline_dec.txt
    //  - argv[2] : golden, e.g. data/baseline_golden.mem
    ReadLLR(LLRss, Ns, Ks, pack_num, argv[1]);
    ReadReliabilities(reliabilitiess); // read all, vector = <128, 256, 512>
    
    Vvb dec_mem; 
    for (int i = 0 ; i < pack_num ; ++i) {
        // initialize decoder object
        PolarDecoder decoder = PolarDecoder(Ns[i], Ks[i]);
        // set LLR
        decoder.ReadLLRs(LLRss[i]);
        // set reliability sequence
        if (N[i] == 128) { decoder.SetReliabilities(reliabilitiess[0]); }
        if (N[i] == 256) { decoder.SetReliabilities(reliabilitiess[1]); }
        if (N[i] == 512) { decoder.SetReliabilities(reliabilitiess[2]); }
        // Execute Decoding
        decoder.Decode();

        cout << "Decoded Message is: " << endl;
        vector<bit> decodedMessage  = decoder.GetDecodedMessage();
        std::reverse(decodedMessage.begin(), decodedMessage.end());
        // print 
        for (auto it : decodedMessage) {
            int x = (it) ? 1 : 0;
            cout << x;
        }
        cout << endl;
        // store 
        dec_mem.push_back(decodedMessage); 
    }

    // write out 
    std::ofstream ofs; 
    ofs.open(".data/SCD-model_result.txt"); 

    if (!ofs.is_open()) {
        cout << "Failed to open file. \n"; 
        return 1; 
    }

    for (int i = 0 ; i < dec_mem.size() ; ++i ) {
        string one_row = ""; 
        // zero-append 
        for (int j = 0 ; j < (140-dec_mem[i].size()) ; ++j) {
            one_row += "0"; 
        }
        // answer
        for (int j = 0 ; j < dec_mem[i].size() ; ++j) {
            one_row += str(dec_mem[i][j]); 
        }
        ofs << one_row << "\n";
    }

    // close 
    ofs.close()

    return 0;
}