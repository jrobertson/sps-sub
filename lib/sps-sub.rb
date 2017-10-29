#!/usr/bin/env ruby

# file: sps-sub.rb

require 'websocket-eventmachine-client'


class SPSSub

  def initialize(hosts: [], port: '59000', host: nil, address: nil, 
                 callback: nil, log: nil )

    log.info 'SPSSub/initialize: active' if log
    
    if host.nil? and address.nil? and hosts.any? then
      hostx, portx = hosts.first.split(':',2)
      portx ||= port
      @host, @port = hostx, portx
    else
      @host = host || address || 'localhost'
      @port = port.to_s
    end
    
    @callback = callback
    @retry_interval = 1
    @hosts = hosts
    @log = log
    
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

  def notice(s)
    
    EventMachine.next_tick do
      @ws.send s
    end    
    
  end

  def subscribe(topic: '#', &blk)
    
    @t = Time.now

    em_connect(topic, &blk)
  end
  
  def em_connect(topic, &blk)
    
    client = self
    host, port, log = @host, @port, @log
    
    EM.run do

      address = host + ':' + port

      @ws = ws = WebSocket::EventMachine::Client.connect(:uri => 'ws://' + address)

      ws.onopen do
        status_msg = "Connected"
        puts status_msg
        log.info 'SPSSub/em_connect: onopen: ' + status_msg if log
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
        status_msg = "Disconnected"
        log.info 'SPSSub/em_connect: onclose: ' + status_msg if log

        return if @status == :quit
        
        if @hosts.any? then
          
          hostx, portx = @hosts.rotate!.first.split(':',2)
          portx ||= @port
          @host, @port = hostx, portx
          client.em_connect topic
          
        else
          @retry_interval *= 2        
          sleep @retry_interval        
          @retry_interval = 1 if @retry_interval > 30
    
          status_msg = "retrying to connect to #{@host}:#{@port}... "
          puts status_msg
          log.info 'SPSSub/em_connect: onclose' + status_msg if log
          client.em_connect topic
        end
      end
      
      ws.onerror do |error|
        status_msg = "Error occured: #{error}"
        puts status_msg
        
        log.info 'SPSSub/em_connect: onerror: ' + status_msg if log
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
