# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
require 'oauth'
require 'json'

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details
  before_filter :authorize, :except=>['index', 'oauth', 'callback']

  protected
  def consumer
    OAuth::Consumer.new(
      'CONSUMER KEY',
      'CONSUMER SECRET',
      {:site => "http://twitter.com/"}
    )
  end
  
  def authorize
    unless session[:oauth]
      flash[:notice] = "Please Sign in With twitter."
      redirect_to :controller=>'index', :action=>'index'
    end
  end
end
