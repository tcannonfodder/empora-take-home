# frozen_string_literal: true

class CachedSingleAddressLookup
  attr_accessor :cache_stream
  attr_reader :cached_validated_results, :client

  def input_id(street:, city:, zip_code:)
    client.class.input_id(street: street, city: city, zip_code: zip_code)
  end

  def initialize(cache_stream:, client:)
    @client = client
    self.cache_stream = cache_stream
  end

  def cached_validated_results
    return @cached_validated_results unless @cached_validated_results.nil?

    cache_data = cache_stream.read

    if cache_data.empty?
      @cached_validated_results = {}
    else
      @cached_validated_results = JSON.parse(cache_data, {symbolize_names: true})
    end
    return @cached_validated_results
  end

  def cached_lookup(street:, city:, zip_code:)
    row_key = client.class.input_id(street: street, city: city, zip_code: zip_code)

    if cached_validated_results.has_key?(row_key)
      return cached_validated_results[row_key]
    end

    client.add_lookup(street: street, city: city, zip_code: zip_code)
    client.load_results

    lookup = client.batch.first

    if lookup.result.empty?
      validated_result = :"Invalid Address"
    else
      validated_address = lookup.result.first

      address = [validated_address.delivery_line_1, validated_address.delivery_line_2]
      city = validated_address.components.city_name
      zip_code = [validated_address.components.zipcode, validated_address.components.plus4_code].compact.join('-')

      validated_result = [address, city, zip_code].flatten.compact.join(', ')
    end

    cached_validated_results[row_key] = validated_result
    client.batch.clear

    return validated_result
  end

  def write_cache!
    IO.write(cache_stream, JSON.generate(cached_validated_results))
  end
end