#!/usr/bin/env ruby

# file: sps-sub.rb

require 'websocket-eventmachine-client'


class SPSSub

  def initialize(port: '59000', host: nil, address: nil, callback: nil)

    @host = host || address || 'localhost'
    @port = port.to_s
    @callback = callback
    
    # Trap ^C 
    Signal.trap("INT") { 
      puts ' ... Bye'
      @status = :quit
      exit
    }
    
    # Trap `Kill `
    Signal.trap("TERM") {
      @status = :quit
      exit
    }    
    
  end



  def subscribe(topic: '#', &blk)

    
    @t = Time.now

    em_connect(topic, &blk)
  end
  
  def em_connect(topic, &blk)
    
    client = self
    host, port = @host, @port 
    
    EM.run do

      address = host + ':' + port

      ws = WebSocket::EventMachine::Client.connect(:uri => 'ws://' + address)

      ws.onopen do
        puts "Connected"
      end

      ws.onmessage do |fqm, type|
        
        topic, msg = fqm.split(/:\s/,2)
        
        EM.defer do
          
          if block_given? then
            blk.call(msg, topic)
          elsif @callback
            @callback.ontopic(topic, msg)
          else
            onmessage msg
            ontopic topic, msg
          end
          
        end
                
      end

      ws.onclose do
        puts "Disconnected"

        return if @status == :quit
        sleep 2            
        puts 'retrying to connect ... '
        client.em_connect topic 
      end
      
      ws.onerror do |error|
        puts "Error occured: #{error}"
      end

      EventMachine.next_tick do
        ws.send 'subscribe to topic: ' + topic
      end

    end    
  end

  # This method is called when a new message is received
  #
  def onmessage(msg)
    puts "Received message: #{msg}"
  end
  
  # Same as onmessage but includes the topic as well as the msg
  #
  def ontopic(topic, msg)

  end
  
end

if __FILE__ == $0 then

  sps = SPSSub.new port: 8080

  def sps.onmessage(msg)
    puts "%s: %s"  % [Time.now.to_s, msg.inspect]
  end

  sps.subscribe topic: 'test'

end
