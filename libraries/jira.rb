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
      servicedesk_version  = node['servicedesk']['version']

      # if people are installing servicedesk use a dedicated url pattern
      if (node['jira']['flavor'] == 'servicedesk') && (Gem::Version.new(servicedesk_version) <= Gem::Version.new("3.1.7"))
        log "Servicedesk #{servicedesk_version} detected detected"
        product = "#{base_url}/atlassian-#{node['jira']['flavor']}-#{servicedesk_version}-jira-#{version}"
      elsif node['jira']['flavor'] == 'servicedesk'
        log "service desk #{servicedesk_version} detected"
        product = "#{base_url}/atlassian-#{node['jira']['flavor']}-#{servicedesk_version}"
      else
        # JIRA versions >= 7.0.0 have different flavors
        # Also (at this time) the URLs for flavors unfortunately differ
        if Gem::Version.new(version) < Gem::Version.new(7)
          product = "#{base_url}/atlassian-jira-#{version}"
        elsif Gem::Version.new(version) >= Gem::Version.new("7.1.9")
          product = "#{base_url}/atlassian-jira-#{node['jira']['flavor']}-#{version}"
        else
          case node['jira']['flavor']
          when 'software'
            product = "#{base_url}/atlassian-jira-#{node['jira']['flavor']}-#{version}-jira-#{version}"
          when 'core'
            product = "#{base_url}/atlassian-jira-#{node['jira']['flavor']}-#{version}"
          end
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
      servicedesk_version = node['servicedesk']['version']

      if Gem::Version.new(version) < Gem::Version.new(7)
        sums = jira_checksum_map[version]
      else
        versionsums = jira_checksum_map[version]
        sums = versionsums[flavor]
      end

      warn "JIRA version #{version} is not supported by the cookbook. Set node['jira']['checksum'] = false to disable checksum checking." unless sums

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
        '5.2.11' => {
          'x32' => '7088a7d123e263c96ff731d61512c62aef4702fe92ad91432dc060bab5097cb7',
          'x64' => 'ad4a851e7dedd6caf3ab587c34155c3ea68f8e6b878b75a3624662422966dff4',
          'tar' => '8d18b1da9487c1502efafacc441ad9a9dc55219a2838a1f02800b8a9a9b3d194'
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
        },
        '7.0.2' => {
          'core' => {
            'x32' => '483cbe3738c5b556ddbadf11adaf98428b0d6d7aec2460eba639c8f4190a6df6',
            'x64' => 'cda659e4b15eb6c70b2ad81acb2917ab66f6a6b114e8f3dad69683ec21b3a844',
            'tar' => '5568de1e67cbfe6c1d3e28869988c78fdc632c59774908d4e229aab1439d255f'
          },
          'software' => {
            'x32' => '235cd2466e3b1e3ac2f4826ee37d64cf53af3c49d72a816a380979931b9fb5fd',
            'x64' => '8ebd0609b3520dfa399672dd10556cbe4886aeb8c59dbf11058b61d5eedb5e2f',
            'tar' => '49a4aca54a5461762d5064b27fce9cb2b8a8a020c1c073c7499a48c19cc8542b'
          }
        },
        '7.0.4' => {
          'core' => {
            'x32' => '5d4fdf75e9f8d17e8e451fa07e8aee9160c2b1a57c563cbedf95b0c40d8b44d0',
            'x64' => '002b83c2a1b1b962c722eefd326797f969a0ffdeb936414efad35ab7836aa8ce',
            'tar' => '915ab38389cfc7777afd272683ce8c8226ccab5e8cc672352e5de14eb99d748c'
          },
          'software' => {
            'x32' => '24cf62ddab600d9ec989693c8f48f1581fcf65e5a25dfc8b5bb6d2de0d3beaa3',
            'x64' => 'bbddc723ab999a948cc9ebd2d4ccdc216e127805b2869cc66614bd4249141134',
            'tar' => '234f66679425c2285a68d75c877785d186cc7b532d73ada0d6907d67833e1522'
          }
        },
        '7.0.10' => {
          'core' => {
            'x32' => '8687f938df213ccd267bca936fc9c213bc01f58d03a4ebb67fbfd3859a92bb7a',
            'x64' => 'edef201ee8e8b58a5cb86728ab3411d3bee8af34b13b5844dcf543f079ebeb19',
            'tar' => 'f0a5c8fb0574f3037088e4449e0b3c5d996331d658b3bead8bf7df465df17c74'
          },
          'software' => {
            'x32' => '362c568471feffc80042b120cdb8b670d5d6a680822a05927fe6d061eda07a11',
            'x64' => '55b4e6314983602fb518b49caeb5f77c4b4b3bd8313bf0c685e3be0152a8f035',
            'tar' => '64af0960961ffcb8a03164dd473ada297c83635dca54ce5b16b1117aa0823cb7'
          }
        },
        '7.1.0' => {
          'core' => {
            'x32' => '1ac8dc90ec6a311363f04f185333f7e38f3b3e2a22d71fe4c1cf9a32a445c502',
            'x64' => '2c81a5163280c7533fafec6cf3954b8c1be6c0e0f9e394aadaa10bc6a7307170',
            'tar' => '5b07753a4cf000337cc8103aeb30ed51683df80765a0b0f1db5afe3eefc103d5'
          },
          'software' => {
            'x32' => 'd0e51e274e964e2f349c69c9fbf7d37f9e69353f653f0a3f8f6c731ee007bbd8',
            'x64' => '7f0fda48b280eaabd256a0d77a991c1fb7b654acb309e10ee64ecabf83a8dd09',
            'tar' => 'a4bdd2c0d9fd92c1cebab6eacef29e35f73058350a918bdfcb1b6a991d9992f2'
          }
        },
        '7.1.2' => {
          'core' => {
            'x32' => '446005c42051124a4c2aa9fc00cec79d9733054b9fd5a4945af4b4b152ba88d3',
            'x64' => 'efc187703a90ced1c31273f1da9fb1e4282a2a9f100e2d4bbe7ba88fc31cdeeb',
            'tar' => 'a402c1d97ad408f9ba3256dcddde9f7c50c013165f5c3ccede87538cb9d818fb'
          },
          'software' => {
            'x32' => 'c33d24f724500f086c1d2c3682f3371f71dfb6e99e6d1d7f2e12a5c6c56973a0',
            'x64' => 'f72337b8d55468c2b3f0526e7496d03dd1ec9bb3d482d0269fcf87f48791094a',
            'tar' => '4837de0425845966a4138e518da5325436bbc6c91bc78e7497bfc0384dfa411b'
          }
        },
        '7.1.7' => {
          'core' => {
            'x32' => 'e2b590c43b23f514b05cd27a37bc97bbaef9bb60098dca8c4f742c07afa12154',
            'x64' => 'c61c2e9f208867bee6db1d82c34f6248b6f220058459e6e13c6c24b8ca80528c',
            'tar' => '61f1def45e069a085922e24a647447709f19d3a520993c0f8f5583f4f9c5b178'
          },
          'software' => {
            'x32' => '57035f4c826abf352e3ef60431602a8753cc58fe98b35f6fa72db940f6e28c78',
            'x64' => '08f49dcfec3b0764a21d318363c2a72780c52c3e95823ade0bab233dcc36f638',
            'tar' => '2cb08d754072293a23906d7db7ec4bce09a53d783e27145e416f63fd205e59c1'
          },
          'servicedesk' => {
            'x32' => '9d1954c7e3502be656b4f69659e7ba937762bdf83a4201fcad0815bca7bb829a',
            'x64' => '35e11db8d870bef0dfb4c14c2e6e0f6d8c10326f1adde2865f6ab859cb714f7a'
          }
        },
        '7.1.9' => {
          'core' => {
            'x32' => '3166c2f10b3193821b221042784985b5081de935a3fb0630e9d6dac437469d7d',
            'x64' => '5617b87790c6d0413047e3cc7e3ad041fb410da91101c49fb759163ba2c6e998',
            'tar' => '2cf04f25edbe19e7b6d9e7320c78af107424c7eb5e81f6cbbb69802623b695a2'
          },
          'software' => {
            'x32' => '98d41db73b342c95a08fec233ddfb5da928875366e1cfea941be7f95bf0cf126',
            'x64' => '02d5d3adecc4d218ff258ad69ac39390678434359638d1785e78562178f39408',
            'tar' => 'f03f2a8dd42c4b5f03918b326f14d7339f16f60fee0fa4a4d9c2e04c82dbbed2'
          }
        },
        '7.2.0' => {
          'core' => {
            'x32' => 'c3a02583c7498d9fcf6dd92e73b2e0390ef2a0ff03edb5e1396fae3c23bd2d51',
            'x64' => '42a7ee7379c46d6cbdda498b0a702a000f2806f2153ac132f1645bfe2f39e576'
          },
          'software' => {
            'x32' => 'e6f3369c4ad2788a82e5ca73762076a66c8de149b4e8a8ca14d95e3721f6304b',
            'x64' => 'ba23f268aff987d6110406dc0d2fa4658c6584db7586755f4fa30cb1a01ae43f'
          }
        },
        '3.2.0' => {
          'servicedesk' => {
            'x32' => '098bc88803aed26940a79f37108f1706a062229922950d22ee40c5903644c60e',
            'x64' => 'd2f123ee324046e0178ce991125cad77a0c5f384237a2c7f59657af0c6b86578'
          }
        }
      }
    end
    # rubocop:enable Metrics/MethodLength

    # rubocop:disable Metrics/AbcSize
    # Function to truncate value to 4 significant bits, render human readable.
    #
    # The output is a human readable string that ends with "g", "m" or "k" if
    # over 1023. The output may be up to 6.25% less than the original value
    # because of the rounding.
    def binround(value)
      # Keep a multiplier which grows through powers of 1
      multiplier = 1

      # Truncate value to 4 most significant bits
      while value >= 16
        value = (value / 2).floor
        multiplier *= 2
      end

      # Factor any remaining powers of 2 into the multiplier
      while value == 2 * (value / 2).floor
        value = (value / 2).floor
        multiplier *= 2
      end

      # Factor enough powers of 2 back into the value to
      # leave the multiplier as a power of 1024 that can
      # be represented as units of "g", "m" or "k".

      # Disabled g and k calculations for now because we prefer easy comparison between values

      # if multiplier >= 1024 * 1024 * 1024
      #   while multiplier > 1024 * 1024 * 1024
      #     value *= 2
      #     multiplier = (multiplier / 2).floor
      #   end
      #   multiplier = 1
      #   units = 'g'

      # elsif multiplier >= 1024 * 1024
      if multiplier >= 1024 * 1024
        while multiplier > 1024 * 1024
          value *= 2
          multiplier = (multiplier / 2).floor
        end
        multiplier = 1
        units = 'm'

      # elsif multiplier >= 1024
      #   while multiplier > 1024
      #     value *= 2
      #     multiplier = (multiplier / 2).floor
      #   end
      #   multiplier = 1
      #   units = 'k'

      else
        units = ''
      end

      # Now we can return a nice human readable string.
      "#{multiplier * value}#{units}"
    end # end normalize def
    # rubocop:enable Metrics/AbcSize
  end
  # rubocop:enable Metrics/ModuleLength
end

::Chef::Recipe.send(:include, Jira::Helpers)
::Chef::Resource.send(:include, Jira::Helpers)
