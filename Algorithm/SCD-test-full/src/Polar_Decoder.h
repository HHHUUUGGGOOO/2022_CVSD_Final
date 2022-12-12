#ifndef _POLAR_DECODER_H_
#define _POLAR_DECODER_H_
#include <iostream>
#include <vector>

using namespace std;
typedef bool bit;
typedef vector<vector<int>> Vvi; 
typedef vector<vector<double>> Vvd;
typedef vector<vector<bit>> Vvb;

class PolarDecoder {
    private:
        int pack_num; 
        vector<int> N;  // channel length  
        vector<int> K;  // Transmitted bit length
        Vvi Reliabilities;  // reliability sequence
        Vvi FrozenBits;     // frozen bit index list
        Vvd LLRs;        // Log-likelihood ratio (LLR) list which is decoder input
        Vvb DecodedMessage; // decoded binary message output list
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