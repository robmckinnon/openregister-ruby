require 'morph'
require 'rest-client'

module OpenRegister
  VERSION = '0.0.1' unless defined? OpenRegister::VERSION
end

class OpenRegister::Register
  include Morph
  def _all_records page_size: 100
    OpenRegister::records_for register.to_sym, try(:_base_url_or_phase), all: true, page_size: page_size
  end

  def _records
    OpenRegister::records_for register.to_sym, try(:_base_url_or_phase)
  end

  def _fields
    fields.map do |field|
      OpenRegister.field field.to_sym, try(:_base_url_or_phase)
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

    def registers base_url_or_phase=nil
      registers = records_for :register, base_url_or_phase, all: true
      registers.each do |r|
        r._uri = url_for('', r.register, base_url_or_phase)
      end if registers
      registers
    end

    def register register, base_url_or_phase=nil
      registers(base_url_or_phase).detect{ |r| r.register == register }
    end

    def records_for register, base_url_or_phase=nil, all: false, page_size: 100
      url = url_for('records', register, base_url_or_phase)
      retrieve url, register, base_url_or_phase, all, page_size
    end

    def record register, record, base_url_or_phase=nil
      url = url_for "record/#{record}", register, base_url_or_phase
      retrieve(url, register, base_url_or_phase).first
    end

    def field record, base_url_or_phase=nil
      @fields ||= {}
      key = "#{record}-#{base_url_or_phase}"
      @fields[key] ||= record('field', record, base_url_or_phase)
    end

    private

    include OpenRegister::Helpers

    def set_morph_listener base_url_or_phase
      @listeners ||= {}
      @listeners[base_url_or_phase] ||= OpenRegister::MorphListener.new base_url_or_phase
      Morph.register_listener @listeners[base_url_or_phase]
      @morph_listener_set = true
    end

    def unset_morph_listener base_url_or_phase
      Morph.unregister_listener @listeners[base_url_or_phase]
      @morph_listener_set = false
    end

    def augment_register_fields base_url_or_phase, &block
      already_set = (@morph_listener_set || false)
      set_morph_listener(base_url_or_phase) unless already_set
      list = yield
      unset_morph_listener(base_url_or_phase) unless already_set
      list
    end

    def retrieve uri, type, base_url_or_phase, all=false, page_size=100
      list = augment_register_fields(base_url_or_phase) do
        url = "#{uri}.tsv"
        url = "#{url}?page-index=1&page-size=#{page_size}" if page_size != 100
        results = []
        response_list(url, all) do |tsv|
          items = Morph.from_tsv(tsv, type, OpenRegister)
          items.each {|item| results.push item }
          nil
        end
        results
      end
      list.each { |item| item._base_url_or_phase = base_url_or_phase } if base_url_or_phase
      list.each { |item| item._uri = uri if uri[/\/record\//] }
      list.each { |item| convert_n_cardinality_data! item }
      list
    end

    def convert_n_cardinality_data! item
      return if item.is_a?(OpenRegister::Field)
      base_url_or_phase = item.try(:_base_url_or_phase)
      attributes = item.class.morph_attributes
      cardinality_n_fields = attributes.select do |symbol|
        !is_entry_resource_field?(symbol) &&
          !augmented_field?(symbol) &&
          (field = field(field_name(symbol), base_url_or_phase)) &&
          cardinality_n?(field)
      end
      cardinality_n_fields.each do |symbol|
        item.send(symbol) # convert string to list
      end
    end

    def url_for path, register, base_url_or_phase
      if base_url_or_phase
        host = case base_url_or_phase
               when Symbol
                 "http://#{register}.#{base_url_or_phase}.openregister.org"
               when String
                 base_url_or_phase.sub('register', register.to_s).chomp('/')
               end
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

  def initialize base_url_or_phase
    @base_url_or_phase = base_url_or_phase || nil
  end

  def call klass, symbol
    return if @handling && @handling == [klass, symbol]
    @handling = [klass, symbol]
    add_register_accessor! klass unless klass.respond_to? :register

    if !register_or_field_class?(klass, symbol) && !is_entry_resource_field?(symbol) && !augmented_field?(symbol)
      add_method_to_access_field_record klass, symbol
    end
  end

  private

  include OpenRegister::Helpers

  def add_register_accessor! klass
    register_name = klass.name.sub('OpenRegister::','').gsub(/([a-z])([A-Z])/, '\1-\2').downcase
    klass.class_eval("def self.register; '#{register_name}'; end")
    klass.class_eval("def self._register(base_url_or_phase); OpenRegister.record('register', register, base_url_or_phase); end")
    klass.class_eval("def _register; self.class._register(_base_url_or_phase); end")
    klass.class_eval("def _register_fields; self.class._register(_base_url_or_phase)._fields; end")
  end

  def register_or_field_class? klass, symbol
    klass.register == 'field' || (klass.name == 'register' && symbol != :fields)
  end

  def field symbol
    OpenRegister::field field_name(symbol), @base_url_or_phase
  end

  def datatype_curie? field
    field && field.datatype == 'curie'
  end

  def register_for_field field
    field.register if field && field.register && field.register.size > 0
  end

  def add_method_to_access_field_record klass, symbol
    field = field(symbol)
    methods = if datatype_curie? field
               curie_retrieve_method(symbol)
             elsif cardinality_n? field
               n_split_methods(symbol, field)
             elsif register = register_for_field(field)
               retrieve_method(symbol, register)
             end
    methods.each {|method| klass.class_eval method} if methods
  end

  def n_split_methods symbol, field
    methods = ["def #{symbol}
  @#{symbol} = @#{symbol}.split(';') if @#{symbol} && !@#{symbol}.is_a?(Array)
  @#{symbol}
end"]
    if register = register_for_field(field)
      method = "_#{symbol}"
      instance_variable = "@#{method}"
      methods << "
def #{method}
  unless #{instance_variable}
    #{instance_variable} = #{symbol}.map {|code| OpenRegister.record('#{field.register}', code, _base_url_or_phase) }
  end
  #{instance_variable}
end"
    end
    methods
  end

  def curie_retrieve_method symbol
    method = "_#{symbol}"
    instance_variable = "@#{method}"
    ["def #{method}
  unless #{instance_variable}
    curie = send(:#{symbol}).split(':')
    register = curie.first
    field = curie.last
    #{instance_variable} = OpenRegister.record(register, field, _base_url_or_phase)
  end
  #{instance_variable}
end"]
  end

  def retrieve_method symbol, register
    method = "_#{symbol}"
    instance_variable = "@#{method}"
    ["def #{method}
  #{instance_variable} ||= OpenRegister.record('#{register}', send(:#{symbol}), _base_url_or_phase)
end"]
  end

end
