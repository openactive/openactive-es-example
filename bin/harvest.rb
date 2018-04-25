require 'rubygems'
require 'bundler'
Bundler.require :default

client = Elasticsearch::Client.new

datasets = JSON.parse( File.read(ARGV[0]) )

INDEX_PREFIX="oa"

datasets.each.each do |id, dataset|
  if dataset["index"] == true
    begin
      indexed = 0
      $stderr.puts "Harvesting #{dataset["title"]}"
      puts dataset["data_url"]
      feed = OpenActive::Feed.new(dataset["data_url"])
      feed.harvest do |page|
          body = []
          page.body["items"].each do |item|
            body << { index: { _index: "#{INDEX_PREFIX}-#{id}", _type: "opp", _id: item["id"] } }
            body << item["data"]
            indexed += 1
          end
          client.bulk body: body unless body.empty?
          raise "Indexed #{indexed}, moving on" if indexed >= 2000
      end
    rescue => e
      $stderr.puts e
    end
  end
end
