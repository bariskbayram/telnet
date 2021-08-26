# frozen_string_literal: true

require 'socket'
require 'logger'
require 'timeout'
require 'open3'

require_relative 'connection'
require_relative 'session'

class Server
  USERNAME = 'admin'
  PASSWORD = 'password'

  def initialize(options)
    @options = options
    @tcp_server = TCPServer.new(options[:host], options[:port])
    @sessions = {}
    @mutex = Mutex.new
    @logger = Logger.new($stdout)

    trap('INT', proc { close_server })
  end

  def all_sessions
    @mutex.synchronize do
      @sessions
    end
  end

  def synchronize(&block)
    @mutex.synchronize(&block)
  end

  def serve
    @logger.info("Server started on #{@tcp_server.local_address.ip_address}:#{@tcp_server.local_address.ip_port}")

    loop do
      Thread.new(@tcp_server.accept) do |socket|
        connection = Connection.new(socket, Thread.current)
        session = check_session_status(connection)

        if session.nil?
          check_authentication(connection)
          session = Session.new
          synchronize { @sessions[session.session_id] = session }
        end
        session.register_connection(connection)
        listen_command(session, connection)
      end
    end
  end

  def check_session_status(connection)
    data = read_data_from_connection(connection)
    response = 'SESSION_CREATE'
    sessions = all_sessions

    if data.include?('SESSION_LIST')
      send_session_list(sessions, connection)
    elsif data.include?('SESSION_ATTACH') && sessions.size.positive?
      session_id = Integer(data.split(',')[0])
      response = 'SESSION_RESUME' if sessions[session_id]
      synchronize { sessions[session_id].is_alive = true if sessions[session_id] }
    end
    send_data_to_connection(connection, "#{response} #{USERNAME} ~]$ ")
    sessions[session_id]
  end

  def send_session_list(sessions, connection)
    response = ''
    sessions.each do |s|
      status = sessions[s[0]].is_alive ? 'ATTACHED' : 'DETACHED'
      response += "#{s[0]} - #{status}\n"
    end

    send_data_to_connection(connection, "#{response}, #{USERNAME} ~]$ ")
    reject_connection(connection)
  end

  def check_authentication(connection)
    username, password = read_data_from_connection(connection).split(',')
    login_count = 2

    while username != USERNAME || password != PASSWORD
      if login_count.zero?
        send_data_to_connection(connection, "403 #{USERNAME} ~]$ ")
        reject_connection(connection)
      end
      send_data_to_connection(connection, "401 #{USERNAME} ~]$ ")
      username, password = read_data_from_connection(connection).split(',')
      login_count -= 1
    end

    send_data_to_connection(connection, "200 #{USERNAME} ~]$ ")
  end

  def listen_command(session, connection)
    request = read_data(session, connection)

    loop do
      begin
        Timeout.timeout(@options[:timeout]) do
          stdin, stdout = Open3.popen3(request)
          stdout.each_line do |line|
            send_data_to_all(session, line)
          end
          send_data_to_all(session, "#{USERNAME} ~]$ ")
          stdin.close
        end
      rescue Timeout::Error
        send_data_to_all(session, "#{USERNAME} ~]$ ")
      rescue Errno::ENOENT
        send_data_to_all(session, "#{request} command not found...\n#{USERNAME} ~]$ ")
      end

      request = read_data(session, connection)
    end
  end

  def read_data(session, connection)
    data = read_data_from_connection(connection)
    if data.include?('SSTOP')
      @logger.info("Connection #{connection.connection_id} is stopped.")
      close_connection(session, connection)
    elsif data.include?('SKILL')
      close_session(session)
      Thread.current.kill
    end
    data
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

  def close_session(session)
    session.connections.each do |connection|
      connection.socket.puts("CLOSE_X #{USERNAME} ~]$ ") unless connection.thread.eql?(Thread.current)
      connection.socket.close
      connection.thread.kill unless connection.thread.eql?(Thread.current)
    end
    synchronize { @sessions.delete(session.session_id) }
    @logger.info("Session #{session.session_id} is closed.")
  end

  def close_server
    Thread.new do
      sessions = all_sessions
      if sessions.size.positive?
        sessions.each_value do |session|
          close_session(session)
        end
      end
    end.join
    sleep(5)
    exit
  end
end
