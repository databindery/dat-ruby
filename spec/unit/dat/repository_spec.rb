require 'spec_helper'

describe Dat::Repository do
  let(:dir) { 'tmp/test/dat_dir' }
  let(:expanded_dir) { File.expand_path dir }
  let(:repo) { described_class.new(dir: dir) }
  let(:log_json) { File.read(sample_file('dat_log_json.txt')) }
  let(:diff_json) { File.read(sample_file('dat_diff_json.txt')) }
  let(:commit_ref_1) { 'revHash1' }
  let(:commit_ref_2) { 'revHash2' }

  subject { repo }

  describe 'init' do
    it 'tells dat to init the repository' do
      expect(subject).to receive(:run_command).with("dat init --path=#{expanded_dir} --no-prompt --json").and_return('{"message":"Initialized a new dat at #{expanded_dir}","created":true}')
      subject.init
    end
  end

  describe 'datasets' do
    let(:datasets_json) { '{"datasets":["urls","scores","addresses"]}'+"\n" }
    subject {repo.datasets}
    it 'gets the list of datasets from dat' do
      expect(repo).to receive(:run_command).with("dat datasets --json").and_return(datasets_json)
      expect(subject).to eq ["urls","scores","addresses"]
    end
  end

  describe 'forks' do
    let(:forks_json) { '{"forks":["78fe797318e01985d2ff906875ec5764d346b03310275392e319d1425f0d30bb","424a463d9a400fa5aa9b1a35284130852dfc584e206253cfd9b403175a3877d2"]}' }
    subject {repo.forks}
    it 'gets the list of forks from dat' do
      expect(repo).to receive(:run_command).with("dat forks --json").and_return(forks_json)
      expect(subject).to eq ["78fe797318e01985d2ff906875ec5764d346b03310275392e319d1425f0d30bb","424a463d9a400fa5aa9b1a35284130852dfc584e206253cfd9b403175a3877d2"]
    end
  end

  describe 'import' do
    let(:file_path) { '/foo/bar' }
    let(:expanded_file_path) { File.expand_path file_path }
    let(:dat_response) { '{"version":"02ad87accca3ab5fbbe2d073d99a617d2c1c6b3bbf8db5534552c9fd186bbe02"}'}

    context 'a file' do
      subject { repo.import(dataset:'billion_flowers', file: file_path) }
      it 'imports data from the file into dat' do
        expect(repo).to receive(:run_command).with("dat import #{expanded_file_path} -d billion_flowers --json").and_return(dat_response)
        subject
      end
    end
    context 'data' do
      let(:the_data) { '{...the data...}' }
      subject { repo.import(dataset:'billion_flowers', data: the_data) }
      it 'imports the data into dat' do
        expect(repo).to receive(:run_command).with("#{the_data} | dat import - -d billion_flowers --json").and_return(dat_response)
        subject
      end
      context 'when data is nil' do
        let(:the_data) { nil }
        it 'raises an error' do
          expect{ subject }.to raise_error(ArgumentError, "You must provide either a file or (string) data")
        end
      end
      context 'when data is empty' do
        let(:the_data) { '' }
        it 'raises an error' do
          expect{ subject }.to raise_error(ArgumentError, ":data cannot be empty")
        end
      end
    end
    context 'with a key' do
      subject { repo.import(dataset:'billion_flowers', file: file_path, key:'dc_identifier') }
      it 'tells dat to use the key' do
        expect(repo).to receive(:run_command).with("dat import #{file_path} -d billion_flowers -k dc_identifier --json").and_return(dat_response)
        subject
      end
    end
    context 'with a message' do
      subject { repo.import(dataset:'billion_flowers', file: file_path, message:'This is my message.') }
      it 'provides the log message to dat' do
        expect(repo).to receive(:run_command).with("dat import #{file_path} -d billion_flowers -m \"This is my message.\" --json").and_return(dat_response)
        subject
      end
    end
  end

  describe 'push' do
    let(:remote) { 'ssh://boo@widgets.com:dat/widget_inventory'}
    let(:push_json) { '{"version":"02ad87accca3ab5fbbe2d073d99a617d2c1c6b3bbf8db5534552c9fd186bbe02"}'}
    subject { repo.push(remote: remote) }
    it 'tells dat to push to a remote dat repo' do
      expect(repo).to receive(:run_command).with("dat push #{remote} --json").and_return(push_json)
      subject
    end
  end

  describe 'pull' do
    let(:remote) { 'ssh://boo@widgets.com:dat/widget_inventory'}
    let(:pull_json) { '{"version":"02ad87accca3ab5fbbe2d073d99a617d2c1c6b3bbf8db5534552c9fd186bbe02"}'}
    subject { repo.pull(remote: remote) }
    it 'tells dat to pull from a remote dat repo' do
      expect(repo).to receive(:run_command).with("dat pull #{remote} --json").and_return(pull_json)
      subject
    end
  end

  describe 'replicate' do
    let(:remote) { 'ssh://boo@widgets.com:dat/widget_inventory'}
    let(:replicate_json) { '{"version":"02ad87accca3ab5fbbe2d073d99a617d2c1c6b3bbf8db5534552c9fd186bbe02"}'}
    subject { repo.replicate(remote: remote) }
    it 'tells dat to replicate to/from a remote dat repo' do
      expect(repo).to receive(:run_command).with("dat replicate #{remote} --json").and_return(replicate_json)
      subject
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

  describe 'run_command' do
    context 'when there\'s an error running the command' do
      subject { repo.send(:run_command, ' | dat import - -d billion_flowers --json') }
      it 'raises an error' do
        expect {subject}.to raise_error(Dat::ExecutionError)
      end
    end
  end

  describe 'run_and_parse_response' do
    let(:dat_response) { '{}' }
    subject { repo.send(:run_and_parse_response, '') }
    before do
      allow(repo).to receive(:run_command).and_return(dat_response)
    end
    context 'when there\'s no dat repo' do
      let(:dat_response) { '{"error":true,"message":"dat: This is not a dat repository, you need to dat init first"}' }
      it 'raises an error' do
        expect{ subject }.to raise_error(Dat::NotARepositoryError, "dat: This is not a dat repository, you need to dat init first")
      end
    end
    context 'when dat can\'t auto detect the data type' do
      let(:dat_response) { '{"error":true,"message":"Could not auto detect input type. Please specify the format."}'}
      it 'raises an error' do
        expect{ subject }.to raise_error(Dat::AutoDetectTypeError, "Could not auto detect input type. Please specify the format.")
      end
    end
  end

end