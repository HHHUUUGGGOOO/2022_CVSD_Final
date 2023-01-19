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
        // single 
        int N;  // channel length  
        int K;  // Transmitted bit length
        vector<int> Reliabilities;  // reliability sequence
        vector<int> FrozenBits;     // frozen bit index list
        vector<double> LLRs;        // Log-likelihood ratio (LLR) list which is decoder input
        vector<bit> DecodedMessage; // decoded binary message output list
        // overall
        vector<int> Ns;  // channel length  
        vector<int> Ks;  // Transmitted bit length
        Vvi Reliabilitiess;  // reliability sequence
        Vvi FrozenBitss;     // frozen bit index list
        Vvd LLRss;        // Log-likelihood ratio (LLR) list which is decoder input
        Vvb DecodedMessages; // decoded binary message output list
        // common
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