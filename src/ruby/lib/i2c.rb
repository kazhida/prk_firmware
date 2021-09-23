class I2C
  def init(sda, scl, i2c_id, baud)
    i2c_init(sda, scl, i2c_id, baud)
  end

  def deinit()
    i2c_deinit()
  end

  def write(address, data, no_stop, timeout)
    i2c_write(address, data, no_stop, timeout)
  end

  def read(address, data, no_stop, timeout)
    i2c_read(address, data, no_stop, timeout)
  end
end
