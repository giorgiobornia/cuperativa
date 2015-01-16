# file: gameavail_hlp.rb
# module used to get the information about game available

require 'rubygems'
require 'yaml'

##
# Class used to provides information about game supported
class InfoAvilGames
  ##
  # Provides detailed information about all supported games
  def self.info_supported_games(logger)
    supported_game_map = {}
    begin
      dir_games = File.join(File.dirname(__FILE__), '../../games')
      Dir.foreach(dir_games) do |filename|
        path_cand = File.join(dir_games , filename)
        if File.directory?(path_cand)
          #exams directories
          if (filename != "." && filename != "..")
            # potential game folder
            game_info_yaml = File.join(path_cand, 'game_info.yaml')
            if File.exist?(game_info_yaml)
              opt = YAML::load_file( game_info_yaml )
              if opt and opt.class == Hash
                next unless opt[:enabled]
                key = opt[:key].to_sym # key is a symbol, path is a string
                if supported_game_map[key] and logger
                  logger.error("CAUTION: game key #{key} is already set, please use an unique key (yaml: #{game_info_yaml}).")
                end
                supported_game_map[key] = {:name => opt[:name], 
                       :class_name => opt[:class_name], :opt => opt[:opt], 
                       :enabled => opt[:enabled], :desc => opt[:desc], 
                       :num_of_players => opt[:num_of_players],
                       :file_req => File.join(path_cand,  opt[:file_req])
                }
              end
            end
          end
        end
      end
    rescue
      supported_game_map = {}
      logger.error("ERROR on load_supported_games #{$!}") if logger
      #p $!
    end
    return supported_game_map
  end #end load_supported_games
end

if $0 == __FILE__
  map = InfoAvilGames.info_supported_games(nil)
  p map
end
