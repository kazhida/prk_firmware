/* mruby/c VM */
#include <mrubyc.h>

#define IO_EXPANDER_INIT() do { \
  mrbc_class *mrbc_class_IO_EXPANDER = mrbc_define_class(0, "IoExpander", mrbc_class_object);   \
  mrbc_class *mrbc_class_TCA9555 = mrbc_define_class(0, "TCA9555", mrbc_class_IO_EXPANDER);     \
  mrbc_class *mrbc_class_TCA9554 = mrbc_define_class(0, "TCA9554", mrbc_class_IO_EXPANDER);     \
} while (0)
