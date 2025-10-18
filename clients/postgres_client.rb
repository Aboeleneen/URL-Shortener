# postgres_client.rb
require 'sequel'

class PostgresClient
  def self.connect
    @db ||= if ENV['DATABASE_URL']
      # Use DATABASE_URL if available (Fly.io standard)
      Sequel.connect(ENV['DATABASE_URL'])
    else
      # Fallback to individual environment variables
      Sequel.connect(
        adapter: 'postgres',
        host: ENV['POSTGRES_HOST'] || 'postgres',
        port: ENV['POSTGRES_PORT'] || 5432,
        database: ENV['POSTGRES_DB'] || 'url_shortener',
        user: ENV['POSTGRES_USER'] || 'postgres',
        password: ENV['POSTGRES_PASSWORD'] || 'password'
      )
    end
  end

  def self.setup_tables
    db = connect
    
    unless db.table_exists?(:urls)
      db.create_table :urls do
        primary_key :id
        String :original_url, null: false
        String :short_code, null: false, unique: true
        DateTime :created_at, default: Sequel::CURRENT_TIMESTAMP
      end
      
      db.add_index :urls, :short_code, unique: true
    end
  end

  def self.find_by_original_url(original_url)
    connect[:urls].where(original_url: original_url).first
  end

  def self.find_by_short_code(short_code)
    connect[:urls].where(short_code: short_code).first
  end

  def self.create_url(original_url, short_code)
      connect[:urls].insert(
        original_url: original_url,
        short_code: short_code,
        created_at: Time.now
      )
  end

  def self.all_urls
    connect[:urls].all
  end

  def self.delete_url(short_code)
    connect[:urls].where(short_code: short_code).delete
  end
end
