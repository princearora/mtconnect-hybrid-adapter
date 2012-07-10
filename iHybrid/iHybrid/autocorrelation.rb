def autocorrelate(signal, window_size)
  r = Array.new

  def r.[](idx)
    (idx < 0 or idx >= self.size) ? 0 : super(idx)
  end

  (0..signal.size).step do |n|
    (0..window_size).step do |i|
      r[i] += signal[n].to_f * signal[n - i].to_f
    end
  end

  return r
end
