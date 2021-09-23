# Keymap rearranger for each layer
class Rearranger

  # constructor
  #
  # == Parameters:
  # expanders::
  #   array of I/O expanders
  # layer_n_cols::
  #   assumed number of columns in the keymap
  def initialize(expanders, layer_n_cols)
    @n_rows = expanders.length
    cols = expanders.map { |exp| exp.positions.size }
    @n_cols = cols.max { |col| col } || 0
    @index_map = {}
    expanders.each do |exp|
      exp.positions.each do |pos|
        unless pos.nil?
          r = pos[0]
          c = pos[1]
          i = r * layer_n_cols + c
          @index_map[i] = pos
        end
      end
    end
  end

  # Make arranged key map
  def arrange(symbols)
    result = (0..@n_rows).map do
      Array.new(@n_cols, :KC_NO)
    end
    symbols.each_index do |i|
      pos = @index_map[i]
      unless pos.nil?
        r = pos[0]
        c = pos[1]
        result[r][c] = symbols[i]
      end
    end
    result.flatten
  end
end
