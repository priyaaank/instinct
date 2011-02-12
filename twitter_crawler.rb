require 'rubygems'
require 'twitter'
require 'active_record'


ActiveRecord::Base.establish_connection(
  :adapter => 'mysql',
  :database => 'twitter_crawler',
  :username => 'root',
  :password => 'p@ssw0rd',
  :host => 'localhost')

class TwitterAccount < ActiveRecord::Base

  scope :uncomputed, :conditions => {:computed => 0}

  def self.add_records(ids)
    begin
      ids.each do |rec|
        TwitterAccount.create(:twitter_id => rec, :computed => 0)
      end
    rescue ActiveRecord::RecordNotUnique => e
      #Do nothing
    end
  end
end

class Crawler
  def self.crawl(id, cursor)
    response = Twitter.follower_ids(id, :cursor => cursor)
    TwitterAccount.add_records(response[:ids])
    if response[:next_cursor] != 0
      t = Thread.new {crawl(id, response[:next_cursor])}
      t.join
    else
      TwitterAccount.update_all("computed = 1","twitter_id = '#{id}'")
    end
  end
end

t1 = Thread.new {Crawler.crawl(16665197,-1)}
t2 = Thread.new {Crawler.crawl(38986813,-1)}
t1.join
t2.join

#puts TwitterAccount.uncomputed.limit(1).to_json
#puts TwitterAccount.find(:all).to_json

#puts Twitter.user("priyaaank").id
#puts json_resp[:ids]
