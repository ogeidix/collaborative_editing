require './application'
CollaborativeEditing::Application.initialize!

# Development middlewares
if CollaborativeEditing::Application.env == 'development'
  use AsyncRack::CommonLogger
  # Enable code reloading on every request
  use Rack::Reloader, 0
end

run CollaborativeEditing::Application.routes