Gem::Specification.new do |s|
  s.name = 'sps-sub'
  s.version = '0.2.1'
  s.summary = 'Subscribes to a SimplePubsub (SPS) broker'
  s.authors = ['James Robertson']
  s.files = Dir['lib/**/*.rb']
  s.add_runtime_dependency('websocket-eventmachine-client', '~> 1.0', '>=1.1.0')  
  s.signing_key = '../privatekeys/sps-sub.pem'
  s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'MIT'
  s.email = 'james@r0bertson.co.uk'
  s.homepage = 'https://github.com/jrobertson/sps-sub'
end
