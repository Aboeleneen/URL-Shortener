# app.rb
require 'sinatra'
require 'json'
require_relative 'clients/init'
require_relative 'utils/init'

configure do
  set :bind, '0.0.0.0'
  set :port, 4567
  set :show_exceptions, false
  set :protection, false
end

before do
  PostgresClient.setup_tables
end

get '/' do
  content_type :json
  {
    message: "ShortLink - URL Shortening Service",
    endpoints: {
      "POST /encode" => "Encode a URL to a shortened URL",
      "POST /decode" => "Decode a shortened URL to its original URL"
    }
  }.to_json
end

# Encode a URL to a shortened URL
# Request:
# {
#   "url": "https://example.com/very/long/url"
# }
# Response:
# {
#   "short_url": "http://your.domain/GeAi9K",
#   "original_url": "https://example.com/very/long/url"
# }
post '/encode' do
  content_type :json
  
  begin
    data = JSON.parse(request.body.read)
    original_url = data['url']
    
    if original_url.nil? || original_url.empty?
      status 400
      return { error: "URL is required" }.to_json
    end
    
    unless UrlValidator.valid?(original_url)
      status 400
      return { error: "Invalid URL format" }.to_json
    end
    
    existing = PostgresClient.find_by_original_url(original_url)
    if existing
      return {
        short_url: "#{request.base_url}/#{existing[:short_code]}",
        original_url: existing[:original_url]
      }.to_json
    end
    
    id = RedisClient.get_next_id
    short_code = Base62.encode(id)
    PostgresClient.create_url(original_url, short_code)
    
    {
      short_url: "#{request.base_url}/#{short_code}",
      original_url: original_url
    }.to_json
    
  rescue JSON::ParserError
    status 400
    { error: "Invalid JSON" }.to_json
  rescue => e
    status 500
    { error: "Internal server error" }.to_json
  end
end

# Decode a shortened URL to its original URL
# Request:
# {
#   "short_url": "http://your.domain/GeAi9K"
# }
# Response:
# {
#   "original_url": "https://example.com/very/long/url",
#   "short_url": "http://your.domain/GeAi9K"
# }
post '/decode' do
  content_type :json
  
  begin
    data = JSON.parse(request.body.read)
    short_url = data['short_url']
    
    if short_url.nil? || short_url.empty?
      status 400
      return { error: "Short URL is required" }.to_json
    end
    
    short_code = UrlValidator.extract_short_code(short_url)
    
    if short_code.nil?
      status 400
      return { error: "Invalid short URL format" }.to_json
    end
    
    url_record = PostgresClient.find_by_short_code(short_code)
    
    if url_record
      {
        original_url: url_record[:original_url],
        short_url: short_url
      }.to_json
    else
      status 404
      { error: "Short URL not found" }.to_json
    end
    
  rescue JSON::ParserError
    status 400
    { error: "Invalid JSON" }.to_json
  rescue => e
    status 500
    { error: "Internal server error" }.to_json
  end
end