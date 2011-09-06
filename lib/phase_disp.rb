
#require 'dm-core'
#require 'dm-validations'
#require 'dm-migrations'
require 'pathname'

module DataLoader
  autoload :PhDisp, 'data_loader/ph_disp'

  class << self
    def setup(db_name = 'sea_data', migrate = false, debug = false)
      DataMapper::Logger.new($stdout, :debug) if debug

      DataMapper.setup(:default, 'postgres://localhost/' + db_name)

      if migrate
        PhDisp.auto_migrate!
      end
    end

    def process_phase_displacement(file_name)
      circuit_info = parse_filename(file_name)
      circuit_info.merge!({ :circuit => 'CML2CMOS' })

      lines = File.readlines(file_name).map #{|l| l.rstrip}[10..-1]

      prev_point_p = { :voltage => 0.0, :time => 48e-9 }
      prev_point_n = { :voltage => 0.0, :time => 48e-9 }
      prev_cross_p = 48.001e-9
      prev_cross_n = 48.001e-9
      #new_zero = 0.0 
      #file_config = { :cycle_start => 50e-9, :time_increment => 3.2e-9 }
      #max = { :bit_miss_v => new_zero, 
      #  :miss_time => file_config[:cycle_start], :type => 'MAX' }
      #min = { :bit_miss_v => new_zero, 
      #  :miss_time => file_config[:cycle_start], :type => 'MIN' }
      #prev_voltage = 0.0

      lines.each do |line|
        c, t, vp, vn, _ = line.split(' ')
        t = t.to_f; vp = vp.to_f; vn = vn.to_f

        if (prev_point_p[:voltage] < 0.5 && vp >= 0.5)
          intercept = calculate_intercept(prev_point_p, { :voltage => vp, :time => t })
          jitter = intercept - prev_cross_p - 640e-12
          wc = PhDisp.create(circuit_info.merge({ :displ_p => jitter, :cycle_end => t }))
          puts "error: #{wc.errors.full_messages}" unless wc.valid?
          prev_cross_p = intercept
        end
        
        prev_point_p[:voltage] = vp
        prev_point_p[:time] = t

        if (prev_point_n[:voltage] < 0.5 && vn >= 0.5)
          intercept = calculate_intercept(prev_point_n, { :voltage => vn, :time => t })
          jitter = intercept - prev_cross_n - 640e-12
          wc = PhDisp.create(circuit_info.merge({ :displ_n => jitter, :cycle_end => t }))
          puts "error: #{wc.errors.full_messages}" unless wc.valid?
          prev_cross_n = intercept
        end

        prev_point_n[:voltage] = vn
        prev_point_n[:time] = t

      end
    end

    def parse_filename(file_name)
      root = Pathname.new(file_name).basename.to_s.gsub(/.txt/, '')
      tokens = root.split('-')

      case tokens.size
        when 2
          { :node => tokens[0], :energy => tokens[1] }
        when 3
          {  :node => tokens[0], :energy => tokens[1], :start_time => tokens[2] }
        when 4
          { :circuit => tokens[0], :energy => tokens[1],
            :node => tokens[2], :scan => tokens[3] }
        when 5
          { :circuit => tokens[0], :energy => tokens[1],
            :node => tokens[3], :scan => tokens[4] }
        else
          { }
      end
    end

    def point_delta(min, max)
      time_delta = (min[:time].abs() - max[:time].abs()).abs()
      voltage_delta = (max[:voltage].abs() - min[:voltage].abs()).abs()
      # TODO: the thresholds should be configurable
      time_threshold = 0.4
      voltage_threshold = 2.0
      return (time_delta > time_threshold) && (voltage_delta < voltage_threshold)
    end

    def calculate_intercept(point1, point2)
      slope = (point2[:voltage] - point1[:voltage]) / (point2[:time] - point1[:time])
      b = point2[:voltage] - point2[:time] * slope
      return (-b) / slope
    end
  end
end
