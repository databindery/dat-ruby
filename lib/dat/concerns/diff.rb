module Dat
  module Diff

    # @return [String] the output of the dat export
    def diff(from_ref, to_ref = nil)
      run_and_parse_response "dat diff --json #{from_ref} #{to_ref}"
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
    def diff_io(from_ref, to_ref = nil)
      Dir.chdir(dir) { IO.popen("dat diff --json #{from_ref} #{to_ref}") }
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
    def diff_in_batches(from_ref, to_ref = nil, batch_size:100)
      batch = []
      diffio = diff_io(from_ref, to_ref)
      diffio.each_line do |row|
        batch << row
        if diffio.eof? || diffio.lineno % batch_size == 0
          yield batch
          batch = []
        end
      end
      diffio.close
    end
  end
end