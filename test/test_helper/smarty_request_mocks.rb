module SmartyRequestMocks
  def draper_street_lookup_response
    [
      {
        "input_index": 0,
        "candidate_index": 0,
        "delivery_line_1": "25 Draper Street",
        "last_line": "Greenville SC 22222-6542",
        "delivery_point_barcode": "997059901010",
        "components": {
          "primary_number": "25",
          "street_name": "Draper",
          "street_suffix": "St",
          "city_name": "Greenville",
          "state_abbreviation": "SC",
          "zipcode": "22222",
          "plus4_code": "6542",
          "delivery_point": "01",
          "delivery_point_check_digit": "0"
        },
        "metadata": {
          "record_type": "S",
          "zip_type": "Standard",
          "county_fips": "02090",
          "county_name": "Greenville",
          "carrier_route": "C004",
          "congressional_district": "SC",
          "rdi": "Commercial",
          "elot_sequence": "0001",
          "elot_sort": "A",
          "latitude": 64.75233,
          "longitude": -147.35297,
          "coordinate_license": 1,
          "precision": "Rooftop",
          "time_zone": "New_York",
          "utc_offset": -9,
          "dst": true
        },
        "analysis": {
          "dpv_match_code": "Y",
          "dpv_footnotes": "AABB",
          "dpv_cmra": "N",
          "dpv_vacant": "N",
          "dpv_no_stat": "Y",
          "active": "Y",
          "footnotes": "L#"
        }
      },
    ]
  end

  def north_pole_and_apple_request_payload
    [
      {
        "input_id": "1 Santa ClausNorth Pole99705",
        "street": "1 Santa Claus, North Pole, 99705",
        "street2": nil,
        "secondary": nil,
        "city": nil,
        "state": nil,
        "zipcode": nil,
        "lastline": nil,
        "addressee": nil,
        "urbanization": nil,
        "match": "strict",
        "candidates": 1
      },
      {
        "input_id": "1 Infinite Loopcupertino95014",
        "street": "1 Infinite Loop, cupertino, 95014",
        "street2": nil,
        "secondary": nil,
        "city": nil,
        "state": nil,
        "zipcode": nil,
        "lastline": nil,
        "addressee": nil,
        "urbanization": nil,
        "match": "strict",
        "candidates": 1
      }
    ]
  end

  def north_pole_and_apple_response
    [
      {
        "input_index": 0,
        "candidate_index": 0,
        "delivery_line_1": "1 Santa Claus Ln",
        "last_line": "North Pole AK 99705-9901",
        "delivery_point_barcode": "997059901010",
        "components": {
          "primary_number": "1",
          "street_name": "Santa Claus",
          "street_suffix": "Ln",
          "city_name": "North Pole",
          "default_city_name": "North Pole",
          "state_abbreviation": "AK",
          "zipcode": "99705",
          "plus4_code": "9901",
          "delivery_point": "01",
          "delivery_point_check_digit": "0"
        },
        "metadata": {
          "record_type": "S",
          "zip_type": "Standard",
          "county_fips": "02090",
          "county_name": "Fairbanks North Star",
          "carrier_route": "C004",
          "congressional_district": "AL",
          "rdi": "Commercial",
          "elot_sequence": "0001",
          "elot_sort": "A",
          "latitude": 64.752140,
          "longitude": -147.353000,
          "precision": "Zip9",
          "time_zone": "Alaska",
          "utc_offset": -9,
          "dst": true
        },
        "analysis": {
          "dpv_match_code": "Y",
          "dpv_footnotes": "AABB",
          "dpv_cmra": "N",
          "dpv_vacant": "N",
          "dpv_no_stat": "Y",
          "active": "Y",
          "footnotes": "L#"
        }
      },
      {
        "input_index": 1,
        "candidate_index": 0,
        "addressee": "Apple Inc",
        "delivery_line_1": "1 Infinite Loop",
        "last_line": "Cupertino CA 95014-2083",
        "delivery_point_barcode": "950142083017",
        "components": {
          "primary_number": "1",
          "street_name": "Infinite",
          "street_suffix": "Loop",
          "city_name": "Cupertino",
          "default_city_name": "Cupertino",
          "state_abbreviation": "CA",
          "zipcode": "95014",
          "plus4_code": "2083",
          "delivery_point": "01",
          "delivery_point_check_digit": "7"
        },
        "metadata": {
          "record_type": "S",
          "zip_type": "Standard",
          "county_fips": "06085",
          "county_name": "Santa Clara",
          "carrier_route": "C067",
          "congressional_district": "17",
          "rdi": "Commercial",
          "elot_sequence": "0037",
          "elot_sort": "A",
          "latitude": 37.333100,
          "longitude": -122.028890,
          "precision": "Zip9",
          "time_zone": "Pacific",
          "utc_offset": -8,
          "dst": true
        },
        "analysis": {
          "dpv_match_code": "Y",
          "dpv_footnotes": "AABB",
          "dpv_cmra": "N",
          "dpv_vacant": "N",
          "dpv_no_stat": "N",
          "active": "Y"
        }
      }
    ]
  end
end