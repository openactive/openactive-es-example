require 'rubygems'
require 'bundler'
Bundler.require :default

INDEX_PREFIX="oa"

client = Elasticsearch::Client.new

index_name = "#{INDEX_PREFIX}-#{ARGV[0]}"

client.indices.delete index: index_name
$stderr.puts "Deleted index #{index_name}"

