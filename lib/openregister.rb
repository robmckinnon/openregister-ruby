require 'morph'
require 'rest-client'

module OpenRegister
  VERSION = '0.0.1' unless defined? OpenRegister::VERSION
end

class OpenRegister::Register
  include Morph
  def _all_records page_size: 100
    OpenRegister::records_for register.to_sym, try(:_base_url), all: true, page_size: page_size
  end

  def _records
    OpenRegister::records_for register.to_sym, try(:_base_url)
  end

  def _fields
    fields.map do |field|
      OpenRegister.field field.to_sym, try(:_base_url)
    end
  end
end

class OpenRegister::Field
  include Morph
end

module OpenRegister::Helpers
  def is_entry_resource_field? symbol
    [:entry_number, :entry_timestamp, :item_hash].include? symbol
  end

  def augmented_field? symbol
    symbol[/^_/]
  end

  def cardinality_n? field
    field.cardinality == 'n' if field && field.cardinality
  end

  def field_name symbol
    symbol.to_s.gsub('_','-')
  end
end

module OpenRegister
  class << self

    def registers base_url=nil
      registers = records_for :register, base_url, all: true
      registers.each do |r|
        r._uri = url_for('', r.register, base_url)
      end if registers
      registers
    end

    def register register, base_url=nil
      registers(base_url).detect{ |r| r.register == register }
    end

    def records_for register, base_url=nil, all: false, page_size: 100
      url = url_for('records', register, base_url)
      retrieve url, register, base_url, all, page_size
    end

    def record register, record, base_url=nil
      url = url_for "record/#{record}", register, base_url
      retrieve(url, register, base_url).first
    end

    def field record, base_url=nil
      @fields ||= {}
      key = "#{record}-#{base_url}"
      @fields[key] ||= record('field', record, base_url)
    end

    private

    include OpenRegister::Helpers

    def set_morph_listener base_url
      @listeners ||= {}
      @listeners[base_url] ||= OpenRegister::MorphListener.new base_url
      Morph.register_listener @listeners[base_url]
      @morph_listener_set = true
    end

    def unset_morph_listener base_url
      Morph.unregister_listener @listeners[base_url]
      @morph_listener_set = false
    end

    def augment_register_fields base_url, &block
      already_set = (@morph_listener_set || false)
      set_morph_listener(base_url) unless already_set
      list = yield
      unset_morph_listener(base_url) unless already_set
      list
    end

    def retrieve url, type, base_url, all=false, page_size=100
      list = augment_register_fields(base_url) do
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
      list.each { |item| item._base_url = base_url } if base_url
      list.each { |item| convert_n_cardinality_data! item }
      list
    end

    def convert_n_cardinality_data! item
      return if item.is_a?(OpenRegister::Field)
      base_url = item.try(:_base_url)
      attributes = item.class.morph_attributes
      cardinality_n_fields = attributes.select do |symbol|
        !is_entry_resource_field?(symbol) &&
          !augmented_field?(symbol) &&
          (field = field(field_name(symbol), base_url)) &&
          cardinality_n?(field)
      end
      cardinality_n_fields.each do |symbol|
        item.send(symbol) # convert string to list
      end
    end

    def url_for path, register, base_url
      if base_url
        host = base_url.sub('register', register.to_s).chomp('/')
        "#{host}/#{path}"
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

  def initialize base_url
    @base_url = base_url || nil
  end

  def call klass, symbol
    return if @handling && @handling == [klass, symbol]
    @handling = [klass, symbol]
    if !register_or_field_class?(klass, symbol) && !is_entry_resource_field?(symbol) && !augmented_field?(symbol)
      add_method_to_access_field_record klass, symbol
    end
  end

  private

  include OpenRegister::Helpers

  def register_or_field_class? klass, symbol
    klass.name == 'OpenRegister::Field' || (klass.name == 'OpenRegister::Register' && symbol != :fields)
  end

  def field symbol
    OpenRegister::field field_name(symbol), @base_url
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
               curie_retrieve_method(symbol)
             elsif cardinality_n? field
               n_split_method(symbol)
             elsif register = register_for_field(field)
               retrieve_method(symbol, register)
             end
    klass.class_eval method if method
  end

  def n_split_method symbol
    "def #{symbol}
  @#{symbol} = @#{symbol}.split(';') if @#{symbol} && !@#{symbol}.is_a?(Array)
  @#{symbol}
end"
  end

  def curie_retrieve_method symbol
    method = "_#{symbol}"
    instance_variable = "@#{method}"
    "def #{method}
  unless #{instance_variable}
    curie = send(:#{symbol}).split(':')
    register = curie.first
    field = curie.last
    #{instance_variable} = OpenRegister.record(register, field, _base_url)
  end
  #{instance_variable}
end"
  end

  def retrieve_method symbol, register
    method = "_#{symbol}"
    instance_variable = "@#{method}"
    "def #{method}
  #{instance_variable} ||= OpenRegister.record('#{register}', send(:#{symbol}), _base_url)
end"
  end

end
