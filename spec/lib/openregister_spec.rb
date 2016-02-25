require_relative '../../lib/openregister'

RSpec.describe OpenRegister do

  before do
    stub_request(:get, "https://register.register.gov.uk/records.json").
      to_return(status: 200,
        body: File.new('./spec/fixtures/register-records.json'),
        headers: {})
  end

  describe 'retrieve registers index' do
    it 'returns array of Ruby objects' do
      records = OpenRegister.registers
      expect(records).to be_an(Array)
      records.each { |r| expect(r).to be_an('OpenRegister::Register'.constantize) }
    end
  end

  shared_examples 'has attributes' do |hash|
    hash.each do |attribute, value|
      it { is_expected.to have_attributes(attribute => value) }
    end
  end

  describe 'retrieved record' do
    subject { OpenRegister.registers[1] }

    include_examples 'has attributes', {
      serial_number: 9,
      _hash: '247cf017d1b91ca8e0cd3abb60712224c6fa2b03',
      fields: ['country', 'name', 'official-name', 'citizen-names', 'start-date', 'end-date'],
      phase: 'alpha',
      register: 'country',
      registry: 'foreign-commonwealth-office',
      text: 'British English-language names and descriptive terms for countries'
    }
  end
end
