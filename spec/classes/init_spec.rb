require 'spec_helper'
describe 'bitban' do

  context 'with defaults for all parameters' do
    it { should contain_class('bitban') }
  end
end
