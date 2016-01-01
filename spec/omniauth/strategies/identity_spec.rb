require 'spec_helper'

class MockIdentity; end

describe OmniAuth::Strategies::Identity do
  attr_accessor :app

  let(:auth_hash) { last_response.headers['env']['omniauth.auth'] }
  let(:identity_hash) { last_response.headers['env']['omniauth.identity'] }

  # customize rack app for testing, if block is given, reverts to default
  # rack app after testing is done
  def set_app!(identity_options = {})
    identity_options = { model: MockIdentity }.merge(identity_options)
    old_app = app
    self.app = Rack::Builder.app do
      use Rack::Session::Cookie
      use OmniAuth::Strategies::Identity, identity_options
      run ->(env) { [404, { 'env' => env }, ['HELLO!']] }
    end
    if block_given?
      yield
      self.app = old_app
    end
    app
  end

  before(:all) do
    set_app!
  end

  describe '#request_phase' do
    it 'should raise an error without an on_login callback' do
      expect { get '/auth/identity' }.to raise_error('on_login not provided')
    end
  end

  describe '#callback_phase' do
    let(:user) { mock(uid: 'user1', info: { 'name' => 'Rockefeller' }) }

    context 'with valid credentials' do
      before do
        MockIdentity.stub('auth_key').and_return('email')
        MockIdentity.should_receive('authenticate').with({ 'email' => 'john' }, 'awesome').and_return(user)
        post '/auth/identity/callback', auth_key: 'john', password: 'awesome'
      end

      it 'should populate the auth hash' do
        auth_hash.should be_kind_of(Hash)
      end

      it 'should populate the uid' do
        auth_hash['uid'].should == 'user1'
      end

      it 'should populate the info hash' do
        auth_hash['info'].should == { 'name' => 'Rockefeller' }
      end
    end

    context 'with invalid credentials' do
      before do
        MockIdentity.stub('auth_key').and_return('email')
        OmniAuth.config.on_failure = ->(env) { [401, {}, [env['omniauth.error.type'].inspect]] }
        MockIdentity.should_receive(:authenticate).with({ 'email' => 'wrong' }, 'login').and_return(false)
        post '/auth/identity/callback', auth_key: 'wrong', password: 'login'
      end

      it 'should fail with :invalid_credentials' do
        last_response.body.should == ':invalid_credentials'
      end
    end

    context 'with auth scopes' do
      it 'should evaluate and pass through conditions proc' do
        MockIdentity.stub('auth_key').and_return('email')
        set_app!(locate_conditions: ->(req) { { model.auth_key => req['auth_key'], 'user_type' => 'admin' } })
        MockIdentity.should_receive('authenticate').with({ 'email' => 'john', 'user_type' => 'admin' }, 'awesome').and_return(user)
        post '/auth/identity/callback', auth_key: 'john', password: 'awesome'
      end
    end
  end

  describe '#on_registration' do
    it 'should trigger from /auth/identity/register by default' do
      expect { get '/auth/identity/register' }.to raise_error('on_registration not provided')
    end
  end

  describe '#registration_phase' do
    context 'with successful creation' do
      let(:properties) do
        {
          name: 'Awesome Dude',
          email: 'awesome@example.com',
          password: 'face',
          password_confirmation: 'face',
          provider: 'identity'
        }
      end

      before do
        MockIdentity.stub('auth_key').and_return('email')
        m = mock(uid: 'abc', name: 'Awesome Dude', email: 'awesome@example.com', info: { name: 'DUUUUDE!' }, persisted?: true)
        MockIdentity.should_receive(:create).with(properties).and_return(m)
        MockIdentity.should_receive(:provider_column?).and_return(m)
      end

      it 'should set the auth hash' do
        post '/auth/identity/register', properties
        auth_hash['uid'].should == 'abc'
        auth_hash['provider'].should == 'identity'
      end
    end

    context 'with invalid identity' do
      let(:properties) do
        {
          name: 'Awesome Dude',
          email: 'awesome@example.com',
          password: 'NOT',
          password_confirmation: 'MATCHING',
          provider: 'identity'
        }
      end

      before do
        MockIdentity.should_receive(:create).with(properties).and_return(mock(persisted?: false))
        MockIdentity.should_receive(:provider_column?).and_return(true)
      end

      context 'default' do
        it 'should raise error' do
          expect { post '/auth/identity/register', properties }.to raise_error('on_registration not provided')
        end
      end

      context 'custom on_failed_registration endpoint' do
        it 'should set the identity hash' do
          set_app!(on_failed_registration: ->(env) { [404, { 'env' => env }, ['HELLO!']] }) do
            post '/auth/identity/register', properties
            identity_hash.should_not be_nil
          end
        end
      end
    end
  end
end
