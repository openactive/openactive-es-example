require 'rubygems'
require 'bundler'
Bundler.require :default

datasets = {}
OpenActive::Datasets.list.each do |site|
  datasets[site[:id].downcase] = {
      "title": site[:title],
      "data_url": site[:data_url],
      "index": false
  }
end

File.open(ARGV[0], "w") do |config|
  config.puts JSON.pretty_generate(datasets)
end
