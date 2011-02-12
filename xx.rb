require 'rubygems'
require 'tweetstream'

TweetStream::Client.new('','').retweet do |status|
  puts status.inspect
  puts "#{status.text}"
end
