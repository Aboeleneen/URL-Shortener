# Use official Ruby image
FROM ruby:3.2

# Set working directory
WORKDIR /usr/src/app

# Install gems directly
RUN gem install sinatra puma rackup

# Copy project files
COPY . .

# Expose port
EXPOSE 4567

# Run the app
CMD ["ruby", "app.rb"]