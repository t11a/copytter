class IndexController < ApplicationController
  def index
    p_obj session
    if session[:oauth]
      # get access token
      access_token = OAuth::AccessToken.new(
        self.consumer,
        session[:oauth_token],
        session[:oauth_verifier]
      )
      
      # get friend timeline
      response = access_token.get('http://twitter.com/statuses/friends_timeline.json')

      case response
      when Net::HTTPSuccess
        @statuses = JSON.parse(response.body).each.collect do |status|
          status
        end
      when Net::HTTPClientError
        reset_session
      else
        reset_session
      end
    end
  end

  def oauth
    # request twitter.com to subscribe an unauthorized request_token
    request_token = self.consumer.get_request_token(
      :oauth_callback => "http://#{request.host_with_port}/callback"
    )
    session[:request_token] = request_token.token
    session[:request_token_secret] = request_token.secret

    redirect_to request_token.authorize_url
  end

  def callback
    consumer = self.consumer
    # exchange authorized request token for access token
    request_token = OAuth::RequestToken.new(
      consumer,
      session[:request_token],
      session[:request_token_secret]
    )
  begin
    access_token = request_token.get_access_token(
      {},
      :oauth_token => params[:oauth_token],
      :oauth_verifier => params[:oauth_verifier]
    )
  rescue => err
    case err
    when OAuth::Unauthorized
      reset_session
      flash[:notice] = err.to_s
      redirect_to :action => :index
      return
    else
      reset_session
      flash[:notice] = "Unknown Error."
      redirect_to :action => :index
      return
    end
  end
    # check the validity of access token
    response = consumer.request(
      :get,
      '/account/verify_credentials.json',
      access_token, { :scheme => :query_string}
    )

    case response
    when Net::HTTPSuccess
      @user_info = JSON.parse(response.body)
      unless @user_info['screen_name']
        flash[:notice] = "Authentication failed."
        redirect_to :action => :index
      end
      # set user info
      session[:id]                = @user_info['id']
      session[:name]              = @user_info['name']
      session[:screen_name]       = @user_info['screen_name']
      session[:profile_image_url] = @user_info['profile_image_url']
      session[:friends_count]     = @user_info['friends_count']
      session[:followers_count]   = @user_info['followers_count']
      session[:statuses_count]    = @user_info['statuses_count']
    else
      res = JSON.parse(response.body)
      
      RAILS_DEFAULT_LOGGER.error "Failed to get user info via OAuth"
      error_msg = res['error']
      error_msg ||= "Authentication Error."
      flash[:notice] = error_msg
      redirect_to :action => :index
      return
    end

    session[:request_token] = nil
    session[:request_token_secret] = nil
    session[:oauth] = true
    session[:oauth_token] = access_token.token
    session[:oauth_verifier] = access_token.secret
    redirect_to :action => :index
  end

  def tweet
    tweet = params[:tweet]
    # get access token
    access_token = OAuth::AccessToken.new(
      self.consumer,
      session[:oauth_token],
      session[:oauth_verifier]
    )
    
    # get friend timeline
    response = access_token.post(
      'http://api.twitter.com/1/statuses/update.json',
      'status' => tweet
    )
    
    status = JSON.parse(response.body).each do |res|
      res
    end
      
    redirect_to :action => :index
  end
  
  def rank
    uri_friends_tl = "http://api.twitter.com/1/statuses/friends_timeline.json"
    count = "200"
    page  = 3
    
    # get access token
    access_token = OAuth::AccessToken.new(
      self.consumer,
      session[:oauth_token],
      session[:oauth_verifier]
    )
    
    # get max id of friends TL
    response = access_token.get( uri_friends_tl + "?count=1" )
    statuses = JSON.parse(response.body).each.collect {|status|
      status
    }

    max_id = nil
    statuses.each do |status|
      max_id = status['id'].to_s
    end

    if max_id.nil?
      flash[:notice] = "GET Max tweet ID FAILURE.Please try again after a while."
      redirect_to :action => :index
      return
    end
    
    # get user histgram
    @user_hist = Hash::new
    @user_prof = Hash::new
    @user_text = Hash::new
    
    @created_at = "" # store latest time
    @sum = 0          # store total tweets
    page.times {|pg|
      uri = uri_friends_tl + "?max_id=" + max_id + "&count=" + count + "&page=" + (pg+1).to_s
      response = access_token.get( uri )
      JSON.parse(response.body).each {|status|
        @created_at = status['created_at']
        user = status['user']
        screen_name = user['screen_name']
        
        if @user_hist.include?(screen_name)
          @user_hist[screen_name] += 1
        else
          @user_hist[screen_name] = 1
        end
        
        if !@user_prof.key?(screen_name)
          tmp_hash = Hash::new
          tmp_hash['name'] = user['name']
          tmp_hash['profile_image_url'] = user['profile_image_url']
          
          @user_prof[screen_name] = tmp_hash
        end
        
        if @user_text.key?(screen_name)
          ary = Array::new
          ary = @user_text[screen_name]
          ary.push([status['text'], @created_at])
          @user_text[screen_name] = ary
        else
          ary = Array::new
          ary.push([status['text'], @created_at])
          @user_text[screen_name] = ary
        end
        
        @sum += 1
      }
    }

  end

  def dm_inbox
    # get access token
    access_token = OAuth::AccessToken.new(
      self.consumer,
      session[:oauth_token],
      session[:oauth_verifier]
    )
    
    uri_dm = "http://api.twitter.com/1/direct_messages.json"
    count = "100"
    
    response = access_token.get( uri_dm + "?count=" + count )
    case response
    when Net::HTTPSuccess
      @d_msgs = JSON.parse(response.body)
    else
      flash[:notice] = "get DM INBOX Error."
    end
  end
  
  def dm_send_box
    # get access token
    access_token = OAuth::AccessToken.new(
      self.consumer,
      session[:oauth_token],
      session[:oauth_verifier]
    )
    
    uri_dm = "http://api.twitter.com/1/direct_messages/sent.json"
    count = "100"

    response = access_token.get( uri_dm + "?count=" + count )
    case response
    when Net::HTTPSuccess
      @d_msgs = JSON.parse(response.body)
    else
      flash[:notice] = "get DM INBOX Error."
    end
  end
  
  def dm_box
    uri_dm       = "http://api.twitter.com/1/direct_messages.json"
    uri_dm_sent  = "http://api.twitter.com/1/direct_messages/sent.json"
    
    # get access token
    access_token = OAuth::AccessToken.new(
      self.consumer,
      session[:oauth_token],
      session[:oauth_verifier]
    )
    
    res_a = get_response(uri_dm, access_token, 100)
    res_b = get_response(uri_dm_sent, access_token, 100)

    @dms = res_a + res_b
=begin
    # sort by time(1st element)
    (res_a + res_b).sort {|a, b|
      [b[0], a[1]] <=> [a[0], b[1]]
    }.each do |arr|
      p arr
    end
=end
  end

  def logout
    reset_session
    redirect_to :action => :index
  end
  
  private
  def get_response(uri, token, count=50)
    response = token.get( uri + "?count=" + count.to_s )
    case response
    when Net::HTTPSuccess
      res = JSON.parse(response.body).each.collect do |d_msg|
        sender = d_msg['sender']
        recipient = d_msg['recipient']
  
        text_hash = Hash::new
        text_hash['s_name'] = sender['name']
        text_hash['r_name'] = recipient['name']
        text_hash['profile_image_url'] = sender['profile_image_url']
        text_hash['text'] = d_msg['text']
        text_hash['user_flag'] = true if sender['id'] == session[:id]
  
        [Time.parse(d_msg['created_at']), text_hash]
      end
    else
      flash[:notice] = "get DM Error."
    end
  end

  def p_obj obj
    p "#####"
    p obj
    p "#####"
  end
end
