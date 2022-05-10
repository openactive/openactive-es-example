# Indexing Opportunity Data Using Elastic Search

This repository contains a simple demonstration of harvesting and indexing [opportunity data](http://status.openactive.io/), published as part of the [OpenActive](https://openactive.io) initiative.

The example uses a set of simple Ruby scripts to drive harvesting of live data feeds and indexes the data in 
[ElasticSearch](https://www.elastic.co/) which is an open source search engine.

The code in this project is published under an open licence and you are free to adapt and reuse it as you see fit.

It is primarily intended as simple example of harvesting and indexing data so isn't production strength. However this 
setup has been successfully used to do some simple analysing and reporting on published data.

## Install dependencies

You will need to install:

* Ruby -- this was built and tested using Ruby 2.4.0 but should work on later rubies)
* Bundler -- to install other ruby dependencies
* Java 1.8+ -- ElasticSearch is a java application

## Grab this code

Clone this repo to your machine, then install the ruby dependencies:

```
bundle install
```

## Download and unzip Elastic Search

Go to [the Elastic Search download page](https://www.elastic.co/downloads/elasticsearch) and download the zip file 
of the latest release.

You will need to unzip the file into the `server` sub-directory of this project. You should ignore the 
main sub-directory in the zip file, you just need to extract the main project folders.

You should end up with a `server` directory that looks something like:

```
server/bin
server/config
server/lib
server/modules
...etc
```

## Update the list of datasets

The ruby scripts that manage the indexes and harvest the data are driven off a list of published datasets. These 
are cached locally for convenience in the `config/datasets.json`.

In a live application you may only want to index specific datasets. And for testing purposes you are likely to only 
want to index some of the smaller feed.

To update the cached configuration run the following:

```
rake prepare:config
```

This downloads the current list of published datasets and stores it in `config/datasets.json`.

By default indexing is disabled for all datasets, you will need to edit `config/datasets.json` to switch on 
whichever datasets you want to try indexing. We suggest trying using the Leisure World Colchester data as its a small 
feed. So edit the following section in `config/datasets.json` so that the `index` key is `true` rather than `false`.

```
  "leisureworldcolchester.github.io": {
    "title": "Leisure World Colchester Sessions",
    "data_url": "https://lw-colchester-openactive.herokuapp.com",
    "index": true
  }
```

## Start ElasticSearch

By default, ElasticSearch starts with SSL security restrictions configured in `config/elasticsearch.yml`. For this example, these can be set to `false` rather than `true` as below:

```
# Enable encryption for HTTP API client connections, such as Kibana, Logstash, and Agents
xpack.security.http.ssl:
  enabled: false
  keystore.path: certs/http.p12
```

We then need to startup ElasticSearch so we can configure some indexes to hold the data. 
**Open a separate terminal window**, cd to the project directory and start ElasticSearch by running the following command:

```
rake es:start
```

This just runs `./server/bin/elasticsearch` so you can run that directly if you prefer.

Test it is running by visiting `http://localhost:9200/`. You may have to log in with the user 'elastic' and the password shown in the terminal log. You should see a JSON response from your local ElasticSearch server.

You can Ctrl-C to shutdown the server at any time. But it needs to be running for the following steps. 

ElasticSearch is configured via its API so you need to have an instance available.

### Aside: Using a different ElasticSearch Server

The scripts all assume that they are working with an ElasticSearch instance available at `http://localhost:9200/`.
If you want to use an alternative server, then for the moment you'll need to edit the scripts in the `bin` directory to 
revise the following lines:

```
client = Elasticsearch::Client.new
```

See the [elasticsearch-ruby configuration](http://www.rubydoc.info/gems/elasticsearch-transport#Configuration) docs for more details.

## Create Elastic Search Indexes

In the original terminal, run the following to create the ElasticSearch indexes:

```
rake es:indexes
```

This will create an index in ElasticSearch for every dataset in `config/datasets.json`. It's safe to run this 
multiple times, e.g. if you update the list of cached datasets.

Indexes are given unique names based on the keys in `config/datasets.json`. The keys could be used directly, but here we've chosen to just 
add a prefix to the names as it makes it easier to apply a consistent index template (see below) to the datasets.

So the index name for `goodgym-oa.github.io` is `oa-goodgym-oa.github.io`. 

Index names are important if you are querying individual datasets.

If you want to reset you data, then you can delete all indexed content by using:

```
rake es:delete_indexes
```

If you want to delete just a single index, then run this script:

```
ruby bin/delete-indexes <dataset-key>
```

Where `<dataset-key>` is one of the keys in `configi/datasets.json`.

### Aside: Configuring indexes

By default ElasticSearch is happy to store any chunk of JSON that you throw at it. We're taking advantage of that in 
this example to initially avoid getting into the details of how you might structure a search index for your application.

The published opportunity data can have a variety of structures, so for a production application you'd need to decide 
how to process the data into a consistent shape for indexing. And also how you want to configure the indexing so that 
you get the best search results.

ElasticSearch allows you to provide an [index template](https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-templates.html) 
when creating an index. 

This example uses a basic template which can be found in `config/index-template.json`. This is stored on the ElasticSearch 
 server and is automatically applied to any new index with an `oa-` prefix. 
 
If you want to play with indexing templates then you can revise this, rebuild your indexes and re-harvest data.

## Crawl the data

The script that will harvest the opportunity data is `bin/harvest.rb`. It uses the [OpenActive](https://github.com/openactive/openactive.rb) ruby gem to walk through feeds.

You can run it using the following command:

```
rake harvest:all
```

This will walk through every dataset that you have configured for indexing, paging through the results from the 
[RPDE](https://www.openactive.io/realtime-paged-data-exchange/) feeds and submitting the data to ElasticSearch.

The indexing uses the ElasticSearch bulk update API to make the indexing more efficient. It submits an entire 
page of data from a feed at a time.

### Aside: improving the harvester

At the moment the harvesting is very simplistic:

* It doesn't remember previous runs, it just reindexes every time
* It doesn't process deletions
* It only indexes the first 2000 items of any feed
* It indexes datasets in turn, rather than in parallel
* It doesn't process any of the received data, e.g. in order to ensure its in a sensible shape for your need.

For a production application you'll need to think through all of those things.

The `bin/harvest.rb` script is liberally commented to indicate what you might need to change to improve the scripts. Feel free to submit a pull request!

## Test the search

We can now check to see that we have indexed some data.

If you visit this URL:

```
http://localhost:9200/_stats
```

Then ElasticSearch will dump the current state of all indexes, including how many documents are in each. You can also 
ask for index specific statistics. So, assuming you have indexes Leisure World Colchester, then if you visit this URL:

```
http://localhost:9200/oa-leisureworldcolchester.github.io/_stats
```

Then you should get stats for just that index. You should see something like this:

```
{
  "_shards": {
    ...
  },
  "_all": {
    ...
  },
  "indices": {
    "oa-leisureworldcolchester.github.io": {
      "primaries": {
        "docs": {
          "count": 156,
          "deleted": 0
        },
        ...
    }
   }   
}
```

Which tells you that 156 records have been indexed.

You can also visit the `_search` endpoint to see all the docs:

```
http://localhost:9200/oa-leisureworldcolchester.github.io/_search
```

We suggest reading [the ElasticSearch documentation on their search API](https://www.elastic.co/guide/en/elasticsearch/reference/current/_exploring_your_data.html) 
for more help.

As noted above, you'll want to process the data and customise the index to get the best results for you application.

## Things to improve in the example

* support deletion
* make index limit configurable or removable
* make ElasticSearch index configurable
* record last index url for each dataset
* include more example searches
* indicate how to process each item better
* indicate how to limit to just those items that conform to standards
* give examples of customising the indexes

Happy to accept pull requests!
