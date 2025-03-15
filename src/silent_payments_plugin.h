#include <stdarg.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>

typedef struct OutputData {
  const uint8_t *pubkey_bytes;
  uint64_t amount;
} OutputData;

typedef struct ReceiverData {
  const uint8_t *b_scan_bytes;
  const uint8_t *B_spend_bytes;
  bool is_testnet;
  const uint32_t *labels;
  uint64_t labels_len;
} ReceiverData;

typedef struct ParamData {
  const struct OutputData *const *outputs_data;
  uint64_t outputs_data_len;
  const uint8_t *tweak_bytes;
  const struct ReceiverData *receiver_data;
} ParamData;

int8_t *api_scan_outputs(const struct ParamData *data);

void free_pointer(char *ptr);
