require 'rake'
require 'kitchen/rake_tasks'

task :default => 'test:vagrant'


  def task_runner(config, suite_name, action, concurrency)
    task_queue = Queue.new
    instances = config.instances.select { | obj | obj.suite.name  =~ /#{suite_name}/ }
    instances.each { |i| task_queue << i }
    workers = (0...concurrency).map do
      Thread.new do
        begin
          while instance = task_queue.pop(true)
            instance.send(action)
          end
        rescue ThreadError
        end
      end
    end
    workers.map(&:join)
  end



namespace :test do

  desc 'Execute the full Vagrant test suites for both the consul agent and consul-template.'
  task :vagrant => ['vagrant:agent', 'vagrant:template' ]


# the cloud task is done this way to allow for greater parallel execution. It's limited to 10
# concurrent instances to work around Aws::EC2::Errors::RequestLimitExceeded errors till
# this can be resolved: https://github.com/test-kitchen/kitchen-ec2/pull/44

  desc 'Execute the full cloud test suites for both the consul agent and consul-template.'
  task :cloud do
    @loader = Kitchen::Loader::YAML.new(local_config: '.kitchen.cloud.yml')
    config = Kitchen::Config.new(loader: @loader)
    concurrency = (ENV["concurrency"] || "10").to_i
    task_runner(config, '.*', 'test', concurrency)
  end


  Kitchen.logger = Kitchen.default_file_logger

  namespace :vagrant do

    @loader = Kitchen::Loader::YAML.new(local_config: '.kitchen.yml')
    config = Kitchen::Config.new(loader: @loader)
    concurrency = (ENV["concurrency"] || "1").to_i

    desc 'Execute the Vagrant test suites (install, clean, remove) for the consul agent.'
    task :agent => ['vagrant:agent:install', 'vagrant:agent:clean', 'vagrant:agent:remove']

    desc 'Execute the Vagrant test suites (install, clean, remove) for consul-template.'
    task :template => ['vagrant:template:install', 'vagrant:template:clean', 'vagrant:template:remove']

    desc 'Destroy all Vagrant instances.'
    task :destroy do
      task_runner(config, '.*', 'destroy', concurrency)
    end

    namespace :agent do
      desc 'Run the Vagrant agent install test suite.'
      task :install do 
        task_runner(config, 'agent-install', 'test', concurrency)
      end
      desc 'Run the Vagrant agent clean test suite.'
      task :clean do
        task_runner(config, 'agent-clean', 'test', concurrency)
      end
      desc 'Run the Vagrant agent removal test suite.'
      task :remove do
        task_runner(config, 'agent-remove', 'test', concurrency)
      end
    end

    namespace :template do
      desc 'Run the Vagrant consul-template install test suite.'
      task :install do
        task_runner(config, 'template-install', 'test', concurrency)
      end
      desc 'Run the Vagrant consul-template clean test suite.'
      task :clean do
        task_runner(config, 'template-clean', 'test', concurrency)
      end
      desc 'Run the Vagrant consul-template removal test suite.'
      task :remove do
        task_runner(config, 'template-remove', 'test', concurrency)
      end
    end
  end



  namespace :cloud do

    @loader = Kitchen::Loader::YAML.new(local_config: '.kitchen.cloud.yml')
    config = Kitchen::Config.new(loader: @loader)
    concurrency = config.instances.size

    desc 'Execute the cloud test suites (install, clean, remove) for the consul agent.'
    task :agent => ['cloud:agent:install', 'cloud:agent:clean', 'cloud:agent:remove']

    desc 'Execute the cloud test suites (install, clean, remove) for consul-template.'
    task :template => ['could:template:install', 'cloud:template:clean', 'cloud:template:remove']

    desc 'Destroy all cloud instances.'
    task :destroy do
      task_runner(config, '.*', 'destroy', concurrency)
    end

    namespace :agent do
      desc 'Run the cloud agent install test suite.'
      task :install do 
        task_runner(config, 'agent-install', 'test', concurrency)
      end
      desc 'Run the cloud agent clean test suite.'
      task :clean do
        task_runner(config, 'agent-clean', 'test', concurrency)
      end
      desc 'Run the cloud agent removal test suite.'
      task :remove do
        task_runner(config, 'agent-remove', 'test', concurrency)
      end
    end

    namespace :template do
      desc 'Run the cloud consul-template install test suite.'
      task :install do
        task_runner(config, 'template-install', 'test', concurrency)
      end
      desc 'Run the cloud consul-template clean test suite.'
      task :clean do
        task_runner(config, 'template-clean', 'test', concurrency)
      end
      desc 'Run the cloud consul-template removal test suite.'
      task :remove do
        task_runner(config, 'template-remove', 'test', concurrency)
      end
    end
  end

end
