

module Rudy
  module MetaData
    class Disk < Storable
      include Rudy::AWS
      
        # This is a flag used internally to specify that a volume has been
        # created for this disk, but not yet formated. 
      attr_accessor :raw_volume
      
      field :rtype
      field :awsid
      
      field :environment
      field :role
      field :path
      field :position
      
      field :zone
      field :region
      field :device
      #field :backups => Array
      field :size
      
      def initialize
        @backups = []
        @raw_volume = false
        @rtype = Disk.rtype
      end
      
      def self.rtype
        Disk.to_s.split('::').last.downcase
      end
      
      def name
        Disk.generate_name(@zone, @environment, @role, @position, @path)
      end
      
      def Disk.generate_name(zon, env, rol, pos, pat, sep=File::SEPARATOR)
        pos = pos.to_s.rjust 2, '0'
        dirs = pat.split sep if pat
        dirs.shift while dirs && (dirs[0].nil? || dirs[0].empty?)
        ["disk", zon, env, rol, pos, *dirs].join(RUDY_DELIM)
      end
      
      def valid?
        @zone && @environment && @role && @position && @path && @size && @device
      end
      
      def to_query(more=[], remove=[])
        criteria = [:rtype, :zone, :environment, :role, :position, :path, *more]
        criteria -= [*remove].flatten
        query = []
        criteria.each do |n|
          val = self.send(n.to_sym)
          query << "['#{n}' = '#{self.send(n.to_sym)}'] " if val # Only add attributes with values
        end
        query.join(" intersection ")
      end
      
      def to_select
        
      end
      
      def save
        @@sdb.store(RUDY_DOMAIN, name, self.to_hash, :replace) # Always returns nil
        true
      end
      
      def destroy
        @@sdb.destroy(RUDY_DOMAIN, name)
        true
      end
      
      def refresh
        h = @@sdb.get(RUDY_DOMAIN, name) || {}
        from_hash(h)
      end
      
      def Disk.get(dname)
        h = @@sdb.get(RUDY_DOMAIN, dname) || {}
        from_hash(h)
      end
      
      def to_s
        str = ""
        field_names.each do |key|
          str << sprintf(" %22s: %s#{$/}", key, self.send(key.to_sym))
        end
        str
      end
       
      
    end
    
  end

end
