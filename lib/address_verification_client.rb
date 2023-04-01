# frozen_string_literal: true
require 'debug'
require 'smartystreets_ruby_sdk'

class AddressVerificationClient
  class BatchFull < StandardError; end

  attr_reader :smarty_client, :credentials, :batch, :max_batch_size

  def initialize(auth_id:, auth_token:, max_batch_size: 100)
    @max_batch_size = [max_batch_size, SmartyStreets::Batch::MAX_BATCH_SIZE].min
    @credentials = SmartyStreets::StaticCredentials.new(auth_id, auth_token)
    @batch ||= SmartyStreets::Batch.new
  end

  def add_lookup(street:, city:, zip_code:)
    freeform_street = [street, city, zip_code].join(', ')
    input_id = self.class.input_id(street: street, city: city, zip_code: zip_code)

    return batch.get_by_input_id(input_id) unless batch.get_by_input_id(input_id).nil?
    raise BatchTooLarge if !can_add_lookup? || batch.full?

    lookup = SmartyStreets::USStreet::Lookup.new
    lookup.input_id = input_id
    lookup.street = freeform_street
    lookup.candidates = 1
    lookup.match = SmartyStreets::USStreet::MatchType::STRICT

    return batch.add(lookup)
  end

  def remaining_batch_size
    max_batch_size - self.batch.size
  end

  def can_add_lookup?
    remaining_batch_size > 0
  end

  def load_results
    client.send_batch(batch)
    return batch
  end

  def self.input_id(street:, city:, zip_code:)
    [street, city, zip_code].join[...32]
  end

  protected

  def client
    @smarty_client ||= SmartyStreets::ClientBuilder.new(self.credentials)
                                            .with_licenses(['us-core-cloud'])
                                            .build_us_street_api_client
  end
end