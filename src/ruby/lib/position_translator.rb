# Keymap translator for each layer
class PositionTranslator

  # constructor
  #
  # == Parameters:
  # expanders::
  #   array of I/O expanders
  # layer_n_cols::
  #   assumed number of columns in the keymap
  def initialize(expanders, layer_n_cols)
    @n_rows = expanders.length
    @n_cols = expanders.max { |exp| exp.positions.length }
    @index_map = {}
    expanders.each do |exp|
      exp.positions.each do |pos|
        r = pos[0]
        c = pos[1]
        i = r * layer_n_cols + c
        @index_map[i] = pos
      end
    end
  end

  # Make translated key map
  def translate(symbols)
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
