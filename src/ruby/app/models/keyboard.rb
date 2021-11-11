class Keyboard

  STANDARD_SPLIT = :standard_split
  RIGHT_SIDE_FLIPPED_SPLIT = :right_side_flipped_split

  def initialize
    puts "Initializing Keyboard ..."
    # mruby/c VM doesn't work with a CONSTANT to make another CONSTANT
    # steep doesn't allow dynamic assignment of CONSTANT
    @SHIFT_LETTER_THRESHOLD_A    = LETTER.index('A').to_i
    @SHIFT_LETTER_OFFSET_A       = @SHIFT_LETTER_THRESHOLD_A - KEYCODE.index(:KC_A).to_i
    @SHIFT_LETTER_THRESHOLD_UNDS = LETTER.index('_').to_i
    @SHIFT_LETTER_OFFSET_UNDS    = @SHIFT_LETTER_THRESHOLD_UNDS - KEYCODE_SFT[:KC_UNDS]
    @before_filters = Array.new
    @keymaps = Hash.new
    @mode_keys = Array.new
    @switches = Array.new
    @layer_names = Array.new
    @layer = :default
    $rgb = nil
    $encoders = Array.new
    @partner_encoders = Array.new
    @macro_keycodes = Array.new
    @buffer = Buffer.new("picoirb")
    @i2c = nil
    @io_expanders = []
  end

  attr_reader :layer

  # TODO: OLED, SDCard
  def append(feature)
    case feature.class
    when RGB
      # @type var feature: RGB
      $rgb = feature
    when RotaryEncoder
      # @type var feature: RotaryEncoder
      feature.init_pins
      $encoders << feature
    else
      # no-op
    end
  end

  def init_pins(rows, cols)
    @rows = rows
    @cols = cols
    @rows.each do |pin|
      gpio_init(pin)
      gpio_set_dir(pin, GPIO_OUT);
      gpio_put(pin, HI);
    end
    @cols.each do |pin|
      gpio_init(pin)
      gpio_set_dir(pin, GPIO_IN);
      gpio_pull_up(pin);
    end
  end

  # Initialize for modulo architecture
  def init_modulo(i2c, layer_n_cols, io_expanders)
    @i2c = i2c
    @io_expanders = io_expanders
    @io_expanders.each do |x|
      x.init_pins(i2c)
    end
    positions = io_expanders.map { |exp| exp.positions }
    # fake attributes
    @rows = (0..@io_expanders.length).map { |r| r + 1 }
    n_cols = positions.map { |p| p.length }
    @cols = (0..(n_cols.max || 0)).map { |c| 29 - c}
  end

  # Input
  #   name:    default, map: [ [ :KC_A, :KC_B, :KC_LCTL,   :MACRO_1 ],... ]
  # ↓
  # Result
  #   layer: { default:      [ [ -0x04, -0x05, 0b00000001, :MACRO_1 ],... ] }
  def add_layer(name, map)
    new_map = Array.new(@rows.size)
    row_index = 0
    col_index = 0
    map.each do |key|
      new_map[row_index] = Array.new(@cols.size) if col_index == 0
      new_map[row_index][col_index] = find_keycode_index(key)
      if col_index == @cols.size - 1
        col_index = 0
        row_index += 1
      else
        col_index += 1
      end
    end
    @keymaps[name] = new_map
    @layer_names << name
  end

  def find_keycode_index(key)
    key = KC_ALIASES[key] ? KC_ALIASES[key] : key
    keycode_index = KEYCODE.index(key)

    if keycode_index
      keycode_index * -1
    elsif KEYCODE_SFT[key]
      (KEYCODE_SFT[key] + 0x100) * -1
    elsif MOD_KEYCODE[key]
      MOD_KEYCODE[key]
    else
      key
    end
  end

  # param[0] :on_release
  # param[1] :on_hold
  # param[2] :release_threshold
  # param[3] :repush_threshold
  def define_mode_key(key_name, param)
    on_release = param[0]
    on_hold = param[1]
    release_threshold = param[2]
    repush_threshold = param[3]
    @keymaps.each do |layer, map|
      map.each_with_index do |row, row_index|
        row.each_with_index do |key_symbol, col_index|
          if key_name == key_symbol
            # @type var on_release_action: Integer | Array[Integer] | Proc | nil
            on_release_action = case on_release.class
            when Symbol
              # @type var on_release: Symbol
              key = KC_ALIASES[on_release] ? KC_ALIASES[on_release] : on_release
              keycode_index = KEYCODE.index(key)
              if keycode_index
                keycode_index * -1
              elsif KEYCODE_SFT[key]
                (KEYCODE_SFT[key] + 0x100) * -1
              end
            when Array
              # @type var on_release: Array[Symbol]
              # @type var ary: Array[Integer]
              ary = Array.new
              on_release.each do |sym|
                keycode_index = KEYCODE.index(sym)
                ary << if keycode_index
                  keycode_index * -1
                elsif KEYCODE_SFT[sym]
                  (KEYCODE_SFT[sym] + 0x100) * -1
                else # Should be a modifier
                  MOD_KEYCODE[sym]
                end
              end
              ary
            when Proc
              # @type var on_release: Proc
              on_release
            end
            on_hold_action = if on_hold.is_a?(Symbol)
              # @type var on_hold: Symbol
              MOD_KEYCODE[on_hold] ? MOD_KEYCODE[on_hold] : on_hold
            else
              # @type var on_hold: Proc
              on_hold
            end
            @mode_keys << ModeKey.new(layer, on_release_action, on_hold_action, release_threshold, repush_threshold, row_index, col_index)
          end
        end
      end
    end
  end

  # MOD_KEYCODE = {
  #        KC_LCTL: 0b00000001,
  #        KC_LSFT: 0b00000010,
  #        KC_LALT: 0b00000100,
  #        KC_LGUI: 0b00001000,
  #        KC_RCTL: 0b00010000,
  #        KC_RSFT: 0b00100000,
  #        KC_RALT: 0b01000000,
  #        KC_RGUI: 0b10000000
  # }
  def invert_sft
    if (@modifier & 0b00100010) > 0
       @modifier &= 0b11011101
    else
       @modifier |= 0b00000010
    end
  end

  def before_report(&block)
    @before_filters << block
  end

  def keys_include?(key)
    keycode = KEYCODE.index(key)
    !keycode.nil? && @keycodes.include?(keycode.chr)
  end

  def action_on_release(mode_key)
    case mode_key.class
    when Integer
      # @type var mode_key.rb: Integer
      if mode_key < -255
        @keycodes << ((mode_key + 0x100) * -1).chr
        @modifier |= 0b00000010
      else
        @keycodes << (mode_key * -1).chr
      end
    when Array
      0 # `steep check` will fail if you remove this line 🤔
      # @type var mode_key.rb: Array[Integer]
      mode_key.each do |key|
        if key < -255
          @keycodes << ((key + 0x100) * -1).chr
          @modifier |= 0b00000010
        elsif key < 0
          @keycodes << (key * -1).chr
        else # Should be a modifier
          @modifier |= key
        end
      end
    when Proc
      # @type var mode_key.rb: Proc
      mode_key.call
    end
  end

  def action_on_hold(mode_key)
    case mode_key.class
    when Integer
      # @type var mode_key: Integer
      @modifier |= mode_key
    when Symbol
      # @type var mode_key: Symbol
      @layer = mode_key
    when Proc
      # @type var mode_key.rb: Proc
      mode_key.call
    end
  end

  def send_key(symbol)
    keycode = KEYCODE.index(symbol)
    if keycode
      modifier = 0
      c = keycode.chr
    else
      keycode = KEYCODE_SFT[symbol]
      if keycode
        modifier = 0b00100000
        c = keycode.chr
      else
        return
      end
    end
    report_hid(modifier, "#{c}\000\000\000\000\000")
    sleep_ms 5
    report_hid(0, "\000\000\000\000\000\000")
  end

  # **************************************************************
  #  For those who are willing to contribute to PRK Firmware:
  #
  #   The author has intentionally made this method big and
  #   redundant for resilience against a change of spec.
  #   Please refrain from "refactoring" for a while.
  # **************************************************************
  def start!
    puts "Starting keyboard task ..."

    @keycodes = Array.new
    # To avoid unintentional report on startup
    # which happens only on Sparkfun Pro Micro RP2040
    default_sleep = 10
    while true
      now = board_millis
      @keycodes.clear

      @switches.clear
      @modifier = 0

      @io_expanders.each_with_index do |exp, r|
        # @type ivar @i2c: I2C
        sw = exp.read_pins(@i2c).map do |c|
          [r, c]
        end
        @switches.concat sw
      end
      # TODO: more features
      $rgb.fifo_push(true) if $rgb && !@switches.empty?

      desired_layer = @layer
      @mode_keys.each do |mode_key|
        next if mode_key.layer != @layer
        if @switches.include?(mode_key.switch)
          case mode_key.prev_state
          when :released
            mode_key.pushed_at = now
            mode_key.prev_state = :pushed
            on_hold = mode_key.on_hold
            if on_hold.is_a?(Symbol) &&
              @layer_names.index(desired_layer).to_i < @layer_names.index(on_hold).to_i
              desired_layer = on_hold
            end
          when :pushed
            if !mode_key.on_hold.is_a?(Symbol) && (now - mode_key.pushed_at > mode_key.release_threshold)
              action_on_hold(mode_key.on_hold)
            end
          when :pushed_then_released
            if now - mode_key.released_at <= mode_key.repush_threshold
              mode_key.prev_state = :pushed_then_released_then_pushed
            end
          when :pushed_then_released_then_pushed
            action_on_release(mode_key.on_release)
          else
            # no-op
          end
        else
          case mode_key.prev_state
          when :pushed
            if now - mode_key.pushed_at <= mode_key.release_threshold
              action_on_release(mode_key.on_release)
              mode_key.prev_state = :pushed_then_released
            else
              mode_key.prev_state = :released
            end
            mode_key.released_at = now
            @layer = @prev_layer || :default
            @prev_layer = nil
          when :pushed_then_released
            if now - mode_key.released_at > mode_key.release_threshold
              mode_key.prev_state = :released
            end
          when :pushed_then_released_then_pushed
            mode_key.prev_state = :released
          else
            # no-op
          end
        end
      end

      if @layer != desired_layer
        @prev_layer ||= @layer
        action_on_hold(desired_layer)
      end

      keymap = @keymaps[@locked_layer || @layer]
      @switches.each do |switch|
        keycode = keymap[switch[0]][switch[1]]
        next unless keycode.is_a?(Integer)
        if keycode < -255 # Key with SHIFT
          @keycodes << ((keycode + 0x100) * -1).chr
          @modifier |= 0b00100000
        elsif keycode < 0 # Normal keys
          @keycodes << (keycode * -1).chr
        else # Modifier keys
          @modifier |= keycode
        end
      end

      # Macro
      macro_keycode = @macro_keycodes.shift
      if macro_keycode
        if macro_keycode < 0
          @modifier |= 0b00100000
          @keycodes << (macro_keycode * -1).chr
        else
          @keycodes << macro_keycode.chr
        end
        default_sleep = 40 # To avoid accidental skip
      else
        default_sleep = 10
      end

      (6 - @keycodes.size).times do
        @keycodes << "\000"
      end

      @before_filters.each do |block|
        block.call
      end

      $encoders.each do |encoder|
        encoder.consume_rotation_anchor
      end

      if @ruby_mode
        code = @keycodes[0].ord
        c = nil
        if @ruby_mode_stop
          @ruby_mode_stop = false if code == 0
        elsif code > 0
          if @modifier & 0b00100010 > 1 # with SHIFT
            if code <= KEYCODE_SFT[:KC_RPRN].to_i
              c = LETTER[code + @SHIFT_LETTER_OFFSET_A]
            elsif code <= KEYCODE_SFT[:KC_QUES].to_i
              c = LETTER[code + @SHIFT_LETTER_OFFSET_UNDS]
            end
          elsif code < @SHIFT_LETTER_THRESHOLD_A
            c = LETTER[code]
          end
          @ruby_mode_stop = true
        end
        if c
          @buffer.put(c)
          @buffer.refresh_screen
        end
      end
      report_hid(@modifier, @keycodes.join)

      if @switches.empty? && @locked_layer.nil?
        @layer = :default
      elsif @locked_layer
        # @type ivar @locked_layer: Symbol
        @layer = @locked_layer
      end

      time = default_sleep - (board_millis - now)
      sleep_ms(time) if time > 0
    end

  end

  #
  # Actions can be used in keymap.rb
  #

  # Raises layer and keeps it
  def raise_layer
    current_index = @layer_names.index(@locked_layer || @layer)
    return if current_index.nil?
    if current_index < @layer_names.size - 1
      # @type var current_index: Integer
      @locked_layer = @layer_names[current_index + 1]
    else
      @locked_layer = @layer_names.first
    end
  end

  # Lowers layer and keeps it
  def lower_layer
    current_index = @layer_names.index(@locked_layer || @layer)
    return if current_index.nil?
    if current_index == 0
      @locked_layer = @layer_names.last
    else
      # @type var current_index: Integer
      @locked_layer = @layer_names[current_index - 1]
    end
  end

  # Switch to specified layer
  def lock_layer(layer)
    @locked_layer = layer
  end

  def unlock_layer
    @locked_layer = nil
  end

  def macro(text, opts = [:ENTER])
    print text.to_s
    prev_c = ""
    text.to_s.each_char do |c|
      index = LETTER.index(c)
      next unless index
      @macro_keycodes << 0
      if index >= @SHIFT_LETTER_THRESHOLD_UNDS
        @macro_keycodes << (index - @SHIFT_LETTER_OFFSET_UNDS) * -1
      elsif index >= @SHIFT_LETTER_THRESHOLD_A
        @macro_keycodes << (index - @SHIFT_LETTER_OFFSET_A) * -1
      else
        @macro_keycodes << index
      end
    end
    opts.each do |opt|
      @macro_keycodes << 0
      @macro_keycodes << LETTER.index(opt)
      puts if opt == :ENTER
    end
  end

  def eval(script)
    if sandbox_picorbc(script)
      if sandbox_resume
        n = 0
        while sandbox_state != 0 do # 0: TASKSTATE_DORMANT == finished(?)
          sleep_ms 50
          n += 50
          if n > 10000
            puts "Error: Timeout (sandbox_state: #{sandbox_state})"
            break;
          end
        end
        macro("=> #{sandbox_result.inspect}")
      end
    else
      macro("Error: Compile failed")
    end
  end

  def ruby
    if @ruby_mode
      @macro_keycodes << LETTER.index(:ENTER)
      @buffer.adjust_screen
      eval @buffer.dump
      @buffer.clear
      @ruby_mode = false
      if $rgb
        $rgb.effect = @prev_rgb_effect || :rainbow
        $rgb.restore
      end
    else
      @buffer.refresh_screen
      @ruby_mode = true
      @ruby_mode_stop = false
      if $rgb
        @prev_rgb_effect = $rgb.effect
        $rgb.save
        $rgb.effect = :ruby
      end
    end
  end
end

$mutex = true
