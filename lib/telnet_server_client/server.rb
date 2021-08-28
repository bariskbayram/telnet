# frozen_string_literal: true

require 'socket'
require 'logger'
require 'timeout'
require 'open3'

require_relative 'connection'
require_relative 'session'
require_relative 'server_base'

class Server < ServerBase
  USERNAME = 'admin'
  PASSWORD = 'password'

  def initialize(options)
    super options
    trap('INT', proc { close_server("CLOSE_X #{USERNAME} ~]$ ") })
  end

  def serve
    accept_connections do |socket|
      connection = Connection.new(socket, Thread.current)
      session = check_session_status(connection)

      if session.nil?
        check_authentication(connection)
        session = create_session
      end
      session.register_connection(connection)
      execute_command_with_loop(session, connection)
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

  def execute_command_with_loop(session, connection)
    request = read_data(session, connection)

    loop do
      send_all_command_result(session, request)
      request = read_data(session, connection)
    end
  end

  def send_all_command_result(session, request)
    execute_command(request) { |result| send_data_to_all(session, result) }
  end

  def send_command_result(connection, request)
    execute_command(request) { |result| send_data_to_connection(connection, result) }
  end

  def execute_command(request)
    Timeout.timeout(@options[:timeout]) do
      stdin, stdout = Open3.popen3(request)
      stdout.each_line { |line| yield line }
      yield "#{USERNAME} ~]$ "
      stdin.close
    end
  rescue Timeout::Error
    yield "#{USERNAME} ~]$ "
  rescue Errno::ENOENT
    yield "#{request} command not found...\n#{USERNAME} ~]$ "
  end

  def read_data(session, connection)
    data = read_data_from_connection(connection)
    if data.include?('SSTOP')
      @logger.info("Connection #{connection.connection_id} is stopped.")
      close_connection(session, connection)
    elsif data.include?('SKILL')
      close_session(session, "CLOSE_X #{USERNAME} ~]$ ")
      Thread.current.kill
    end
    data
  end
end
