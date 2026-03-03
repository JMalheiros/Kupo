puts "Creating admin user..."
User.find_or_create_by!(email_address: "admin@mstation.com") do |user|
  user.password = "password123"
end

puts "Creating categories..."
categories = %w[Ruby Rails JavaScript DevOps].map do |name|
  Category.find_or_create_by!(name: name)
end

puts "Creating sample articles..."
[
  {
    title: "Getting Started with Ruby on Rails 8",
    body: "# Getting Started with Rails 8\n\nRails 8 brings the **Solid** stack...\n\n## What's New\n\n- Solid Queue replaces Redis for jobs\n- Solid Cache for caching\n- Solid Cable for WebSockets\n\n```ruby\nrails new myapp\n```\n\nEnjoy building!",
    status: "published",
    published_at: 3.days.ago,
    categories: [ categories[0], categories[1] ]
  },
  {
    title: "Understanding Hotwire and Turbo",
    body: "# Hotwire and Turbo\n\nHotwire is the default frontend approach in Rails...\n\n## Turbo Frames\n\nTurbo Frames allow you to update parts of a page without a full reload.\n\n## Turbo Streams\n\nFor real-time updates over WebSocket.",
    status: "published",
    published_at: 1.day.ago,
    categories: [ categories[1], categories[2] ]
  },
  {
    title: "Draft: Advanced Ruby Patterns",
    body: "# Advanced Ruby Patterns\n\nThis is a draft article about metaprogramming...",
    status: "draft",
    published_at: nil,
    categories: [ categories[0] ]
  }
].each do |attrs|
  cats = attrs.delete(:categories)
  article = Article.find_or_create_by!(title: attrs[:title]) do |a|
    a.assign_attributes(attrs)
  end
  article.categories = cats
end

puts "Seed complete!"
