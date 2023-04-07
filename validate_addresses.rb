require 'bundler/setup'
Bundler.require(:default)
require_relative "lib/cached_single_address_lookup"
require_relative "lib/address_csv_transformer"
require_relative "lib/address_verification_client"

client = AddressVerificationClient.new(
  auth_id: ENV.fetch("SMARTY_AUTH_ID"),
  auth_token: ENV.fetch("SMARTY_AUTH_TOKEN")
)

cache_stream = File.open('cached_lookups.json', 'r+')

address_lookup = CachedSingleAddressLookup.new(
  cache_stream: cache_stream, client: client
)

transformer = AddressCSVTransformer.new(
  input_stream: ARGF.to_io,
  address_lookup: address_lookup
)

transformer.validate!

transformer.validated_results.values.lazy.each do |result|
  puts result
end