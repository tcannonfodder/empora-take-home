require "test_helper"
require_relative "test_helper/smarty_request_mocks"

class AddressVerificationClientTest < Minitest::Test
  include SmartyRequestMocks
  def assert_lookup_details(expected_input_id:, expected_freeform_street:, lookup:)
    assert_equal expected_input_id, lookup.input_id
    assert_equal expected_freeform_street, lookup.street
    assert_equal 1, lookup.candidates
    assert_equal SmartyStreets::USStreet::MatchType::STRICT, lookup.match
  end

  test "input_id: builds a 32-character max string key for an address" do
    expected = "143 e Maine StreetColumbus43215"
    assert_equal expected, AddressVerificationClient.input_id(street: "143 e Maine Street", city: "Columbus", zip_code: "43215")

    expected = "143 east Maine StreetColumbus432"

    assert_equal expected, AddressVerificationClient.input_id(street: "143 east Maine Street", city: "Columbus", zip_code: "43215")
  end

  test "add_lookup: Adds a new lookup using the freeform_street format" do
    expected_input_id = "143 e Maine StreetColumbus43215"
    expected_freeform_street = "143 e Maine Street, Columbus, 43215"

    client = AddressVerificationClient.new(auth_id: "abcd1234", auth_token: "2122222")
    client.add_lookup(street: "143 e Maine Street", city: "Columbus", zip_code: "43215")

    lookup = client.batch.get_by_input_id(expected_input_id)

    assert_lookup_details(expected_input_id: expected_input_id, expected_freeform_street: expected_freeform_street, lookup: lookup)
  end

  test "add_lookup: Adds a new lookup using the freeform_street format with a combined 2-line address" do
    expected_input_id = "143 e Maine Street Suite AColumb"
    expected_freeform_street = "143 e Maine Street Suite A, Columbus, 43215"

    client = AddressVerificationClient.new(auth_id: "abcd1234", auth_token: "2122222")
    client.add_lookup(street: "143 e Maine Street Suite A", city: "Columbus", zip_code: "43215")

    lookup = client.batch.get_by_input_id(expected_input_id)

    assert_lookup_details(expected_input_id: expected_input_id, expected_freeform_street: expected_freeform_street, lookup: lookup)
  end


  test "add_lookup: Adds a new lookup using the freeform_street format with a zip +4 code" do
    expected_input_id = "25 Draper St.Greenville22222-234"
    expected_freeform_street = "25 Draper St., Greenville, 22222-2345"

    client = AddressVerificationClient.new(auth_id: "abcd1234", auth_token: "2122222")
    client.add_lookup(street: "25 Draper St.", city: "Greenville", zip_code: "22222-2345")

    lookup = client.batch.get_by_input_id(expected_input_id)

    assert_lookup_details(expected_input_id: expected_input_id, expected_freeform_street: expected_freeform_street, lookup: lookup)
  end

  test "add_lookup: Adds a new lookup using the freeform_street format with a city + state combo" do
    expected_input_id = "25 Draper St.Greenville, SC22222"
    expected_freeform_street = "25 Draper St., Greenville, SC, 22222"

    client = AddressVerificationClient.new(auth_id: "abcd1234", auth_token: "2122222")
    client.add_lookup(street: "25 Draper St.", city: "Greenville, SC", zip_code: "22222")

    lookup = client.batch.get_by_input_id(expected_input_id)

    assert_lookup_details(expected_input_id: expected_input_id, expected_freeform_street: expected_freeform_street, lookup: lookup)
  end

  test "add_lookup: Adds a new lookup with a truncated input_id" do
    expected_input_id = "143 east Maine StreetColumbus432"
    expected_freeform_street = "143 east Maine Street, Columbus, 43215"

    client = AddressVerificationClient.new(auth_id: "abcd1234", auth_token: "2122222")
    client.add_lookup(street: "143 east Maine Street", city: "Columbus", zip_code: "43215")

    lookup = client.batch.get_by_input_id(expected_input_id)

    assert_lookup_details(expected_input_id: expected_input_id, expected_freeform_street: expected_freeform_street, lookup: lookup)
  end

  test "add_lookup: Does not add duplicate lookups" do
    expected_input_id = "143 e Maine StreetColumbus43215"
    expected_freeform_street = "143 e Maine Street, Columbus, 43215"

    client = AddressVerificationClient.new(auth_id: "abcd1234", auth_token: "2122222")
    client.add_lookup(street: "143 e Maine Street", city: "Columbus", zip_code: "43215")

    lookup = client.batch.get_by_input_id(expected_input_id)

    assert_equal 99, client.remaining_batch_size

    assert_lookup_details(expected_input_id: expected_input_id, expected_freeform_street: expected_freeform_street, lookup: lookup)

    client.add_lookup(street: "143 e Maine Street", city: "Columbus", zip_code: "43215")

    client.batch.get_by_input_id(expected_input_id)
    assert_equal 99, client.remaining_batch_size
  end

  test "add_lookup: Raises BatchTooLarge if can_add_lookup? is false" do
    client = AddressVerificationClient.new(auth_id: "abcd1234", auth_token: "2122222")

    client.expects(:can_add_lookup?).once.returns(false)

    assert_raises AddressVerificationClient::BatchFull do
      client.add_lookup(street: "143 e Maine Street", city: "Columbus", zip_code: "43215")
    end
  end

  test "add_lookup: Raises BatchTooLarge if batch.full? returns true" do
    client = AddressVerificationClient.new(auth_id: "abcd1234", auth_token: "2122222")

    client.batch.expects(:full?).once.returns(true)

    assert_raises AddressVerificationClient::BatchFull do
      client.add_lookup(street: "143 e Maine Street", city: "Columbus", zip_code: "43215")
    end
  end

  test "remaining_batch_size, can_add_lookup?" do
    client = AddressVerificationClient.new(auth_id: "abcd1234", auth_token: "2122222")

    default_max = SmartyStreets::Batch::MAX_BATCH_SIZE
    assert_equal true, default_max > 0

    assert_equal true, client.can_add_lookup?

    (default_max - 1).times do |n|
      assert_equal (default_max - n), client.remaining_batch_size
      client.add_lookup(street: "#{n} Main Street", city: "Columbia", zip_code: "11111")

      assert_equal (default_max - (n + 1)), client.remaining_batch_size
      assert_equal true, client.can_add_lookup?
    end

    client.add_lookup(street: "#{default_max} Main Street", city: "Columbia", zip_code: "11111")
    assert_equal 0, client.remaining_batch_size
    assert_equal false, client.can_add_lookup?
  end

  test "remaining_batch_size: custom max_batch_size, can_add_lookup?" do
    client = AddressVerificationClient.new(auth_id: "abcd1234", auth_token: "2122222", max_batch_size: 20)

    19.times do |n|
      assert_equal (20 - n), client.remaining_batch_size
      client.add_lookup(street: "#{n} Main Street", city: "Columbia", zip_code: "11111")

      assert_equal (20 - (n + 1)), client.remaining_batch_size
      assert_equal true, client.can_add_lookup?
    end

    client.add_lookup(street: "20 Main Street", city: "Columbia", zip_code: "11111")
    assert_equal 0, client.remaining_batch_size
    assert_equal false, client.can_add_lookup?
  end

  test "load_results: loads a single lookup as a GET request" do
    stub_request(:get,
      "https://us-street.api.smartystreets.com/street-address?addressee&auth-id=abcd1234&auth-token=2122222&candidates=1&city&input_id=25%20Draper%20St.Greenville22222&lastline&license=us-core-cloud&match=strict&secondary&state&street=25%20Draper%20St.,%20Greenville,%2022222&street2&urbanization&zipcode"
    ).to_return(status: 200, body: draper_street_lookup_response.to_json)


    client = AddressVerificationClient.new(auth_id: "abcd1234", auth_token: "2122222")
    client.add_lookup(street: "25 Draper St.", city: "Greenville", zip_code: "22222")

    client.load_results

    assert_equal 1, client.batch.size

    assert_equal "25 Draper Street", client.batch[0].result.first.delivery_line_1
    assert_nil client.batch[0].result.first.delivery_line_2
    assert_equal "Greenville", client.batch[0].result.first.components.city_name
    assert_equal "22222", client.batch[0].result.first.components.zipcode
    assert_equal "6542", client.batch[0].result.first.components.plus4_code
  end

  test "load_results: loads a single lookup as a GET request, returning an empty array if there are no results" do
    stub_request(:get,
      "https://us-street.api.smartystreets.com/street-address?addressee&auth-id=abcd1234&auth-token=2122222&candidates=1&city&input_id=25%20Draper%20St.Greenville22222&lastline&license=us-core-cloud&match=strict&secondary&state&street=25%20Draper%20St.,%20Greenville,%2022222&street2&urbanization&zipcode"
    ).to_return(status: 200, body: [].to_json)


    client = AddressVerificationClient.new(auth_id: "abcd1234", auth_token: "2122222")
    client.add_lookup(street: "25 Draper St.", city: "Greenville", zip_code: "22222")

    client.load_results

    assert_equal 1, client.batch.size

    assert_empty client.batch[0].result
  end

  test "load_results: loads a batch of lookups as a POST request" do
    stub_request(:post, "https://us-street.api.smartystreets.com/street-address?auth-id=abcd1234&auth-token=2122222&license=us-core-cloud")
      .with(body: north_pole_and_apple_request_payload.to_json)
      .to_return(status: 200, body: north_pole_and_apple_response.to_json)

    client = AddressVerificationClient.new(auth_id: "abcd1234", auth_token: "2122222")
    client.add_lookup(street: "1 Santa Claus", city: "North Pole", zip_code: "99705")
    client.add_lookup(street: "1 Infinite Loop", city: "cupertino", zip_code: "95014")

    client.load_results

    assert_equal 2, client.batch.size

    assert_equal "1 Santa Claus Ln", client.batch[0].result.first.delivery_line_1
    assert_nil client.batch[0].result.first.delivery_line_2
    assert_equal "North Pole", client.batch[0].result.first.components.city_name
    assert_equal "99705", client.batch[0].result.first.components.zipcode
    assert_equal "9901", client.batch[0].result.first.components.plus4_code

    assert_equal "1 Infinite Loop", client.batch[1].result.first.delivery_line_1
    assert_nil client.batch[1].result.first.delivery_line_2
    assert_equal "Cupertino", client.batch[1].result.first.components.city_name
    assert_equal "95014", client.batch[1].result.first.components.zipcode
    assert_equal "2083", client.batch[1].result.first.components.plus4_code
  end

  test "load_results: loads a batch of lookups as a POST request with an empty resultset" do
    only_one_result = [north_pole_and_apple_response.first]

    stub_request(:post, "https://us-street.api.smartystreets.com/street-address?auth-id=abcd1234&auth-token=2122222&license=us-core-cloud")
      .with(body: north_pole_and_apple_request_payload.to_json)
      .to_return(status: 200, body: only_one_result.to_json)

    client = AddressVerificationClient.new(auth_id: "abcd1234", auth_token: "2122222")
    client.add_lookup(street: "1 Santa Claus", city: "North Pole", zip_code: "99705")
    client.add_lookup(street: "1 Infinite Loop", city: "cupertino", zip_code: "95014")

    client.load_results

    assert_equal 2, client.batch.size

    assert_equal "1 Santa Claus Ln", client.batch[0].result.first.delivery_line_1
    assert_nil client.batch[0].result.first.delivery_line_2
    assert_equal "North Pole", client.batch[0].result.first.components.city_name
    assert_equal "99705", client.batch[0].result.first.components.zipcode
    assert_equal "9901", client.batch[0].result.first.components.plus4_code

    assert_empty client.batch[1].result
  end

  test "load_results: raises BadCredentialsError if the API request returns 401" do
    stub_request(:get,
      "https://us-street.api.smartystreets.com/street-address?addressee&auth-id=abcd1234&auth-token=2122222&candidates=1&city&input_id=25%20Draper%20St.Greenville22222&lastline&license=us-core-cloud&match=strict&secondary&state&street=25%20Draper%20St.,%20Greenville,%2022222&street2&urbanization&zipcode"
    ).to_return(status: 401)


    client = AddressVerificationClient.new(auth_id: "abcd1234", auth_token: "2122222")
    client.add_lookup(street: "25 Draper St.", city: "Greenville", zip_code: "22222")

    assert_raises SmartyStreets::BadCredentialsError do
      client.load_results
    end
  end

  test "load_results: raises UnprocessableEntityError if the API request returns 422" do
    stub_request(:get,
      "https://us-street.api.smartystreets.com/street-address?addressee&auth-id=abcd1234&auth-token=2122222&candidates=1&city&input_id=25%20Draper%20St.Greenville22222&lastline&license=us-core-cloud&match=strict&secondary&state&street=25%20Draper%20St.,%20Greenville,%2022222&street2&urbanization&zipcode"
    ).to_return(status: 422)


    client = AddressVerificationClient.new(auth_id: "abcd1234", auth_token: "2122222")
    client.add_lookup(street: "25 Draper St.", city: "Greenville", zip_code: "22222")

    assert_raises SmartyStreets::UnprocessableEntityError do
      client.load_results
    end
  end
end
