# utils/url_validator.rb
class UrlValidator
  def self.valid?(url)
    uri = URI.parse(url)
    uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
  rescue URI::InvalidURIError
    false
  end

  def self.extract_short_code(url)
    # Extract short code from URL like http://domain.com/abc123
    uri = URI.parse(url)
    path = uri.path
    return nil if path.nil? || path.empty? || path == '/'
    
    # Remove leading slash and get the short code
    short_code = path[1..-1]
    
    # Validate that it looks like a Base62 short code (alphanumeric)
    return short_code if short_code.match?(/\A[0-9A-Za-z]+\z/)
    
    nil
  rescue URI::InvalidURIError
    nil
  end
end
