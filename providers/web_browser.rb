#
# Cookbook Name:: gecos-ws-mgmt
# Provider:: web_browser
#
# Copyright 2013, Junta de Andalucia
# http://www.juntadeandalucia.es/
#
# All rights reserved - EUPL License V 1.1
# http://www.osor.eu/eupl
#

action :setup do

  begin

package 'libsqlite3-ruby'
package 'libsqlite3-dev'

require 'sqlite3'

new_resource.users.each do |user|
  username = user.username
  homedir = `eval echo ~#{user.username}`.gsub("\n","")
  plugins = user.plugins
  bookmarks =  user.bookmarks

## GENERAL STUFF
  sqlitefiles = []
  profiles = "#{homedir}/.mozilla/firefox/profiles.ini"
  if ::File.exist? profiles
    ::File.open(profiles, "r") do |infile|
      while (line = infile.gets)
        aline=line.split('=')
        if aline[0] == 'Path'
          sqlitefiles << "#{homedir}/.mozilla/firefox/#{aline[1].chomp}/places.sqlite"
        end
      end
    end

## BOOKMARKS STUFf
    Chef::Log.info("Setting user #{username} web bookmarks")     
    sqlitefiles.each do |sqlitedb|
      if ::FileTest.exist? sqlitedb
         db = SQLite3::Database.open(sqlitedb)

          id_folder_bookmarks = db.get_first_value("SELECT id FROM moz_bookmarks WHERE title=\'Marcadores corporativos\'")
          if !id_folder_bookmarks.nil?
            db.execute("delete from moz_bookmarks where parent=#{id_folder_bookmarks} ")
          end
 
          bookmarks.each  do |bkm|
            unless bkm.title.empty? 
              date_now = Time.now.to_i*1000000
              url = db.get_first_value("SELECT url FROM moz_places WHERE url LIKE \'#{bkm.uri}\'")
              if !url.nil?
                db.execute("delete from moz_places where url LIKE \'#{bkm.uri}\'")
              end

              id_toolbar_bookmarks = db.get_first_value("SELECT id FROM moz_bookmarks WHERE title=\'Barra de herramientas de marcadores\'")

              last_pos_toolbar = db.get_first_value("SELECT MAX(position) FROM moz_bookmarks WHERE parent=#{id_toolbar_bookmarks}")

              last_pos_folder = 0

              if id_folder_bookmarks.nil?
                db.execute("INSERT INTO moz_bookmarks (type,parent,position,title,dateAdded,lastModified) VALUES (2,#{id_toolbar_bookmarks},#{last_pos_toolbar+1},\'Marcadores corporativos\',#{date_now},#{date_now})")
                id_folder_bookmarks = db.get_first_value("SELECT last_insert_rowid()")
              else
                last_pos_folder = db.get_first_value("SELECT MAX(position) FROM moz_bookmarks WHERE id=#{id_folder_bookmarks}")
              end

              db.execute("INSERT INTO moz_places (url,title,rev_host,visit_count,hidden,typed,last_visit_date) VALUES  (\'#{bkm.uri}\',\'#{bkm.title}\',\'#{bkm.uri.reverse}.\',1,0,1,#{date_now})")
               foreign_key = db.get_first_value("SELECT last_insert_rowid()")
 
              db.execute("INSERT INTO moz_bookmarks (type,fk,parent,position,title,dateAdded,lastModified) VALUES (1,#{foreign_key},#{id_folder_bookmarks},#{last_pos_folder+1},\'#{bkm.title}\',#{date_now},#{date_now})") 

            end

          end
        end
      end
    end

      puts user.config
      puts user.certs
  end
   
    # TODO:
    # save current job ids (new_resource.job_ids) as "ok"

  rescue
    # TODO:
    # just save current job ids as "failed"
    # save_failed_job_ids
    raise
  end
end



