# I/O expander for modulo
class IoExpander

  attr_reader :positions
  attr_reader :address

  # constructor
  #
  # == Parameters:
  # address::
  #   Address of I/O expander device
  # positions::
  #   Positions assigned pins.
  #   ex) [[3, 0], [3, 1], [3, 2], [3, 3], [3, 4], [3, 5], nil, nil ]
  #
  def initialize(address, positions)
    @address = address
    @positions = positions.map do |a|
      if a.is_a?(Array)
        [a[0].to_i, a[1].to_i]
      else
        nil
      end
    end
  end

  # Initialize I/O expander device
  # _abstract method_
  def init_pins(i2c)
  end

  # Read from I/O expander device
  # _abstract method_
  def read_pins(i2c)
    []
  end
end


#
# Implement the actual I/O expander below
#

class TCA9554 < IoExpander

  def initialize(address, positions)
    super(address + 0x20, positions)
  end

  def init_pins(i2c)
    i2c.i2c_write(@address, [bytes([0x03, 0xFF]])
  end

  def read_pins(i2c)
    buffer = [0xFF]
    i2c.i2c_write(@address, [bytes([0x00]])
    i2c.i2c_write(@address, buffer)
    0..8.each do |j|
      mask = 1 << j
      if buffer[0] & mask == 0
        result << j
      end
    end
    result
  end
end

class TCA9555 < IoExpander

  def initialize(address, positions)
    super(address + 0x20, positions)
  end

  def init_pins(i2c)
    i2c.i2c_write(@address, [bytes([0x06, 0xFF]])
    i2c.i2c_write(@address, [bytes([0x07, 0xFF]])
  end

  def read_pins(i2c)
    buffer = [0xFF, 0xFF]
    i2c.i2c_write(@address, [bytes([0x00]])
    i2c.i2c_write(@address, buffer)
    buffer.each_index do |i|
      0..8.each do |j|
        mask = 1 << j
        if buffer[i] & mask == 0
          result << i * 8 + j
        end
      end
    end
    result
  end
end
