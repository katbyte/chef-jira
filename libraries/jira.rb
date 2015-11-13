# Jira module
module Jira
  # Jira::Helpers module
  # rubocop:disable Metrics/ModuleLength
  module Helpers
    # TODO: fix AbcSize
    # rubocop:disable Metrics/AbcSize
    class Jira
      def self.settings(node)
        begin
          if Chef::Config[:solo]
            begin
              settings = Chef::DataBagItem.load('jira', 'jira')['local']
            rescue
              Chef::Log.info('No jira data bag found')
            end
          else
            begin
              settings = Chef::EncryptedDataBagItem.load('jira', 'jira')[node.chef_environment]
            rescue
              Chef::Log.info('No jira encrypted data bag found')
            end
          end
        ensure
          settings ||= node['jira'].to_hash

          case settings['database']['type']
          when 'mysql'
            settings['database']['port'] ||= 3306
          when 'postgresql'
            settings['database']['port'] ||= 5432
          else
            warn 'Unsupported database type! - Use a supported type or handle DB creation/config in a wrapper cookbook!'
          end
        end

        settings
      end
    end
    # rubocop:enable Metrics/AbcSize

    def jira_virtual_host_name
      node['jira']['apache2']['virtual_host_name'] || node['fqdn']
    end

    def jira_virtual_host_alias
      node['jira']['apache2']['virtual_host_alias'] || node['hostname']
    end

    # Detects the current JIRA version.
    # Returns nil if JIRA isn't installed.
    #
    # @return [String] JIRA version
    def jira_version
      pom_file = File.join(
        node['jira']['install_path'],
        '/atlassian-jira/META-INF/maven/com.atlassian.jira/atlassian-jira-webapp/pom.properties'
      )

      begin
        return Regexp.last_match(1) if File.read(pom_file) =~ /^version=(.*)$/
      rescue Errno::ENOENT
        # JIRA is not installed
        return nil
      end
    end

    # Returns download URL for JIRA artifact
    # rubocop:disable Metrics/AbcSize
    # rubocop:disable CyclomaticComplexity
    def jira_artifact_url
      return node['jira']['url'] unless node['jira']['url'].nil?

      base_url = 'https://www.atlassian.com/software/jira/downloads/binary'
      version  = node['jira']['version']

      # JIRA versions >= 7.0.0 have different flavors
      # Also (at this time) the URLs for flavors unfortunately differ
      if Gem::Version.new(version) < Gem::Version.new(7)
        product = "#{base_url}/atlassian-jira-#{version}"
      else
        case node['jira']['flavor']
        when 'software'
          product = "#{base_url}/atlassian-jira-#{node['jira']['flavor']}-#{version}-jira-#{version}"
        when 'core'
          product = "#{base_url}/atlassian-jira-#{node['jira']['flavor']}-#{version}"
        end
      end

      # Return actual URL
      case node['jira']['install_type']
      when 'installer'
        "#{product}-#{jira_arch}.bin"
      when 'standalone'
        "#{product}.tar.gz"
      when 'war'
        fail 'WAR install type is no longer supported by Atlassian and removed from this cookbook.'
      end
    end
    # rubocop:enable CyclomaticComplexity
    # rubocop:enable Metrics/AbcSize

    # Returns SHA256 checksum of specific JIRA artifact
    # rubocop:disable Metrics/AbcSize
    def jira_artifact_checksum
      return node['jira']['checksum'] unless node['jira']['checksum'].nil?

      version = node['jira']['version']
      flavor  = node['jira']['flavor']

      if Gem::Version.new(version) < Gem::Version.new(7)
        sums = jira_checksum_map[version]
      else
        versionsums = jira_checksum_map[version]
        sums = versionsums[flavor]
      end

      fail "JIRA version #{version} is not supported by the cookbook" unless sums

      case node['jira']['install_type']
      when 'installer' then sums[jira_arch]
      when 'standalone' then sums['tar']
      end
    end
    # rubocop:enable Metrics/AbcSize

    def jira_arch
      (node['kernel']['machine'] == 'x86_64') ? 'x64' : 'x32'
    end

    # rubocop:disable Metrics/MethodLength
    # Returns SHA256 checksum map for JIRA artifacts
    def jira_checksum_map
      {
        '5.2' => {
          'x32' => '05335145554cc446adfb90e318139f9408b41cacb57d90d0e11b788718ed8734',
          'x64' => '95841d1b222db63c5653b81583837a5d90e315a2ff2661534b310113afcff33f',
          'tar' => '80e05e65778ce2e3d91422da9d30a547e174fe2b9ba920b7dcdff78e29f353da'
        },
        '5.2.11' => {
          'x32' => '7088a7d123e263c96ff731d61512c62aef4702fe92ad91432dc060bab5097cb7',
          'x64' => 'ad4a851e7dedd6caf3ab587c34155c3ea68f8e6b878b75a3624662422966dff4',
          'tar' => '8d18b1da9487c1502efafacc441ad9a9dc55219a2838a1f02800b8a9a9b3d194'
        },
        '6.0' => {
          'x32' => '3967f8f663c24ff51bf30300ae0f2fb27320c9b356ed4dbf78fce7cc1238eccb',
          'x64' => '915b773c9870ebacbee4712e26d1c9539b48210b6055cb1b2d81e662deae2e60',
          'tar' => '791a8a4a65e40cd00c1ee2a3207935fbcc2c103416e739ad4e3ed29e39372383'
        },
        '6.0.1' => {
          'x32' => 'e383961667e6ef6b5bc387123fa76620a5bdf71413283de5b79cd0ae71248922',
          'x64' => '4e56ef7980b8f3b5b434a7a440d663b9d08e5588d635214e4434eabc3a8d9623',
          'tar' => '492e46119310f378d7944dea0a92c470f0d0b794219d6647a92ea08f8e99f80e'
        },
        '6.0.2' => {
          'x32' => 'bfa7d8731ef2ec5b7e802c119d5a68b1b93505d904c831801236eacff9fa1f5e',
          'x64' => 'fee8fe6804ace532abb805eea5ae0df342526eaf45b2c3e8e34978c97b5aa3aa',
          'tar' => '89b0178bf33488040c032d678ffcdeebc9b9d4565599a31b35515e3aaa391667'
        },
        '6.0.3' => {
          'x32' => 'cda9499247c43c0f812bd2924e569ba3dd08c088e03455ec9c1f79bd30c1509a',
          'x64' => 'cdbd679e70097120c0083e9e0949c66b842742a3a4ccbae0db01b81d9e9fce9e',
          'tar' => '0f94b9d31b8825e91c05e06538dce5891801b83549adbc1dfd26f5b9100c24cf'
        },
        '6.0.4' => {
          'x32' => '4f60c69a13d3d66b0864849d9d3d5a8dfe240830b332cdd8848ae14055709984',
          'x64' => 'd7b845cb21461f032e1563e40f7daa220277809c53e14e4342728f04d0fa039a',
          'tar' => 'ca0f80c36ab408131e283b5c00aead949ce37c4ef8a870b2726eb55882ea6821'
        },
        '6.0.5' => {
          'x32' => '10f9cc9ebb702f01d44f315eabfa4bc1af75dadf161a2cf6d5439c720d604fed',
          'x64' => '0826bf54c7765b053e571d3118b8b48f899d60a76518dc4df34da14a66930e37',
          'tar' => '9050297a28059468a9a3ddfcc8b788aaf62210b341f547d4aebbab92baa96dd3'
        },
        '6.0.6' => {
          'x32' => '030f25f6ab565d66b9f390dced8cafafe0d338ea792d942a6d1901888fa91b7d',
          'x64' => 'bf7145fbbbe0446f3a349e85b7b1277cab3cbe1dfc85029a2fb974f8fac3be59',
          'tar' => '27e699692e107a9790926d5f6fb0ddb89a1bd70e1d6877ce23991c0701495d67'
        },
        '6.0.7' => {
          'x32' => '159f143a1d15c9764b05f0b07f5ea24e4afe851f276ba5290eadabcf5f404a53',
          'x64' => '89da53718d80aad4680e48559ff126ffb35addccfed556c022d5450fb8e44cbb',
          'tar' => '6de5ac1a06116de2c95d5944eab1da416170e8b6bea3a0a7a641b52836100946'
        },
        '6.0.8' => {
          'x32' => 'ad1d17007314cf43d123c2c9c835e03c25cd8809491a466ff3425d1922d44dc0',
          'x64' => 'b7d14d74247272056316ae89d5496057b4192fb3c2b78d3aab091b7ba59ca7aa',
          'tar' => '2ca0eb656a348c43b7b9e84f7029a7e0eed27eea9001f34b89bbda492a101cb6'
        },
        '6.1' => {
          'x32' => 'c879e0c4ba5f508b4df0deb7e8f9baf3b39db5d7373eac3b20076c6f6ead6e84',
          'x64' => '72e49cc770cc2a1078dd60ad11329508d6815582424d16836efd873f3957e2c8',
          'tar' => 'e63821f059915074ff866993eb5c2f452d24a0a2d3cf0dccea60810c8b3063a0'
        },
        '6.1.5' => {
          'x32' => 'f3e589fa34182195902dcb724d82776005a975df55406b4bd5864613ca325d97',
          'x64' => 'b0b67b77c6c1d96f4225ab3c22f31496f356491538db1ee143eca0a58de07f78',
          'tar' => '6e72f3820b279ec539e5c12ebabed13bb239f49ba38bb2e70a40d36cb2a7d68f'
        },
        '6.3.15' => {
          'x32' => '739ac3864951b06a4ce910826f5175523b4ab9eae5005770cbcb774cc94e2e29',
          'x64' => 'a334865dd0b5df5b3bcc506b5c40ab7b65700e310edb6e7e6f86d30c3a8e3375',
          'tar' => '056553ec88cdeeefec73a6692d270a21b9b395af63a5c1ad9865752928dcec2c'
        },
        '6.4.6' => {
          'x32' => 'bede3c18bced84a4b2134ad07c5c4387f6c6991cfaf59768307a31bf72ba8de4',
          'x64' => '0ea1cc37b7de135315b2b241992fca572f808337b730ad68dc0c8c514136a480',
          'tar' => '9bfdba6975cc5188053efe07787d290c12347b62ae13a10d37dd44f14fe68e05'
        },
        '6.4.7' => {
          'x32' => '8545173ce7c0abdad2213a9514adc2b91443acbed31de1a47a385e52521f7114',
          'x64' => '95db7901de1f0c3d346b6ce716cbdf8cd7dc8333024c26b4620be78ba70f3212',
          'tar' => 'c8623ca2a1c0fea18e3921ee1834b3ffe39d70ee2c539f99a99eee2cfb09edd4'
        },
        '6.4.11' => {
          'x32' => 'c68ac38ff0495084dd74d73a85c5e37889af265f3097149a05e4752279610ad6',
          'x64' => '4030010efd5fbec3735dc3a585cd833af957cf7efe4f4bbc34b17175ff9ba328',
          'tar' => 'a8fb59ea41a65e751888491e4c8c26f8a0a6df053805a1308e2b6711980881ec'
        },
        '6.4.12' => {
          'x32' => 'dc807ebed5065416eebb117c061aa57bd07c1d168136aca786ae2b0c100f7e30',
          'x64' => '9897ae190a87a61624d5a307c428e8f4c86ac9ff03e1a89dbfb2da5f6d3b0dbd',
          'tar' => 'a77cf4c646d3f49d3823a5739daea0827adad1254dae1d1677c629e512a7afd4'
        },
        '7.0.0' => {
          'core' => {
            'x32' => 'bcd4746dcd574532061f79ec549e16d8641346f4e45f1cd3db032730fd23ea80',
            'x64' => '314bb496b7d20fb1101eb303c48a80041775e4fadd692fd97583b9c248df5099',
            'tar' => '56bdae7b78ac4472e6c9a22053e4b083d9feb07ee948f4e38c795591d9fc9ae9'
          },
          'software' => {
            'x32' => '3a43274bc2ae404ea8d8c2b50dcb00cc843d03140c5eb11de558b3025202a791',
            'x64' => '49e12b2ba9f1eaa4ed18e0a00277ea7be19ffd6c55d4a692da3e848310815421',
            'tar' => '2eb0aff3e71272dc0fd3d9d6894f219f92033d004e46b25b542241151a732817'
          }
        }
      }
    end
    # rubocop:enable Metrics/MethodLength
  end
  # rubocop:enable Metrics/ModuleLength
end

::Chef::Recipe.send(:include, Jira::Helpers)
::Chef::Resource.send(:include, Jira::Helpers)
::Chef::Mixin::Template::TemplateContext.send(:include, Jira::Helpers)

