# Change log

## 0.9.3 in 2021/09/17
### Improvement
- Abbreviated keynames things like `KC_ENT` for `KC_ENTER` can be used in `keymap.rb`. See [bc23e52](https://github.com/picoruby/prk_firmware/commit/bc23e52f51c2899ce5309643f0ab89606a9b469d)

## 0.9.2 in 2021/09/15
### Useful feature 🎉
- You can see debug print on a USB serial port that will be helpful if your `keymap.rb` doesn't work well
  - Configuration:
      
      ```
      Baud: 115200
      Data bits: 8
      Parity: None
      Stop bits: 1
      Flow control: None
      ```

  ![](doc/images/serial_port.png)

## 0.9.1 in 2021/09/12
### Small improvement
- Sparkfun Pro Micro RP2040 will reboot to BOOTSEL mode if you double-press RESET button without detaching USB cable!

  ![](doc/images/RP2040_boards.jpg)

## 0.9.0 in 2021/09/10 (First release🎊)
### BIG BIG IMPROVEMENT 🍣
- You no longer need any compiler toolchain!!!
- No longer detaching USB cable every time amending your keymap, too!!!
- See README.md 👀

## 2021/08/17
### Breaking Change 💣
- Code upgraded to correspond to the newest pico-sdk as of today. Please upgrade your pico-sdk

## 2021/08/16
### Changed
- Bump up PicoRuby to "mruby3 version"
- There is no external change though, if your keymap doesn't work, try to add `sleep 1` to the beggining of your keymap.rb

## 2021/06/19
###  New feature added
- Rotary Encoders &#x1F39B;
  - Find an example in [prk_helix_rev3/keymap.rb](https://github.com/picoruby/prk_helix_rev3/blob/master/keymap.rb)

## 2021/06/01
### Breaking Change 💣
- The second argument of `Keyboard#add_layer`

  Before the change: `Array[Array[Symbol]]`
  ```ruby
  kbd.add_layer :default, [
    %i(KC_ESCAPE KC_Q KC_W KC_E KC_R KC_T KC_Y KC_U KC_I KC_O KC_P      KC_MINUS),
    %i(KC_TAB    KC_A KC_S KC_D KC_F KC_G KC_H KC_J KC_K KC_L KC_SCOLON KC_BSPACE),
    ...
  ]
  ```

  After the change: `Array[Symbol]`
  ```ruby
  kbd.add_layer :default, %i(
    KC_ESCAPE KC_Q KC_W KC_E KC_R KC_T KC_Y KC_U KC_I KC_O KC_P      KC_MINUS
    KC_TAB    KC_A KC_S KC_D KC_F KC_G KC_H KC_J KC_K KC_L KC_SCOLON KC_BSPACE
    ...
  )
  ```

## 2021/05/21
### Dependency
- CRuby (MRI) for static type checking by RBS and Steep
### Changed
- Directory of Ruby source is changed from `src/` to `src/ruby/`

## 2021/05/08
###  Added
- RGB class 🌈

## 2021/04/14
- Published as a public beta 🎉
