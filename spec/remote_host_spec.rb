require "remote_host"
require 'net/ssh/connection/session'

RSpec.describe RemoteHost do
  describe 'deploy' do
    it 'should run the right rsync command' do
      user = { username: "a1234", password: "password" }
      host = "https://localhost"
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
      host = "https://localhost"
      sshCommand = ['ls -al', 'echo "test"']

      @ssh = double(Net::SSH)
      exitcode = { exit_code: 0 }
      allow(Net::SSH).to receive(:start).with(host, user[:username], password: user[:password], verify_host_key: :never).and_yield(@ssh)
      allow(@ssh).to receive(:exec!).with('ls -al', status: exitcode).and_return("hallo")
      allow(@ssh).to receive(:exec!).with('echo "test"', status: exitcode).and_return("test")

      remote_host = RemoteHost.new(user: user, host: host)
      expect(remote_host.execute(sshCommand))
        .to eq(['ls -al', 'echo "test"'])
    end
  end
end

