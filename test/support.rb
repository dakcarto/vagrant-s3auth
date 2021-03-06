require 'http'

BOX_BASE = ENV['VAGRANT_S3AUTH_BOX_BASE'].freeze
BUCKET = ENV['VAGRANT_S3AUTH_BUCKET'].freeze
REGION_STANDARD = 'us-east-1'.freeze
REGION_NONSTANDARD = ENV['VAGRANT_S3AUTH_REGION_NONSTANDARD'].freeze

ATLAS_TOKEN = ENV['ATLAS_TOKEN'].freeze
ATLAS_USERNAME = ENV['ATLAS_USERNAME'].freeze
ATLAS_BOX_NAME = ENV['VAGRANT_S3AUTH_ATLAS_BOX_NAME'].freeze

class Atlas
  BASE_URL = 'https://app.vagrantup.com/api/v1'.freeze

  BOX_CREATE_URL = "#{BASE_URL}/boxes".freeze
  BOX_RESOURCE_URL = "#{BASE_URL}/box/%<username>s/%<box_name>s".freeze

  VERSION_CREATE_URL = "#{BOX_RESOURCE_URL}/versions".freeze
  VERSION_RESOURCE_URL = "#{BOX_RESOURCE_URL}/version/%<version>s".freeze
  VERSION_RELEASE_URL = "#{VERSION_RESOURCE_URL}/release".freeze

  PROVIDER_CREATE_URL = "#{VERSION_RESOURCE_URL}/providers".freeze
  PROVIDER_RESOURCE_URL = "#{VERSION_RESOURCE_URL}/provider/%<provider_name>s".freeze

  attr_accessor :provider

  def initialize(token, username)
    raise if !token || token.empty?
    raise if !username || username.empty?

    @token = token
    @username = username
    @provider = 'virtualbox'
  end

  def create_box(box_name)
    post(BOX_CREATE_URL, data: { box: { name: box_name, is_private: false } })
  end

  def delete_box(box_name)
    url_params = { box_name: box_name }
    delete(BOX_RESOURCE_URL, url_params: url_params)
  end

  def create_version(box_name, version)
    post(VERSION_CREATE_URL,
      data: { version: { version: version } },
      url_params: { box_name: box_name })
  end

  def release_version(box_name, version)
    put(VERSION_RELEASE_URL,
      url_params: { box_name: box_name, version: version })
  end

  def create_provider(box_name, version, url)
    post(PROVIDER_CREATE_URL,
      data: { provider: { name: @provider, url: url } },
      url_params: { box_name: box_name, version: version })
  end

  def request(method, url, options)
    url_params = (options[:url_params] || {}).merge(username: @username)
    data = (options[:data] || {})

    url = (url % url_params) + "?access_token=#{@token}"
    response = HTTP.request(method, url, json: data)
    raise response unless response.code >= 200 && response.code < 400
  end

  def post(url, options)
    request(:post, url, options)
  end

  def put(url, options)
    request(:put, url, options)
  end

  def delete(url, options)
    request(:delete, url, options)
  end
end
