require 'morph'
require 'rest-client'

module OpenRegister
  VERSION = '0.0.1' unless defined? OpenRegister::VERSION
end

class OpenRegister::Register
  include Morph
  def all_records
    OpenRegister::records_for register.to_sym, from_openregister: try(:from_openregister), all: true
  end

  def records
    OpenRegister::records_for register.to_sym, from_openregister: try(:from_openregister)
  end
end

class OpenRegister::Field
  include Morph
end

module OpenRegister
  class << self

    def registers from_openregister: false
      records_for :register, from_openregister: from_openregister, all: true
    end

    def register register, from_openregister: false
      registers(from_openregister: from_openregister).detect{ |r| r.register == register }
    end

    def records_for register, from_openregister: false, all: false
      url = url_for('records', register, from_openregister)
      retrieve url, register, from_openregister, all
    end

    def record register, record, from_openregister: false
      url = url_for "#{register}/#{record}", register, from_openregister
      retrieve(url, register, from_openregister).first
    end

    def field record, from_openregister: false
      record('field', record, from_openregister: from_openregister)
    end

    private

    def set_morph_listener from_openregister
      @listeners ||= {}
      @listeners[from_openregister] ||= OpenRegister::MorphListener.new from_openregister
      Morph.register_listener @listeners[from_openregister]
    end

    def unset_morph_listener from_openregister
      Morph.unregister_listener @listeners[from_openregister]
    end

    def augment_register_fields from_openregister, &block
      set_morph_listener(from_openregister)
      list = yield
      unset_morph_listener(from_openregister)
      list
    end

    def retrieve url, type, from_openregister, all=false
      augment_register_fields(from_openregister) do
        json_list = json_list(url+'.json', all)
        list = json_list.map { |json| Morph.from_json(json, type, OpenRegister) }.flatten
        list.each { |item| item.from_openregister = true } if from_openregister
        list
      end
    end

    def url_for path, register, from_openregister
      if from_openregister
        "http://#{register}.openregister.org/#{path}"
      else
        "https://#{register}.register.gov.uk/#{path}"
      end
    end

    def json_list url, all
      response = RestClient.get(url)
      json = munge response.body
      list = [json]
      if all && link_header = response.headers[:link]
        if rel_next = links(link_header)[:next]
          next_url = "#{url}#{rel_next}"
          list << json_list(next_url, all)
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

class OpenRegister::MorphListener

  def initialize from_openregister
    @from_openregister = from_openregister
  end

  def call klass, symbol
    if !register_or_field_class?(klass) && !hash_or_serial?(symbol)
      add_method_to_access_field_record klass, symbol
    end
  end

  private

  def register_or_field_class? klass
    ['OpenRegister::Register', 'OpenRegister::Field'].include? klass.name
  end

  def hash_or_serial? symbol
    [:_hash, :serial_number].include? symbol
  end

  def field_name symbol
    symbol.to_s.gsub('_','-')
  end

  def register_for_field symbol
    field = OpenRegister::field field_name(symbol), from_openregister: @from_openregister
    register = field.register
    register if register && register.size > 0
  end

  def add_method_to_access_field_record klass, symbol
    register = register_for_field(symbol)
    klass.class_eval method_def(symbol, register) if register
  end

  def method_def symbol, register
    method = "_#{symbol}"
    "def #{method}; OpenRegister.record('#{register}', send(:#{symbol}), from_openregister: #{@from_openregister} ); end"
  end

end
