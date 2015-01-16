#file: mod_core_queue.rb

module CoreGameQueueHandler
  
  def init_process_queue
  end
  
  ##
  # Process only one event and return the size of events to process
  # Don't use suspend because we are processing only one event
  def process_only_one_gevent
    return 0 if @suspend_queue_proc == true
    return 0 unless @proc_queue
    if @proc_queue.size > 0
      next_ev_handl = @proc_queue.pop
      send(next_ev_handl)
    end
    return @proc_queue.size
  end
  
  ##
  # Process all queud events
  def process_next_gevent
    #@log.info "Process next event"
      return if @suspend_queue_proc == true
      while @proc_queue.size > 0
        next_ev_handl = @proc_queue.pop
        send(next_ev_handl)
        return  if @suspend_queue_proc == true
      end
    
  end
  
  ##
  # Clear game event queue
  def clear_gevent
      @num_of_suspend = 0
      @proc_queue.clear
  end
  
   ##
  # Suspend the queue process
  def suspend_proc_gevents(str="")
      @suspend_queue_proc = true
      @num_of_suspend += 1
      @log.debug("suspend_proc_gevents (#{str}) add lock #{@num_of_suspend}")
  end
  
  ##
  # continue with suspende queue events
  def continue_process_events(str="")
      @num_of_suspend -= 1
      if @num_of_suspend <= 0
        @num_of_suspend = 0
        @suspend_queue_proc = false
        @log.debug("Continue to process core events (locks: #{@num_of_suspend}) (#{str})")
        process_next_gevent
      else
        @log.debug("Suspend yet locked #{@num_of_suspend} (#{str})")
      end
  end
  
  ##
  # Submit the next event to be processed. It is the next processed
  def submit_next_event(ev)
      unless @proc_queue.index(ev) 
        #@proc_queue.push(ev)
        @proc_queue.insert(0,ev)
      else
        @log.warn "Event #{ev} duplicated in submit_next_event, ignore it"
      end
  end
  
  ##
  # Provides the gevent size
  def gevent_queue_size
    return @proc_queue.size
  end
  
end