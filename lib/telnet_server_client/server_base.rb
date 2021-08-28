# frozen_string_literal: true

class ServerBase
  def initialize(options)
    @options = options
    @tcp_server = TCPServer.new(options[:host], options[:port])
    @sessions = {}
    @mutex = Mutex.new
    @logger = Logger.new($stdout)
  end

  def all_sessions
    @mutex.synchronize do
      @sessions
    end
  end

  def synchronize(&block)
    @mutex.synchronize(&block)
  end

  def accept_connections
    @logger.info("Server started on #{@tcp_server.local_address.ip_address}:#{@tcp_server.local_address.ip_port}")
    loop do
      Thread.new(@tcp_server.accept) do |socket|
        yield socket
      end
    end
  end

  def create_session
    session = Session.new
    synchronize { @sessions[session.session_id] = session }
    session
  end

  def read_data_from_connection(connection)
    connection.socket.gets.chomp
  rescue IOError, NoMethodError
    ''
  end

  def send_data_to_connection(connection, message)
    connection.socket.puts(message) unless connection.socket.closed?
  end

  def send_data_to_all(session, message)
    session.connections.each do |connection|
      send_data_to_connection(connection, message)
    end
  end

  def reject_connection(connection)
    connection.socket.close
    connection.thread.kill
  end

  def close_connection(session, connection)
    synchronize do
      session.connections.delete_if { |c| c.connection_id == connection.connection_id }
      session.is_alive = false if session.connections.size.zero?
    end
    reject_connection(connection)
  end

  def close_session(session, close_request)
    session.connections.each do |connection|
      connection.socket.puts(close_request) unless connection.thread.eql?(Thread.current)
      connection.socket.close
      connection.thread.kill unless connection.thread.eql?(Thread.current)
    end
    synchronize { @sessions.delete(session.session_id) }
    @logger.info("Session #{session.session_id} is closed.")
  end

  def close_server(close_request)
    Thread.new do
      sessions = all_sessions
      if sessions.size.positive?
        sessions.each_value do |session|
          close_session(session, close_request)
        end
      end
    end.join
    sleep(5)
    exit
  end
end
