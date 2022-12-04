# 2022_CVSD_Final
Polar Decoder 

# Useful Tutorial 
- (1) **[Polar code introduction and basic example](https://www.zhihu.com/question/31656512)** (very easy-to-know by Hugo)
- (2) **[SC decoder introduction and basic example (Successive Cancellation)](https://marshallcomm.cn/2017/03/13/polar-code-6-sc-decoder/)** (very easy-to-know after finishing the above tutorial) 
- (3) **[Polar code introduction in detail](https://marshallcomm.cn/2017/03/01/polar-code-1-summary/)** (Hugo 11/26)
- (4) **[信道分裂遞迴公式理解圖](https://blog.csdn.net/m0_52610504/article/details/117265594)** (Hugo 11/26)
- (5) **[信道合併, 信道分裂總結](https://www.cnblogs.com/Mr-Tiger/p/7496501.html)** (Hugo 11/26)
- (6) **[中山大學博士論文: SC Decoder 半平行化架構設計優化](http://140.117.121.23/ETD-db/ETD-search/getfile?URN=etd-0016117-154531&filename=etd-0016117-154531.pdf)**

# Paper Survey 
- (1) **(Preliminary)** [A Brief Introduction to Polar Codes (2017)](http://pfister.ee.duke.edu/courses/ecen655/polar.pdf)
- (2) **(Old, basic)** [Efficient Design and Decoding of Polar Codes (2012)](https://ieeexplore.ieee.org/stamp/stamp.jsp?arnumber=6279525)
- (3) **(Improved)** [Memory-Efficient Polar Decoders (2017)](https://ieeexplore.ieee.org/stamp/stamp.jsp?tp=&arnumber=8070938)
- (4) **(Improved)** [Polar Code Encoder and Decoder Implementation (2018)](https://ieeexplore.ieee.org/stamp/stamp.jsp?tp=&arnumber=8723895)
- (5) **(Improved, New, Clear, Preffered)** [Enhanced BP Decoding Schemes of Polar Codes (2021)](https://ietresearch.onlinelibrary.wiley.com/doi/epdf/10.1049/cmu2.12148) 

# Source Code Reference 
- **SCL Algorithm** 
    - [Python version](https://github.com/mohammad-rowshan/List-Decoder-for-Polar-Codes-and-PAC-Codes)
    - [C++ version](https://github.com/just1nGH/Polar-Code-CPP)
    - [Matlab version](https://github.com/YuYongRun/PolarCodes-Encoding-Decoding-Construction)

# Hugo : SCL-related 
- (1) **[(paper) LLR-based Successive Cancellation List Decoder for Polar Codes with Multi-bit Decision](https://arxiv.org/pdf/1603.07055)** (TA-provided, help for hardware implementation)
- (2) **[高吞吐量的併行化極化碼 CRC-SCL 譯碼器 (decoder) 的 FPGA 實現](https://www.opticsjournal.net/Articles/OJ53898d449a8aa760/FullText)** **(Use this)**
    - [Intro & Example for SCL (知乎)](https://marshallcomm.cn/2017/03/15/polar-code-7-scl-decoder/)
    - [IEEE paper, 用估計值再度簡化 f, g 函數的乘除過程 (大幅降低面積和計算時間)](https://ieeexplore.ieee.org/document/6327689) **(main)**
    - [基於 FPGA 的 SCL 解碼算法優化與設計](https://kknews.cc/zh-tw/news/pke3mpj.html) **(main)**
    - [CRC-SCL polar decoder](https://ieeexplore.ieee.org/stamp/stamp.jsp?arnumber=6297420) **(main)**
        - **CRC check 似乎都要套在整套流程, i.e. 他要 pre-processing before encoding, 所以先刻 SCL 就好, 再看什麼方法可以降低 error-rate**
- (3) **[(SCL Algorithm) List Decoding of Polar Codes](https://arxiv.org/abs/1206.0050)**
    - [Github code in C](https://github.com/tavildar/Polar)

