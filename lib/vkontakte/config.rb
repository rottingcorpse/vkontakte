require 'active_support/configurable'

module Vkontakte
  def self.configure(&block)
    yield @config ||= Vkontakte::Configuration.new
  end
  
  def self.config
    @config
  end
  
  class Configuration 
    include ActiveSupport::Configurable
    config_accessor :client_id
    config_accessor :client_secret
    config_accessor :base_url
    config_accessor :authorize_base_url
    config_accessor :acess_token_base_url
    config_accessor :api_base_url
  end
  
  configure do |config|
    config.base_url = 'http://vk.com'
    config.authorize_base_url = 'https://oauth.vk.com/authorize'
    config.acess_token_base_url = 'https://oauth.vk.com/access_token'
    config.api_base_url = 'https://api.vk.com/method'
  end
end
