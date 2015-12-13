require 'spec_helper'

describe 'Java' do
  describe command('java -version 2>&1') do
    its(:exit_status) { should eq 0 }
  end
end

describe 'Postgresql' do
  it_behaves_like 'postgresql'
end

describe 'JIRA' do
  it_behaves_like 'jira behind the apache proxy'
end
