

module Rudy::CLI
  class Instances < Rudy::CLI::Base
    
    def connect
      puts "Rudy Connect".bright

      if @argv.cmd
        @argv.cmd = [@argv.cmd].flatten.join(' ')
        if @global.user.to_s == "root"
          exit unless Annoy.are_you_sure?(:medium)
        end
      end
      
      rudy = Rudy::Instances.new(:config => @config, :global => @global)
      rudy.connect(@option.group, @argv.cmd, @option.awsid, @option.print)
    end

    def copy_valid?
      raise "You must supply a source and a target. See rudy #{@alias} -h" unless @argv.size >= 2
      raise "You cannot download and upload at the same time" if @option.download && @alias == 'upload'
      true
    end
    def copy
      puts "Rudy Copy".bright
      opts = {}
      opts[:group] = @option.group if @option.group
      opts[:id] = @option.awsid if @option.awsid
      opts[:id] &&= [opts[:id]].flatten
      
      # Is this more clear?
      @option.recursive && opts[:recursive] = true
      @option.preserve  && opts[:preserve]  = true
      @option.print     && opts[:print]     = true
      
      
      opts[:paths] = @argv
      opts[:dest] = opts[:paths].pop
      
      opts[:task] = :download if @alias == 'download' || @option.download
      opts[:task] = :upload if @alias == 'upload'
      opts[:task] ||= :upload
      
      #exit unless @option.print || Annoy.are_you_sure?(:low)
      
      rudy = Rudy::Instances.new(:config => @config, :global => @global)
      rudy.copy(opts[:group], opts[:id], opts)
    end


    def status
      puts "Instance Status".bright
      opts = {}
      opts[:group] = @option.group if @option.group
      opts[:state] = @option.state if @option.state
      
      # A nil value forces the @ec2.instances.list to return all instances
      if @option.all
        opts[:state] = :any
        opts[:group] = :any
      end
      
      opts[:id] = @argv.awsid if @argv.awsid
      opts[:id] &&= [opts[:id]].flatten
      rudy = Rudy::Instances.new(:config => @config, :global => @global)
      
      lt = rudy.list(opts[:state], opts[:group], opts[:id]) do |inst|
        puts '-'*60
        puts "Instance: #{inst.awsid.bright} (AMI: #{inst.ami})"
        puts inst.to_s
      end
      puts "No instances running" if !lt || lt.empty?
    end
    alias :instance :status
    
    def console_valid?
      
      @rmach = Rudy::Instances.new(:config => @config, :global => @global)
    end
    
    def console
      puts "Instance Console".bright
      opts = {}
      opts[:group] = @option.group if @option.group
      opts[:id] = @argv.awsid if @argv.awsid
      opts[:id] &&= [opts[:id]].flatten
      
      unless @rmach.any?
        puts "No instances running"
        return
      end
      
      console = @rmach.console(opts[:group], opts[:id])
      
      if console
        puts console
      else
        puts "Console output is not available"
      end
      
    end
    
    
    def instance_create
      puts "Create Instance".bright
      opts = {}
      [:group, :ami, :address, :itype, :keypair].each do |n|
        opts[n] = @option.send(n) if @option.send(n)
      end

      rmach = Rudy::Instances.new(:config => @config, :global => @global)
      # TODO: Print number of instances running. If more than 0, use Annoy.are_you_sure?
      rmach.create(opts) do |inst| # Rudy::AWS::EC2::Instance objects
        puts '-'*60
        puts "Instance: #{inst.awsid.bright} (AMI: #{inst.ami})"
        puts inst.to_s
      end
    
    end
    
    
    def instance_destroy
      puts "Destroy Instances".bright
      opts = {}
      opts[:group] = @option.group if @option.group
      opts[:id] = @argv.awsid if @argv.awsid
      opts[:id] &&= [opts[:id]].flatten
      
      rmach = Rudy::Instances.new(:config => @config, :global => @global)
      instances = rmach.list(:running, opts[:group], opts[:id])
      raise "No instances running" if instances.nil? || instances.empty?
      @logger.puts "Destroying #{instances.size} instances in #{instances.first.group}"
      exit unless Annoy.are_you_sure?(:low)
      rmach.destroy(opts[:group], opts[:id])
      puts "Done!"
    end
    
  end
end


