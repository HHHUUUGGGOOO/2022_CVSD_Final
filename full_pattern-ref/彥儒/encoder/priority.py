import csv
import numpy as np

n = 1024 # modify n here

N_map = {1024 : 0, 512 : 1, 256 : 2, 128 : 3, 64 : 4}
def compute_priority(N):
    topk = []
    # print(topk)
    with open('Polar_sequence.csv', newline='') as csvfile:
        rows = csv.reader(csvfile)
        for i, row in enumerate(rows):
            if i > 0 and i <= N:
                # print(i - 1,int(row[N_map[N]]))
                topk.append((i - 1,int(row[N_map[N]])))
    topk= sorted(topk, key=lambda x: x[1])
    x = np.zeros(N)
    # print(topk)
    for i, elem in enumerate(topk):
        x[elem[0]] = i
    # print(x)
    return x
with open("priority.txt","w") as f:
    p = compute_priority(n)
    for i, e in enumerate(p):
    
        f.write("priority_" + str(n) + "[" + str(i) + "]" + " = " + str(int(e))+";\n")