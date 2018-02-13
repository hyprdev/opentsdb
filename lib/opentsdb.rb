module Opentsdb
  class << self
    attr_writer :host
    attr_writer :port
    attr_writer :type
    attr_writer :timezone
    attr_writer :logger
    attr_writer :executable_path

    def configure
      yield self
    end

    def host
      @host || 'localhost'
    end

    def port
      @port || 4242
    end

    def type
      @type || 'details'
    end

    def timezone
      @timezone || 'UTC'
    end

    def executable_path
      @executable_path || 'tsdb'
    end

    def logger
      @logger || nil
    end
  end
end

require 'date'
require 'json'
require 'faraday'
require 'httpclient'
require 'active_support/time'
require 'opentsdb/error/api_error'
require 'opentsdb/error/uid_not_exists_error'
require 'opentsdb/error/metric_not_exists_error'
require 'opentsdb/error/tagk_not_exists_error'
require 'opentsdb/error/tagv_not_exists_error'
require 'opentsdb/client'
require 'opentsdb/version'
