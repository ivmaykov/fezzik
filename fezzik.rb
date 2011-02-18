namespace :fezzik do
  task :run do
    if ARGV.size == 0
      puts "    Usage: fez to_destination task"
      exit 1
    end
    destination = ARGV[0]
    destination = $1 if destination.match(/to_(.+)/)
    tasks = ARGV[1..-1]
    Rake::Task["fezzik:load_config"].invoke destination
    tasks.each do |task|
      Rake::Task["fezzik:#{task}"].invoke
    end
  end

  task :load_config, :destination do |t, args|
    @destination = args[:destination].to_sym
    require "config/deploy.rb"
    puts "configuring for #{domain}"
  end

  def destination(target, &block)
    block.call if target == @destination
  end


  # The following core tasks are used to deploy your application to the destination servers.
  # This is a decent initial setup, but is completely configurable.

  task :stage do
    puts "staging project in /tmp/#{app}"
    system("cp -r #{local_path} /tmp/#{app}")
  end

  remote_task :setup do
    puts "setting up servers"
    run "mkdir -p #{deploy_to}/releases"
  end

  remote_task :push => [:stage, :setup] do
    rsync "/tmp/#{app}/", "#{target_host}:#{release_path}"
  end

  remote_task :symlink => :push do
    puts "symlinking current to #{release_path}"
    run "cd #{deploy_to} && ln -fns #{release_path} current"
  end

  remote_task :start do
    puts "starting from #{release_path}"
    run "cd #{current_path} && ./bin/run_#{app}.sh"
  end

  task :deploy => [:symlink, :start] do
    puts "#{app} deployed!"
  end
end
