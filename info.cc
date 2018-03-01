#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <vector>
    
extern void readBlockTransactions(int f_num);
extern void readTransactionSender(int f_num);
extern void readTransactionReceiver(int f_num);
extern void readTransactionData(int f_num);
extern void readAccountStorage(int f_num);

extern int getInternalFile(int fd);
extern void internalSync(int fd);
extern void internalSync2(int fd);
extern void internalStep();

int num(char c) {
    switch (c) {
        case '0': return 0;
        case '1': return 1;
        case '2': return 2;
        case '3': return 3;
        case '4': return 4;
        case '5': return 5;
        case '6': return 6;
        case '7': return 7;
        case '8': return 8;
        case '9': return 9;
        case 'a': return 10;
        case 'b': return 11;
        case 'c': return 12;
        case 'd': return 13;
        case 'e': return 14;
        case 'f': return 15;
    }
    return 0;
}

uint8_t *fromHex(char *str) {
    uint8_t *res = (uint8_t*)malloc(32);
    for (int i = 0; i < 32; i++) {
        res[i] = num(str[i*2+0])*16 + num(str[i*2+1]);
    }
    return res;
}

uint8_t *toUint256(uint32_t v) {
    uint8_t *res = (uint8_t*)malloc(32);
    for (int i = 0; i < 32; i++) res[i] = 0;
    res[31] = v&0xff;
    res[30] = (v>>8)&0xff;
    res[29] = (v>>16)&0xff;
    res[28] = (v>>24)&0xff;
    return res;
}

int fromUint256(uint8_t *dta) {
    int res = 0;
    res = dta[28];
    res = res*256 + dta[29];
    res = res*256 + dta[30];
    res = res*256 + dta[31];
    return res;
}

int blockTransactions(int blk) {
    FILE *f = fopen("block_inst", "wb");
    fwrite(toUint256(blk), 32, 1, f);
    int num = getInternalFile(fileno(f));
    
    fclose(f);
    printf("Calling custom instruction for file %d\n", num);
    internalSync(num);
    internalStep();
    readBlockTransactions(num);
    internalSync2(num);
    
    f = fopen("block_inst", "rb");
    uint8_t *buf = (uint8_t*)malloc(32);
    fread(buf, 1, 32, f);
    return fromUint256(buf);
}

uint8_t *transactionSender(int blk, int tr_num) {
    FILE *f = fopen("block_inst", "wb");
    fwrite(toUint256(blk), 32, 1, f);
    fwrite(toUint256(tr_num), 32, 1, f);
    int num = getInternalFile(fileno(f));
    
    fclose(f);
    printf("Calling custom instruction for file %d\n", num);
    internalSync(num);
    internalStep();
    readTransactionSender(num);
    internalSync2(num);
    
    f = fopen("block_inst", "rb");
    uint8_t *buf = (uint8_t*)malloc(20);
    fread(buf, 1, 20, f);
    return buf;
}

uint8_t *transactionReceiver(int blk, int tr_num) {
    FILE *f = fopen("block_inst", "wb");
    fwrite(toUint256(blk), 32, 1, f);
    fwrite(toUint256(tr_num), 32, 1, f);
    int num = getInternalFile(fileno(f));
    
    fclose(f);
    printf("Calling custom instruction for file %d\n", num);
    internalSync(num);
    internalStep();
    readTransactionReceiver(num);
    internalSync2(num);
    
    f = fopen("block_inst", "rb");
    uint8_t *buf = (uint8_t*)malloc(20);
    fread(buf, 1, 20, f);
    return buf;
}

uint8_t *transactionData(int blk, int tr_num) {
    FILE *f = fopen("block_inst", "wb");
    fwrite(toUint256(blk), 32, 1, f);
    fwrite(toUint256(tr_num), 32, 1, f);
    int num = getInternalFile(fileno(f));

    fclose(f);
    printf("Calling custom instruction for file %d\n", num);
    internalSync(num);
    internalStep();
    readTransactionData(num);
    internalSync2(num);

    f = fopen("block_inst", "rb");
    uint8_t *buf = (uint8_t*)malloc(32);
    fread(buf, 1, 32, f);
    return buf;
}

uint8_t *accountStorage(int blk, std::vector<uint8_t> address, std::vector<uint8_t> ptr) {
    FILE *f = fopen("block_inst", "wb");
    fwrite(toUint256(blk), 32, 1, f);
    fwrite(address.data(), 32, 1, f);
    fwrite(ptr.data(), 32, 1, f);
    int num = getInternalFile(fileno(f));

    fclose(f);
    printf("Calling custom instruction for file %d\n", num);
    internalSync(num);
    internalStep();
    readAccountStorage(num);
    internalSync2(num);

    f = fopen("block_inst", "rb");
    uint8_t *buf = (uint8_t*)malloc(32);
    fread(buf, 1, 32, f);
    return buf;
}

