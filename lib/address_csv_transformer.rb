# frozen_string_literal: true

require 'csv'

class AddressCSVTransformer
  attr_accessor :input_stream, :output_stream
  attr_reader :address_lookup, :parsed_csv, :validated_results

  def initialize(input_stream:, address_lookup:)
    @address_lookup = address_lookup
    @validated_results = {}
    self.input_stream = input_stream
  end

  def validate!
    parsed_csv.lazy.each do |row|
      validate_row!(row: row)
    end

    address_lookup.write_cache!

    return validated_results
  end

  def validated_results
    @validated_results ||= {}
  end

  def parsed_csv
    return @parsed_csv unless @parsed_csv.nil?
    @parsed_csv = CSV.parse(input_stream, headers: true, header_converters: :symbol)
    @parsed_csv.by_row!
    return @parsed_csv
  end

  protected

  def validate_row!(row:)
    input_id = address_lookup.input_id(street: row[:street], city: row[:city], zip_code: row[:zip_code])
    original_row = row.to_s.strip

    validated_result = address_lookup.cached_lookup(street: row[:street], city: row[:city], zip_code: row[:zip_code])

    validated_results[input_id] = [original_row, validated_result].join(' -> ')
  end
end