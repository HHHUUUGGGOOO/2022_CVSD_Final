module reliability_ROM2Out(
    input   [1:0]   N,
    input   [8:0]   index,
    output  [8:0]   reliability1,
    output  [8:0]   reliability2
);

    wire    [6:0]   reliability_128[0:127];
    wire    [7:0]   reliability_256[0:255];
    wire    [8:0]   reliability_512[0:511];

    assign  reliability1 = (N[1] == 1) ? reliability_512[index] : (N[0] == 1) ? reliability_256[index[7:0]] : reliability_128[index[6:0]];
    assign  reliability2 = (N[1] == 1) ? reliability_512[index+1] : (N[0] == 1) ? reliability_256[index[7:0]+1] : reliability_128[index[6:0]+1];

    // ===========================================
    // 128 reliability ROM
    // ===========================================

    assign  reliability_128[0] = 0;
    assign  reliability_128[1] = 1;
    assign  reliability_128[2] = 2;
    assign  reliability_128[3] = 4;
    assign  reliability_128[4] = 8;
    assign  reliability_128[5] = 16;
    assign  reliability_128[6] = 32;
    assign  reliability_128[7] = 3;
    assign  reliability_128[8] = 5;
    assign  reliability_128[9] = 64;
    assign  reliability_128[10] = 9;
    assign  reliability_128[11] = 6;
    assign  reliability_128[12] = 17;
    assign  reliability_128[13] = 10;
    assign  reliability_128[14] = 18;
    assign  reliability_128[15] = 12;
    assign  reliability_128[16] = 33;
    assign  reliability_128[17] = 65;
    assign  reliability_128[18] = 20;
    assign  reliability_128[19] = 34;
    assign  reliability_128[20] = 24;
    assign  reliability_128[21] = 36;
    assign  reliability_128[22] = 7;
    assign  reliability_128[23] = 66;
    assign  reliability_128[24] = 11;
    assign  reliability_128[25] = 40;
    assign  reliability_128[26] = 68;
    assign  reliability_128[27] = 19;
    assign  reliability_128[28] = 13;
    assign  reliability_128[29] = 48;
    assign  reliability_128[30] = 14;
    assign  reliability_128[31] = 72;
    assign  reliability_128[32] = 21;
    assign  reliability_128[33] = 35;
    assign  reliability_128[34] = 26;
    assign  reliability_128[35] = 80;
    assign  reliability_128[36] = 37;
    assign  reliability_128[37] = 25;
    assign  reliability_128[38] = 22;
    assign  reliability_128[39] = 38;
    assign  reliability_128[40] = 96;
    assign  reliability_128[41] = 67;
    assign  reliability_128[42] = 41;
    assign  reliability_128[43] = 28;
    assign  reliability_128[44] = 69;
    assign  reliability_128[45] = 42;
    assign  reliability_128[46] = 49;
    assign  reliability_128[47] = 74;
    assign  reliability_128[48] = 70;
    assign  reliability_128[49] = 44;
    assign  reliability_128[50] = 81;
    assign  reliability_128[51] = 50;
    assign  reliability_128[52] = 73;
    assign  reliability_128[53] = 15;
    assign  reliability_128[54] = 52;
    assign  reliability_128[55] = 23;
    assign  reliability_128[56] = 76;
    assign  reliability_128[57] = 82;
    assign  reliability_128[58] = 56;
    assign  reliability_128[59] = 27;
    assign  reliability_128[60] = 97;
    assign  reliability_128[61] = 39;
    assign  reliability_128[62] = 84;
    assign  reliability_128[63] = 29;
    assign  reliability_128[64] = 43;
    assign  reliability_128[65] = 98;
    assign  reliability_128[66] = 88;
    assign  reliability_128[67] = 30;
    assign  reliability_128[68] = 71;
    assign  reliability_128[69] = 45;
    assign  reliability_128[70] = 100;
    assign  reliability_128[71] = 51;
    assign  reliability_128[72] = 46;
    assign  reliability_128[73] = 75;
    assign  reliability_128[74] = 104;
    assign  reliability_128[75] = 53;
    assign  reliability_128[76] = 77;
    assign  reliability_128[77] = 54;
    assign  reliability_128[78] = 83;
    assign  reliability_128[79] = 57;
    assign  reliability_128[80] = 112;
    assign  reliability_128[81] = 78;
    assign  reliability_128[82] = 85;
    assign  reliability_128[83] = 58;
    assign  reliability_128[84] = 99;
    assign  reliability_128[85] = 86;
    assign  reliability_128[86] = 60;
    assign  reliability_128[87] = 89;
    assign  reliability_128[88] = 101;
    assign  reliability_128[89] = 31;
    assign  reliability_128[90] = 90;
    assign  reliability_128[91] = 102;
    assign  reliability_128[92] = 105;
    assign  reliability_128[93] = 92;
    assign  reliability_128[94] = 47;
    assign  reliability_128[95] = 106;
    assign  reliability_128[96] = 55;
    assign  reliability_128[97] = 113;
    assign  reliability_128[98] = 79;
    assign  reliability_128[99] = 108;
    assign  reliability_128[100] = 59;
    assign  reliability_128[101] = 114;
    assign  reliability_128[102] = 87;
    assign  reliability_128[103] = 116;
    assign  reliability_128[104] = 61;
    assign  reliability_128[105] = 91;
    assign  reliability_128[106] = 120;
    assign  reliability_128[107] = 62;
    assign  reliability_128[108] = 103;
    assign  reliability_128[109] = 93;
    assign  reliability_128[110] = 107;
    assign  reliability_128[111] = 94;
    assign  reliability_128[112] = 109;
    assign  reliability_128[113] = 115;
    assign  reliability_128[114] = 110;
    assign  reliability_128[115] = 117;
    assign  reliability_128[116] = 118;
    assign  reliability_128[117] = 121;
    assign  reliability_128[118] = 122;
    assign  reliability_128[119] = 63;
    assign  reliability_128[120] = 124;
    assign  reliability_128[121] = 95;
    assign  reliability_128[122] = 111;
    assign  reliability_128[123] = 119;
    assign  reliability_128[124] = 123;
    assign  reliability_128[125] = 125;
    assign  reliability_128[126] = 126;
    assign  reliability_128[127] = 127;
    
    // ===========================================
    // 256 reliability ROM
    // ===========================================

    assign  reliability_256[0] = 0;
    assign  reliability_256[1] = 1;
    assign  reliability_256[2] = 2;
    assign  reliability_256[3] = 4;
    assign  reliability_256[4] = 8;
    assign  reliability_256[5] = 16;
    assign  reliability_256[6] = 32;
    assign  reliability_256[7] = 3;
    assign  reliability_256[8] = 5;
    assign  reliability_256[9] = 64;
    assign  reliability_256[10] = 9;
    assign  reliability_256[11] = 6;
    assign  reliability_256[12] = 17;
    assign  reliability_256[13] = 10;
    assign  reliability_256[14] = 18;
    assign  reliability_256[15] = 128;
    assign  reliability_256[16] = 12;
    assign  reliability_256[17] = 33;
    assign  reliability_256[18] = 65;
    assign  reliability_256[19] = 20;
    assign  reliability_256[20] = 34;
    assign  reliability_256[21] = 24;
    assign  reliability_256[22] = 36;
    assign  reliability_256[23] = 7;
    assign  reliability_256[24] = 129;
    assign  reliability_256[25] = 66;
    assign  reliability_256[26] = 11;
    assign  reliability_256[27] = 40;
    assign  reliability_256[28] = 68;
    assign  reliability_256[29] = 130;
    assign  reliability_256[30] = 19;
    assign  reliability_256[31] = 13;
    assign  reliability_256[32] = 48;
    assign  reliability_256[33] = 14;
    assign  reliability_256[34] = 72;
    assign  reliability_256[35] = 21;
    assign  reliability_256[36] = 132;
    assign  reliability_256[37] = 35;
    assign  reliability_256[38] = 26;
    assign  reliability_256[39] = 80;
    assign  reliability_256[40] = 37;
    assign  reliability_256[41] = 25;
    assign  reliability_256[42] = 22;
    assign  reliability_256[43] = 136;
    assign  reliability_256[44] = 38;
    assign  reliability_256[45] = 96;
    assign  reliability_256[46] = 67;
    assign  reliability_256[47] = 41;
    assign  reliability_256[48] = 144;
    assign  reliability_256[49] = 28;
    assign  reliability_256[50] = 69;
    assign  reliability_256[51] = 42;
    assign  reliability_256[52] = 49;
    assign  reliability_256[53] = 74;
    assign  reliability_256[54] = 160;
    assign  reliability_256[55] = 192;
    assign  reliability_256[56] = 70;
    assign  reliability_256[57] = 44;
    assign  reliability_256[58] = 131;
    assign  reliability_256[59] = 81;
    assign  reliability_256[60] = 50;
    assign  reliability_256[61] = 73;
    assign  reliability_256[62] = 15;
    assign  reliability_256[63] = 133;
    assign  reliability_256[64] = 52;
    assign  reliability_256[65] = 23;
    assign  reliability_256[66] = 134;
    assign  reliability_256[67] = 76;
    assign  reliability_256[68] = 137;
    assign  reliability_256[69] = 82;
    assign  reliability_256[70] = 56;
    assign  reliability_256[71] = 27;
    assign  reliability_256[72] = 97;
    assign  reliability_256[73] = 39;
    assign  reliability_256[74] = 84;
    assign  reliability_256[75] = 138;
    assign  reliability_256[76] = 145;
    assign  reliability_256[77] = 29;
    assign  reliability_256[78] = 43;
    assign  reliability_256[79] = 98;
    assign  reliability_256[80] = 88;
    assign  reliability_256[81] = 140;
    assign  reliability_256[82] = 30;
    assign  reliability_256[83] = 146;
    assign  reliability_256[84] = 71;
    assign  reliability_256[85] = 161;
    assign  reliability_256[86] = 45;
    assign  reliability_256[87] = 100;
    assign  reliability_256[88] = 51;
    assign  reliability_256[89] = 148;
    assign  reliability_256[90] = 46;
    assign  reliability_256[91] = 75;
    assign  reliability_256[92] = 104;
    assign  reliability_256[93] = 162;
    assign  reliability_256[94] = 53;
    assign  reliability_256[95] = 193;
    assign  reliability_256[96] = 152;
    assign  reliability_256[97] = 77;
    assign  reliability_256[98] = 164;
    assign  reliability_256[99] = 54;
    assign  reliability_256[100] = 83;
    assign  reliability_256[101] = 57;
    assign  reliability_256[102] = 112;
    assign  reliability_256[103] = 135;
    assign  reliability_256[104] = 78;
    assign  reliability_256[105] = 194;
    assign  reliability_256[106] = 85;
    assign  reliability_256[107] = 58;
    assign  reliability_256[108] = 168;
    assign  reliability_256[109] = 139;
    assign  reliability_256[110] = 99;
    assign  reliability_256[111] = 86;
    assign  reliability_256[112] = 60;
    assign  reliability_256[113] = 89;
    assign  reliability_256[114] = 196;
    assign  reliability_256[115] = 141;
    assign  reliability_256[116] = 101;
    assign  reliability_256[117] = 147;
    assign  reliability_256[118] = 176;
    assign  reliability_256[119] = 142;
    assign  reliability_256[120] = 31;
    assign  reliability_256[121] = 200;
    assign  reliability_256[122] = 90;
    assign  reliability_256[123] = 149;
    assign  reliability_256[124] = 102;
    assign  reliability_256[125] = 105;
    assign  reliability_256[126] = 163;
    assign  reliability_256[127] = 92;
    assign  reliability_256[128] = 47;
    assign  reliability_256[129] = 208;
    assign  reliability_256[130] = 150;
    assign  reliability_256[131] = 153;
    assign  reliability_256[132] = 165;
    assign  reliability_256[133] = 106;
    assign  reliability_256[134] = 55;
    assign  reliability_256[135] = 113;
    assign  reliability_256[136] = 154;
    assign  reliability_256[137] = 79;
    assign  reliability_256[138] = 108;
    assign  reliability_256[139] = 224;
    assign  reliability_256[140] = 166;
    assign  reliability_256[141] = 195;
    assign  reliability_256[142] = 59;
    assign  reliability_256[143] = 169;
    assign  reliability_256[144] = 114;
    assign  reliability_256[145] = 156;
    assign  reliability_256[146] = 87;
    assign  reliability_256[147] = 197;
    assign  reliability_256[148] = 116;
    assign  reliability_256[149] = 170;
    assign  reliability_256[150] = 61;
    assign  reliability_256[151] = 177;
    assign  reliability_256[152] = 91;
    assign  reliability_256[153] = 198;
    assign  reliability_256[154] = 172;
    assign  reliability_256[155] = 120;
    assign  reliability_256[156] = 201;
    assign  reliability_256[157] = 62;
    assign  reliability_256[158] = 143;
    assign  reliability_256[159] = 103;
    assign  reliability_256[160] = 178;
    assign  reliability_256[161] = 93;
    assign  reliability_256[162] = 202;
    assign  reliability_256[163] = 107;
    assign  reliability_256[164] = 180;
    assign  reliability_256[165] = 151;
    assign  reliability_256[166] = 209;
    assign  reliability_256[167] = 94;
    assign  reliability_256[168] = 204;
    assign  reliability_256[169] = 155;
    assign  reliability_256[170] = 210;
    assign  reliability_256[171] = 109;
    assign  reliability_256[172] = 184;
    assign  reliability_256[173] = 115;
    assign  reliability_256[174] = 167;
    assign  reliability_256[175] = 225;
    assign  reliability_256[176] = 157;
    assign  reliability_256[177] = 110;
    assign  reliability_256[178] = 117;
    assign  reliability_256[179] = 212;
    assign  reliability_256[180] = 171;
    assign  reliability_256[181] = 226;
    assign  reliability_256[182] = 216;
    assign  reliability_256[183] = 158;
    assign  reliability_256[184] = 118;
    assign  reliability_256[185] = 173;
    assign  reliability_256[186] = 121;
    assign  reliability_256[187] = 199;
    assign  reliability_256[188] = 179;
    assign  reliability_256[189] = 228;
    assign  reliability_256[190] = 174;
    assign  reliability_256[191] = 122;
    assign  reliability_256[192] = 203;
    assign  reliability_256[193] = 63;
    assign  reliability_256[194] = 181;
    assign  reliability_256[195] = 232;
    assign  reliability_256[196] = 124;
    assign  reliability_256[197] = 205;
    assign  reliability_256[198] = 182;
    assign  reliability_256[199] = 211;
    assign  reliability_256[200] = 185;
    assign  reliability_256[201] = 240;
    assign  reliability_256[202] = 206;
    assign  reliability_256[203] = 95;
    assign  reliability_256[204] = 213;
    assign  reliability_256[205] = 186;
    assign  reliability_256[206] = 227;
    assign  reliability_256[207] = 111;
    assign  reliability_256[208] = 214;
    assign  reliability_256[209] = 188;
    assign  reliability_256[210] = 217;
    assign  reliability_256[211] = 229;
    assign  reliability_256[212] = 159;
    assign  reliability_256[213] = 119;
    assign  reliability_256[214] = 218;
    assign  reliability_256[215] = 230;
    assign  reliability_256[216] = 233;
    assign  reliability_256[217] = 175;
    assign  reliability_256[218] = 123;
    assign  reliability_256[219] = 220;
    assign  reliability_256[220] = 183;
    assign  reliability_256[221] = 234;
    assign  reliability_256[222] = 125;
    assign  reliability_256[223] = 241;
    assign  reliability_256[224] = 207;
    assign  reliability_256[225] = 187;
    assign  reliability_256[226] = 236;
    assign  reliability_256[227] = 126;
    assign  reliability_256[228] = 242;
    assign  reliability_256[229] = 244;
    assign  reliability_256[230] = 189;
    assign  reliability_256[231] = 215;
    assign  reliability_256[232] = 219;
    assign  reliability_256[233] = 231;
    assign  reliability_256[234] = 248;
    assign  reliability_256[235] = 190;
    assign  reliability_256[236] = 221;
    assign  reliability_256[237] = 235;
    assign  reliability_256[238] = 222;
    assign  reliability_256[239] = 237;
    assign  reliability_256[240] = 243;
    assign  reliability_256[241] = 238;
    assign  reliability_256[242] = 245;
    assign  reliability_256[243] = 127;
    assign  reliability_256[244] = 191;
    assign  reliability_256[245] = 246;
    assign  reliability_256[246] = 249;
    assign  reliability_256[247] = 250;
    assign  reliability_256[248] = 252;
    assign  reliability_256[249] = 223;
    assign  reliability_256[250] = 239;
    assign  reliability_256[251] = 251;
    assign  reliability_256[252] = 247;
    assign  reliability_256[253] = 253;
    assign  reliability_256[254] = 254;
    assign  reliability_256[255] = 255;

    // ===========================================
    // 512 reliability ROM
    // ===========================================

    assign  reliability_512[0] = 0;
    assign  reliability_512[1] = 1;
    assign  reliability_512[2] = 2;
    assign  reliability_512[3] = 4;
    assign  reliability_512[4] = 8;
    assign  reliability_512[5] = 16;
    assign  reliability_512[6] = 32;
    assign  reliability_512[7] = 3;
    assign  reliability_512[8] = 5;
    assign  reliability_512[9] = 64;
    assign  reliability_512[10] = 9;
    assign  reliability_512[11] = 6;
    assign  reliability_512[12] = 17;
    assign  reliability_512[13] = 10;
    assign  reliability_512[14] = 18;
    assign  reliability_512[15] = 128;
    assign  reliability_512[16] = 12;
    assign  reliability_512[17] = 33;
    assign  reliability_512[18] = 65;
    assign  reliability_512[19] = 20;
    assign  reliability_512[20] = 256;
    assign  reliability_512[21] = 34;
    assign  reliability_512[22] = 24;
    assign  reliability_512[23] = 36;
    assign  reliability_512[24] = 7;
    assign  reliability_512[25] = 129;
    assign  reliability_512[26] = 66;
    assign  reliability_512[27] = 11;
    assign  reliability_512[28] = 40;
    assign  reliability_512[29] = 68;
    assign  reliability_512[30] = 130;
    assign  reliability_512[31] = 19;
    assign  reliability_512[32] = 13;
    assign  reliability_512[33] = 48;
    assign  reliability_512[34] = 14;
    assign  reliability_512[35] = 72;
    assign  reliability_512[36] = 257;
    assign  reliability_512[37] = 21;
    assign  reliability_512[38] = 132;
    assign  reliability_512[39] = 35;
    assign  reliability_512[40] = 258;
    assign  reliability_512[41] = 26;
    assign  reliability_512[42] = 80;
    assign  reliability_512[43] = 37;
    assign  reliability_512[44] = 25;
    assign  reliability_512[45] = 22;
    assign  reliability_512[46] = 136;
    assign  reliability_512[47] = 260;
    assign  reliability_512[48] = 264;
    assign  reliability_512[49] = 38;
    assign  reliability_512[50] = 96;
    assign  reliability_512[51] = 67;
    assign  reliability_512[52] = 41;
    assign  reliability_512[53] = 144;
    assign  reliability_512[54] = 28;
    assign  reliability_512[55] = 69;
    assign  reliability_512[56] = 42;
    assign  reliability_512[57] = 49;
    assign  reliability_512[58] = 74;
    assign  reliability_512[59] = 272;
    assign  reliability_512[60] = 160;
    assign  reliability_512[61] = 288;
    assign  reliability_512[62] = 192;
    assign  reliability_512[63] = 70;
    assign  reliability_512[64] = 44;
    assign  reliability_512[65] = 131;
    assign  reliability_512[66] = 81;
    assign  reliability_512[67] = 50;
    assign  reliability_512[68] = 73;
    assign  reliability_512[69] = 15;
    assign  reliability_512[70] = 320;
    assign  reliability_512[71] = 133;
    assign  reliability_512[72] = 52;
    assign  reliability_512[73] = 23;
    assign  reliability_512[74] = 134;
    assign  reliability_512[75] = 384;
    assign  reliability_512[76] = 76;
    assign  reliability_512[77] = 137;
    assign  reliability_512[78] = 82;
    assign  reliability_512[79] = 56;
    assign  reliability_512[80] = 27;
    assign  reliability_512[81] = 97;
    assign  reliability_512[82] = 39;
    assign  reliability_512[83] = 259;
    assign  reliability_512[84] = 84;
    assign  reliability_512[85] = 138;
    assign  reliability_512[86] = 145;
    assign  reliability_512[87] = 261;
    assign  reliability_512[88] = 29;
    assign  reliability_512[89] = 43;
    assign  reliability_512[90] = 98;
    assign  reliability_512[91] = 88;
    assign  reliability_512[92] = 140;
    assign  reliability_512[93] = 30;
    assign  reliability_512[94] = 146;
    assign  reliability_512[95] = 71;
    assign  reliability_512[96] = 262;
    assign  reliability_512[97] = 265;
    assign  reliability_512[98] = 161;
    assign  reliability_512[99] = 45;
    assign  reliability_512[100] = 100;
    assign  reliability_512[101] = 51;
    assign  reliability_512[102] = 148;
    assign  reliability_512[103] = 46;
    assign  reliability_512[104] = 75;
    assign  reliability_512[105] = 266;
    assign  reliability_512[106] = 273;
    assign  reliability_512[107] = 104;
    assign  reliability_512[108] = 162;
    assign  reliability_512[109] = 53;
    assign  reliability_512[110] = 193;
    assign  reliability_512[111] = 152;
    assign  reliability_512[112] = 77;
    assign  reliability_512[113] = 164;
    assign  reliability_512[114] = 268;
    assign  reliability_512[115] = 274;
    assign  reliability_512[116] = 54;
    assign  reliability_512[117] = 83;
    assign  reliability_512[118] = 57;
    assign  reliability_512[119] = 112;
    assign  reliability_512[120] = 135;
    assign  reliability_512[121] = 78;
    assign  reliability_512[122] = 289;
    assign  reliability_512[123] = 194;
    assign  reliability_512[124] = 85;
    assign  reliability_512[125] = 276;
    assign  reliability_512[126] = 58;
    assign  reliability_512[127] = 168;
    assign  reliability_512[128] = 139;
    assign  reliability_512[129] = 99;
    assign  reliability_512[130] = 86;
    assign  reliability_512[131] = 60;
    assign  reliability_512[132] = 280;
    assign  reliability_512[133] = 89;
    assign  reliability_512[134] = 290;
    assign  reliability_512[135] = 196;
    assign  reliability_512[136] = 141;
    assign  reliability_512[137] = 101;
    assign  reliability_512[138] = 147;
    assign  reliability_512[139] = 176;
    assign  reliability_512[140] = 142;
    assign  reliability_512[141] = 321;
    assign  reliability_512[142] = 31;
    assign  reliability_512[143] = 200;
    assign  reliability_512[144] = 90;
    assign  reliability_512[145] = 292;
    assign  reliability_512[146] = 322;
    assign  reliability_512[147] = 263;
    assign  reliability_512[148] = 149;
    assign  reliability_512[149] = 102;
    assign  reliability_512[150] = 105;
    assign  reliability_512[151] = 304;
    assign  reliability_512[152] = 296;
    assign  reliability_512[153] = 163;
    assign  reliability_512[154] = 92;
    assign  reliability_512[155] = 47;
    assign  reliability_512[156] = 267;
    assign  reliability_512[157] = 385;
    assign  reliability_512[158] = 324;
    assign  reliability_512[159] = 208;
    assign  reliability_512[160] = 386;
    assign  reliability_512[161] = 150;
    assign  reliability_512[162] = 153;
    assign  reliability_512[163] = 165;
    assign  reliability_512[164] = 106;
    assign  reliability_512[165] = 55;
    assign  reliability_512[166] = 328;
    assign  reliability_512[167] = 113;
    assign  reliability_512[168] = 154;
    assign  reliability_512[169] = 79;
    assign  reliability_512[170] = 269;
    assign  reliability_512[171] = 108;
    assign  reliability_512[172] = 224;
    assign  reliability_512[173] = 166;
    assign  reliability_512[174] = 195;
    assign  reliability_512[175] = 270;
    assign  reliability_512[176] = 275;
    assign  reliability_512[177] = 291;
    assign  reliability_512[178] = 59;
    assign  reliability_512[179] = 169;
    assign  reliability_512[180] = 114;
    assign  reliability_512[181] = 277;
    assign  reliability_512[182] = 156;
    assign  reliability_512[183] = 87;
    assign  reliability_512[184] = 197;
    assign  reliability_512[185] = 116;
    assign  reliability_512[186] = 170;
    assign  reliability_512[187] = 61;
    assign  reliability_512[188] = 281;
    assign  reliability_512[189] = 278;
    assign  reliability_512[190] = 177;
    assign  reliability_512[191] = 293;
    assign  reliability_512[192] = 388;
    assign  reliability_512[193] = 91;
    assign  reliability_512[194] = 198;
    assign  reliability_512[195] = 172;
    assign  reliability_512[196] = 120;
    assign  reliability_512[197] = 201;
    assign  reliability_512[198] = 336;
    assign  reliability_512[199] = 62;
    assign  reliability_512[200] = 282;
    assign  reliability_512[201] = 143;
    assign  reliability_512[202] = 103;
    assign  reliability_512[203] = 178;
    assign  reliability_512[204] = 294;
    assign  reliability_512[205] = 93;
    assign  reliability_512[206] = 202;
    assign  reliability_512[207] = 323;
    assign  reliability_512[208] = 392;
    assign  reliability_512[209] = 297;
    assign  reliability_512[210] = 107;
    assign  reliability_512[211] = 180;
    assign  reliability_512[212] = 151;
    assign  reliability_512[213] = 209;
    assign  reliability_512[214] = 284;
    assign  reliability_512[215] = 94;
    assign  reliability_512[216] = 204;
    assign  reliability_512[217] = 298;
    assign  reliability_512[218] = 400;
    assign  reliability_512[219] = 352;
    assign  reliability_512[220] = 325;
    assign  reliability_512[221] = 155;
    assign  reliability_512[222] = 210;
    assign  reliability_512[223] = 305;
    assign  reliability_512[224] = 300;
    assign  reliability_512[225] = 109;
    assign  reliability_512[226] = 184;
    assign  reliability_512[227] = 115;
    assign  reliability_512[228] = 167;
    assign  reliability_512[229] = 225;
    assign  reliability_512[230] = 326;
    assign  reliability_512[231] = 306;
    assign  reliability_512[232] = 157;
    assign  reliability_512[233] = 329;
    assign  reliability_512[234] = 110;
    assign  reliability_512[235] = 117;
    assign  reliability_512[236] = 212;
    assign  reliability_512[237] = 171;
    assign  reliability_512[238] = 330;
    assign  reliability_512[239] = 226;
    assign  reliability_512[240] = 387;
    assign  reliability_512[241] = 308;
    assign  reliability_512[242] = 216;
    assign  reliability_512[243] = 416;
    assign  reliability_512[244] = 271;
    assign  reliability_512[245] = 279;
    assign  reliability_512[246] = 158;
    assign  reliability_512[247] = 337;
    assign  reliability_512[248] = 118;
    assign  reliability_512[249] = 332;
    assign  reliability_512[250] = 389;
    assign  reliability_512[251] = 173;
    assign  reliability_512[252] = 121;
    assign  reliability_512[253] = 199;
    assign  reliability_512[254] = 179;
    assign  reliability_512[255] = 228;
    assign  reliability_512[256] = 338;
    assign  reliability_512[257] = 312;
    assign  reliability_512[258] = 390;
    assign  reliability_512[259] = 174;
    assign  reliability_512[260] = 393;
    assign  reliability_512[261] = 283;
    assign  reliability_512[262] = 122;
    assign  reliability_512[263] = 448;
    assign  reliability_512[264] = 353;
    assign  reliability_512[265] = 203;
    assign  reliability_512[266] = 63;
    assign  reliability_512[267] = 340;
    assign  reliability_512[268] = 394;
    assign  reliability_512[269] = 181;
    assign  reliability_512[270] = 295;
    assign  reliability_512[271] = 285;
    assign  reliability_512[272] = 232;
    assign  reliability_512[273] = 124;
    assign  reliability_512[274] = 205;
    assign  reliability_512[275] = 182;
    assign  reliability_512[276] = 286;
    assign  reliability_512[277] = 299;
    assign  reliability_512[278] = 354;
    assign  reliability_512[279] = 211;
    assign  reliability_512[280] = 401;
    assign  reliability_512[281] = 185;
    assign  reliability_512[282] = 396;
    assign  reliability_512[283] = 344;
    assign  reliability_512[284] = 240;
    assign  reliability_512[285] = 206;
    assign  reliability_512[286] = 95;
    assign  reliability_512[287] = 327;
    assign  reliability_512[288] = 402;
    assign  reliability_512[289] = 356;
    assign  reliability_512[290] = 307;
    assign  reliability_512[291] = 301;
    assign  reliability_512[292] = 417;
    assign  reliability_512[293] = 213;
    assign  reliability_512[294] = 186;
    assign  reliability_512[295] = 404;
    assign  reliability_512[296] = 227;
    assign  reliability_512[297] = 418;
    assign  reliability_512[298] = 302;
    assign  reliability_512[299] = 360;
    assign  reliability_512[300] = 111;
    assign  reliability_512[301] = 331;
    assign  reliability_512[302] = 214;
    assign  reliability_512[303] = 309;
    assign  reliability_512[304] = 188;
    assign  reliability_512[305] = 449;
    assign  reliability_512[306] = 217;
    assign  reliability_512[307] = 408;
    assign  reliability_512[308] = 229;
    assign  reliability_512[309] = 159;
    assign  reliability_512[310] = 420;
    assign  reliability_512[311] = 310;
    assign  reliability_512[312] = 333;
    assign  reliability_512[313] = 119;
    assign  reliability_512[314] = 339;
    assign  reliability_512[315] = 218;
    assign  reliability_512[316] = 368;
    assign  reliability_512[317] = 230;
    assign  reliability_512[318] = 391;
    assign  reliability_512[319] = 313;
    assign  reliability_512[320] = 450;
    assign  reliability_512[321] = 334;
    assign  reliability_512[322] = 233;
    assign  reliability_512[323] = 175;
    assign  reliability_512[324] = 123;
    assign  reliability_512[325] = 341;
    assign  reliability_512[326] = 220;
    assign  reliability_512[327] = 314;
    assign  reliability_512[328] = 424;
    assign  reliability_512[329] = 395;
    assign  reliability_512[330] = 355;
    assign  reliability_512[331] = 287;
    assign  reliability_512[332] = 183;
    assign  reliability_512[333] = 234;
    assign  reliability_512[334] = 125;
    assign  reliability_512[335] = 342;
    assign  reliability_512[336] = 316;
    assign  reliability_512[337] = 241;
    assign  reliability_512[338] = 345;
    assign  reliability_512[339] = 452;
    assign  reliability_512[340] = 397;
    assign  reliability_512[341] = 403;
    assign  reliability_512[342] = 207;
    assign  reliability_512[343] = 432;
    assign  reliability_512[344] = 357;
    assign  reliability_512[345] = 187;
    assign  reliability_512[346] = 236;
    assign  reliability_512[347] = 126;
    assign  reliability_512[348] = 242;
    assign  reliability_512[349] = 398;
    assign  reliability_512[350] = 346;
    assign  reliability_512[351] = 456;
    assign  reliability_512[352] = 358;
    assign  reliability_512[353] = 405;
    assign  reliability_512[354] = 303;
    assign  reliability_512[355] = 244;
    assign  reliability_512[356] = 189;
    assign  reliability_512[357] = 361;
    assign  reliability_512[358] = 215;
    assign  reliability_512[359] = 348;
    assign  reliability_512[360] = 419;
    assign  reliability_512[361] = 406;
    assign  reliability_512[362] = 464;
    assign  reliability_512[363] = 362;
    assign  reliability_512[364] = 409;
    assign  reliability_512[365] = 219;
    assign  reliability_512[366] = 311;
    assign  reliability_512[367] = 421;
    assign  reliability_512[368] = 410;
    assign  reliability_512[369] = 231;
    assign  reliability_512[370] = 248;
    assign  reliability_512[371] = 369;
    assign  reliability_512[372] = 190;
    assign  reliability_512[373] = 364;
    assign  reliability_512[374] = 335;
    assign  reliability_512[375] = 480;
    assign  reliability_512[376] = 315;
    assign  reliability_512[377] = 221;
    assign  reliability_512[378] = 370;
    assign  reliability_512[379] = 422;
    assign  reliability_512[380] = 425;
    assign  reliability_512[381] = 451;
    assign  reliability_512[382] = 235;
    assign  reliability_512[383] = 412;
    assign  reliability_512[384] = 343;
    assign  reliability_512[385] = 372;
    assign  reliability_512[386] = 317;
    assign  reliability_512[387] = 222;
    assign  reliability_512[388] = 426;
    assign  reliability_512[389] = 453;
    assign  reliability_512[390] = 237;
    assign  reliability_512[391] = 433;
    assign  reliability_512[392] = 347;
    assign  reliability_512[393] = 243;
    assign  reliability_512[394] = 454;
    assign  reliability_512[395] = 318;
    assign  reliability_512[396] = 376;
    assign  reliability_512[397] = 428;
    assign  reliability_512[398] = 238;
    assign  reliability_512[399] = 359;
    assign  reliability_512[400] = 457;
    assign  reliability_512[401] = 399;
    assign  reliability_512[402] = 434;
    assign  reliability_512[403] = 349;
    assign  reliability_512[404] = 245;
    assign  reliability_512[405] = 458;
    assign  reliability_512[406] = 363;
    assign  reliability_512[407] = 127;
    assign  reliability_512[408] = 191;
    assign  reliability_512[409] = 407;
    assign  reliability_512[410] = 436;
    assign  reliability_512[411] = 465;
    assign  reliability_512[412] = 246;
    assign  reliability_512[413] = 350;
    assign  reliability_512[414] = 460;
    assign  reliability_512[415] = 249;
    assign  reliability_512[416] = 411;
    assign  reliability_512[417] = 365;
    assign  reliability_512[418] = 440;
    assign  reliability_512[419] = 374;
    assign  reliability_512[420] = 423;
    assign  reliability_512[421] = 466;
    assign  reliability_512[422] = 250;
    assign  reliability_512[423] = 371;
    assign  reliability_512[424] = 481;
    assign  reliability_512[425] = 413;
    assign  reliability_512[426] = 366;
    assign  reliability_512[427] = 468;
    assign  reliability_512[428] = 429;
    assign  reliability_512[429] = 252;
    assign  reliability_512[430] = 373;
    assign  reliability_512[431] = 482;
    assign  reliability_512[432] = 427;
    assign  reliability_512[433] = 414;
    assign  reliability_512[434] = 223;
    assign  reliability_512[435] = 472;
    assign  reliability_512[436] = 455;
    assign  reliability_512[437] = 377;
    assign  reliability_512[438] = 435;
    assign  reliability_512[439] = 319;
    assign  reliability_512[440] = 484;
    assign  reliability_512[441] = 430;
    assign  reliability_512[442] = 488;
    assign  reliability_512[443] = 239;
    assign  reliability_512[444] = 378;
    assign  reliability_512[445] = 459;
    assign  reliability_512[446] = 437;
    assign  reliability_512[447] = 380;
    assign  reliability_512[448] = 461;
    assign  reliability_512[449] = 496;
    assign  reliability_512[450] = 351;
    assign  reliability_512[451] = 467;
    assign  reliability_512[452] = 438;
    assign  reliability_512[453] = 251;
    assign  reliability_512[454] = 462;
    assign  reliability_512[455] = 442;
    assign  reliability_512[456] = 441;
    assign  reliability_512[457] = 469;
    assign  reliability_512[458] = 247;
    assign  reliability_512[459] = 367;
    assign  reliability_512[460] = 253;
    assign  reliability_512[461] = 375;
    assign  reliability_512[462] = 444;
    assign  reliability_512[463] = 470;
    assign  reliability_512[464] = 483;
    assign  reliability_512[465] = 415;
    assign  reliability_512[466] = 485;
    assign  reliability_512[467] = 473;
    assign  reliability_512[468] = 474;
    assign  reliability_512[469] = 254;
    assign  reliability_512[470] = 379;
    assign  reliability_512[471] = 431;
    assign  reliability_512[472] = 489;
    assign  reliability_512[473] = 486;
    assign  reliability_512[474] = 476;
    assign  reliability_512[475] = 439;
    assign  reliability_512[476] = 490;
    assign  reliability_512[477] = 463;
    assign  reliability_512[478] = 381;
    assign  reliability_512[479] = 497;
    assign  reliability_512[480] = 492;
    assign  reliability_512[481] = 443;
    assign  reliability_512[482] = 382;
    assign  reliability_512[483] = 498;
    assign  reliability_512[484] = 445;
    assign  reliability_512[485] = 471;
    assign  reliability_512[486] = 500;
    assign  reliability_512[487] = 446;
    assign  reliability_512[488] = 475;
    assign  reliability_512[489] = 487;
    assign  reliability_512[490] = 504;
    assign  reliability_512[491] = 255;
    assign  reliability_512[492] = 477;
    assign  reliability_512[493] = 491;
    assign  reliability_512[494] = 478;
    assign  reliability_512[495] = 383;
    assign  reliability_512[496] = 493;
    assign  reliability_512[497] = 499;
    assign  reliability_512[498] = 502;
    assign  reliability_512[499] = 494;
    assign  reliability_512[500] = 501;
    assign  reliability_512[501] = 447;
    assign  reliability_512[502] = 505;
    assign  reliability_512[503] = 506;
    assign  reliability_512[504] = 479;
    assign  reliability_512[505] = 508;
    assign  reliability_512[506] = 495;
    assign  reliability_512[507] = 503;
    assign  reliability_512[508] = 507;
    assign  reliability_512[509] = 509;
    assign  reliability_512[510] = 510;
    assign  reliability_512[511] = 511;

endmodule