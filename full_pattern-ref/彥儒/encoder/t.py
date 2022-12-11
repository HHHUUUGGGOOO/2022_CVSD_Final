import csv
import numpy as np
N_map = {1024 : 0, 512 : 1, 256 : 2, 128 : 3, 64 : 4}
def compute_mask(N, K):
    topk = [(i, -1000) for i in range(K)]
    # print(topk)
    with open('Polar_sequence.csv', newline='') as csvfile:
        rows = csv.reader(csvfile)
        for i, row in enumerate(rows):
            if i > 0 and i <= N:
                # print(i - 1,int(row[N_map[N]]))
                if(int(row[N_map[N]]) > topk[0][1]):
                    topk[0] = (i - 1,int(row[N_map[N]]))
                topk= sorted(topk, key=lambda x: x[1])
                # print(topk)
    x = np.zeros(N)
    # print(topk)
    for i in topk:
        x[i[0]] = 1
    # print(x)
    return x