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
    @positions = positions
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

# Keymap translator for each layer
class Translator

  # constructor
  #
  # == Parameters:
  # positions::
  #   array of position
  # layer_n_cols::
  #   assumed number of columns in the keymap
  def initialize(positions, layer_n_cols)
    @n_rows = positions.length
    cols = positions.map { |pos| pos.size }
    @n_cols = cols.max { |col| col } || 0
    @position_map = {}
    positions.each do |pos|
      pos.each do |p|
        unless p.nil?
          r = p[0]
          c = p[1]
          i = r * layer_n_cols + c
          @position_map[i] = p
        end
      end
    end
  end

  # Make translated key map
  def translate(symbols)
    result = (0..@n_rows).map do
      Array.new(@n_cols, :KC_NO)
    end
    symbols.each_index do |i|
      pos = @position_map[i]
      unless pos.nil?
        r = pos[0]
        c = pos[1]
        result[r][c] = symbols[i]
      end
    end
    result.flatten
  end
end

#
# Implement the actual I/O expander below
#

class TCA9555 < IoExpander

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
    @positions = positions
  end

  # Initialize I/O expander device
  def init_pins(i2c)
    i2c.write(@address, [0x06, 0xFF])
    i2c.write(@address, [0x07, 0xFF])
  end

  # Read from I/O expander device
  def read_pins(i2c)
    result = []
    if @address & 0x80 == 0
      buffer = [0xFF, 0xFF]
      i2c.write(@address, [0x00])
      i2c.read(@address, buffer)
      buffer.each_index do |i|
        (0..8).each do |j|
          mask = 1 << j
          if buffer[i] & mask == 0
            result << i * 8 + j
          end
        end
      end
    end
    result
  end
end

class TCA9554 < IoExpander

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
    @positions = positions
  end

  # Initialize I/O expander device
  def init_pins(i2c)
    i2c.write(@address, [0x03, 0xFF])
  end

  # Read from I/O expander device
  def read_pins(i2c)
    result = []
    if @address & 0x80 == 0
      buffer = [0xFF]
      i2c.write(@address, [0x00])
      i2c.read(@address, buffer)
      (0..8).each do |j|
        mask = 1 << j
        if buffer[0] & mask == 0
          result << j
        end
      end
    end
    result
  end
end
