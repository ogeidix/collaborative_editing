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

    def self.initialize!
      Cramp::Websocket.backend = :thin
      @logger       = Logger.new 'app/collabedit.log', (ENV['LOG'] || 'info').split(',')
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
        add('/old').static(Application.root('app/index.html'))
        add('/').static(Application.root('app/new_implementation.html'))
        get('/client/:document').to(Client)
        add('/js/rangy-core.js').static(Application.root('app/js/rangy-core.js'))
        add('/js/jquery-1.9.1.min.js').static(Application.root('app/js/jquery-1.9.1.min.js'))
        add('/js/jquery.json-2.2.min.js').static(Application.root('app/js/jquery.json-2.2.min.js'))
        add('/js/date.js').static(Application.root('app/js/date.js'))
        add('/js/application.js').static(Application.root('app/js/application.js'))
      end
    end

    def self.env
      @env ||= ENV['RACK_ENV'] || 'development'
    end
  end
end

Bundler.require(:default, CollaborativeEditing::Application.env)

Dir['./app/*.rb'].each {|f| require f}
