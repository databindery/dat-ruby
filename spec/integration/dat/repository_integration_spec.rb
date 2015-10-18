require 'spec_helper'

describe Dat::Repository do
  let(:repo) { create_sample_repo }

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

  def create_sample_repo
    sample_repo_path = File.expand_path('tmp/dat/sample')
    sample_repo = ::Dat::Repository.new(dir:sample_repo_path)
    FileUtils.rm_rf(sample_repo_path)
    puts "creating sample dat repo at #{sample_repo_path}"
    sample_repo.init
    sample_repo.import(dataset:'hail', file: sample_file_path('hail-2014.csv'), key:'ZTIME')
    sample_repo.import(dataset:'proteins', file: sample_file_path('1pqx-ATOMS.csv'), key:'serial')
    sample_repo.import(dataset:'plants', file: sample_file_path('plantlst.csv'), key:'Symbol')
    puts "created sample repo with datasets #{sample_repo.datasets}"
    sample_repo
  end
end