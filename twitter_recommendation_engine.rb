require 'crawler_objects'

module Twitter
  module Recommendations
    
    def self.generate_master_tweet_list_for(user)
      puts user.inspect
      tweet_hash_with_empty_weight = user.retweets.each.inject({}) {|hash, tweet| hash[tweet.twitter_id] = 0; hash}
      puts tweet_hash_with_empty_weight
      Person.all.each.inject({}) {|hash, person| hash[person.screen_name] = tweet_hash_with_empty_weight; hash }
    end

    def self.get_cached_master_tweet_list_for(user)
      @tweet_master_set ||= generate_master_tweet_list_for(user)
    end

    def self.calculate_similarity_between(tweet_master_set, user, person)
      get_cached_master_tweet_list_for(user)
    end

    def self.recommend_tweets(tweet_master_set, person)

    end
  end
end

Twitter::Recommendations.calculate_similarity_between(nil, Person.find(:first, :conditions => {:screen_name => "priyaaank"}), nil)
