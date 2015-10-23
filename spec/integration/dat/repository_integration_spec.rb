require 'spec_helper'

describe Dat::Repository do
  let(:repo) { setup_sample_dat_repo('tmp/dat/sample') }

  describe 'export_in_batches' do
    it 'chunks the export into batches of a specified size, allowing you to run a lambda on them' do
      batches = []
      repo.export_in_batches(dataset:'hail', batch_size:5) do |batch|
        batches << batch
      end
      expect(batches.map { |b| b.length }).to eq [5, 5, 5, 5, 4]
      expect(batches.last.last).to include '"value":{"ZTIME":"20140101084029","LON":"-82.30876","LAT":"29.27561","WSR_ID":"KTLH","CELL_ID":"T4","RANGE":"125","AZIMUTH":"122","SEVPROB":"-999","PROB":"-999","MAXSIZE":"-999"}'
    end
  end

  describe 'diff_in_batches' do
    let(:from_ref) { repo.commit_hashes[-2]} # commit that added Protein data
    let(:to_ref)  { repo.commit_hashes[-1] } # commit that added Plant data
    it 'chunks the diff into batches of a specified size, allowing you to run a lambda on them' do
      batches = []
      repo.diff_in_batches(from_ref, to_ref, batch_size:7) do |batch|
        batches << batch
      end
      expect(batches.map { |b| b.length }).to eq [7, 7, 7, 7, 2]
      expect(batches.last.last).to include '"value":{"Symbol":"ABVE2","Synonym Symbol":"","Scientific Name with Author":"Abies veitchii Lindl.","Common Name":"Christmastree","Family":"Pinaceae"}'
    end
  end

  def setup_sample_dat_repo(dat_path)
    sample_dat_repo = Dat::Repository.new(dir: dat_path)
    if sample_dat_repo.is_dat_repository? && sample_dat_repo.datasets == ["proteins", "plants", "hail"]
      puts "[integration] using the existing dat repo at #{sample_dat_repo.dir}"
    else
      puts "[integration] creating sample dat repo at #{sample_dat_repo.dir}"
      init_and_import_into(sample_dat_repo)
      puts "[integration] created sample repo with datasets #{sample_dat_repo.datasets}"
    end
    sample_dat_repo
  end

  def init_and_import_into(repository)
    FileUtils.rm_rf(repository.dir)
    repository.init
    repository.import(dataset:'hail', file: sample_file_path('hail-2014.csv'), key:'ZTIME', message: 'Add Hail data')
    repository.import(dataset:'proteins', file: sample_file_path('1pqx-ATOMS.csv'), key:'serial', message: 'Add Protein data')
    repository.import(dataset:'plants', file: sample_file_path('plantlst.csv'), key:'Symbol', message: 'Add Plant data')
    repository
  end
end