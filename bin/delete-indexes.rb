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
datasets = JSON.parse( File.read(ARGV[0]) )

datasets.keys.each do |dataset|
  index_name = "#{INDEX_PREFIX}-#{dataset}"
  if (!client.indices.exists? index: index_name)
    $stderr.puts "Index #{index_name} already deleted, skipping"
  else
    client.indices.delete index: index_name
    $stderr.puts "Deleted index #{index_name} for #{datasets[dataset]["title"]}"
  end

end
