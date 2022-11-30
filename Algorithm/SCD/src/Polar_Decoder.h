#ifndef _POLAR_DECODER_H_
#define _POLAR_DECODER_H_
#include <iostream>
#include <vector>

using namespace std;
typedef bool bit;

class PolarDecoder {
    private:
        int N;  // channel length  
        int K;  // Transmitted bit length
        vector<int> Reliabilities;  // reliability sequence
        vector<int> FrozenBits;     // frozen bit index list
        vector<double> LLRs;        // Log-likelihood ratio (LLR) list which is decoder input
        vector<bit> DecodedMessage; // decoded binary message output list
        string DecodeMethod;    // decode method
        vector<bit> SC(vector<double> llr, int l, int r);    // Successive Cancellation Decoding Method
        bool CheckIsFrozen(int index);     // check if the decoded bit is set to frozen bit
    public:
        PolarDecoder(int n, int k);     // Constructor
        void SetReliabilities(vector<int>& r);   // Set reliabilities
        void ReadLLRs(vector<double>& input_data);  // read LLRs
        void Decode();  // Execute decoding
        vector<bit> GetDecodedMessage();    // Get decoded message
};


#endif