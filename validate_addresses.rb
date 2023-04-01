require 'bundler/setup'
Bundler.require(:default)
require_relative "lib/address_csv_transformer"
require_relative "lib/address_verification_client"

client = AddressVerificationClient.new(
  auth_id: ENV.fetch("SMARTY_AUTH_ID"),
  auth_token: ENV.fetch("SMARTY_AUTH_TOKEN")
)


transformer = AddressCSVTransformer.new(
  input_stream: ARGF.to_io,
  client: client
)

transformer.validate!

transformer.validated_results.values.lazy.each do |result|
  puts result
end