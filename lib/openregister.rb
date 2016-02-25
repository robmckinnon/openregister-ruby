require 'morph'
require 'rest-client'

module OpenRegister
  VERSION = '0.0.1' unless defined? OpenRegister::VERSION
end

module OpenRegister
  class << self

    def registers
      retrieve 'https://register.register.gov.uk/records', :register
    end

    def retrieve url, type
      json_list = json_list(url+'.json')
      json_list.map do |json|
        Morph.from_json(json, type, OpenRegister)
      end.flatten
    end

    private

    def json_list url
      response = RestClient.get(url)
      json = munge response.body
      [json]
    end

    def munge json
      json = JSON.parse(json).to_json
      json.gsub!('"hash":','"_hash":')
      json.gsub!(/"entry":{"([^}]+)}}/, '"\1}')
      json
    end

  end
end
