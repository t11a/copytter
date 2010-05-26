module IndexHelper
  def time_format time
    time.strftime "%Y/%m/%d %H:%M:%S %Z"
  end
end
