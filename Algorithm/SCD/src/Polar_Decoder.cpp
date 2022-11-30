#include "Polar_Decoder.h"
#include "Utilities.h"
#include <vector>
#include <algorithm>

using namespace std;

// Constructor
PolarDecoder::PolarDecoder(int n, int k) {
    N = n;
    K = k;
    DecodeMethod = "SCD";
}

// Set Reliabilities
void PolarDecoder::SetReliabilities(vector<int>& r) {

    // check reliabilities sequence length is equal to K
    if (r.size() != N) {
        cerr << "Reliabilities sequence length is not equal to K" << endl;
        throw;
    }
    Reliabilities = r;

    // Set frozen bit index list
    int threshold = N - K;
    for (int i = 0; i<Reliabilities.size(); i++) {
        if (Reliabilities[i] < threshold) {
            FrozenBits.push_back(i);
        }
    }

    // check frozen bit index list length is equal to N - K
    if (FrozenBits.size() != threshold) {
        cerr << "Frozen Bit sequence length is not equal to N - K" << endl;
        throw;
    }
}

// Read LLRs
void PolarDecoder::ReadLLRs(vector<double>& input_data) {
    // check input_data length is equal to N
    if (input_data.size() != N) {
        cerr << "input LLR data length is not equal to N" << endl;
        throw;
    }
    LLRs = input_data;
}

// Execute decoding
void PolarDecoder::Decode() {
    if (DecodeMethod == "SCD") {
        vector<bit> result = SC(LLRs, 0, N-1);
    }
}

// Get decoded message
vector<bit> PolarDecoder::GetDecodedMessage() {
    return DecodedMessage;
}

// Successive Cancellation Decoding Method
vector<bit> PolarDecoder::SC(vector<double> llr, int l, int r) {
    if (llr.size() == 2) {   // boundary case
        // return bit list
        vector<bit> result;

        double llr_u0 = f(llr[0], llr[1]);
        bit u0 = hard_decision(llr_u0);
        // assign final decoded bit list if l is not frozen bit
        if (!CheckIsFrozen(l)) {
            DecodedMessage.push_back(u0);
        }
        else {
            u0 = 0;
        }

        double llr_u1 = g(llr[0], llr[1], u0);
        bit u1 = hard_decision(llr_u1);
        // assign final decoded bit list if l is not frozen bit
        if (!CheckIsFrozen(r)) {
            DecodedMessage.push_back(u1);
        }
        else {
            u1 = 0;
        }

        // encode
        bit x1 = u0 != u1;
        bit x2 = u1;
        result.push_back(x1);
        result.push_back(x2);

        return result;
    }
    else {
        // input llr length in each level
        int llr_length = llr.size();
        int half_length = llr_length / 2;

        // decoded bits list using f()
        vector<bit> decodedFirstHalf;

        // decoded bits list using g()
        vector<bit> decodedSecondHalf;

        // return encoded bits list
        vector<bit> encodedBitList;

        // decoded llr list using f()
        vector<double> decoded_f;

        // decoded llr list using g()
        vector<double> decoded_g;

        // decode using f()
        for (int i = 0; i < half_length; i++) {
            double decoded_llr = f(llr[i], llr[i+half_length]);
            decoded_f.push_back(decoded_llr);
        }
        int r_n = l + (r - l) / 2;
        decodedFirstHalf = SC(decoded_f, l, r_n);

        // decode using g()
        for (int i = 0; i < half_length; i++) {
            double decoded_llr = g(llr[i], llr[i+half_length], decodedFirstHalf[i]);
            decoded_g.push_back(decoded_llr);
        }
        int l_n = r_n + 1;
        decodedSecondHalf = SC(decoded_g, l_n, r);

        // Encode current level bit list and return to upper level
        for (int i=0; i<decodedFirstHalf.size(); i++) {
            bit d = decodedFirstHalf[i] != decodedSecondHalf[i];
            encodedBitList.push_back(d);
        }
        encodedBitList.insert(encodedBitList.end(), decodedSecondHalf.begin(), decodedSecondHalf.end());

        return encodedBitList;
    }
}

// check if the decoded bit is set to frozen bit
bool PolarDecoder::CheckIsFrozen(int index) {
    auto it = std::find(FrozenBits.begin(), FrozenBits.end(), index);
    return it != FrozenBits.end();
}

