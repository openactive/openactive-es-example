require 'rubygems'
require 'bundler'
Bundler.require :default

require_relative 'connect'

client = Elasticsearch::Client.new(
  host: "https://elastic:#{ELASTIC_PASSWORD}@localhost:9200",
  transport_options: { ssl: { verify: false } },
  ca_fingerprint: CERT_FINGERPRINT
)

#Parse the config/datasets.json file
datasets = JSON.parse( File.read(ARGV[0]) )

INDEX_PREFIX="oa"

#Change this if you want to index more data from each feed
PAGE_LIMIT=2000

#Page through each dataset
datasets.each.each do |id, dataset|
  #If its configured for indexing
  if dataset["index"] == true
    #Start harvesting
    begin
      #Start counting how many items we've found in the feed
      indexed = 0

      $stderr.puts "Harvesting #{dataset["title"]}"
      puts dataset["data_url"]

      #Create the feed from the metadata
      #In a production application we'd start from our last point of indexing, not the data-url
      feed = OpenActive::Feed.new(dataset["data_url"])
      #Start harvesting. We receive a callback for each page that's found. At the end of the harvesting
      #the last_page variable will have the URL of the final page
      last_page = feed.harvest do |page|
          #this is the array of updates to send to the ElasticSearch bulk update API
          body = []
          #iterate through the items array in the response
          page.body["items"].each do |item|
            #add each item to the update, using the appropriate index
            #we use the unique id for the item in the feed as the document id
            #TODO: we should be checking the state of the item and processing deletes here
            body << { index: { _index: "#{INDEX_PREFIX}-#{id}", _id: item["id"] } }

            #here we just add the data about the item that was included in the feed
            #in a production application you will probably want to process this data to ensure that
            #its suitable for you purposes.
            #
            #This can include:
            # validation - to ensure required data is provided
            # filtering - to certain data types, or just those items that meet specific criteria
            # enriching - e.g. adding extra data such as geolocating addresses
            # normalising - organising the data so that it fits your needs and index configuration
            body << item["data"]

            #update how many items we've seen
            indexed += 1
          end
          #submit the data for indexing
          client.bulk body: body unless body.empty?
          #Stop when we hit the page limit. In a product app you won't want to put a limit on this
          raise "Indexed #{indexed}, moving on" if indexed >= PAGE_LIMIT
      end

      #At this point we should really store the value of the last_page variable somewhere
      #So that next time we index this dataset we start from that URL, rather than the data_url property from the
      #configuration file
    rescue => e
      #oops
      $stderr.puts e
      $stderr.puts e.backtrace
    end
  end
end
