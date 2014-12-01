namespace :app do

  namespace :backup do

    desc "Backup a file to the asset store that corresponds to the current environment."
    task :logfile, [:type, :src_file]=>:environment do |t, args|
      dest = "#{args[:type]}/#{Date.today}.log"
      DC::Store::AssetStore.new.save_backup(args[:src_file], dest)
    end

  end

  task :start do
    sh "sudo /etc/init.d/nginx start"
  end

  task :devstart do
    sh "rake crowd:server:start && rake crowd:node:start && rake sunspot:solr:start && sudo nginx"
  end

  task :restart_solr do
    sh "rake #{RAILS_ENV} sunspot:solr:stop sunspot:solr:start"
  end

  task :stop do
    sh "sudo /etc/init.d/nginx stop"
  end

  task :restart do
    sh "touch tmp/restart.txt"
  end

  task :warm do
    secrets = YAML.load_file("#{Rails.root}/secrets/secrets.yml")[RAILS_ENV]
    sh "curl -s -u #{secrets['guest_username']}:#{secrets['guest_password']} http://localhost:80 > /dev/null"
  end

  task :console do
    exec "script/console #{RAILS_ENV}"
  end

  desc "Update the Rails application"
  task :update do
    sh 'cd secrets && git pull && cd ..'
    sh 'git pull'
    sleep 0.2
    sh 'bundle update'
  end

  desc "Repackage static assets"
  task :jammit do
    config = YAML.load(ERB.new(File.read("#{Rails.root}/config/document_cloud.yml")).result(binding))[Rails.env]
    sh "jammit -u http://#{config['server_root']}"
  end

  desc "Publish all documents with expired publish_at timestamps"
  task :publish => :environment do
    Document.publish_due_documents
  end

  namespace :clearcache do

    desc "Clears out cached document JS files."
    task :docs do
      print `find ./public/documents/ -maxdepth 1 -name "*.js" -delete`
      invoke 'app:clearcache:notes'
    end

    desc "Clears out cached annotation JS files."
    task :notes do
      print `find ./public/documents/*/annotations/ -maxdepth 1 -name "*.js" -delete`
    end

    desc "Purges cached search embeds."
    task :search do
      print `rm -rf ./public/search/embed/*`
    end

  end

end

namespace :openoffice do

  task :start do
    utility = RUBY_PLATFORM.match(/darwin/) ? "/Applications/LibreOffice.app/Contents/MacOS/soffice.bin" : "soffice"
    sh "nohup #{utility} --headless --accept=\"socket,host=127.0.0.1,port=8100;urp;\" --nofirststartwizard > log/soffice.log 2>&1 & echo $! > ./tmp/pids/soffice.pid"
  end

end

# def nginx_pid
#   pid_locations = ['/var/run/nginx.pid', '/usr/local/nginx/logs/nginx.pid', '/opt/nginx/logs/nginx.pid']
#   @nginx_pid ||= pid_locations.detect {|pid| File.exists?(pid) }
# end

