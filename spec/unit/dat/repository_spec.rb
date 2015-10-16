require 'spec_helper'

describe Dat::Repository do
  let(:dir) { 'tmp/test/dat_dir' }
  let(:repo) { described_class.new(dir: dir) }
  let(:log_json) { File.read(sample_file('dat_log_json.txt')) }
  let(:diff_json) { File.read(sample_file('dat_diff_json.txt')) }
  subject { repo }

  describe 'init' do
    it 'tells dat to init the repository' do
      expect(subject).to receive(:run_command).with("dat init --path=#{dir} --no-prompt")
      subject.init
    end
  end

  describe 'import' do
    let(:file_path) { '/foo/bar' }
    context 'a file' do
      subject { repo.import(dataset:'billion_flowers', file: file_path) }
      it 'imports data from the file into dat' do
        expect(repo).to receive(:run_command).with("dat import #{file_path} -d billion_flowers")
        subject
      end
    end
    context 'data' do
      let(:the_data) { '{...the data...}' }
      subject { repo.import(dataset:'billion_flowers', data: the_data) }
      it 'imports the data into dat' do
        expect(repo).to receive(:run_command).with("#{the_data} | dat import - -d billion_flowers")
        subject
      end
    end
    context 'with a key' do
      subject { repo.import(dataset:'billion_flowers', file: file_path, key:'dc_identifier') }
      it 'tells dat to use the key' do
        expect(repo).to receive(:run_command).with("dat import #{file_path} -d billion_flowers -k dc_identifier")
        subject
      end
    end
    context 'with a message' do
      subject { repo.import(dataset:'billion_flowers', file: file_path, message:'This is my message.') }
      it 'provides the log message to dat' do
        expect(repo).to receive(:run_command).with("dat import #{file_path} -d billion_flowers -m \"This is my message.\"")
        subject
      end
    end
  end

  describe 'diff' do
    subject { repo.diff('revHash1') }
    it 'runs a dat diff and parses the result' do
      expect(repo).to receive(:run_command).with("dat diff --json revHash1 ").and_return(diff_json)
      expect(subject.count).to eq 2
      expect(subject.first.keys).to eq(["key", "forks", "versions"])
      expect(subject.first['key']).to eq 'https://youtu.be/D5IiMUryqmM'
      expect(subject.first['versions'].count).to eq 2
    end
    it 'takes an optional second revision hash to diff against' do
      expect(repo).to receive(:run_command).with("dat diff --json revHash1 revHash2").and_return(diff_json)
      repo.diff('revHash1', 'revHash2')
    end
  end

  describe 'log' do
    subject { repo.log }
    it 'parses the log info from dat' do
      expect(repo).to receive(:run_command).with("dat log --json").and_return(log_json)
      expect(subject.count).to eq 10
      expect(subject.first['version']).to eq '46eb0d95add65882d5b63681be1acfc68822200109cc8b4259d439d1394b744a'
    end
  end

  describe 'commit_hashes' do
    subject { repo.commit_hashes }
    it 'extracts the commit hashes from the log in chronological order' do
      expect(repo).to receive(:run_command).with("dat log --json").and_return(log_json)
      expect(subject.count).to eq 10
      expect(subject).to eq ["46eb0d95add65882d5b63681be1acfc68822200109cc8b4259d439d1394b744a", "2bff235b78981973310c2d3312337388afdc1b29303f45f0d7d96eb072b991d4", "ddcf22973fccbb3da6476e53aca3a91c3e7d859cda18d26515f51b2ed283a6fa", "d533d86f897ab3117555bfa78b3b17abc340a384f278b65ce1975c7558c1e29f", "ee619307a4b25a1885fd092060af6ede6d92e39e885550cf06c8ac6701a1872f", "04f89a2e93e449c774a19819b032af5e5f7ec1ec66cd03427af3023eb351679e", "3f8bca48dd92adf070ab7d7de102ec92d16a12f6942a53f2f31f0669819038a1", "81fd875c4c33e1a22d89e119328d4edc6e05358bd09ee3d3986a6ceb45a54a46", "bbc6d63eb5b5f1d7bbe4b77ae83dc6d0b6cceafc7e2c42a5ee6b6d47fab9be21", "116bdd86a3284d58fcd63396b02645cf37c6fe8c3b2ab0f587ed5c2e726f0565"]
    end
  end

end