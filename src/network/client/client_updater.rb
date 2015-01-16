# file: client_updater.rb
# manage a client update with the server

$:.unshift File.dirname(__FILE__) + '/../..'

require 'rubygems'
require 'net/http'
require 'fileutils'
require 'log4r'
require 'archive/tar/minitar' # to install it: gem install -r archive-tar-minitar
require 'zlib'
require 'yaml'
require 'base/core/cup_strings'

##
# Class used to manage the full client update process
# Process is stepped in 3 stage: download package, decompress into a tmp dir
# install a decompressed package into a new directory that partial or totally
# substitute the current app directory 
class ClientUpdaterCtrl
  attr_accessor :target_app_root_path, :out_download_pack_path, :out_package_down
  attr_accessor :gui_progress, :net_controller, :info_package
  
  def initialize
    # server where to find update package to download (no http://)
    @url_server_name_pkg = '127.0.0.1'
    # filename of the package to download
    @url_file_name_pkg = '' # e.g. /tmp/upd_cup_0_6_0.tgz
    @gui_progress = nil
    @net_controller = nil
    @log = Log4r::Logger["coregame_log"]
    # folder where the exe or the bin is present, it is the application root
    @target_app_root_path = File.expand_path(File.join( File.dirname(__FILE__), '../../../..'))
    # out folder where the download package is stored
    @out_download_pack_path = File.join( @target_app_root_path, 'download')
    # manifest filename
    @manifest_fname = 'manifest'
    # application destination root subfolder
    @app_root_subfolder = 'app'
    # version of the new installed package
    @new_version_str = '0.0.0'
    # used to manage state
    @model_net_data = nil
    # update progress
    @dialog_sw = nil
    # error message
    @error_message = "Errore"
    # information about package that need to be installed
    @info_package = {}
    # update progress indicator
    @update_prg_ind = 0
    @updater_yaml_interface = "updater_process.yml"
  end
  
  ##
  # Set info about server and package
  def set_package_src(server_name, package_name)
    @url_server_name_pkg = server_name # NOTE: don't use http://
    @url_file_name_pkg = package_name
    # better is to set a complete url with http://... and then use URI.parse()
  end
  
  ##
  # Download and save the package
  def download_update_package
    @log.debug "Donwloading from #{@url_server_name_pkg}..."
    http=Net::HTTP.start(@url_server_name_pkg)
    # this call is blocking but it works also with medium files.
    # tested on 16Mb file without problems
    #resp = http.get(@url_file_name_pkg)
    # using iterator
    resp = http.request_get(@url_file_name_pkg)
    # check if the file was found
    case resp
    when Net::HTTPSuccess     then
      @log.debug "Download OK"
      # download OK
      FileUtils.mkdir_p(@out_download_pack_path) unless File.directory? @out_download_pack_path
      # url found and downloaded
      pack_filename = File.basename(@url_file_name_pkg)
      @out_package_down = File.join(@out_download_pack_path,pack_filename)
      # store it into a file 
      File.open(@out_package_down, 'wb'){|f| f << resp.body}
      @log.debug "Download saved on #{@out_package_down}"
    else
      raise "Package to download #{@url_file_name_pkg} not found on server #{@url_server_name_pkg}"
    end
  end
  
  ##
  # Provides the directory name where files are untared. This the root dir
  # of new files where to find the manifest.
  def root_dir_untarfiles
    pkg_name = @out_package_down
    dir_to_unpack = File.dirname(pkg_name)
    name_extr_folder = File.basename(pkg_name).split(".").first
    return File.join(dir_to_unpack, name_extr_folder)
  end
  
  
  ##
  # Untar downloaded package. Extract package inside the package directory.
  def untar_downloaded_package
    pkg_name = @out_package_down
    dir_to_unpack = File.dirname(pkg_name)
    name_extr_folder = File.basename(pkg_name).split(".").first
    old_dir = Dir.pwd
    begin
      Dir.chdir(dir_to_unpack)
      @log.info("Untar package: #{pkg_name}")
      tgz = Zlib::GzipReader.new(File.open(pkg_name, 'rb'))
      step_inc = 2
      count = 0
      Archive::Tar::Minitar.unpack(tgz, "./#{name_extr_folder}", []) do |fileop, filename, infodet|
        count += 1
        if count % step_inc == 0
          @update_prg_ind += 1
          step_inc = step_inc * 2 if step_inc < 80
          if @update_prg_ind >= 80
            @update_prg_ind  = 79
          end
          #p @update_prg_ind
          @dialog_sw.update_progress(@update_prg_ind) if @dialog_sw
        end
        
      end
        
    #rescue
    #  raise "Untar download package error (#{@out_package_down})"
    ensure
      Dir.chdir(old_dir)
    end
  end
  
  ##
  # Process a file to be installed in app sub directory 
  # new_file_hash: hash with :src and :dst key for source and destination 
  def proc_file_toinst(new_file_hash, root_new_files)
    new_file = new_file_hash[:src]
    dst_file = new_file_hash[:dst]
    @log.debug("Processing file: #{new_file}")
    app_dir_dst = File.join(@target_app_root_path, @app_root_subfolder)
    old_dst_file = File.join(app_dir_dst, dst_file)
    src_file =  File.join(root_new_files, new_file)
    # copy file
    FileUtils.cp_r(src_file, old_dst_file)
    @log.debug("Copy file #{src_file} to #{old_dst_file}")
  rescue
    @log.error("proc_file_toinst error #{$!}")
  end
  
  ##
  # Process a file to be installed in app sub directory 
  # new_file_hash: hash with :src and :dst key for source and destination 
  def proc_file_toinst(new_file_hash, root_new_files)
    new_file = new_file_hash[:src]
    dst_file = new_file_hash[:dst]
    @log.debug("Processing file: #{new_file}")
    app_dir_dst = File.join(@target_app_root_path, @app_root_subfolder)
    old_dst_file = File.join(app_dir_dst, dst_file)
    src_file =  File.join(root_new_files, new_file)
    # copy file
    FileUtils.cp_r(src_file, old_dst_file)
    @log.debug("Copy file #{src_file} to #{old_dst_file}")
  rescue
    @log.error("proc_file_toinst error #{$!}")
  end
  
  ##
  # Process a new directory to install in app subdirectory
  # new_dir: forlder into untarred package
  # root_new_files: untar root directory
  def proc_dir_toinst(new_dir, root_new_files)
    @log.debug("Processing dir: #{new_dir}")
    app_dir_dst = File.join(@target_app_root_path, @app_root_subfolder)
    old_dest_dir = File.join(app_dir_dst, new_dir)
    if File.directory?(old_dest_dir)
      # old dir backup
      time_form = Time.now.strftime("%y%m%d%H%M%S")
      old_dest_bckdir = "#{old_dest_dir}_#{time_form}"
      FileUtils.mv(old_dest_dir, old_dest_bckdir)
      @log.info("moved directory #{old_dest_dir} to backup dir #{old_dest_bckdir}")
    else
      @log.debug("#{old_dest_dir} not a directory")
    end
    # copy source directory in to destination recursively
    src_dir = File.join(root_new_files, new_dir)
    FileUtils.cp_r(src_dir ,old_dest_dir)
    @log.debug("Copy dir #{src_dir} to #{old_dest_dir}")
  end
  
  ##
  # When the package is extracted, we need to install new files.
  # Load and parse manifest file in order to install new package
  def execute_manifest
    # load manifest, it is on the root dir of the package
    root_new_files = root_dir_untarfiles
    @log.debug("execute_manifest, search manifest in dir #{root_new_files}")
    mani_filename = File.join(root_new_files, @manifest_fname)
    # open updater_process.yml
    updater_dir = File.join(File.dirname(__FILE__), "../../../../updater")
    updater_yamlname = File.join(updater_dir, @updater_yaml_interface)
    updt = YAML::load_file( updater_yamlname )
    
    updt[:process_manifest] = true
    updt[:manifest_dir] = root_new_files
    # write back 
    File.open( updater_yamlname, 'w' ) do |out|
      YAML.dump( updt, out )
    end
    @log.debug "Information ready on yaml for updater."
    # read the new version
    opt = YAML::load_file( mani_filename )
    if opt
      if opt.class == Hash
        @new_version_str = opt[:version_str]
      end
    end
#    opt = YAML::load_file( mani_filename )
#    if opt
#      if opt.class == Hash
#        arr_newdir =  opt[:new_dir]
#        version_title = opt[:version_title]
#        arr_newfiles = opt[:new_file]
#        @new_version_str = opt[:version_str]
#        if version_title
#          @log.info("Update description: #{version_title}")
#        end
#        if arr_newdir
#          # process all directories
#          arr_newdir.each{|x| proc_dir_toinst(x, root_new_files)}
#        end
#        if arr_newfiles
#          # process all single files
#          arr_newfiles.each{|x| proc_file_toinst(x, root_new_files)}
#        end
#      else
#        @log.error("Malformed manifest")
#      end
#    else
#      @log.error("Manifest file #{mani_filename} not found")
#    end
  rescue
    @log.error("Error on execute_manifest #{$!}")
    raise("Errore nell'esecuzione del manifesto")
  end
  
  ##
  # Display a default manifets to be changed when a new package is created
  def display_default_manifest
    # this dirctories are replaced with dirs a new package
    opt = {}
    # this section overwrite the destination with the new directory.
    # Old directory is unamed
    opt[:new_dir] = ['/src']
    # new files to installed, no renaming of the old is used
    opt[:new_file] = [{:src => '/readme.txt', :dst => '/readme.txt'}]
    # package description 
    opt[:version_title] = 'patch to version 0.5.5' 
    opt[:version_str] = '0.5.5'
    @log.debug( YAML.dump( opt) )
  end
  
  ##
  # start the install process with patch file
  def begin_install_patch(model, patch_filename)
    @model_net_data = model
    @error_message = "Aggiornamento fallito."
    if @gui_progress
      # shows a little dialog information to inform user that vae to restart application
      str_text = u"Sto per applicare una nuova versione del programma \ncuperativa\n"
      str_text += "Vuoi continuare?"
      str_title = "Vuoi aggiornare il programma?"
      @dialog_sw = @gui_progress.get_sw_dlgdialog 
      if @dialog_sw
        @dialog_sw.button_state_initial
        @dialog_sw.set_job_install(:install_package_patch, patch_filename)
        @dialog_sw.set_text(str_text)
        @dialog_sw.clientup = self
        @dialog_sw.show
      end
      return
    end
  end
  
  ##
  # Install update starting from a patch stored into a local file
  def install_package_patch(patch_filename)
    @log.debug "install_package_patch: #{patch_filename}"
    @dialog_sw = @gui_progress.get_sw_dlgdialog
    begin
      @out_package_down = patch_filename
      @dialog_sw.update_progress(@update_prg_ind = 15) if @dialog_sw
      untar_downloaded_package
      @dialog_sw.update_progress(@update_prg_ind = 80) if @dialog_sw
      execute_manifest
      @dialog_sw.update_progress(@update_prg_ind =90) if @dialog_sw
      restart_application
    rescue
      str = "Install new software version failed.\n -> #{$!}"
      @log.error(str)
      raise("Errore: update del programma NON riuscita.\nCausa:\n#{str}") 
    end
  end
  
  ##
  # Manage the process of update a new version from download a new package till
  # install it and trigger a restart
  def install_package
    begin
      download_update_package
      @dialog_sw.update_progress(@update_prg_ind =40) if @dialog_sw
      untar_downloaded_package
      @dialog_sw.update_progress(@update_prg_ind =80) if @dialog_sw
      execute_manifest
      @dialog_sw.update_progress(@update_prg_ind =90) if @dialog_sw
      restart_application
    rescue
      str = "Install new software version failed.\n -> #{$!}"
      @log.error(str)
      raise("Errore: update del programma NON riuscita.\nCausa:\n#{str}")  
    end
  end
  
  ##
  # The client update process should be asked to the user
  # We have the same problem of the restart routine: on worker thread problems with modal dialogbox
  # Show the modaldialogbox inside a timer handler
  def install_package_question(model)
    @model_net_data = model
    if @gui_progress
      @log.info("Ask if the user want update the client")
      # ask it on main thread
      @gui_progress.registerTimeout(100, :onTimeoutAskInstallPack, self)
    end
  end
  
  ##
  # Dialog notification to start update sequence
  # This function is called from update progress dialogbox (swupdate_dlg.rb)
  # job_to_start: method called in background for installation process
  def start_update_sequence(*args)
    @log.debug "start_update_sequence with #{args}"
    Thread.new{
    begin
      @gui_progress.log_sometext("Aggiornamento iniziato....\n")
      @gui_progress.hide
      @dialog_sw.set_text "Aggiornamento in corso, attendere..."
      @dialog_sw.update_progress(@update_prg_ind =2)
      #sleep 5
      #install_package
      if args[0].size == 1
        send args[0][0]
      elsif args[0].size == 2
        send args[0][0], args[0][1]
      else
        raise "ERRORE: start_update_sequence: programming error(job parameters not supported)"
      end
      #restart_application
      @dialog_sw.update_progress(@update_prg_ind =100)
      @dialog_sw.set_text "Aggiornamento terminato con successo."
      @gui_progress.log_sometext("Aggiornamento finito OK\n")
      # now all is terminated without errors
      @dialog_sw.end_update_proccess
      @model_net_data.event_cupe_raised(:ev_update_terminated)
    rescue
      # something goes wrong
      error_msg = "ERRORE: **** Installazione nuovo software fallita.\n -> #{$!}"
      @log.error(error_msg)
      @gui_progress.log_sometext("#{error_msg}\n")
      @dialog_sw.update_progress(@update_prg_ind =100)
      @dialog_sw.set_text "ERRORE durante la fase di aggiornamento: \n#{$!}\nImpossibile continuare col gioco di rete\n"
      error_and_disconnect
      @dialog_sw.end_update_proccess
    ensure
      @gui_progress.show
    end
    }
  end
  
  ##
  # Shows an error message and disconnect
  def error_and_disconnect
    #@gui_progress.log_sometext("Impossibile continuare con il gioco in rete. Questo programma non e' aggiornato.\nMaggiori informazioni su www.invido.it\n")
    @log.debug "client update disconnect"
    @gui_progress.log_sometext(@error_message)
    if @net_controller
      @net_controller.close_remote_srv_conn
    end
    
  end
  
  ##
  # Dialog notification to start update sequence
  def cancel_update_sequence
    error_and_disconnect
    if @dialog_sw
      @dialog_sw.button_state_initial
      @dialog_sw.hide
    end
    @model_net_data.event_cupe_raised(:ev_update_terminated)
  end
  
  ##
  # Now we can ask the user if want to install a new software
  def onTimeoutAskInstallPack
    if @gui_progress
      # shows a little dialog information to inform user that vae to restart application
      str_text = u"U+00c8 disponibile una nuova versione del programma Cuperativa.\n"
      str_text += u"Essa U+00e8 necessaria per giocare in rete.\nVuoi aggiornare il programma cuperativa?\n"
      str_text += u"(in caso negativo non sarU+00e0 possibile utilizzare la rete).\n"
      str_text += u"\nIl pacchetto da scaricare U+00e8 di #{@info_package[:size]}\n"
      str_text += u"Nota sulla nuova versione:\n"
      str_text += u"#{@info_package[:descr]}\n"
      str_title = "Vuoi aggiornare il programma?"
      @dialog_sw = @gui_progress.get_sw_dlgdialog 
      if @dialog_sw
        @error_message = "Impossibile continuare con il gioco in rete. Questo programma non e' aggiornato.\nMaggiori informazioni su www.invido.it\n"
        @dialog_sw.button_state_initial
        @dialog_sw.set_job_install(:install_package)
        @dialog_sw.set_text(str_text)
        @dialog_sw.clientup = self
        @dialog_sw.show
      end
      return
      ##res = @gui_progress.modal_yesnoquestion_box(str_title , str_text )
      ##dlg = DlgSwUpdate.new(@gui_progress, str_title, str_text)
      #if dlg.execute != 0
        ## start install process
        ##TEST CODE.....
        ##install_package
        ##sleep 10
      #else
        ## close connection
        #@gui_progress.log_sometext("Impossibile continuare con il gioco in rete. Questo programma non e' aggiornato.\nMaggiori informazioni su www.invido.it\n")
        #if @net_controller
          #@net_controller.close_remote_srv_conn
        #end
      #end
    end
  end
  
  ##
  # Trigger a restart application
  def restart_application
    if @gui_progress
      @log.info("Prepare to restart application")
      @gui_progress.restart_need = true
      # wait on main thread
      @gui_progress.registerTimeout(200, :onTimeoutTerminateApp, self)
    end
  end
  
  ##
  # Using timer to terminate application
  def onTimeoutTerminateApp
    @log.info("Applicazione sta terminando...")
    if @gui_progress
      # shows a little dialog information to inform user that vae to restart application
      msgrestart = "Programma aggiornato con successo alla versione #{@new_version_str}.\nCuperativa ha bisogno di un riavvio  per continuare."
      if @dialog_sw
        @dialog_sw.set_text(msgrestart)
        @dialog_sw.update_progress(100)
        sleep 0.5
        @dialog_sw.hide
      end
      @gui_progress.modal_information_box("Restart",msgrestart )
    end
    # this function don't work if it is called inside a worker thread.
    # We use a timer to call this funtion from main thread
    FXApp.instance.handle(FXApp.instance, MKUINT(FXApp::ID_QUIT, SEL_COMMAND), nil)
  end
end

if $0 == __FILE__
  include Log4r
  log = Log4r::Logger.new("coregame_log")
  log.outputters << Outputter.stdout
  
  updater = ClientUpdaterCtrl.new
  updater.set_package_src('127.0.0.1', '/cuperativa/update_packages/ver_0_5_5_src.tar.gz')
  # use a temporary path to test install process
  updater.target_app_root_path = '/home/igor/Projects/ruby/tmp/test_update/cuperativa_app'
  updater.out_download_pack_path = '/home/igor/Projects/ruby/tmp/test_update/download'
  updater.out_package_down = 'C:\Biblio\ruby\ruby_win32_deployed\update_package/update_package_full.tar.gz'
  #updater.download_update_package
  #updater.install_package
  updater.untar_downloaded_package
  #updater.execute_manifest
  #updater.display_default_manifest
  #updater.install_package_patch(updater.out_package_down)
end
