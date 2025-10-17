# base62.rb
class Base62
  CHARS = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz".freeze
  BASE = CHARS.length

  def self.encode(number)
    return "0" if number == 0
    
    result = ""
    while number > 0
      result = CHARS[number % BASE] + result
      number /= BASE
    end
    result
  end

  def self.decode(string)
    result = 0
    string.each_char do |char|
      result = result * BASE + CHARS.index(char)
    end
    result
  end
end
