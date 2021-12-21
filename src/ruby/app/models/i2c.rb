class I2C

  def initialize(sda, scl, i2c_id, baud = 400 * 1000, slave = 0xFF)
    i2c_init(sda, scl, i2c_id, baud, slave)
  end

  def deinit()
    i2c_deinit()
  end

  def write(address, data, no_stop = true, timeout = 50 * 1000)
    i2c_write(address, data, no_stop, timeout)
  end

  def read(address, data, no_stop = true, timeout = 50 * 1000)
    i2c_read(address, data, no_stop, timeout)
  end
end
