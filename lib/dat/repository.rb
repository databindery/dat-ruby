require 'open3'

module Dat
  class Repository
    include Dat::Export
    include Dat::Diff

    attr_accessor :dir

    # @param [String] dir directory where the dat repository is stored
    def initialize(dir:)
      @dir = File.expand_path(dir)
    end

    def init
      FileUtils.mkdir_p dir
      run_and_parse_response "dat init --path=#{dir} --no-prompt --json"
    end

    def is_dat_repository?
      return false unless File.exists?(dir)
      begin
        status
      rescue
        return false
      end
      true
    end

    def status
      run_and_parse_response "dat status --json"
    end

    def datasets
      json = run_and_parse_response "dat datasets --json"
      json["datasets"]
    end

    def forks
      json = run_and_parse_response "dat forks --json"
      json["forks"]
    end

    def import(file: nil, data: nil, dataset: , key: nil, message: nil)
      raise ArgumentError, "You must provide either a file or (string) data" unless data || file
      unless file
        raise ArgumentError, ":data cannot be empty" if data.empty?
      end

      command =  "dat import"
      if data
        command = "#{data} | dat import -"
      else
        command = "dat import #{file.to_s}"
      end

      command << " -d #{dataset}"
      command << " -k #{key}" if key
      command << " -m \"#{message}\"" if message
      command << " --json"

      run_and_parse_response command
    end

    def replicate(remote:)
      run_and_parse_response "dat replicate #{remote} --json"
    end

    def push(remote:)
      run_and_parse_response "dat push #{remote} --json"
    end

    def pull(remote:)
      run_and_parse_response "dat pull #{remote} --json"
    end

    # the commit hashes in chronological order -- most recent commits are listed last
    def commit_hashes
      log.map {|entry| entry['version']}
    end

    # return dat log in json form
    # the json is sorted in chronological order, so the most recent commits are listed last
    def log
      run_and_parse_response "dat log --json"
    end

    private

    # Run dat command
    # @example
    #   run_command "dat log --json"
    def run_command(command)
      # Dir.chdir(dir) { %x(#{command}) }
      result = nil
      Dir.chdir(dir) do
        result = ::Open3.popen3(command) do |stdin, stdout, stderr, wait_thr|
          errors = stderr.read
          raise Dat::ExecutionError, errors unless errors.empty?
          stdout.read
        end
      end
      result
    end

    def run_and_parse_response(command)
      raw_json = run_command(command)
      json_array = parse_ndj(raw_json)
      if json_array.length > 1
        response_json = json_array
      else
        response_json = json_array.first
        if response_json['error']
          case response_json['message']
            when /This is not a dat repository/
              raise Dat::NotARepositoryError, response_json['message']
            when /Could not auto detect input type/
              raise Dat::AutoDetectTypeError, response_json['message']
            else
              raise Dat::Error, response_json['message']
          end
        end
      end
      response_json
    end

    def parse_ndj(ndj_json)
      ndj_json.split("\n").map {|json_string| JSON.parse(json_string) }
    end
  end
end