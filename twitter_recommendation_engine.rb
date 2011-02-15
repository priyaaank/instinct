require 'crawler_objects'

module Twitter
  module Recommendations
    
    def self.generate_master_tweet_list_for(user)
      tweet_hash_with_empty_weight = user.retweets.each.inject({}) {|hash, tweet| hash[tweet.twitter_id] = 0; hash}
      puts tweet_hash_with_empty_weight
      master_graph = Person.all.each.inject({}) {|hash, person| hash[person.screen_name] = tweet_hash_with_empty_weight; hash }
      user.retweets.each do |retweet|
        Person.all.each do |person|
          master_graph[person][retweet] = 1 if person.retweets.map(&:twitter_id).include?(retweet.twitter_id)
        end
      end
    end

    def self.get_cached_master_tweet_list_for(user)
      @tweet_master_set ||= generate_master_tweet_list_for(user)
    end

    def self.calculate_similarity_between(user, person)
      retweet_graph_for_all_users = get_cached_master_tweet_list_for(user)

      common_retweets_user_and_person = retweet_graph_for_all_users[user].keys & retweet_graph_for_all_users[person].keys
      total_number_of_common_retweets = common_retweets_user_and_person.count

      #Using Pearson's corelation method to calculate similarity between two datasets of user and a person
      user_retweet_data_sum = 0
      person_retweet_data_sum = 0
      user_person_retweet_data_sum = 0
      user_tweet_data_square_sum = 0
      person_retweet_square_data_sum = 0

      common_retweets_user_and_person.each do |retweet|
        current_rating_for_user = retweet_graph_for_all_users[user][retweet] 
        current_rating_for_person = retweet_graph_for_all_users[person][retweet] 

        user_retweet_data_sum += current_rating_for_user 
        person_retweet_data_sum += current_rating_for_person 

        user_person_retweet_data_sum += (current_rating_for_user*current_rating_for_person) 

        user_tweet_data_square_sum += (current_rating_for_user**2)
        person_tweet_data_square_sum += (current_rating_for_person**2)
      end

      number = user_person_retweet_data_sum - ((user_retweet_data_sum * person_retweet_data_sum) / total_number_of_common_retweets) 
      denominator = Math.sqrt((user_tweet_data_square_sum - ((user_retweet_data_sum **2)/total_number_of_common_retweets)) *
                              (person_retweet_square_data_sum - ((person_retweet_data_sum**2)/total_number_of_common_retweets)))
      return 0 if denominator == 0
      number / denominator
    end

    def self.recommend_tweets(tweet_master_set, user)
      user_similarity_score = {}
      tweets_user_has_not_retweeted = (Tweet.all.each.map(&:twitter_id) - user.retweets.each.map(&:twitter_id))

      Person.all.each do |person|
        next if user == person
        user_similarity_score[person] = calculate_similarity_between(user, person)
      end


    end
  end
end

Twitter::Recommendations.calculate_similarity_between(nil, Person.find(:first, :conditions => {:screen_name => "priyaaank"}), nil)
