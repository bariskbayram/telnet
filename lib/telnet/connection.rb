# frozen_string_literal: true

module TelnetServerClient
  class Connection
    attr_reader :connection_id, :socket, :thread

    def initialize(socket, thread)
      @connection_id = socket.fileno
      @socket = socket
      @thread = thread
    end
  end
end
