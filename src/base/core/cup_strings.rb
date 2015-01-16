# file: cup_strings.rb
# File for using utf8 strings with fox
#reference :http://www.fxruby.org/doc/unicode.html

# leave this 2 line below commented, so we are using iso-8859-1
# but for such strings we use utf8 coding
#require 'jcode'
#$KCODE = 'u'

# U+00e8 = e'
# U+00e0 = a'

# table on http://www.utf8-zeichentabelle.de/
# on this table use the first column, i.e something like U+00C8

class UString < String
  # Show u-prefix as in Python
  def inspect; "u#{ super }" end

  # Count multibyte characters
  def length; self.scan(/./).length end

  # Reverse the string
  def reverse; self.scan(/./).reverse.join end
end

module Kernel
  def u( str )
    UString.new str.gsub(/U\+([0-9a-fA-F]{4,4})/u){["#$1".hex ].pack('U*')}
  end
end 

