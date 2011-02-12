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
      cursor = -1
      while cursor != 0 do
        twitter_response = Twitter.friends(user_handle, :cursor => cursor)
        twitter_response[:users].each do |person|
          Person.create(:screen_name => person[:screen_name], 
                        :twitter_id  => person[:id],
                        :processed   => false)
          cursor = twitter_response[:next_cursor]
        end
      end
    end

    def self.load_all_tweets_and_retweets_for_friends
      users_to_delete = []
      Person.find(:all, :conditions => {:processed => false}).each do |person|
        begin
          twitter_response = Twitter.user_timeline(person.twitter_id, :include_rts => 1)
          twitter_response.each do |status|
            if status[:retweeted_status].present?
              retweeter = status[:retweeted_status][:user]
              current_tweet = Tweet.find(:first, :conditions => {:twitter_id => status[:retweeted_status][:id] }) || 
                              Tweet.create(:text       => status[:text],
                                           :twitter_id => status[:retweeted_status][:id])
              retweeter = Person.find(:first, :conditions => {:twitter_id => retweeter[:id]}) || 
                          Person.create(:screen_name => retweeter[:screen_name],
                                        :twitter_id  => retweeter[:id])
              retweeter.tweets << current_tweet
              current_tweet.retweeters << person
              person.retweets << current_tweet
              retweeter.save
              current_tweet.save
              person.save
            else
              current_tweet = Tweet.create(:text       => status[:text],
                                           :twitter_id => status[:id])
              current_tweet.people << person
              current_tweet.save
            end
          end
        rescue Twitter::Unauthorized => e
          puts "Person #{person.screen_name} does not allow public access"
          users_to_delete << person
        end

        person.processed = true
        person.save
      end 
      puts "Deleting all private users"
      users_to_delete.each {|person| person.destroy}
    end
  end
end

#Twitter::DataLoader.clear_data
#Twitter::DataLoader.load_friends_data_for_user("priyaaank")
Twitter::DataLoader.load_all_tweets_and_retweets_for_friends
