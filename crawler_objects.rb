require 'rubygems'
require 'mongoid'

Mongoid.configure do |config|
  name = "twitter"
  host = "localhost"
  config.master = Mongo::Connection.new.db(name)
  config.persist_in_safe_mode = false
end

class DatabaseManager
  include Mongoid::Document

  def self.cleanup_database
    Mongoid.master.collections.select do |collection|
      collection.name !~ /system/
    end.each(&:drop)
  end
end

class Person
  include Mongoid::Document
 
  references_and_referenced_in_many :tweets, :class_name => "Tweet", :stored_as => :array, :inverse_of => :owner
  references_and_referenced_in_many :retweets, :class_name => "Tweet", :stored_as => :array, :inverse_of => :retweeters
end

class Tweet
  include Mongoid::Document

  references_and_referenced_in_many :owner, :class_name => "Person", :stored_as => :array, :inverse_of => :tweets
  references_and_referenced_in_many :retweeters, :class_name => "Person", :stored_as => :array, :inverse_of => :retweets
end

