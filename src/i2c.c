#include "uart.h"

#include "hardware/i2c.h"
#include "hardware/gpio.h"

#define I2C_ID    (i2c_id == 0 ? i2c0 : i2c1)
#define BAUD_RATE (400 * 1000)
#define SDA_PIN 4  // GPIO4
#define SCL_PIN 5  // GPIO5

static int i2c_id = 0;

/*
 * i2c_init(sda = SDA_PIN, scl = SCL_PIN, baud = BAUD_RATE, i2c_id = 0, [slave_address])
 */
void
c_i2c_init(mrb_vm *vm, mrb_value *v, int argc)
{
  uint sda = argc > 1 ? GET_INT_ARG(1) : SDA_PIN;
  gpio_set_function(sda, GPIO_FUNC_I2C);

  uint scl = argc > 2 ? GET_INT_ARG(2) : SCL_PIN;
  gpio_set_function(scl, GPIO_FUNC_I2C);

  i2c_id = argc > 3 ? GET_INT_ARG(3) : 0;
  uint baud = argc > 4 ? GET_INT_ARG(4) : BAUD_RATE;

  i2c_init(I2C_ID, baud);

  gpio_set_pulls(sda, true, false);
  gpio_set_pulls(scl, true, false);

  if (argc > 5) {
    uint8_t address = GET_INT_ARG(5);
    if (address < 0x80) {
      i2c_set_slave_mode(I2C_ID, 1, address);
    }
  }
}

/*
 * i2c_deinit()
 */
void
c_i2c_deinit(mrb_vm *vm, mrb_value *v, int argc)
{
  i2c_deinit(I2C_ID);
}

void
c_i2c_write(mrb_vm *vm, mrb_value *v, int argc)
{
  uint8_t address = GET_INT_ARG(1);
  struct RArray *array = GET_ARY_ARG(2).array;
  bool no_stop = argc > 3 ? (GET_TT_ARG(3) == MRBC_TT_TRUE) : false;
  uint timeout = argc > 4 ? GET_INT_ARG(4) : 10;

  uint8_t data[8];    // todo: Is 8 bytes enough?
  size_t n = 8;
  if (n > array->n_stored) n = array->n_stored;
  for (int i = 0; i < n; i++) {
    data[i] = array->data[i].i;
  }

  int i2c_result = i2c_write_timeout_us(I2C_ID, address, data, n, no_stop, timeout);

  SET_INT_RETURN(i2c_result);
}

void
c_i2c_read(mrb_vm *vm, mrb_value *v, int argc)
{
  uint8_t address = GET_INT_ARG(1);
  struct RArray *array = GET_ARY_ARG(2).array;
  bool no_stop = argc > 3 ? (GET_TT_ARG(3) == MRBC_TT_TRUE) : false;
  uint timeout = argc > 4 ? GET_INT_ARG(4) : 10;

  uint8_t data[8];    // todo: Is 8 bytes enough?
  size_t n = 8;
  if (n > array->n_stored) n = array->n_stored;

  int i2c_result = i2c_read_timeout_us(I2C_ID, address, data, n, no_stop, timeout);

  for (int i = 0; i < n; i++) {
    array->data[i].i = data[i];
  }

  SET_INT_RETURN(i2c_result);
}
