


module Rudy
  module MetaData
    include Rudy::AWS
    extend self
    
    def get(rname)
      @@sdb.get(Rudy::DOMAIN, rname) || nil
    end
    
    def query(qstr)
      @@sdb.query_with_attributes(Rudy::DOMAIN, qstr) || nil
    end
    
    #def destroy(rname)
    #  @@sdb.destroy(Rudy::DOMAIN, rname)
    #end

    # 20090224-1813-36
    def format_timestamp(dat)
      mon, day, hour, min, sec = [dat.mon, dat.day, dat.hour, dat.min, dat.sec].collect { |v| v.to_s.rjust(2, "0") }
      [dat.year, mon, day, Rudy::DELIM, hour, min, Rudy::DELIM, sec].join
    end
    
    module ObjectBase
      include Rudy::AWS
      
      def name; raise "#{self.class} must override 'name'"; end
      def valid?; raise "#{self.class} must override 'valid?'"; end
      
      def to_query(more=[], less=[])
        Rudy::AWS::SimpleDB.generate_query build_criteria(more, less)
      end
    
      def to_select(more=[], less=[])
        Rudy::AWS::SimpleDB.generate_select ['*'], Rudy::DOMAIN, build_criteria(more, less)
      end
    
      def save(replace=true)
        replace = true if replace.nil?
        @@sdb.store(Rudy::DOMAIN, name, self.to_hash, replace) # Always returns nil
        true
      end
    
      def destroy
        @@sdb.destroy(Rudy::DOMAIN, name)
        true
      end
    
      def refresh
        h = @@sdb.get(Rudy::DOMAIN, name) || {}
        from_hash(h)
      end
      
      def ==(other)
        self.name == other.name
      end
      
      def to_s
        str = ""
        field_names.each do |key|
          str << sprintf(" %22s: %s#{$/}", key, self.send(key.to_sym))
        end
        str
      end

      
      
    protected
    
      # Builds a zipped Array from a list of criteria.
      # The list of criteria is made up of metadata object attributes. 
      # The list is constructed by taking the adding +more+, and
      # subtracting +less+ from <tt>:rtype, :zone, :environment, :role, :position</tt>
      # Returns [[:rtype, value], [:zone, value], ...]
      def build_criteria(more=[], less=[])
        criteria = [:rtype, :zone, :environment, :role, :position, *more].compact
        criteria -= [*less].flatten.uniq.compact
        values = criteria.collect do |n|
          self.send(n.to_sym)
        end
        criteria.zip(values)
      end
    end
  end
end