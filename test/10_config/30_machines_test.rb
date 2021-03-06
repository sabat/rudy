
module Rudy::Test
  class Case_10_Config
    
    context "#{name}_30 Machines" do
      
      should "(10) have accounts.aws" do
        stop_test !@@config.accounts.is_a?(Rudy::Config::Accounts), "Not an Accounts class"
        
        stop_test @@config.accounts.aws.accountnum.nil?, "No account"
        stop_test @@config.accounts.aws.accesskey.nil?, "No accesskey"
        stop_test @@config.accounts.aws.secretkey.nil?, "No secretkey"
      end
      
      should "(20) have defaults" do
        assert @@config.defaults.is_a?(Rudy::Config::Defaults), "Not a Defaults class"
        assert !@@config.defaults.region.nil?, "No default region"
        assert !@@config.defaults.zone.nil?, "No default zone"
        assert !@@config.defaults.environment.nil?, "No default environment"
        assert !@@config.defaults.role.nil?, "No default role"
      end
      
      should "(30) have machines" do
        assert @@config.machines.is_a?(Rudy::Config::Machines), "Not a Machines class"
        assert !@@config.machines.keys.empty?, "Nothing in machine config"
      end
      
      should "(31) have 2 disks" do
        reg, zon = @@config.defaults.region, @@config.defaults.zone 
        env, rol = @@config.defaults.environment, @@config.defaults.role
        
      end
      
      # Disabled for 0.5.0 (routines config removed)
      xshould "(40) have routines" do
        assert @@config.routines.is_a?(Rudy::Config::Routines), "Not a Routines class"
      end
      
      # Disabled for 0.5.0 (most machines config removed)
      xshould "(50) be able to find and find_deferred" do
        reg, zon = @@config.defaults.region, @@config.defaults.zone 
        env, rol = @@config.defaults.environment, @@config.defaults.role 

        #Caesars.enable_debug
        
        conf = @@config.machines[env][rol]
        conf_find = @@config.machines.find(env, rol)
        conf_find_def = @@config.machines.find_deferred(env, rol)
        
        assert_equal conf, conf_find, "config hash and find not equal"
        assert_equal conf_find_def, conf_find, "find and find_deferred not equal"
      end
      
      should "(51) find different config for each zone" do
        reg, zon = @@config.defaults.region, @@config.defaults.zone 
        env, rol = @@config.defaults.environment, @@config.defaults.role
        
        us_ami = @@config.machines.find(:"us-east-1b", :ami)
        eu_ami = @@config.machines.find(:"eu-west-1b", :ami)
        
        assert us_ami.is_a?(String), "No ami for us-east-1b zone"
        assert eu_ami.is_a?(String), "No ami for eu-west-1b"
        assert us_ami != eu_ami, "EU (#{eu_ami}) and US (#{us_ami}) AMIs are the same"
      end
      
    end
    
  end
end