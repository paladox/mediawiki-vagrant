module MediaWikiVagrant
  class Plugin < Vagrant.plugin('2')
    name 'MediaWiki-Vagrant'

    command 'roles' do
      require 'mediawiki-vagrant/roles/root'
      Roles::Root
    end

    command 'config' do
      require 'mediawiki-vagrant/config'
      Config
    end

    command 'forward-port' do
      require 'mediawiki-vagrant/forward_port'
      ForwardPort
    end

    command 'paste-puppet' do
      require 'mediawiki-vagrant/paste-puppet'
      PastePuppet
    end

    command 'run-tests' do
      require 'mediawiki-vagrant/run-tests'
      RunTests
    end

    command 'git-update' do
      require 'mediawiki-vagrant/git-update'
      GitUpdates
    end

    command('list-roles', primary: false) do
      # deprecated in favor of `vagrant roles list`
      require 'mediawiki-vagrant/roles/list'
      Roles::List
    end

    command('reset-roles', primary: false) do
      # deprecated in favor of `vagrant roles reset`
      require 'mediawiki-vagrant/roles/reset'
      Roles::Reset
    end

    command('enable-role', primary: false) do
      # deprecated in favor of `vagrant roles enable`
      require 'mediawiki-vagrant/roles/enable'
      Roles::Enable
    end

    command('disable-role', primary: false) do
      # deprecated in favor of `vagrant roles disable`
      require 'mediawiki-vagrant/roles/disable'
      Roles::Disable
    end

    command 'import-dump' do
      require 'mediawiki-vagrant/import-dump'
      ImportDump
    end

    command 'hiera' do
      require 'mediawiki-vagrant/hiera'
      Hiera
    end

    action_hook(self::ALL_ACTIONS) do |hook|
      require 'mediawiki-vagrant/middleware'
      hook.before(Vagrant::Action::Builtin::Provision, Middleware)
    end

    action_hook(:mediawiki, :machine_action_destroy) do |hook|
      require 'mediawiki-vagrant/destroy'
      hook.before(VagrantPlugins::ProviderVirtualBox::Action::Destroy, Destroy)
    end

    provisioner 'mediawiki_reload' do
      require 'mediawiki-vagrant/reload'
      MediaWikiVagrant::Reload
    end

    config(:lsb_check, :provisioner) do
      require 'mediawiki-vagrant/lsb_check/config'
      MediaWikiVagrant::LsbCheck::Config
    end

    provisioner :lsb_check do
      require 'mediawiki-vagrant/lsb_check/provisioner'
      MediaWikiVagrant::LsbCheck::Provisioner
    end

  end
end
