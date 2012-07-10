def normalize(signal)
  signal.map { |signal_n| signal_n / signal[0] }
end