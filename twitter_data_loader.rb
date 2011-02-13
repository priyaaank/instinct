require 'rubygems'
require 'twitter'
require 'crawler_objects'
require 'tweetstream'

module Twitter
  module DataLoader
  
    def self.clear_data
      DatabaseManager.cleanup_database
    end

    def self.load_friends_data_for_user(user_handle)
      user = Twitter.user(user_handle)
      Person.find(:first, :conditions => {:screen_name => user[:screen_name]}) ||
      Person.create(:screen_name => user[:screen_name],
                    :twitter_id  => user[:id_str])

      cursor = -1
      while cursor != 0 do
        twitter_response = Twitter.friends(user_handle, :cursor => cursor)
        twitter_response[:users].each do |person|
          Person.create(:screen_name => person[:screen_name], 
                        :twitter_id  => person[:id_str])
          cursor = twitter_response[:next_cursor]
        end
      end
    end

    def self.load_all_tweets_and_retweets_for_friends
      puts "API streaming has started. We are all ears to new updates!"
      puts "*"*100
      people_ids = Person.all.each.map(&:twitter_id).map(&:to_i)
      TweetStream::Client.new(ENV["TWITTER_USERNAME"], ENV["TWITTER_PASSWORD"]).follow(*people_ids) do |orig_status|
        status = orig_status.clone
        is_retweet = false

        begin
          status.retweeted_status
          is_retweet = true
        rescue 
          #do nothing
        end

        person = Person.find(:first, :conditions => {:twitter_id => status.user.id_str}) ||
                 Person.create(:screen_name => status.user.screen_name, :twitter_id => status.user.id_str)
        if is_retweet 
          original_tweeter = status.retweeted_status.user

          puts "*"*100
          puts "It's a retweet! The values are:"
          puts "Status Id: #{status.retweeted_status.id_str}"
          puts "Status Text: #{status.retweeted_status.text}"
          puts "Original Tweeter Screenname: #{original_tweeter.screen_name}"
          puts "Original Tweeter id: #{original_tweeter.id_str}"
          puts "Person screen name is #{person.screen_name}"
          puts "Locally stored id is: #{person.twitter_id}"
          puts "*"*100
          
          current_tweet = Tweet.find(:first, :conditions => {:twitter_id => status.retweeted_status.id_str }) || 
                          Tweet.create(:text       => status.text,
                                       :twitter_id => status.retweeted_status.id_str)
          original_tweeter = Person.find(:first, :conditions => {:twitter_id => original_tweeter.id_str}) || 
                             Person.create(:screen_name => original_tweeter.screen_name,
                                           :twitter_id  => original_tweeter.id_str)
          current_tweet.retweeters << person
          current_tweet.owner << original_tweeter 
          current_tweet.save!
        else
          puts "*"*100
          puts "It's an original Tweet"
          puts "Status Id: #{status.id_str}"
          puts "Status Text: #{status.text}"
          puts "Tweeter Id: #{status.user.id_str}"
          puts "Person screen name is #{person.screen_name}"
          puts "Locally stored id is: #{person.twitter_id}"
          puts "*"*100

          current_tweet = Tweet.create(:text       => status.text,
                                       :twitter_id => status.id_str)
          current_tweet.owner << person
          current_tweet.save!
        end
      end
    end
  end
end

#Twitter::DataLoader.clear_data
#Twitter::DataLoader.load_friends_data_for_user("priyaaank")
Twitter::DataLoader.load_all_tweets_and_retweets_for_friends
