require 'open3'

module Dat
  class Repository
    attr_accessor :dir

    # @param [String] dir directory where the dat repository is stored
    def initialize(dir:)
      @dir = File.expand_path(dir)
    end

    def init
      FileUtils.mkdir_p dir
      run_and_parse_response "dat init --path=#{dir} --no-prompt --json"
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

    # @return [String] the output of the dat export
    def export(dataset:)
      run_command "dat export -d #{dataset} --full"
    end

    # Read the contents of +dataset+ as an IO stream.
    # This is good for exporting large amounts of data from a dat repository
    # as a piped IO stream rather than loading all of the data into memory all
    # at once as a giant String.
    #
    # Remember to close the IO object when you're done reading it.
    # @param [String] dataset name of the dataset to export data from
    # @return [IO] an IO stream of the output of the dat export
    # @example
    #   proteins_io = export_io(dataset: 'proteins')
    #   proteins_io.each_line do |row|
    #     load_row(row)
    #   end
    #   proteins_io.close
    def export_io(dataset:)
      Dir.chdir(dir) { IO.popen("dat export -d #{dataset} --full") }
    end

    # Export +dataset+, yielding batches of +batch_size+
    # This is good for exporting large amounts of data from a dat repository and
    # performing an operation on batches of them.
    # @param [String] dataset name of the dataset to export data from
    # @param [Integer] batch_size size of the batches to export
    # @yieldparam batch [Array] each batch is an Array of objects. batches of +batch_size+ will be yielded until the full export is complete
    # @example load data the proteins dataset into some other system 500 rows at a time
    #   dat_repo.export_in_batches(dataset: 'proteins', batch_size: 500) do |batch|
    #     load_rows(batch)
    #   end
    def export_in_batches(dataset:, batch_size:100)
      batch = []
      exportio = export_io(dataset: dataset)
      exportio.each_line do |row|
        batch << row
        if exportio.eof? || exportio.lineno % batch_size == 0
          yield batch
          batch = []
        end
      end
      exportio.close
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

    def diff(ref1, ref2=nil)
      run_and_parse_response "dat diff --json #{ref1} #{ref2}"
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