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
