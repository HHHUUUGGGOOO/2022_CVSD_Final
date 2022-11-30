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
    vector<double> LLRs;
    vector<int> reliabilities;
    int N;
    int K;

    // read necessary file
    ReadLLR(LLRs, N, K, argv[1]);
    ReadReliabilities(reliabilities, N);
    
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