# Introducing the Sps-sub gem

    require 'sps-sub'

    sps = SPSSub.new port: 8080

    def sps.onmessage(msg)
      puts "%s: %s"  % [Time.now.to_s, msg.inspect]
    end

    sps.subscribe topic: 'test'

output:

<pre>
Connected

2015-05-16 10:49:12 +0100: "test: hello"

</pre>

## Resources

* ?sps-sub https://rubygems.org/gems/sps-sub?

spssub subscribe client simplepubsub gem
