class IndexController < ApplicationController
  def index
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

  private
  def p_obj obj
    p "#####"
    p obj
    p "#####"
  end
end
