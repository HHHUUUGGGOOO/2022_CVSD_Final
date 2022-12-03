#ifndef _POLAR_DECODER_H_
#define _POLAR_DECODER_H_
#include <iostream>
#include <vector>
#include <map>

using namespace std;
typedef bool bit;

class PolarDecoder {
    private:
        int N; // channel length  
        int K; // Transmitted bit length 
        vector<int> Reliabilities; // reliability sequence
        vector<int> FrozenBits; // frozen bit index list
        vector<double> LLRs; // Log-likelihood ratio (LLR) list which is decoder input
        vector<bit> DecodedMessage; // decoded binary message output list
        string DecodeMethod; // decode method
        vector<bit> SC(vector<double> llr, int l, int r); // Successive Cancellation Decoding Method
        bool CheckIsFrozen(int index); // check if the decoded bit is set to frozen bit
        /* SCL added */
        int max_L; // Max list capacity in each stage 
        int current_num_path; // Current number of path, need <= L                         
        vector<double> LLR_List; // store different paths' decoded LLR, need <= 2*L
        vector<bit> SCL(); // Successive Cancellation List Decoding Method
    public:
        PolarDecoder(int n, int k); // Constructor
        void SetReliabilities(vector<int>& r); // Set reliabilities
        void ReadLLRs(vector<double>& input_data); // read LLRs
        void Decode(); // Execute decoding
        vector<bit> GetDecodedMessage(); // Get decoded message
}; 


#endif