module IndexHelper
  def time_format time
    time.strftime "%Y/%m/%d %H:%M:%S %Z"
  end
  
  def find_uri(s)
    uri_reg = URI.regexp(%w[http https])
    s.gsub(uri_reg) {%Q{<a href="#{$&}" target="_blank">#{$&}</a>}}
  end
end
