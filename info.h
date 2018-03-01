
#include <vector>

int blockTransactions(int blk);
uint8_t *transactionSender(int blk, int tr_num);
uint8_t *transactionReceiver(int blk, int tr_num);
uint8_t *transactionData(int blk, int tr_num);
// uint8_t *accountStorage(int blk, uint8_t *address, uint8_t *ptr);
uint8_t *accountStorage(int blk, std::vector<uint8_t> address, std::vector<uint8_t> ptr);
