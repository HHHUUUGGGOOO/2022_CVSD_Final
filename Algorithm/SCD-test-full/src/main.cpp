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
    Vvd LLRs;
    Vvi reliabilities;
    vector<int> N;
    vector<int> K;
    int pack_num; 

    // read necessary file
    //  - argv[1] : pattern in decimal, e.g. data/baseline/baseline_dec.txt
    //  - argv[2] : golden, e.g. data/baseline_golden.mem
    ReadLLR(LLRs, N, K, pack_num, argv[1]);
    ReadReliabilities(reliabilities, N); // read all, vector = <128, 256, 512>
    
    // initialize decoder object
    PolarDecoder decoder = PolarDecoder(N, K);
    // set LLR
    decoder.ReadLLRs(LLRs);
    // set reliability sequence
    decoder.SetReliabilities(reliabilities);
    // Execute Decoding
    decoder.Decode();

    cout << "Decoded Message is: " << endl;
    vector<bit> decodedMessage  = decoder.GetDecodedMessage();
    std::reverse(decodedMessage.begin(), decodedMessage.end());
    for (auto it : decodedMessage) {
        int x = (it) ? 1 : 0;
        cout << x;
    }
    cout << endl;
    return 0;
}