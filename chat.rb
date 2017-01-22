require 'socket'
require 'logger'

include Socket::Constants

logger = Logger.new(STDOUT)

addresses = Addrinfo.getaddrinfo(nil, 3000, AF_INET, :STREAM, nil, AI_PASSIVE)

server = nil
addresses.each do |address|
  server = Socket.new(AF_INET, SOCK_STREAM, 0)
  logger.info("Starting server: #{server}")

  begin
    server.setsockopt(:SOCKET, :REUSEADDR, true)
    if server.bind(address) < 0
      logger.warn("can't bind #{socket} to #{address.inspect}, closing")
      server.close
    end
  rescue => error
    logger.error("#{error}: #{address.inspect}")
    server.close if server
  end
end

if server && !server.closed?
  logger.debug("Listening...")
  server.listen(10)
end

clients = [server]
loop do
  logger.debug("Waiting for #select")
  read, _, _ = IO.select(clients)
  logger.debug("Received #select, #{read}")

  read.each do |read|
    logger.debug("Processing #{read}")

    if read == server
      client, address = server.accept
      logger.info("New connection from #{client}:#{address.inspect}")
      clients << client
      logger.info("Total clients now: #{clients}")
    else
      logger.debug("Handling client #{read}")
      data = read.gets

      logger.debug("Client sent #{data.inspect}")
      if data.nil?
        logger.debug("No data, closing connection for #{read}")
        clients.delete(read)
        read.close
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
