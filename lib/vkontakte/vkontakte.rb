require 'open-uri'
require 'curb'

module Vkontakte
  class MethodCallError < RuntimeError
    attr_accessor :method
    attr_accessor :code
    attr_accessor :message
    attr_accessor :params

    def initialize(method, code, message, params)
      self.method = method
      self.code = code
      self.message = message
      self.params = params
    end
  end

  def self.execute(method_name, options, &block)
    options ||= {}
    params = options.map{ |k,v| "#{k.to_s}=#{v.to_s}" }.join("&")
    url = URI::encode "#{Vkontakte.config.api_base_url}/#{method_name}?#{params}"
    json = ActiveSupport::JSON.decode open(url)
    if json["error"].present? 
      error = json["error"]
      params = error["request_params"].map { |p| {:key => p["key"], :value => p["value"]} }
      raise MethodCallError.new(method_name, error["error_code"], error["error_msg"], params)
    else
      block_given? ? yield(json) : json["response"]
    end
  end

  class Application
    def self.api_method(scope, method, &block)
      method_name = "#{scope.to_s}_#{method.to_s}"
      url_method_name = "#{scope.to_s}_#{method.to_s}_url"
      api_method_name = "#{scope.to_s}.#{method.to_s.camelcase(:lower)}"
      define_method url_method_name.to_sym do |options = nil|
        method_url(api_method_name, options)
      end
      define_method method_name.to_sym do |options = nil|
        url = method_url(api_method_name, options)
        json = ActiveSupport::JSON.decode open(url)
        if json["error"].present? 
          error = json["error"]
          params = error["request_params"].map { |p| {:key => p["key"], :value => p["value"]} }
          raise MethodCallError.new(method_name, error["error_code"], error["error_msg"], params)
        else
          block_given? ? yield(json) : json["response"]
        end
      end 
    end

    def self.authorize_url(scope, redirect)
      params = {
        :scope => scope.map{|item| item.to_s}.join(','),
        :client_id => Vkontakte.config.client_id,
        :redirect_uri => redirect
      }.map{|k,v| "#{k.to_s}=#{v.to_s}"}.join("&")
      URI::encode "#{Vkontakte.config.authorize_base_url}?#{params}"
    end

    def self.access_token_url(code, redirect)
      params = {
        :code => code,
        :client_id => Vkontakte.config.client_id,
        :client_secret => Vkontakte.config.client_secret,
        :redirect_uri => redirect
      }.map{|k,v| "#{k.to_s}=#{v.to_s}"}.join("&")
      URI::encode "#{Vkontakte.config.acess_token_base_url}?#{params}"
    end
    
    def self.request_access_token(code, redirect)
      json = ActiveSupport::JSON.decode(open(access_token_url(code,redirect)))
      yield json["access_token"], json["user_id"], json["expires_in"]
    end

    api_method :users, :get
    api_method :users, :search
    api_method :photos, :get
    api_method :photos, :get_albums
    api_method :photos, :get_albums_count
    api_method :photos, :create_album
    api_method :photos, :get_upload_server
    api_method :photos, :save
    api_method :photos, :move
    api_method :photos, :edit
    api_method :audio, :get
    api_method :newsfeed, :search
    api_method :friends, :get

    alias :users :users_get
    alias :friends, :friends_get
    alias :photos :photos_get
    alias :edit_photo :photos_edit
    alias :photo_albums :photos_get_albums
    alias :create_photo_album :photos_create_album
    alias :photo_albums_count :photos_get_albums_count
    alias :move_photo :photos_move
    alias :audio :audio_get
  
    def initialize(user_id, token)
      @user_id = user_id
      @token = token
    end

    def account_url
      URI::encode "#{Vkontakte.config.base_url}/id#{@user_id}"
    end

    def method_url(method_name, options = nil)
      options ||= {}
      params = options.merge(:access_token => @token).map{ |k,v| "#{k.to_s}=#{v.to_s}" }.join("&")
      URI::encode "#{Vkontakte.config.api_base_url}/#{method_name}?#{params}"
    end

    def photo_albums_with_photos(options = nil)
      self.photos_get_albums(options).map do |album|
        photos = photos_get(:aid => album["aid"]).map do |photo|
          {
            :title => photo["text"],
            :url => photo["src"]
          }
        end
        album.merge({:photos => photos})
      end
    end

    def photos_count
      photo_albums_with_photos.inject(0) { |sum, album| sum += album[:photos].count }
    end

    def create_photo(options)
      upload_options = photos_get_upload_server({:aid => options[:aid]})
      curl = Curl::Easy.new(upload_options.delete("upload_url"))
      curl.multipart_form_post = true
      curl.http_post(Curl::PostField.file('file1', options[:url]))
      upload_json = ActiveSupport::JSON.decode(curl.body_str)
      photos_save(options.except(:url).merge(upload_json))
    end
  end
end
