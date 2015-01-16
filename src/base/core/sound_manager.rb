#file: sound_manager.rb

##
# Sound player
class SoundManager
  
  @@resource_path = File.dirname(__FILE__) + "/../../../res"
  
  def initialize(resource_path=nil)
    @log =  Log4r::Logger["coregame_log"]
    @sound_enabled = true
    @sound_play_intro_onnetw = true
    @linux_sound_stoppped = {}
    @duration_linux = {}
    @duration_win = {}
    set_duration(:play_intro_netwgamestart, :async) 
    set_duration(:play_fitbell, :async)
    set_duration(:play_ba, :async)
    set_duration(:play_click4, :async)
    set_duration(:play_mescola, :async)
  end
  
  ##
  # Set the duration for the next play sound
  # duration: :loop, :async
  def set_duration(type, duration)
    if $g_os_type == :win32_system
      @duration_win[type] = Sound::ASYNC
      if duration == :loop
        @duration_win[type] = Sound::ASYNC|Sound::LOOP
      end
    end
    if $g_os_type == :linux
      @duration_linux[type] = duration
    end
    
  end
  
  def set_local_settings(app_settings)
    sound_opt = app_settings["sound"]
    if sound_opt
      @sound_enabled = sound_opt[:use_sound_ongame]  
      @sound_play_intro_onnetw = sound_opt[:play_intro_netwgamestart] 
    end 
  end
  
  def get_resource_path
    return @@resource_path
  end
  
  ##
  # Provides the sound source
  def get_sound_source(type)
    sound = nil
    case type
      when :play_intro_netwgamestart
        # intro for a new netwok game
        #@log.debug("Sound play intro init game")
        if @sound_play_intro_onnetw
          #sound = File.dirname(__FILE__) + "/../res/sound/alarm.wav"
          #sound = File.join(get_resource_path, "sound/alarm.wav")
          sound = File.join(get_resource_path, "sound/fitebell.wav") 
          #system("playsound " + sound) if $g_os_type == :linux # on LINUX
          # on ubuntu 8.04 don't find playsound anymore..
        end
      when :play_fitbell
        sound = File.join(get_resource_path, "sound/fitebell.wav")
      when :play_ba
        sound = File.join(get_resource_path, "sound/ba.wav")
      when :play_click4
        sound = File.join(get_resource_path, "sound/click_4bit.wav")
      when :play_mescola
        sound = File.join(get_resource_path, "sound/mischen1.wav")   
      else
        @log.debug("Sound not recognized #{type}")
    end #end case
    return sound
  end
  
  ##
  # Stop play a sound in loop
  def stop_sound(type)
    set_duration(type, :async)
    if $g_os_type == :win32_system
      Sound.stop()
    end
    if $g_os_type == :linux
      @linux_sound_stoppped[type] = true
    end
  end
  
   ##
  # Play a sound
  # type: type of the sound
  def play_sound(type)
    @log.debug("Play sound #{type}, os: #{$g_os_type}")
    sound = get_sound_source(type)
    
    #p @sound_enabled
    @linux_sound_stoppped[type] = false
    if sound and @sound_enabled == true
      Thread.new{
        if $g_os_type == :win32_system
          Sound.play(sound, @duration_win[type] )
        end
        if $g_os_type == :linux
          while !@linux_sound_stoppped[type]
            system("aplay -q " + sound)
            break if @duration_linux[type] != :loop
          end
        end 
      }
    end
  end
  
end