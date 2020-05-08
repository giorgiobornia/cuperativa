#!/bin/bash

#    You need certain packages related to Ruby.
#    Instructions for openSuSE 13.2 (it should be almost the same in all linux distros):
#    
#     Run the following as root:

      
      zypper in ruby
      zypper in ruby-devel
      zypper in fox16 
      zypper in fox16-devel
      gem install rubygems-update
      gem update --system 
      gem install fxruby
      gem install log4r
      gem install archive-tar-minitar
