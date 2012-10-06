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
    config_accessor :authorize_url
    config_accessor :acess_token_url
  end
  
  configure |config| do
    config.authorize_url = 'https://oauth.vk.com/authorize'
    config.acess_token_url = 'https://oauth.vk.com/access_token'
  end
end