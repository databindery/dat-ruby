module Dat
  class Repository
    attr_accessor :dir

    # @param [String] dir directory where the dat repository is stored
    def initialize(dir:)
      @dir = dir
    end

    def init
      FileUtils.mkdir_p dir
      run_command "dat init --path=#{dir} --no-prompt"
    end

    def status
      run_and_parse_response "dat status --json"
    end

    def forks
      run_and_parse_response "dat forks --json"
    end

    def import(file: nil, data: nil, dataset: , key: nil, message: nil)
      raise ArgumentError, "You must provide either a file or (string) data" unless data || file
      command =  "dat import"
      if data
        command = "#{data} | dat import -"
      else
        command = "dat import #{file}"
      end

      command << " -d #{dataset}"
      command << " -k #{key}" if key
      command << " -m \"#{message}\"" if message

      run_command command
    end

    def replicate(remote:)
      run_command "dat replicate #{remote}"
    end

    def push(remote:)
      run_command "dat push #{remote}"
    end

    def pull(remote:)
      run_command "dat pull #{remote}"
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

    def diff(ref1, ref2=nil)
      run_and_parse_response "dat diff --json #{ref1} #{ref2}"
    end

    private

    # Run dat command
    # @example
    #   run_command "dat log --json"
    def run_command(command)
      Dir.chdir(dir) { %x(#{command}) }
    end

    def run_and_parse_response(command)
      parse_ndj( run_command(command) )
    end

    def parse_ndj(ndj_json)
      ndj_json.split("\n").map {|json_string| JSON.parse(json_string) }
    end
  end
end