# Smarty Address Validator

This is a command-line utility that accepts a CSV-formatted list of US addresses, validates the addresses using [Smarty's US Address Verification API](https://www.smarty.com/products/us-address-verification), and outputs either:

* The corrected address
* `Invalid Address` if the normalized address could not be determined

# Setup

## Getting your Smarty API keys

You'll need to have an active Smarty Account, and generate a Secret Key for the API:

* https://www.smarty.com/pricing/choose-your-plan
* https://www.smarty.com/docs/cloud/authentication#keypairs


## Installation  & Setup

```sh
bundle install
cp .env.example .env
```

After that, you'll need to replace the `SMARTY_AUTH_ID` and `SMARTY_AUTH_TOKEN` with your Auth ID and Token

## File Format

The CSV file is expected to be given in the following format:

```
Street, City, Zip Code
143 e Maine Street, Columbus, 43215
...
```

# Running

You can either pipe in the file contents to the command:

```sh
cat file.csv | bundle exec ruby validate_addresses.rb 
```

Or pass the filename as an argument for the command:

```sh
bundle exec ruby validate_addresses.rb file.csv
```

# Tests

Tests can be run using the provided `Rakefile`:

```sh
bundle exec rake
```

# Design Process

The codebase is broken into 3 sections, to try to keep the coupling low, and allow different components to be swapped out

## `AddressVerificationClient`

This class is the client for interacting with Smarty's Address Verification API; in this case, through the [official Ruby SDK](https://www.smarty.com/docs/sdk/ruby)

The requests are performed in batches, to reduce HTTP traffic and optimize API usage. The usage pattern is:

1. Initialize a new instance of `AddressVerificationClient` with your credentials, and an optional override for the max batch size
2. Call `add_lookup` for every address you wish to look up in a batch. This method also generates a stable `input_id` based on the given street + city + zip_code so that lookups aren't duplicated (as much as possible)
3. Call `load_results` to have the client send the batch and store the results
4. Iterate through the `batch`; processing each lookup's results
5. Call `batch.clear` to clear the batch
6. Repeat the process for any subsequent batches

To make usage easier, the following helper methods are provided:

* `AddressVerificationClient.input_id`: generates a stable `input_id` based on the given street + city + zip_code for lookups & hash map storage
* Helper methods for determining how much capacity is left in the batch:
  * `remaining_batch_size`
  * `can_add_lookup?`
  * `max_batch_size`


## `AddressCSVTransformer`

This class takes the provided `input_stream` and `client`, in order to:

1. Parses the `input_stream` as a CSV
2. Validates the lookups for each row of the CSV using the provided `client`
3. Stores the `validated_results` for use later

The class provides the following public methods:

* `parsed_csv`: a `CSV::Table` of the `input_stream`, already set to navigate `by_row!`
* `validate!`: The method to process the `parsed_csv` and validate the given addresses
  * The method processes the rows in batches (using `client.max_batch_size`), and uses a lazy enumerator to reduce memory usage
  * The underlying `validate_batch!` method combines both `delivery_line_1/2` for the address (to ensure deliverability), and handles cases where a ZIP Code does not have a +4 code
* `validated_results`: The cached results for this file

## `validate_addresses.rb`

The command-line program that ties together:
* A `AddressVerificationClient` instance using the `SMARTY_AUTH_ID` and `SMARTY_AUTH_TOKEN` `ENV` variables
* A `AddressCSVTransformer` instance using the `ARGF` Ruby provides for standardized IO reading (see: https://ruby-doc.org/3.2.1/ARGF.html#method-i-to_io)
* Prints the transformer's `validates_results` in the expected format


## Reasoning

Each of these components solve a specific problem in the chain:

1. Accessing Smarty's API performantly and with strict match requirements to ensure we get accurate results
2. Parsing & processing a CSV while respecting the client's batch capacity
3. Providing a command-line interface that works for both UNIX piping and filename arguments

Keeping them separate allows us to test each component in isolation, extend features as needed, and swap out implementations.

### Testing

[Webmock](https://github.com/bblimke/webmock) is used for stubbing HTTP requests, and [Mocha](https://github.com/freerange/mocha) is used for general stubbing and expectations.

HTTP Stubbing is only done for the `AddressVerificationClient` tests, because HTTP stubs are harder to maintain. Rather than peppering HTTP stubs throughout the tests for `AddressCSVTransformer`, using generalized stubs and expectations decouples that component from the actual HTTP API