require 'spec_helper'

describe Dat::Repository do
  let(:dir) { 'tmp/test/dat_dir' }
  let(:expanded_dir) { File.expand_path dir }
  let(:repo) { described_class.new(dir: dir) }

  describe 'export' do
    let(:dat_response) { '{}' }
    subject { repo.export(dataset: 'billion_flowers') }
    it 'exports data from dat as a string' do
      expect(repo).to receive(:run_command).with("dat export -d billion_flowers --full").and_return(dat_response)
      subject
    end
  end

  describe 'export_io' do
    subject { repo.export_io(dataset: 'billion_flowers') }
    it 'returns an IO stream for exporting the data' do
      the_io_object = double("IO")
      expect(IO).to receive(:popen).with("dat export -d billion_flowers --full").and_return(the_io_object)
      expect(subject).to be the_io_object
    end
  end

  describe 'export_in_batches' do
    # see integration test for full coverage of this method
    it 'relies on export_io and closes it when finished' do
      the_io_object = double("IO")
      expect(the_io_object).to receive(:each_line)
      expect(the_io_object).to receive(:close)
      expect(repo).to receive(:export_io).with(dataset:'plants').and_return(the_io_object)
      repo.export_in_batches(dataset:'plants', batch_size:5) {|batch| 'do nothing'}
    end
  end

end
