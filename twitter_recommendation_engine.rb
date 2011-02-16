require 'crawler_objects'

module Twitter
  module Recommendations
    
    def self.tweet_map_for(person)
      person.retweets.map(&:twitter_id).each.inject({}) {|hash, tweet| hash[tweet] = 1; hash}
    end

    def self.generate_master_tweet_list_for(user)
      master_has = {}
      user_tweet_hash_with_zero_weight = user.retweets.map(&:twitter_id).each.inject({}) {|hash, tweet| hash[tweet] = 0; hash}

      master_hash = Person.all.each.inject({}) do |hash, person|
        hash[person.screen_name] = user_tweet_hash_with_zero_weight.merge!(tweet_map_for(person))
        hash
      end
      puts master_hash.to_json
      master_hash
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

      tweets_user_has_not_retweeted.each do |tweet|
        similarity_sum = 0
        total_similarity_score = 0

        user_similarity_score.each do |critic, score|
          if critic.retweets.include?(tweet)
            similarity_sum += score
            total_similarity_score += (score * @tweet_master_set[critic][tweet])
          end
       
         similarity_sum[tweet] = (total_similarity_score/similarity_sum) unless similarity_sum == 0 
        end
      end
    end

  end
end

result = Twitter::Recommendations.get_cached_master_tweet_list_for(Person.find(:first, :conditions => {:screen_name => "just3ws"}))

puts result["just3ws"].to_json
puts result["priyaaank"].to_json
puts result["markhneedham"].to_json

