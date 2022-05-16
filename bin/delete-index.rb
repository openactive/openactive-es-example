require 'rubygems'
require 'bundler'
Bundler.require :default

INDEX_PREFIX="oa"

require_relative 'connect'

client = Elasticsearch::Client.new(
  host: "https://elastic:#{ELASTIC_PASSWORD}@localhost:9200",
  transport_options: { ssl: { verify: false } },
  ca_fingerprint: CERT_FINGERPRINT
)

index_name = "#{INDEX_PREFIX}-#{ARGV[0]}"

client.indices.delete index: index_name
$stderr.puts "Deleted index #{index_name}"

