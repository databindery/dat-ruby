require 'spec_helper'

describe Dat::Repository do
  let(:dir) { 'tmp/test/dat_dir' }
  let(:repo) { described_class.new(dir: dir) }
  let(:diff_json) { File.read(sample_file('dat_diff_json.txt')) }
  let(:commit_ref_1) { 'revHash1' }
  let(:commit_ref_2) { 'revHash2' }

  describe 'diff' do
    subject { repo.diff(commit_ref_1) }
    it 'runs a dat diff and parses the result' do
      expect(repo).to receive(:run_command).with("dat diff --json #{commit_ref_1} ").and_return(diff_json)
      expect(subject.count).to eq 2
      expect(subject.first.keys).to eq(["key", "forks", "versions"])
      expect(subject.first['key']).to eq 'https://youtu.be/D5IiMUryqmM'
      expect(subject.first['versions'].count).to eq 2
    end
    it 'takes an optional second revision hash to diff against' do
      expect(repo).to receive(:run_command).with("dat diff --json #{commit_ref_1} #{commit_ref_2}").and_return(diff_json)
      repo.diff(commit_ref_1, commit_ref_2)
    end
  end

  describe 'diff_io' do
    subject { repo.diff_io(commit_ref_1, commit_ref_2) }
    it 'returns an IO stream for exporting the data' do
      the_io_object = double("IO")
      expect(IO).to receive(:popen).with("dat diff --json #{commit_ref_1} #{commit_ref_2}").and_return(the_io_object)
      expect(subject).to be the_io_object
    end
  end

  describe 'diff_in_batches' do
    # see integration test for full coverage of this method
    it 'relies on diff_io and closes it when finished' do
      the_io_object = double("IO")
      expect(the_io_object).to receive(:each_line)
      expect(the_io_object).to receive(:close)
      expect(repo).to receive(:diff_io).with(commit_ref_1, commit_ref_2).and_return(the_io_object)
      repo.diff_in_batches(commit_ref_1, commit_ref_2, batch_size:5) {|batch| 'do nothing'}
    end
  end

end