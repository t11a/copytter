# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_twitterOAuth20100522_session',
  :secret      => '5eaafbec14069662d04c44abbb64656fda9bbb5192a5c50d37dadd12f86c024fbfcbca99a021ad8c50e74f4c7368a908cae0194cc4c858cfa48dbef216f76112'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
