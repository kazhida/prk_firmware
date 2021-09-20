/* mruby/c VM */
#include <mrubyc.h>

void c_i2c_init(mrb_vm *vm, mrb_value *v, int argc);
void c_i2c_deinit(mrb_vm *vm, mrb_value *v, int argc);
void c_i2c_write(mrb_vm *vm, mrb_value *v, int argc);
void c_i2c_read(mrb_vm *vm, mrb_value *v, int argc);

#define I2C_INIT() do { \
  mrbc_class *mrbc_class_I2C = mrbc_define_class(0, "I2C", mrbc_class_object);        \
  mrbc_define_method(0, mrbc_class_I2C, "i2c_init",     c_i2c_init);    \
  mrbc_define_method(0, mrbc_class_I2C, "i2c_deinit",   c_i2c_deinit);  \
  mrbc_define_method(0, mrbc_class_I2C, "i2c_write",    c_i2c_write);   \
  mrbc_define_method(0, mrbc_class_I2C, "i2c_read",     c_i2c_read);    \
} while (0)
