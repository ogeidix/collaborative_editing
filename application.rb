require 'rubygems'
require 'bundler'
require 'yajl'
require 'erb'
require 'stringio'
require 'fileutils'
require 'rexml/document'
require 'time'
require 'digest/md5'

Thread.abort_on_exception = true

module CollaborativeEditing
  class Application
    LOG_FILENAME = 'app/collabedit.log'

    def self.initialize!
      Cramp::Websocket.backend = :thin
      Checkpointer.recovery LOG_FILENAME
      @logger       = Logger.new LOG_FILENAME, (ENV['LOG'] || 'info').split(',')
      @checkpointer = Checkpointer.new
    end

    def self.logger
      return @logger
    end

    def self.checkpointer
      return @checkpointer
    end

    def self.root(path = nil)
      @root ||= File.expand_path(File.dirname(__FILE__))
      path ? File.join(@root, path.to_s) : @root
    end

    def self.routes
      @routes ||=  HttpRouter.new do
        add('/').static(Application.root('app/client.html'))
        get('/client/:document').to(Client)
        add('/js').static('app/js')
        add('/css').static('app/css')
      end
    end

    def self.env
      @env ||= ENV['RACK_ENV'] || 'development'
    end
  end
end

Bundler.require(:default, CollaborativeEditing::Application.env)

Dir['./app/*.rb'].each {|f| require f}
