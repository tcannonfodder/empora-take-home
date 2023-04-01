require "test_helper"

class AddressCSVTransformerTest < Minitest::Test
  def build_lookup_with_result(input_id:, candidate_data:)
    lookup = SmartyStreets::USStreet::Lookup.new
    lookup.input_id = input_id
    lookup.candidates = 1
    lookup.match = SmartyStreets::USStreet::MatchType::STRICT

    unless candidate_data.nil?
      lookup.result.push(SmartyStreets::USStreet::Candidate.new(candidate_data))
    end

    return lookup
  end

  test "sets up the client with the given smarty_auth_id and smarty_auth_token, a default max_batch_size of 100" do
    AddressVerificationClient.expects(:new).once.with(auth_id: "abcd1234", auth_token: "12222", max_batch_size: 100)
    transformer = AddressCSVTransformer.new(input_stream: StringIO.new, smarty_auth_id: "abcd1234", smarty_auth_token: "12222")
  end

  test "sets up the client with the given smarty_auth_id and smarty_auth_token, and custom max_batch_size" do
    AddressVerificationClient.expects(:new).once.with(auth_id: "abcd1234", auth_token: "12222", max_batch_size: 20)
    transformer = AddressCSVTransformer.new(input_stream: StringIO.new, smarty_auth_id: "abcd1234", smarty_auth_token: "12222", max_batch_size: 20)
  end

  test "stores the input_stream" do
    stream = StringIO.new(<<~CSV
      Street, City, Zip Code
      143 e Maine Street, Columbus, 43215
      1 Empora St, Title, 11111
    CSV
    )
    transformer = AddressCSVTransformer.new(input_stream: stream, smarty_auth_id: "abcd1234", smarty_auth_token: "12222")

    assert_equal stream, transformer.input_stream
  end

  test "validate!: adds lookups for each row in the CSV, checking the validated results and returning them" do
    stream = StringIO.new(<<~CSV
      Street, City, Zip Code
      143 e Maine Street, Columbus, 43215
      1 Infinite Loop, cupertino, 95014
      25 Draper St., Greenville SC, 22222
      1 Empora St, Title, 11111
      25 Draper St.,"Greenville, SC", 22222
    CSV
    )

    transformer = AddressCSVTransformer.new(input_stream: stream, smarty_auth_id: "abcd1234", smarty_auth_token: "12222")

    transformer.client.expects(:add_lookup).with(street: "143 e Maine Street", city: " Columbus", zip_code: " 43215")
    transformer.client.expects(:add_lookup).with(street: "1 Infinite Loop", city: " cupertino", zip_code: " 95014")
    transformer.client.expects(:add_lookup).with(street: "25 Draper St.", city: " Greenville SC", zip_code: " 22222")
    transformer.client.expects(:add_lookup).with(street: "1 Empora St", city: " Title", zip_code: " 11111")
    transformer.client.expects(:add_lookup).with(street: "25 Draper St.", city: "Greenville, SC", zip_code: " 22222")

    transformer.client.expects(:load_results).once.returns(true)

    input_id_1 = AddressVerificationClient.input_id(street: "143 e Maine Street", city: " Columbus", zip_code: " 43215")
    lookup_1 = build_lookup_with_result(input_id: input_id_1, candidate_data: {
      "candidate_index" => 0,
      "delivery_line_1" => "143 East Main Street",
      "components" => {
        "city_name" => "Columbus",
        "zipcode" => "43215",
        "plus4_code" => nil
      }
    })

    input_id_2 = AddressVerificationClient.input_id(street: "1 Infinite Loop", city: " cupertino", zip_code: " 95014")
    lookup_2 = build_lookup_with_result(input_id: input_id_2, candidate_data: {
      "candidate_index" => 0,
      "delivery_line_1" => "1 Infinite Loop",
      "components" => {
        "city_name" => "Cupertino",
        "zipcode" => "95014",
        "plus4_code" => "2083"
      }
    })

    input_id_3 = AddressVerificationClient.input_id(street: "25 Draper St.", city: " Greenville SC", zip_code: " 22222")
    lookup_3 = build_lookup_with_result(input_id: input_id_3, candidate_data: {
      "candidate_index" => 0,
      "delivery_line_1" => "25 Draper St.",
      "components" => {
        "city_name" => "Greenville",
        "zipcode" => "22222",
        "plus4_code" => "6542"
      }
    })

    input_id_4 = AddressVerificationClient.input_id(street: "1 Empora St", city: " Title", zip_code: " 11111")
    lookup_4 = build_lookup_with_result(input_id: input_id_4, candidate_data: nil)

    transformer.client.stubs(:batch).returns([lookup_1, lookup_2, lookup_3, lookup_4])

    transformer.validate!

    assert_equal "143 e Maine Street, Columbus, 43215 -> 143 East Main Street, Columbus, 43215", transformer.validated_results[input_id_1]
    assert_equal "1 Infinite Loop, cupertino, 95014 -> 1 Infinite Loop, Cupertino, 95014-2083", transformer.validated_results[input_id_2]
    assert_equal "25 Draper St., Greenville SC, 22222 -> 25 Draper St., Greenville, 22222-6542", transformer.validated_results[input_id_3]
    assert_equal "1 Empora St, Title, 11111 -> Invalid Address", transformer.validated_results[input_id_4]
  end

  test "validate!: processes the results in the batches supported by the client" do
    stream = StringIO.new(<<~CSV
      Street, City, Zip Code
      143 e Maine Street, Columbus, 43215
      1 Infinite Loop, cupertino, 95014
      25 Draper St., Greenville SC, 22222
      1 Empora St, Title, 11111
      25 Draper St.,"Greenville, SC", 22222
    CSV
    )

    transformer = AddressCSVTransformer.new(input_stream: stream, smarty_auth_id: "abcd1234", smarty_auth_token: "12222", max_batch_size: 2)

    slices = transformer.parsed_csv.lazy.each_slice(2).to_a

    transformer.expects(:validate_batch!).with(row_batch: slices[0])
    transformer.expects(:validate_batch!).with(row_batch: slices[1])
    transformer.expects(:validate_batch!).with(row_batch: slices[2])

    transformer.validate!
  end

  test "validated_results is cached" do
    stream = StringIO.new(<<~CSV
      Street, City, Zip Code
      143 e Maine Street, Columbus, 43215
      1 Infinite Loop, cupertino, 95014
      25 Draper St., Greenville SC, 22222
      1 Empora St, Title, 11111
      25 Draper St.,"Greenville, SC", 22222
    CSV
    )

    transformer = AddressCSVTransformer.new(input_stream: stream, smarty_auth_id: "abcd1234", smarty_auth_token: "12222")

    transformer.client.expects(:add_lookup).with(street: "143 e Maine Street", city: " Columbus", zip_code: " 43215")
    transformer.client.expects(:add_lookup).with(street: "1 Infinite Loop", city: " cupertino", zip_code: " 95014")
    transformer.client.expects(:add_lookup).with(street: "25 Draper St.", city: " Greenville SC", zip_code: " 22222")
    transformer.client.expects(:add_lookup).with(street: "1 Empora St", city: " Title", zip_code: " 11111")
    transformer.client.expects(:add_lookup).with(street: "25 Draper St.", city: "Greenville, SC", zip_code: " 22222")

    transformer.client.expects(:load_results).once.returns(true)

    input_id_1 = AddressVerificationClient.input_id(street: "143 e Maine Street", city: " Columbus", zip_code: " 43215")
    lookup_1 = build_lookup_with_result(input_id: input_id_1, candidate_data: {
      "candidate_index" => 0,
      "delivery_line_1" => "143 East Main Street",
      "components" => {
        "city_name" => "Columbus",
        "zipcode" => "43215",
        "plus4_code" => nil
      }
    })

    input_id_2 = AddressVerificationClient.input_id(street: "1 Infinite Loop", city: " cupertino", zip_code: " 95014")
    lookup_2 = build_lookup_with_result(input_id: input_id_2, candidate_data: {
      "candidate_index" => 0,
      "delivery_line_1" => "1 Infinite Loop",
      "components" => {
        "city_name" => "Cupertino",
        "zipcode" => "95014",
        "plus4_code" => "2083"
      }
    })

    input_id_3 = AddressVerificationClient.input_id(street: "25 Draper St.", city: " Greenville SC", zip_code: " 22222")
    lookup_3 = build_lookup_with_result(input_id: input_id_3, candidate_data: {
      "candidate_index" => 0,
      "delivery_line_1" => "25 Draper St.",
      "components" => {
        "city_name" => "Greenville",
        "zipcode" => "22222",
        "plus4_code" => "6542"
      }
    })

    input_id_4 = AddressVerificationClient.input_id(street: "1 Empora St", city: " Title", zip_code: " 11111")
    lookup_4 = build_lookup_with_result(input_id: input_id_4, candidate_data: nil)

    transformer.client.stubs(:batch).returns([lookup_1, lookup_2, lookup_3, lookup_4])

    transformer.validate!

    assert_equal "143 e Maine Street, Columbus, 43215 -> 143 East Main Street, Columbus, 43215", transformer.validated_results[input_id_1]
    assert_equal "1 Infinite Loop, cupertino, 95014 -> 1 Infinite Loop, Cupertino, 95014-2083", transformer.validated_results[input_id_2]
    assert_equal "25 Draper St., Greenville SC, 22222 -> 25 Draper St., Greenville, 22222-6542", transformer.validated_results[input_id_3]
    assert_equal "1 Empora St, Title, 11111 -> Invalid Address", transformer.validated_results[input_id_4]

    transformer.client.batch.clear

    assert_equal "143 e Maine Street, Columbus, 43215 -> 143 East Main Street, Columbus, 43215", transformer.validated_results[input_id_1]
    assert_equal "1 Infinite Loop, cupertino, 95014 -> 1 Infinite Loop, Cupertino, 95014-2083", transformer.validated_results[input_id_2]
    assert_equal "25 Draper St., Greenville SC, 22222 -> 25 Draper St., Greenville, 22222-6542", transformer.validated_results[input_id_3]
    assert_equal "1 Empora St, Title, 11111 -> Invalid Address", transformer.validated_results[input_id_4]
  end

  test "parsed_csv: parses the input_stream as a CSV, navigating by_row!" do
    stream = StringIO.new(<<~CSV
      Street, City, Zip Code
      143 e Maine Street, Columbus, 43215
      1 Infinite Loop, cupertino, 95014
      25 Draper St., Greenville SC, 22222
      1 Empora St, Title, 11111
      25 Draper St.,"Greenville, SC", 22222
    CSV
    )
    transformer = AddressCSVTransformer.new(input_stream: stream, smarty_auth_id: "abcd1234", smarty_auth_token: "12222")

    parsed_csv = transformer.parsed_csv

    assert_kind_of CSV::Table, parsed_csv
    assert_equal 5, parsed_csv.size

    assert_equal "143 e Maine Street", parsed_csv[0][:street]
    assert_equal " Columbus", parsed_csv[0][:city]
    assert_equal " 43215", parsed_csv[0][:zip_code]


    assert_equal "1 Infinite Loop", parsed_csv[1][:street]
    assert_equal " cupertino", parsed_csv[1][:city]
    assert_equal " 95014", parsed_csv[1][:zip_code]

    assert_equal "25 Draper St.", parsed_csv[2][:street]
    assert_equal " Greenville SC", parsed_csv[2][:city]
    assert_equal " 22222", parsed_csv[2][:zip_code]

    assert_equal "1 Empora St", parsed_csv[3][:street]
    assert_equal " Title", parsed_csv[3][:city]
    assert_equal " 11111", parsed_csv[3][:zip_code]

    assert_equal "25 Draper St.", parsed_csv[4][:street]
    assert_equal "Greenville, SC", parsed_csv[4][:city]
    assert_equal " 22222", parsed_csv[4][:zip_code]

  end

  test "parsed_csv: raises an exception if the input_stream cannot be parsed as a CSV" do
    stream = StringIO.new({a: "basdde"}.to_json)
    transformer = AddressCSVTransformer.new(input_stream: stream, smarty_auth_id: "abcd1234", smarty_auth_token: "12222")

    assert_raises CSV::MalformedCSVError do
      transformer.parsed_csv
    end
  end

  test "parsed_csv: raises an exception if the input_stream is a malformed CSV" do
    stream = StringIO.new(<<~CSV
      Street, City, Zip Code
      143 e Maine Street, Columbus, 43215
      1 Infinite Loop, cupertino, 95014
      25 Draper St., Greenville SC, 22222
      1 Empora St, Title, 11111
      25 Draper St.,"Greenville, SC, 22222
    CSV
    )
    transformer = AddressCSVTransformer.new(input_stream: stream, smarty_auth_id: "abcd1234", smarty_auth_token: "12222")

    assert_raises CSV::MalformedCSVError do
      transformer.parsed_csv
    end
  end

  test "parsed_csv: does nothing if the input_stream is empty" do
    transformer = AddressCSVTransformer.new(input_stream: StringIO.new, smarty_auth_id: "abcd1234", smarty_auth_token: "12222")

    assert_equal true, transformer.parsed_csv.empty?
  end
end