require 'spec_helper'

describe 'Postgresql' do
  it_behaves_like 'postgresql'
end

describe 'JIRA' do
  it_behaves_like 'jira behind the apache proxy'
end
