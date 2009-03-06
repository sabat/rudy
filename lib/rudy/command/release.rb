

module Rudy
  module Command
    class Release < Rudy::Command::Base
      
      def release_valid?
        raise "No EC2 .pem keys provided" unless has_pem_keys?
        raise "No SSH key provided for #{@global.user}!" unless has_keypair?
        raise "No SSH key provided for root!" unless has_keypair?(:root)
        
        @list = @ec2.instances.list(machine_group)
        #raise "Please start an instance in #{machine_group} before releasing! (rudy -e stage instances --start)" if @list.empty?
        puts "TODO: check running instances"
        exit unless are_you_sure?
        
        @scm, @scm_params = find_scm
        
        true
      end
        
      def release

       # @option.image ||= machine_image
       # 
       # @global.user = "root"
       # 
       # puts "Starting an instance in #{machine_group}"
       # puts "with machine data:", machine_data.to_yaml
       #
       # instances = @ec2.instances.create(@option.image, machine_group.to_s, File.basename(keypairpath), machine_data.to_yaml, @global.zone)
       # inst = instances.first
       # id, state = inst[:aws_instance_id], inst[:aws_state]
       # 
       # if @option.address ||= machine_address
       #   puts "Associating #{@option.address} to #{id}"
       #   @ec2.addresses.associate(id, @option.address)
       # end
       # 
       # wait_to_attach_disks(id)
       #
       # 
       # # TODO: store metadata about release with local username and hostname
        puts "Creating release from working copy"
        #tag = @scm.create_release(@global.local_user)
       tag = "http://rilli.unfuddle.com/svn/rilli_rilli/tags/rudy-2009-03-06-delano-r01"
        puts "Done! (#{tag})"
        
        if @option.switch
          puts "Switching working copy to new tag"
          @scm.switch_working_copy(tag)
        end
        
        if @scm && @scm_params[:command]
          
          ssh do |session|
            cmd = "svn #{@scm_params[:command]} #{tag} #{@scm_params[:path]}"
            puts "Running #{cmd}"
            #puts session.exec!(cmd)
          end
          
        end
        
        
        
        config = @config.machinegroup.find_deferred(@global.environment, @global.role, :release, :config) || {}
        
        config[:global] = @global.marshal_dump
        config[:global].reject! { |n,v| n == :cert || n == :privatekey }

        tf = Tempfile.new('release-config')
        write_to_file(tf.path, config.to_hash.to_yaml, 'w')

        
        machine = @list.values.first # NOTE: we're assuming there's only one machine
        
        rscripts = @config.machinegroup.find_deferred(@global.environment, @global.role, :release, :after) || []
        rscripts = [rscripts] unless rscripts.is_a?(Array)
        rscripts.each do |rscript|
          user, script = rscript.shift
          script &&= script
          
          switch_user(user) # scp and ssh will run as this user
          
          puts "Transfering release-config.yaml..."
          scp do |scp|
            # The release-config.yaml file contains settings from ~/.rudy/config 
            scp.upload!(tf.path, "~/release-config.yaml") do |ch, name, sent, total|
              puts "#{name}: #{sent}/#{total}"
            end
          end
          ssh do |session|
            puts "Running #{script}..."
            session.exec!("chmod 700 #{script}")
            puts session.exec!("#{script}")
            
            puts "Cleaning up..."
            session.exec!("rm ~/release-config.yaml")
            session.exec!("rm #{script}")
          end
        end
        
        
        tf.delete    # remove release-config.yaml
        
        switch_user # return to the requested user
      end
      
      
      def find_scm
        env, rol, att = @global.environment, @global.role
        
        # Look for the source control engine, checking all known scm values.
        # The available one will look like [environment][role][svn]
        params = nil
        scm = nil
        SUPPORTED_SCM_NAMES.each do |v|
          scm = v
          params = @config.machinegroup.find_deferred(env, rol, :release, scm)
          break if params
        end
        if params
          klass = eval "Rudy::SCM::#{scm.to_s.upcase}"
          scm = klass.new(:base => params[:base])
        end
        
        [scm, params]
      end
      private :find_scm
      
    end
  end
end

