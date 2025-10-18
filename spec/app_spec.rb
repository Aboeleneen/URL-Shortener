# spec/app_spec.rb
require 'spec_helper'

RSpec.describe 'ShortLink API' do
  describe 'POST /encode' do
    describe 'input validation' do
      it 'returns error for missing URL field' do
        post '/encode', {}.to_json, 'CONTENT_TYPE' => 'application/json'
        
        expect(last_response.status).to eq(400)
        data = JSON.parse(last_response.body)
        expect(data['error']).to eq('URL is required')
      end
      
      it 'returns error for empty URL' do
        post '/encode', { url: '' }.to_json, 'CONTENT_TYPE' => 'application/json'
        
        expect(last_response.status).to eq(400)
        data = JSON.parse(last_response.body)
        expect(data['error']).to eq('URL is required')
      end
      
      it 'returns error for invalid JSON' do
        post '/encode', 'invalid json', 'CONTENT_TYPE' => 'application/json'
        
        expect(last_response.status).to eq(400)
        data = JSON.parse(last_response.body)
        expect(data['error']).to eq('Invalid JSON')
      end
    end

    describe 'URL format validation' do
      it 'returns error for invalid URL format' do
        post '/encode', { url: 'not-a-url' }.to_json, 'CONTENT_TYPE' => 'application/json'
        
        expect(last_response.status).to eq(400)
        data = JSON.parse(last_response.body)
        expect(data['error']).to eq('Invalid URL format')
      end
      
      it 'accepts valid HTTP URL' do
        post '/encode', { url: 'http://example.com' }.to_json, 'CONTENT_TYPE' => 'application/json'
        
        expect(last_response.status).to eq(200)
        data = JSON.parse(last_response.body)
        expect(data['original_url']).to eq('http://example.com')
        expect(data['short_url']).to match(%r{http://.*/[0-9A-Za-z]+})
      end
      
      it 'accepts valid HTTPS URL' do
        post '/encode', { url: 'https://example.com' }.to_json, 'CONTENT_TYPE' => 'application/json'
        
        expect(last_response.status).to eq(200)
        data = JSON.parse(last_response.body)
        expect(data['original_url']).to eq('https://example.com')
        expect(data['short_url']).to match(%r{http://.*/[0-9A-Za-z]+})
      end
      
      it 'accepts URL with query parameters' do
        post '/encode', { url: 'https://example.com?param=value&test=123' }.to_json, 'CONTENT_TYPE' => 'application/json'
        
        expect(last_response.status).to eq(200)
        data = JSON.parse(last_response.body)
        expect(data['original_url']).to eq('https://example.com?param=value&test=123')
        expect(data['short_url']).to match(%r{http://.*/[0-9A-Za-z]+})
      end
    end

    describe 'business logic' do
      it 'creates new short URL for new URL' do
        post '/encode', { url: 'https://new-example.com' }.to_json, 'CONTENT_TYPE' => 'application/json'
        
        expect(last_response.status).to eq(200)
        data = JSON.parse(last_response.body)
        expect(data['original_url']).to eq('https://new-example.com')
        expect(data['short_url']).to match(%r{http://.*/[0-9A-Za-z]+})
      end
      
      it 'returns existing short URL for already encoded URL' do
        # First encode
        post '/encode', { url: 'https://duplicate-example.com' }.to_json, 'CONTENT_TYPE' => 'application/json'
        first_response = JSON.parse(last_response.body)
        
        # Second encode of same URL
        post '/encode', { url: 'https://duplicate-example.com' }.to_json, 'CONTENT_TYPE' => 'application/json'
        
        expect(last_response.status).to eq(200)
        data = JSON.parse(last_response.body)
        expect(data['original_url']).to eq('https://duplicate-example.com')
        expect(data['short_url']).to eq(first_response['short_url'])
      end
    end

    describe 'edge cases' do
      it 'handles very long URLs' do
        long_url = 'https://example.com/' + 'a' * 1000
        post '/encode', { url: long_url }.to_json, 'CONTENT_TYPE' => 'application/json'
        
        expect(last_response.status).to eq(200)
        data = JSON.parse(last_response.body)
        expect(data['original_url']).to eq(long_url)
        expect(data['short_url']).to match(%r{http://.*/[0-9A-Za-z]+})
      end
    end
  end

  describe 'POST /decode' do
    describe 'input validation' do
      it 'returns error for missing short_url field' do
        post '/decode', {}.to_json, 'CONTENT_TYPE' => 'application/json'
        
        expect(last_response.status).to eq(400)
        data = JSON.parse(last_response.body)
        expect(data['error']).to eq('Short URL is required')
      end
      
      it 'returns error for empty short_url' do
        post '/decode', { short_url: '' }.to_json, 'CONTENT_TYPE' => 'application/json'
        
        expect(last_response.status).to eq(400)
        data = JSON.parse(last_response.body)
        expect(data['error']).to eq('Short URL is required')
      end
      
      it 'returns error for invalid JSON' do
        post '/decode', 'invalid json', 'CONTENT_TYPE' => 'application/json'
        
        expect(last_response.status).to eq(400)
        data = JSON.parse(last_response.body)
        expect(data['error']).to eq('Invalid JSON')
      end
    end

    describe 'short URL format validation' do
      it 'returns error for invalid short URL format' do
        post '/decode', { short_url: 'not-a-url' }.to_json, 'CONTENT_TYPE' => 'application/json'
        
        expect(last_response.status).to eq(400)
        data = JSON.parse(last_response.body)
        expect(data['error']).to eq('Invalid short URL format')
      end
      
      it 'accepts valid short URL format' do
        post '/decode', { short_url: 'http://localhost:4567/abc123' }.to_json, 'CONTENT_TYPE' => 'application/json'
        
        expect(last_response.status).to eq(404) # Not found, but format is valid
        data = JSON.parse(last_response.body)
        expect(data['error']).to eq('Short URL not found')
      end
      
      it 'rejects short URL with different domain' do
        post '/decode', { short_url: 'https://other-domain.com/abc123' }.to_json, 'CONTENT_TYPE' => 'application/json'
        
        expect(last_response.status).to eq(400) # Invalid format due to different domain
        data = JSON.parse(last_response.body)
        expect(data['error']).to eq('Invalid short URL format')
      end
      
      it 'accepts short URL with path' do
        post '/decode', { short_url: 'http://localhost:4567/path/abc123' }.to_json, 'CONTENT_TYPE' => 'application/json'
        
        expect(last_response.status).to eq(400) # Invalid format due to extra path
        data = JSON.parse(last_response.body)
        expect(data['error']).to eq('Invalid short URL format')
      end
      
      it 'accepts short URL with query parameters' do
        post '/decode', { short_url: 'http://localhost:4567/abc123?param=value' }.to_json, 'CONTENT_TYPE' => 'application/json'
        
        expect(last_response.status).to eq(404) # Not found, but format is valid
        data = JSON.parse(last_response.body)
        expect(data['error']).to eq('Short URL not found')
      end
    end

    describe 'business logic' do
      it 'returns original URL for existing short URL' do
        # First encode a URL to get a valid short URL
        post '/encode', { url: 'https://example.com/decode-test' }.to_json, 'CONTENT_TYPE' => 'application/json'
        encode_response = JSON.parse(last_response.body)
        short_url = encode_response['short_url']
        
        # Now decode it
        post '/decode', { short_url: short_url }.to_json, 'CONTENT_TYPE' => 'application/json'
        
        expect(last_response.status).to eq(200)
        data = JSON.parse(last_response.body)
        expect(data['original_url']).to eq('https://example.com/decode-test')
        expect(data['short_url']).to eq(short_url)
      end
      
      it 'returns 404 for non-existent short URL' do
        post '/decode', { short_url: 'http://localhost:4567/nonexistent123' }.to_json, 'CONTENT_TYPE' => 'application/json'
        
        expect(last_response.status).to eq(404)
        data = JSON.parse(last_response.body)
        expect(data['error']).to eq('Short URL not found')
      end
    end

    describe 'edge cases' do
      it 'rejects short URLs with different protocols' do
        post '/decode', { short_url: 'https://localhost:4567/abc123' }.to_json, 'CONTENT_TYPE' => 'application/json'
        
        expect(last_response.status).to eq(400) # Invalid format due to different protocol
        data = JSON.parse(last_response.body)
        expect(data['error']).to eq('Invalid short URL format')
      end
      
      it 'rejects short URLs with different port numbers' do
        post '/decode', { short_url: 'http://localhost:3000/abc123' }.to_json, 'CONTENT_TYPE' => 'application/json'
        
        expect(last_response.status).to eq(400) # Invalid format due to different port
        data = JSON.parse(last_response.body)
        expect(data['error']).to eq('Invalid short URL format')
      end
    end
  end
end
