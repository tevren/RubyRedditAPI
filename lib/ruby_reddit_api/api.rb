module Reddit

  # @author James Cook
  class Api < Base
    attr_accessor :user, :password
    attr_reader :last_action, :debug

    def initialize(user=nil,password=nil,options={})
      @user     = user
      @password = password
      @debug    = StringIO.new
    end

    def inspect
      "<Reddit::Api>"
    end

    # Browse submissions by subreddit
    # @param [String] Subreddit to browse
    # @return [Array<Reddit::Submission>]
    def browse(subreddit, options={})
      query = Hash.new
      options.merge! :handler => "Submission"
      options.each do |k,v|
        if k.match(/limit|before|after|section/)
          query[k.to_sym] = v
        end
      end
      options.merge!({:query => query})
      unless subreddit.empty? || subreddit.nil?
        subreddit = sanitize_subreddit(subreddit)        
        read("/r/#{subreddit}.json", options )
      else
        read("/.json", options )
      end
    end

    def saved(options={})
      query = Hash.new
      options.merge! :handler => "Submission"
      options.each do |k,v|
        if k.match(/limit|before|after|section/)
          query[k.to_sym] = v
        end
      end
      if logged_in? && !user.nil?
        read("/user/#{user.to_s}/saved/.json", options )
      elsif options[:cookie] && options[:user]
        read("/user/#{options[:user]}/saved/.json", options )
      end
    end

    # Return user's subscribed subreddits, if no user exists, returns the default list of subreddits
    # @return [Array<Reddt::Submission>]
    def mine(options={})
      if logged_in? || options[:cookie]
        if options[:limit]
          options.merge!({:query => {:limit => options[:limit]}})
        end
        read("/reddits/mine.json", options)
      else
        if options[:limit]
          options.merge!({:query => {:limit => options[:limit]}})
        end
        read("/reddits.json", options)
      end
    end

    # Search reddit
    # @param [String, Hash] Search terms and options
    # @example
    #   search("programming", :in => "ruby", :sort => "relevance")
    # @return [Array<Reddit::Submission>]
    def search(terms=nil, options={})
      http_options = {:verb => "get", :query => {}}
      subreddit    = options[:in]
      sort         = options.fetch(:sort){ "relevance" }
      http_options[:query].merge!({:sort => sort})

      if subreddit
        http_options[:query].merge!({:restrict_sr => "1"})
      end

      if terms
        http_options[:query].merge!({:q => terms})
      end
      path = subreddit.to_s == "" ? "/r/search.json" : "/r/#{subreddit}/search.json"
      read(path, http_options)
    end

    # Read sent messages
    # @return [Array<Reddit::Message>]
    def sent_messages
      messages :sent
    end

    # Read received messages
    # @return [Array<Reddit::Message>]
    def received_messages
      messages :inbox
    end

    #Read unread messages
    # @return [Array<Reddit::Message>]
    def unread_messages
      messages :unread
    end

    # Read received comments
    # @return [Array<Reddit::Message>]
    def comments
      messages :comments
    end

    # Read post replies
    # @return [Array<Reddit::Message>]
    def post_replies
      messages :selfreply
    end

    protected
    def messages(kind)
      read("/message/#{kind.to_s}.json", :handler => "Message")
    end
  end
end
