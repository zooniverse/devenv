#!/usr/bin/env ruby

require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'
  gem 'aws-sdk', require: false
end

require 'date'
date = Date.today.prev_day

require 'aws-sdk'
client = Aws::S3::Client.new(region: 'us-east-1')

puts "Finding latest dump"
result = client.list_objects(bucket: 'zooniverse-code', prefix: "databases/#{date.to_s}/rds/panoptes-panoptes-production")

if object = result.contents[0]
  dest = File.expand_path("../../tmp/postgres/panoptes.dump", __FILE__)

  puts "Found #{object.key}"
  puts "Downloading to #{dest}"
  client.get_object(response_target: dest, bucket: result.name, key: result.contents[0].key)

  puts "Importing"
  puts `docker exec -it devenv_postgres_1 gosu postgres dropdb --if-exists panoptes_development`
  puts `docker exec -it devenv_postgres_1 gosu postgres createdb panoptes_development`
  puts `docker exec -it devenv_postgres_1 gosu postgres pg_restore -d panoptes_development /var/lib/postgresql/panoptes.dump`
  puts "Done"
else
  raise "Could not find yesterdays dump"
end