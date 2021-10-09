require "remote_host"
require 'net/ssh/connection/session'

RSpec.describe RemoteHost do
  describe 'deploy' do
    it 'should run the right rsync command' do
      user = { username: "a1234", password: "password" }
      host = "localhost"
      exclude = %w[logs .deploy-now .git .github css/dummy.css]
      dist = './'
      cmd = "rsync -av --delete --rsh=\"/usr/bin/sshpass -e ssh -o StrictHostKeyChecking=no\" --exclude=logs --exclude=.deploy-now --exclude=.git --exclude=.github --exclude=css/dummy.css ./ a1234@https://localhost:"

      io = double(IO)

      allow(IO).to receive(:popen).with(ENV.merge!({ 'SSHPASS' => user[:password] }), cmd).and_yield(io)
      allow(io).to receive(:each).and_yield("rsync response")

      remote_host = RemoteHost.new(user: user, host: host)
      remote_host.deploy(dist_folder: dist,
                         excludes: exclude)

    end
  end

  describe 'execute' do
    it 'should execute the remote commands' do
      user = { username: "a1234", password: "password" }
      host = "localhost"
      sshCommand = ['ls -al', 'echo "test"']
      #https://github.com/Jeff-Tian/mybnb/blob/1a42890a1d2f1344d5465f8be10c42df01964f5a/Ruby200/lib/ruby/gems/2.0.0/gems/rhc-1.26.9/spec/rhc/commands/deployment_spec.rb
      @ssh = double(Net::SSH)
      #exitcode = { exit_code: 0 }
      exitcode = double({})
      allow(exitcode).to receive(:exit_code).and_return(1)
      allow(Net::SSH).to receive(:start).with(host, user[:username], password: user[:password], verify_host_key: :never).and_yield(@ssh)
      #allow(@ssh).to receive(:exec!).with('ls -al', status: exitcode).and_return("test"|0|"DATA","0", "DATA")
      testVar = net_ssh_connection_session_string_with_exitstatus_new = Net::SSH::Connection::Session::StringWithExitstatus.new("test", 0), "test"

      allow(@ssh).to receive(:exec!).with('ls -al', status: exitcode).and_return(testVar)
      allow(@ssh).to receive(:exec!).with('echo "test"', status: exitcode).and_return("test","0", "DATA" )

      remote_host = RemoteHost.new(user: user, host: host)
      expect(remote_host.execute(sshCommand))
        .to eq(['ls -al', 'echo "test"'])
    end
  end
end

