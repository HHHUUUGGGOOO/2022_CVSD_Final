import numpy as np
from encoder import Encoder
from transmit import SimpleBPSKModulationAWGN
from t import compute_mask

N = [128, 256, 512]
K = [range(12, 109), range(12, 141), range(12, 141)]
SNR_DB  = [7, 8]

def round(a): # doing symmetric saturated rounding s7.4
    if a > 127.9375:
        return 127.9375
    if a < -127.9375:
        return -127.9375
    if a >= 0:
        if a % (1/16) >= (1/32):
            return a - a % (1/16) + (1/16)
        else:
            return a - a % (1/16)
    if a < 0:
        if a % (1/16) > (1/32):
            return a - a % (1/16) + (1/16)
        else:
            return a - a % (1/16)

def round_array(array):
    for i in range(array.shape[0]):
        array[i] = round(array[i])
    return array

def generate_llr(N, k, snr_db):

    # snr_db = 7
    message = np.random.randint(0, 2, k)
    # message = np.array([1,1,0,1,1,0,0,1,1,1,0,1])
    # print(message)
    mask = compute_mask(N, k)
    # print(mask)
    encoder = Encoder(mask)

    encoded = encoder.encode(message)
    # print(encoded)
    channel = SimpleBPSKModulationAWGN(fec_rate = k / N)
    llr = channel.transmit(message=encoded, snr_db=snr_db, with_noise = True)
    # print(llr.shape)
    return (message, round_array(llr))

def twos_comp(val): # transform the number into two's complement mode of s7.4
    val = int(val * 16)
    if val >= 0:
        return (bin(val)[2:].zfill(12))
    return ("1" + bin(2**11 - abs(val))[2:].zfill(11))

# print(bin(12)[2:].zfill(12))
# print(str(bin(6)[2:].zfill(192)) + "\n")
# print(generate_llr(128, 12, 7)[1])
# print(twos_comp(-0))

file_idx = 0
packet_idx = 0
for n_idx, n in enumerate(N):
    for k in K[n_idx]:
        for snr_db in SNR_DB:
            message, llr = generate_llr(n, k, snr_db)
            if packet_idx == 0:
                with open("../00_TESTBED/PATTERN/full/full_" + str(file_idx) + "_golden.mem", "w") as f_gold:
                    with open("../00_TESTBED/PATTERN/full/full_" + str(file_idx) + ".mem", "w") as f_mem:
                        with open("../00_TESTBED/PATTERN/full/full_" + str(file_idx) + "_dec.txt", "w") as f_dec:
                            
                            # write dec file
                            if file_idx == 16:
                                f_dec.write("6\n")
                            else:
                                f_dec.write("44\n")
                            # write mem file
                            if file_idx == 16:
                                f_mem.write(str(bin(6)[2:].zfill(192)) + "\n")
                            else:
                                f_mem.write(str(bin(44)[2:].zfill(192)) + "\n")
                            

            with open("../00_TESTBED/PATTERN/full/full_" + str(file_idx) + "_golden.mem", "a") as f_gold:
                with open("../00_TESTBED/PATTERN/full/full_" + str(file_idx) + ".mem", "a") as f_mem:
                    with open("../00_TESTBED/PATTERN/full/full_" + str(file_idx) + "_dec.txt", "a") as f_dec:
                        # write dec file
                        f_dec.write(str(k) + " " + str(n) + "\n")
                        for i in range(32):
                            if i * 16 < n:
                                for j in range(16):
                                    f_dec.write(str(llr[i * 16 + 15 - j]) + " ")
                                f_dec.write("\n")
                            else:
                                f_dec.write("0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 \n")
                        # write mem file
                        f_mem.write("0"*174 + str(bin(k)[2:].zfill(8)) + str(bin(n)[2:].zfill(10)) + "\n")
                        for i in range(32):
                            if i * 16 < n:
                                for j in range(16):
                                    f_mem.write(str(twos_comp(llr[i * 16 + 15 - j])))
                                f_mem.write("\n")
                            else:
                                for j in range(16):
                                    f_mem.write(str(twos_comp(0)))
                                f_mem.write("\n")
                        # write gold file
                        ans = "0" * (140 - k)
                        for i in range(k):
                            ans += str(int(message[k - i - 1]))
                        f_gold.write(ans + "\n")
            packet_idx += 1
            if packet_idx >= 44:
                packet_idx = 0
                file_idx += 1




