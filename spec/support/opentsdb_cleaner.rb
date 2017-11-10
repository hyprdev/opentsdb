require 'byebug'
require 'open3'

class OpentsdbCleaner
  cattr_accessor :tsd_bin

  class << self
    @@tsd_bin = Opentsdb.executable_path

    def import
      filename = File.expand_path('../../fixtures/opentsdb-data.txt', __FILE__)

      run_command(tsd_bin, "import", "--auto-metric", filename)
    end

    def create_metrics
      ['hashrate','miners','fee','total_miners_paid','total_payments','last_block_found','total_blocks_found','round_hashes'].each do |metric|
        run_command(tsd_bin, "uid", "assign", "metrics", "test.pool.stats.#{metric}")
      end
    end

    def drop_caches
      run_command('/usr/bin/env', 'curl', '-i', '-H "Content-Type: application/json"', 'http://localhost:4242/api/dropcaches')
    end

    def clean
      uid_types = ['metrics', 'tagk', 'tagv']

      uid_types.each do |uid_type|
        uids = collect_uids_by_type type: uid_type, prefix: "test"
        uids.each do |uid|
          clean_uid **uid
        end
      end
    end

    protected

    def collect_uids_by_type type:, prefix:
      uid_format = /(metrics|tagk|tagv)\s+([\w\.\-]+):\s*(\[[\d\s,]+\])/i
      uids = []

      run_command(tsd_bin, "uid", "grep", type, prefix) do |stdout|
        lines = stdout.split(/(\r?\n)+/)

        lines = lines.map(&:strip)
        lines = lines.select{|line| line.match?(uid_format)}

        uids = lines.map do |line|
          matchdata = line.match uid_format

          {type: matchdata[1], name: matchdata[2], uid: matchdata[3]}
        end
      end

      uids
    end

    def clean_uid type:, name:, uid:
      if type == "metrics"
        # FIXME: this command sometimes fails when data is inconsistent
        # Probably should try `tsdb uid fsck fix delete_unknown`
        run_command tsd_bin, "scan", "--delete", "1970/01/02", "sum", name
      end

      run_command tsd_bin, "uid", "delete", type, name
    end

    def run_command(command, *args, &block)
      Open3.popen3(command, *args) do |stdin, stdout, stderr, wait_thr|
        stdout = stdout.read
        stderr = stderr.read

        if !wait_thr.value.success? and !stderr.empty?
          error = [
            wait_thr.value.inspect,
            "STDOUT:", stdout,
            "STDERR:", stderr,
          ].join("\n")

          arg_string = args.join(" ")

          raise RuntimeError.new("Execution failed: #{command} #{arg_string}\n#{error}")
        end

        yield stdout if block_given?
      end
    end
  end
end

RSpec.configure do |config|
  config.before(:suite) do
    OpentsdbCleaner.create_metrics
    OpentsdbCleaner.import
    OpentsdbCleaner.drop_caches
  end

  config.after(:suite) do
    OpentsdbCleaner.clean
  end
end
