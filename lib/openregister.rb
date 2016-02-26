require 'morph'
require 'rest-client'

module OpenRegister
  VERSION = '0.0.1' unless defined? OpenRegister::VERSION
end

class OpenRegister::Register
  include Morph
  def records
    OpenRegister::records_for register.to_sym
  end
end

module OpenRegister
  class << self

    def registers
      records_for :register
    end

    def records_for register
      retrieve "https://#{register}.register.gov.uk/records", register
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
      list = [json]
      if link_header = response.headers[:link]
        if rel_next = links(link_header)[:next]
          next_url = "#{url}#{rel_next}"
          list << json_list(next_url)
        end
      end
      list.flatten
    end

    def munge json
      json = JSON.parse(json).to_json
      json.gsub!('"hash":','"_hash":')
      json.gsub!(/"entry":{"([^}]+)}}/, '"\1}')
      json
    end

    def links link_header
      link_header.split(',').each_with_object({}) do |link, hash|
        link.strip!
        parts = link.match(/<(.+)>; *rel="(.+)"/)
        hash[parts[2].to_sym] = parts[1]
      end
    end

  end
end
