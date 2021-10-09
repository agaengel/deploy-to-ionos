# frozen_string_literal: true

require 'English'
require 'net/ssh'

class RemoteHost
  def initialize(options)
    @user = options[:user]
    @host = options[:host]
  end

  def deploy(options)
    exclude_options = (options[:excludes]).map { |exclude| "--exclude=#{exclude}" }.join(' ')
    cmd = "rsync -av --delete --rsh=\"/usr/bin/sshpass -e ssh -o StrictHostKeyChecking=no\" #{exclude_options} #{options[:dist_folder]} #{@user[:username]}@#{@host}:"
    puts cmd
    IO.popen(ENV.merge!({ 'SSHPASS' => @user[:password] }), cmd) do |io|
      io.each do |line|
        puts line
      end
    end

    exit $CHILD_STATUS.exitstatus unless $CHILD_STATUS.exitstatus.zero?
  end

  def execute(commands)
    Net::SSH.start(@host, @user[:username], password: @user[:password], verify_host_key: :never) do |ssh|
      commands.each do |command|
        puts "Running the remote command: #{command}"
        status = Status.new(0)
        test = ssh.exec!(command, status: status)
        ssh.exec!(command, status: status) do |test, status, data|
          puts data
        end
        abort 'Error running the remote command' unless status[:exit_code].zero?
      end
    end
  end
end

class Status
  attr_accessor :exit_code

  def initialize(exit_code)
    exit_code = exit_code
  end
end
