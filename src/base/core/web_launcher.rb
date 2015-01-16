# file: web_launcher.rb
# used to go on web url

module LanciaApp
    def self.log(msg)
      #if ENV['LAUNCHY_DEBUG'] == 'true' then
      #    $stderr.puts "LAUNCHY_DEBUG: #{msg}"
      #end
      #puts msg
    end
     
    class Application
        @@KNOWN_OS_FAMILIES = [ :windows, :darwin, :nix, :cygwin ]
        
        class << self
            def inherited(sub_class)
                application_classes << sub_class
            end            
            def application_classes
                @application_classes ||= []
            end                
            
            def find_application_class_for(*args)
                LanciaApp.log "#{self.name} : finding application classes for [#{args.join(' ')}]"
                application_classes.find do |klass| 
                    LanciaApp.log "#{self.name} : Trying #{klass.name}"
                    if klass.handle?(*args) then
                        true
                    else
                        false
                    end
                end
            end
            
           # find an executable in the available paths
            # mkrf did such a good job on this I had to borrow it.
            def find_executable(bin,*paths)
                paths = ENV['PATH'].split(File::PATH_SEPARATOR) if paths.empty?
                paths.each do |path|
                    file = File.join(path,bin)
                    if File.executable?(file) then
                        LanciaApp.log "#{self.name} : found executable #{file}"
                        return file
                    end
                end
                LanciaApp.log "#{self.name} : Unable to find `#{bin}' in #{paths.join(', ')}"
                return nil
            end
            
            # return the current 'host_os' string from ruby's configuration
            def my_os
                if ENV['LAUNCHY_HOST_OS'] then 
                    LanciaApp.log "#{self.name} : Using LAUNCHY_HOST_OS override of '#{ENV['LAUNCHY_HOST_OS']}'"
                    return ENV['LAUNCHY_HOST_OS']
                else
                    ::Config::CONFIG['host_os']
                end
            end
        
            # detect what the current os is and return :windows, :darwin or :nix
            def my_os_family(test_os = my_os)
                case test_os
                when /mswin/i
                    family = :windows
                when /windows/i
                    family = :windows
                when /darwin/i
                    family = :darwin
                when /mac os/i
                    family = :darwin
                when /solaris/i
                    family = :nix
                when /bsd/i
                    family = :nix
                when /linux/i
                    family = :nix
                when /cygwin/i
                    family = :cygwin
                else
                    $stderr.puts "Unknown OS familiy for '#{test_os}'.  Please report this bug to #{Launchy::SPEC.email}"
                    family = :unknown
                end
            end
        end


        # Determine the appropriate desktop environment for *nix machine.  Currently this is
        # linux centric.  The detection is based upon the detection used by xdg-open from 
        # http://portland.freedesktop.org/wiki/XdgUtils
        def nix_desktop_environment
            if not @nix_desktop_environment then
                @nix_desktop_environment = :generic
                if ENV["KDE_FULL_SESSION"] || ENV["KDE_SESSION_UID"] then
                    @nix_desktop_environment = :kde
                elsif ENV["GNOME_DESKTOP_SESSION_ID"] then
                    @nix_desktop_environment = :gnome
                elsif find_executable("xprop") then
                    if %x[ xprop -root _DT_SAVE_MODE | grep ' = \"xfce\"$' ].strip.size > 0 then
                        @nix_desktop_environment = :xfce
                    end
                end
                LanciaApp.log "#{self.class.name} : nix_desktop_environment => '#{@nix_desktop_environment}'"
            end
            return @nix_desktop_environment
        end
        
        # find an executable in the available paths
        def find_executable(bin,*paths)
            Application.find_executable(bin,*paths)
        end
        
        # return the current 'host_os' string from ruby's configuration
        def my_os
            Application.my_os
        end
        
        # detect what the current os is and return :windows, :darwin, :nix, or :cygwin
        def my_os_family(test_os = my_os)
            Application.my_os_family(test_os)
        end
        
        # returns the list of command line application names for the current os.  The list 
        # returned should only contain appliations or commands that actually exist on the
        # system.  The list members should have their full path to the executable.
        def app_list
            @app_list ||= self.send("#{my_os_family}_app_list")
        end
                
        # On darwin a good general default is the 'open' executable.
        def darwin_app_list
            LanciaApp.log "#{self.class.name} : Using 'open' application on darwin."
            [ find_executable('open') ]
        end
        
        # On windows a good general default is the 'start' Command Shell command
        def windows_app_list
            LanciaApp.log "#{self.class.name} : Using 'start' command on windows."
            %w[ start ]
        end
        
        # Cygwin uses the windows start but through an explicit execution of the cmd shell
        def cygwin_app_list
            LanciaApp.log "#{self.class.name} : Using 'cmd /C start' on windows."
            [ "cmd /C start" ]
        end
        
        # run the command
        def run(cmd,*args)
            args.unshift(cmd)
            cmd_line = args.join(' ')
            LanciaApp.log "#{self.class.name} : Spawning on #{my_os_family} : #{cmd_line}"
            
            if my_os_family == :windows then
                system cmd_line
            else
                # fork, and the child process should NOT run any exit handlers
                child_pid = fork do 
                                cmd_line += " > /dev/null 2>&1"
                                system cmd_line
                                exit! 
                            end
                Process.detach(child_pid)
            end
        end #run
    end #application
    
    ############################################################
    ############################################################
    
    class Browser < Application
        
        @@DESKTOP_ENVIRONMENT_BROWSER_LAUNCHERS = {
            :kde     => "kfmclient",
            :gnome   => "gnome-open",
            :xfce    => "exo-open",
            :generic => "htmlview"
        }
        
        @@FALLBACK_BROWSERS = %w[ firefox seamonkey opera mozilla netscape galeon ]
        
        class << self
            def run(*args)
                Browser.new.visit(args[0]) 
            end
            
            # return true if this class can handle the given parameter(s)
            def handle?(*args)
                begin 
                    LanciaApp.log "#{self.name} : testing if [#{args[0]}] (#{args[0].class}) is a url."
                    uri = URI.parse(args[0])
                    result =  [URI::HTTP, URI::HTTPS, URI::FTP].include?(uri.class)
                rescue Exception => e
                    # hmm... why does rcov not see that this is executed ?
                    LanciaApp.log "#{self.name} : not a url, #{e}" 
                    return false
                end
            end
        end
        
        def initialize
            raise "Unable to find browser to launch for os family '#{my_os_family}'." unless browser
        end                        
            
        # Find a list of potential browser applications to run on *nix machines.  
        # The order is:
        #     1) What is in ENV['LAUNCHY_BROWSER'] or ENV['BROWSER']
        #     2) xdg-open
        #     3) desktop environment launcher program
        #     4) a list of fallback browsers
        def nix_app_list
            if not @nix_app_list then
                browser_cmds = ['xdg-open']
                browser_cmds << @@DESKTOP_ENVIRONMENT_BROWSER_LAUNCHERS[nix_desktop_environment]
                browser_cmds << @@FALLBACK_BROWSERS
                browser_cmds.flatten!
                browser_cmds.delete_if { |b| b.nil? || (b.strip.size == 0) }
                LanciaApp.log "#{self.class.name} : Initial *Nix Browser List: #{browser_cmds.join(', ')}"
                @nix_app_list = browser_cmds.collect { |bin| find_executable(bin) }.find_all { |x| not x.nil? }
                LanciaApp.log "#{self.class.name} : Filtered *Nix Browser List: #{@nix_app_list.join(', ')}"
            end
            @nix_app_list
        end
                                
        # return the full command line path to the browser or nil
        def browser
            if not @browser then
                if ENV['LAUNCHY_BROWSER'] and File.exists?(ENV['LAUNCHY_BROWSER']) then
                    LanciaApp.log "#{self.class.name} : Using LAUNCHY_BROWSER environment variable : #{ENV['LAUNCHY_BROWSER']}"
                    @browser = ENV['LAUNCHY_BROWSER']
                elsif ENV['BROWSER'] and File.exists?(ENV['BROWSER']) then
                    LanciaApp.log "#{self.class.name} : Using BROWSER environment variable : #{ENV['BROWSER']}"
                    @browser = ENV['BROWSER']
                elsif app_list.size > 0 then
                    @browser = app_list.first
                    LanciaApp.log "#{self.class.name} : Using application list : #{@browser}"
                else
                    msg = "Unable to launch. No Browser application found."
                    LanciaApp.log "#{self.class.name} : #{msg}"
                    $stderr.puts msg
                end
            end
            return @browser
        end
        
        # launch the browser at the appointed url
        def visit(url)
            run(browser,url)
        end
    end #Browser
    
end #module
