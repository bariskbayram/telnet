# frozen_string_literal: true

class Session
  @@session_index = 0

  attr_accessor :is_alive
  attr_reader :session_id, :connections

  def initialize
    @session_id = @@session_index
    @@session_index += 1
    @connections = []
    @is_alive = true
    @mutex = Mutex.new
  end

  def register_connection(connection)
    @mutex.synchronize do
      @connections << connection
    end
  end
end
