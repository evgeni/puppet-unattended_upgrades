require 'spec_helper'

describe 'unattended_upgrades' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:file_unattended) { '/etc/apt/apt.conf.d/50unattended-upgrades' }

      it { is_expected.to compile.with_all_deps }

      it do
        is_expected.to create_file('/etc/apt/apt.conf.d/10periodic').
          with_owner('root').
          with_group('root').
          with_content(%r{APT::Periodic::Enable "1";}).
          with_content(%r{APT::Periodic::BackupArchiveInterval "0";}).
          with_content(%r{APT::Periodic::BackupLevel "3";}).
          with_content(%r{APT::Periodic::MaxAge "0";}).
          with_content(%r{APT::Periodic::MinAge "2";}).
          with_content(%r{APT::Periodic::MaxSize "0";}).
          with_content(%r{APT::Periodic::Update-Package-Lists "1";}).
          with_content(%r{APT::Periodic::Download-Upgradeable-Packages "0";}).
          with_content(%r{APT::Periodic::Download-Upgradeable-Packages-Debdelta "1";}).
          with_content(%r{APT::Periodic::Unattended-Upgrade "1";}).
          with_content(%r{APT::Periodic::AutocleanInterval "0";}).
          with_content(%r{APT::Periodic::Verbose "0";})
      end

      it { is_expected.to contain_apt__conf('auto-upgrades').with_ensure('absent') }

      it do
        is_expected.to create_file('/etc/apt/apt.conf.d/10options').
          with_owner('root').
          with_group('root').
          with_content(%r{^Dpkg::Options\s\{}).
          without_content(%r{^\s+\"--force-confdef\";}).
          without_content(%r{^\s+\"--force-confold\";}).
          without_content(%r{\"--force-confnew\";}).
          without_content(%r{\"--force-confmiss\";})
      end

      it { is_expected.to create_file(file_unattended).with_owner('root').with_group('root') }

      # rubocop:disable Style/RegexpLiteral
      case os_facts[:operatingsystem]
      when 'Debian'
        case os_facts[:lsbdistcodename]
        when 'stretch', 'buster'
          it do
            is_expected.to create_file(file_unattended).with_content(
              /Unattended-Upgrade::Origins-Pattern\ {\n
              \t"origin=Debian,codename=\${distro_codename},label=Debian-Security";\n
              };/x
            )
          end
        when 'bullseye'
          it do
            is_expected.to create_file(file_unattended).with_content(
              /Unattended-Upgrade::Origins-Pattern\ {\n
              \t"origin=Debian,codename=\${distro_codename},label=Debian";\n
              \t"origin=Debian,codename=\${distro_codename}-security,label=Debian-Security";\n
              };/x
            )
          end
        end
      when 'Ubuntu'
        it do
          is_expected.to create_file(file_unattended).with_content(
            /Unattended-Upgrade::Allowed-Origins\ {\n
            \t"\${distro_id}\:\${distro_codename}";\n
            \t"\${distro_id}\:\${distro_codename}-security";\n
            \t"\${distro_id}ESMApps\:\${distro_codename}-apps-security";\n
            \t"\${distro_id}ESM\:\${distro_codename}-infra-security";\n
            };/x
          )
        end
      end
      # rubocop:enable Style/RegexpLiteral
    end
  end
end
