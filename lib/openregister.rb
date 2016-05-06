require 'morph'
require 'rest-client'

module OpenRegister
  VERSION = '0.0.1' unless defined? OpenRegister::VERSION
end

class OpenRegister::Register
  include Morph
  def all_records page_size: 100
    OpenRegister::records_for register.to_sym, from_openregister: try(:from_openregister), all: true, page_size: page_size
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

    def records_for register, from_openregister: false, all: false, page_size: 100
      url = url_for('records', register, from_openregister)
      retrieve url, register, from_openregister, all, page_size
    end

    def record register, record, from_openregister: false
      url = url_for "record/#{record}", register, from_openregister
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
      @morph_listener_set = true
    end

    def unset_morph_listener from_openregister
      Morph.unregister_listener @listeners[from_openregister]
      @morph_listener_set = false
    end

    def augment_register_fields from_openregister, &block
      already_set = (@morph_listener_set || false)
      set_morph_listener(from_openregister) unless already_set
      list = yield
      unset_morph_listener(from_openregister) unless already_set
      list
    end

    def retrieve url, type, from_openregister, all=false, page_size=100
      list = augment_register_fields(from_openregister) do
        url = "#{url}.tsv"
        url = "#{url}?page-index=1&page-size=#{page_size}" if page_size != 100
        results = []
        response_list(url, all) do |tsv|
          items = Morph.from_tsv(tsv, type, OpenRegister)
          items.each {|item| results.push item }
          nil
        end
        results
      end
      list.each { |item| item.from_openregister = true } if from_openregister
      list
    end

    def url_for path, register, from_openregister
      if from_openregister
        "http://#{register}.alpha.openregister.org/#{path}"
      else
        "https://#{register}.register.gov.uk/#{path}"
      end
    end

    def response_list url, all, &block
      response = RestClient.get(url)
      tsv = response.body
      yield tsv
      if all && link_header = response.headers[:link]
        if rel_next = links(link_header)[:next]
          next_url = "#{url.split('?').first}#{rel_next}"
          response_list(next_url, all, &block)
        end
      end
      nil
    rescue RestClient::ResourceNotFound => e
      puts e.to_s
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
    @from_openregister = from_openregister || false
  end

  def call klass, symbol
    return if @handling && @handling == [klass, symbol]
    @handling = [klass, symbol]
    if !register_or_field_class?(klass, symbol) && !is_entry_resource_field?(symbol) && !augmented_field?(symbol)
      add_method_to_access_field_record klass, symbol
    end
  end

  private

  def register_or_field_class? klass, symbol
    klass.name == 'OpenRegister::Field' || (klass.name == 'OpenRegister::Register' && symbol != :fields)
  end

  def is_entry_resource_field? symbol
    [:entry_number, :entry_timestamp, :item_hash].include? symbol
  end

  def augmented_field? symbol
    symbol.to_s[/^_/]
  end

  def field_name symbol
    symbol.to_s.gsub('_','-')
  end

  def field symbol
    OpenRegister::field field_name(symbol), from_openregister: @from_openregister
  end

  def datatype_curie? field
    field && field.datatype == 'curie'
  end

  def register_for_field field
    field.register if field && field.register && field.register.size > 0
  end

  def add_method_to_access_field_record klass, symbol
    field = field(symbol)
    method = if datatype_curie? field
               curie_retreive_method(symbol)
             elsif register = register_for_field(field)
               retreive_method(symbol, register)
             elsif cardinality_n? field
               n_split_method(symbol)
             end
    klass.class_eval method if method
  end

  def cardinality_n? field
    field.cardinality == 'n' if field && field.cardinality
  end

  def n_split_method symbol
    "def #{symbol}
  @#{symbol} = @#{symbol}.split(';') unless @#{symbol}.is_a?(Array)
  @#{symbol}
end"
  end

  def curie_retreive_method symbol
    method = "_#{symbol}"
    "def #{method}
  curie = send(:#{symbol}).split(':')
  register = curie.first
  field = curie.last
  @#{method} ||= OpenRegister.record(register, field, from_openregister: #{@from_openregister} )
end"
  end

  def retreive_method symbol, register
    method = "_#{symbol}"
    "def #{method}
  @#{method} ||= OpenRegister.record('#{register}', send(:#{symbol}), from_openregister: #{@from_openregister} )
end"
  end

end
