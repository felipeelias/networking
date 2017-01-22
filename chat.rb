require 'socket'
require 'logger'

include Socket::Constants

logger = Logger.new(STDOUT)
server = TCPServer.new(3000)

clients = [server]
loop do
  logger.debug("Waiting for #select")
  read, _, _ = IO.select(clients)
  logger.debug("Received #select, #{read}")

  read.each do |read|
    if read == server
      client = server.accept
      clients << client
      logger.info("New connection from #{client}. Clients: #{clients.inspect}")
    else
      data = read.gets
      logger.debug("Client sent: #{data.inspect}")

      if data.nil?
        clients.delete(read)
        read.close
        logger.debug("No data, closing connection for #{read}")
      else
        clients.each do |client|
          if client != server && client != read
            logger.debug("Broadcasting message to #{client}")
            client.write("[from #{read}]: #{data}")
          end
        end
      end
    end
  end
end
