class SSHKit::Backend::Local
  def initialize(host = Host.new(:local), &block)
    super
  end
end

class SSHKit::Runner::Abstract
  def backend(host, &block)
    if host.local?
      SSHKit::Backend::Local.new(host, &block)
    else
      SSHKit.config.backend.new(host, &block)
    end
  end
end
