require 'rubygems'
require 'bundler'
require 'yajl'
require 'erb'
require 'stringio'
require 'fileutils'

module CollaborativeEditing
  class Application

    def self.initialize!
      Cramp::Websocket.backend = :thin
    end

    def self.root(path = nil)
      @root ||= File.expand_path(File.dirname(__FILE__))
      path ? File.join(@root, path.to_s) : @root
    end

    def self.routes
      @routes ||=  HttpRouter.new do
        add('/').static(Application.root('app/index.html'))
        get('/client/:document').to(Client)
        add('/js/rangy-core.js').static(Application.root('app/js/rangy-core.js'))
      end
    end

    def self.env
      @env ||= ENV['RACK_ENV'] || 'development'
    end
  end
end

Bundler.require(:default, CollaborativeEditing::Application.env)

Dir['./app/*.rb'].each {|f| require f}
