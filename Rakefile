require 'rubygems'
require 'rake'
require 'rake/clean'

require 'bundler'
Bundler.require :default


CLEAN.include("data")

#Configure indexes for datasets

CONFIG="config/datasets.json"

namespace :prepare do
  desc "Create dataset config"
  task :config do
    sh %{ruby bin/prepare-config.rb #{CONFIG}}
  end
end

namespace :es do

  desc "create Elastic Search indexes"
  task :indexes do
    sh %{ruby bin/create-indexes.rb #{CONFIG} config/index-template.json}
  end

  desc "Delete all indexes"
  task :delete_indexes do
    sh %{ruby bin/delete-indexes.rb #{CONFIG}}
  end

  desc "Start elastic search"
  task :start do
    sh %{./server/bin/elasticsearch}
  end

end

namespace :harvest do
  task :all do
    sh %{ruby bin/harvest.rb #{CONFIG}}
  end
end


