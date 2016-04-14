module Luban
  module Deployment
    module Helpers
      module Utils
        LogLevels = %i(fatal error warn info debug trace)

        attr_reader :backend

        def check_pass?(type, *args)
          send("#{type}?", *args)
        end

        def directory?(path)
          test "[ -d #{path} ]"
        end

        def file?(path)
          test "[ -f #{path} ]"
        end

        def symlink?(path)
          test "[ -L #{path} ]"
        end

        def match?(cmd, expect)
          expect = Regexp.new(Regexp.escape(expect.to_s)) unless expect.is_a?(Regexp)
          output = capture(cmd)
          output =~ expect
        end

        def assure(type, *args)
          unless check_pass?(type, *args)
            if block_given?
              yield
            else
              abort "Aborted! #{type} dependency with #{args.inspect} are not met and no block is given to resolve it."
            end
          end
        end

        def assure_dirs(*dirs)
          dirs.each { |dir| assure(:directory, dir) { mkdir(dir) } }
        end

        def assure_symlink(source_path, target_path)
          unless symlink?(target_path) and readlink(target_path) == source_path.to_s
            ln(source_path, target_path)
          end
        end

        def mkdir(*opts, path)
          execute(:mkdir, '-p', *opts, path)
        end

        def rm(*opts, path)
          execute(:rm, '-fr', *opts, path)
        end
        alias_method :rmdir, :rm

        def chmod(*opts, path)
          execute(:chmod, '-R', *opts, path)
        end

        def ln(*opts, source_path, target_path)
          execute(:ln, '-nfs', *opts, source_path, target_path)
        end

        def mv(*opts, source_path, target_path)
          execute(:mv, *opts, source_path, target_path)
        end

        def cp(*opts, source_path, target_path)
          execute(*opts, source_path, target_path)
        end

        def readlink(source_file)
          capture("$(type -p readlink greadlink|head -1) #{source_file}") 
        end

        def md5_for_file(file)
          capture(:cat, "#{file} 2>/dev/null | openssl md5")
        end

        def sudo(*args)
          execute(:sudo, *args)
        end

        def os_name
          @os_name ||= capture("uname -s")
        end

        def os_release
          @os_release ||= capture("uname -r")
        end

        def hardware_name
          @hardware_name ||= capture("uname -m")
        end

        def user_home
          @user_home ||= capture("eval echo ~")
        end

        def url_exists?(download_url)
          # Sent HEAD request to avoid downloading the file contents
          test("curl -s -L -I -o /dev/null -f #{download_url}")

          # Other effective ways to check url existence with curl

          # In case HEAD request is refused, 
          # only the first byte of the file is requested
          # test("curl -s -L -o /dev/null -f -r 0-0 #{download_url}")

          # Alternatively, http code (200) can be validated
          # capture("curl -s -L -I -o /dev/null -w '%{http_code}' #{download_url}") == '200'
        end

        def upload_by_template(file_to_upload:, template_file:, auto_revision: false, **opts)
          template = File.read(template_file)

          if auto_revision
            require 'digest/md5'
            revision = Digest::MD5.hexdigest(template)
            return if revision_match?(file_to_upload, revision)
          end

          require 'erb'
          context = opts[:binding] || binding
          upload!(StringIO.new(ERB.new(template, nil, '<>').result(context)), file_to_upload)
          yield file_to_upload if block_given?
        end

        def revision_match?(file_to_upload, revision)
          file?(file_to_upload) and match?("grep \"Revision: \" #{file_to_upload}", revision)
        end

        [:test, :make, :within, :with, :as, :execute, 
         :upload!, :download!].each do |cmd|
          define_method(cmd) do |*args, &blk|
            backend.send(__method__, *args, &blk)
          end
        end

        def capture(*args, &blk)
          backend.capture(*args, &blk).chomp
        end

        def md5_matched?(file_path, md5)
          file?(file_path) and md5 == md5_for_file(file_path)
        end

        #def execute(*args, &blk)
        #  if args.last.is_a?(::Hash)
        #    args.last.merge(verbosity: SSHKit::Logger::DEBUG)
        #  else
        #    args.push(verbosity: SSHKit::Logger::DEBUG)
        #  end
        #  backend.execute(*args, &blk)
        #end

        LogLevels.each do |cmd|
          define_method(cmd) { |msg| backend.send(__method__, "[#{hostname}] #{msg}") }
        end

        def host
          @host ||= backend.host
        end

        def hostname
          @hostname ||= host.hostname
        end

        def method_missing(sym, *args, &blk)
          backend.respond_to?(sym) ? backend.send(sym, *args, &blk) : super
        end
      end
    end
  end
end
