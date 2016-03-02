require 'morph'
require 'rest-client'

module OpenRegister
  VERSION = '0.0.1' unless defined? OpenRegister::VERSION
end

class OpenRegister::Register
  include Morph
  def records
    OpenRegister::records_for register.to_sym, from_openregister: try(:from_openregister)
  end
end

module OpenRegister
  class << self

    def registers from_openregister: false
      records_for :register, from_openregister: from_openregister
    end

    def register register, from_openregister: false
      registers(from_openregister: from_openregister).detect{ |r| r.register == register }
    end

    def records_for register, from_openregister: false
      url = url_for('records', register, from_openregister)
      retrieve url, register, from_openregister
    end

    def record register, record, from_openregister: false
      url = url_for "#{register}/#{record}", register, from_openregister
      retrieve(url, register, from_openregister).first
    end

    private

    def retrieve url, type, from_openregister
      json_list = json_list(url+'.json')
      list = json_list.map do |json|
        Morph.from_json(json, type, OpenRegister)
      end.flatten
      list.each { |item| item.from_openregister = true } if from_openregister
      list
    end

    def url_for path, register, from_openregister
      if from_openregister
        "http://#{register}.openregister.org/#{path}"
      else
        "https://#{register}.register.gov.uk/#{path}"
      end
    end

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
