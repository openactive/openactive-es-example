# Indexing Opportunity Data Using Elastic Search

This repository contains a simple demonstration of harvesting and indexing 
opportunity data, published as part of the OpenActive project.

## Grab this code

Clone the repo

```
bundle install
```

## Download and unzip Elastic Search

Go to the Elastic Search page, download the zip file

Unpack the zip file into the `server` directory, ignoring the first directory 
in the zip.

You should have something like looks like:

```
server/bin
server/config
server/lib
...etc
```

## Update the list of datasets

Run:

```
rake prepare:config
```

Then edit `config/datasets.json` to switch on whichever datasets you want to try indexing.

Suggest using Colchester to begin with as its small

## Start ElasticSearch

In a separate terminal window, start ElasticSearch:

```
rake es:start
```

You can Ctrl-C to shutdown the server at any time. It needs to be running for next steps

## Configure Elastic Search

Run the following to create the ElasticSearch indexes:

```
rake es:indexes
```

If you want to reset things you can delete all indexed content by using:

```
rake es:delete_indexes
```

This creates indexes for every dataset. The indexes names are based on the keys 
in `config/datasets.json`. E.g. `oa-goodgym-oa.github.io`

## Crawl feeds

```
rake harvest:all
```

This will walk through every dataset you've configured for indexing, fetching the data. 
Each item in the feed that has a status of "modified" will be added to the index.

The indexing uses bulk updates to Elastic Search to make the updates more efficient.
It submits an entire page of updates in each bulk update.

At the moment it will only index up to 2000 items per dataset

Indexing is not parallelised so will be slow on the larger feeds.

## Test the search

You can then test out searching via a suitable ElasticSearch client

## TODO

* TODO: support deletion
* TODO: make index limit configurable
* TODO: it doesn't record date of last run
* TODO: it doesn't let you do anything to process each item
* TODO: include example searches