# frozen_string_literal: true

module Telnet
  class Session
    @@session_index = 0

    attr_accessor :is_alive
    attr_reader :session_id, :connections

    def initialize
      @session_id = @@session_index
      @@session_index += 1
      @connections = []
      @is_alive = true
    end

    def register_connection(connection)
      @connections << connection
    end
  end
end