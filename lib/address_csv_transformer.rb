# frozen_string_literal: true

require 'csv'

class AddressCSVTransformer
  attr_accessor :input_stream, :output_stream
  attr_reader :client, :parsed_csv, :validated_results

  def initialize(input_stream:, smarty_auth_id:, smarty_auth_token:, max_batch_size: 100)
    @client = AddressVerificationClient.new(
      auth_id: smarty_auth_id,
      auth_token: smarty_auth_token,
      max_batch_size: max_batch_size
    )
    self.input_stream = input_stream
  end

  def validate!
    original_rows = {}
    parsed_csv.each_slice(client.max_batch_size).each do |row_batch|
      row_batch.each do |row|
        row_key = client.class.input_id(street: row[:street], city: row[:city], zip_code: row[:zip_code])
        original_rows[row_key] = row.to_s.strip
        client.add_lookup(street: row[:street], city: row[:city], zip_code: row[:zip_code])
      end

      client.load_results
      client.batch.each do |lookup|
        original_row = original_rows[lookup.input_id]

        if lookup.result.empty?
          validated_result = :"Invalid Address"
        else
          validated_address = lookup.result.first

          address = [validated_address.delivery_line_1, validated_address.delivery_line_2]
          city = validated_address.components.city_name
          zip_code = [validated_address.components.zipcode, validated_address.components.plus4_code].join('-')

          validated_result = [address, city, zip_code].flatten.compact.join(', ')
        end

        validated_results[lookup.input_id] = [original_row, validated_result].join(' -> ')
      end

      client.batch.clear
    end

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
end