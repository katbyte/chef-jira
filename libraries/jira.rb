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
    # rubocop:disable Metrics/PerceivedComplexity
    # rubocop:disable CyclomaticComplexity
    def jira_artifact_url
      return node['jira']['url'] unless node['jira']['url'].nil?

      base_url = 'https://www.atlassian.com/software/jira/downloads/binary'
      version  = node['jira']['version']
      product = "#{base_url}/atlassian-jira-#{node['jira']['flavor']}-#{version}"

      # JIRA versions >= 7.0.0 have different flavors
      # By default we assume you want >= 7.0.0
      v = Gem::Version.new(version)

      if node['jira']['flavor'].downcase == 'software' && (v >= Gem::Version.new('7.0.0'))
        # Software had a different set of URLs for from 7.0.0 to 7.1.7
        if v < Gem::Version.new('7.1.9')
          product = "#{base_url}/atlassian-jira-#{node['jira']['flavor']}-#{version}-jira-#{version}"
        elsif v >= Gem::Version.new('7.2')
          product = "#{base_url}/atlassian-jira-#{node['jira']['flavor']}-#{version}"
        end
      elsif v < Gem::Version.new(7)
        product = "#{base_url}/atlassian-jira-#{version}"
      end

      # Return actual URL
      case node['jira']['install_type']
      when 'installer'
        "#{product}-#{jira_arch}.bin"
      when 'standalone'
        "#{product}.tar.gz"
      else
        fail 'Only the "installer" or "standalone" install types are supported by Atlassian and this cookbook.'
      end
    end
    # rubocop:enable CyclomaticComplexity
    # rubocop:enable Metrics/PerceivedComplexity
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
        '7.1.10' => {
          'core' => {
            'x32' => '530f253a6fa2b4d0e4ec8b02a4c546deeba21e881c8735008640dcaa38958d5d',
            'x64' => 'deb3ca344a9caba48b444c9dbe7529245c329bfffaaa211bdc52abc9aa4df0ec',
            'tar' => '234de0845500ede5af654ad2b88ed69ac57aa966c3a5f418b5702ca0508aec44'
          },
          'software' => {
            'x32' => 'a18fddcbc087294b44c6f0da3cd5cfe53aaa8caf7aa74fa30f2aa8ca2ebff58a',
            'x64' => 'fac63007aaced032ca47855966981ae2808fb2a8e3519e4cdbc799a3341debe0',
            'tar' => 'd13bd5c8768cc19844f64f6e1e5ae754c2601a955b5a95e1e4ef55e864619a21'
          }
        },
        '7.2.0' => {
          'core' => {
            'x32' => 'c3a02583c7498d9fcf6dd92e73b2e0390ef2a0ff03edb5e1396fae3c23bd2d51',
            'x64' => '42a7ee7379c46d6cbdda498b0a702a000f2806f2153ac132f1645bfe2f39e576',
            'tar' => '20f376cabd4565d37543f39168c553b717645521b947dc14af85a87a5d6db403'
          },
          'software' => {
            'x32' => 'e6f3369c4ad2788a82e5ca73762076a66c8de149b4e8a8ca14d95e3721f6304b',
            'x64' => 'ba23f268aff987d6110406dc0d2fa4658c6584db7586755f4fa30cb1a01ae43f',
            'tar' => 'aef51677548089f9f85e78eefd80bd21af5464a18985e1c071218f921a4f1f10'
          }
        },
        '7.2.1' => {
          'core' => {
            'x32' => '0fe47f6f532994fc7a6a8a75a0c03fe47eeb233c68e8996296500f8e770b5b2c',
            'x64' => '0e1462185b06439edb1c86060214dbcba076dc11142cf3c50ae3ee9acfa53f4a',
            'tar' => '5ee23a97049080e1379a038635d719f0c694de6fa35aa945d87783f683ba9a6d'
          },
          'software' => {
            'x32' => 'dd6303d52b5be18dcd89423cde5f9be468845036769553c5a1ec0d22517ff188',
            'x64' => 'b41c0c567a3e203d3e1ade7dbddf2a692dffa9d8629f88281509595665846111',
            'tar' => '16279d1d3e6cb7fb1bdf74d18fac8467746b72d4164036d19e2955a7332b8cb3'
          }
        },
        '7.2.2' => {
          'core' => {
            'x32' => '2cf576a725f5e730ee14028bf61a12d320e1886e5e3beff4869d8e73c2f75dbc',
            'x64' => '7ab345fb4eb5932c768008c0d15b523f10732774e595d073fd737c410afff3ca',
            'tar' => '40f923d73abc3cf96c115a8aa6627065cc6c8df946ada226dde80dcfc379904a'
          },
          'software' => {
            'x32' => 'f7e04a8e0ecd593c7a6b04cb5f6c0a6094092f3f17974d96edb9d829c2492f30',
            'x64' => '8de4607beb9cdcf71b3be7e1cb7c3d1e0c0dd716c0eb79c8b33e299338b5fc6d',
            'tar' => 'f6a7c72b11e47c4225e71b22531d54279f23a7cbb02671e5d8747c26a98f3d63'
          }
        },
        '7.2.3' => {
          'core' => {
            'x32' => '38a6064a63933aecf09b131d70e2c982f55a690b95a2ed3e69b51f00b474940b',
            'x64' => '39c0a43a62be0a3daba06e66b8c110202815ec8460d437e0a8c4b65df9b966e8',
            'tar' => '13ae134a4ddeed32b4a08a520c2ec8d410e9e93c4d5657d808b10ac9f83483d2'
          },
          'software' => {
            'x32' => '9d3a0413b32c07ffbfb717efb07d8bde28d9dfdac7cd24396bb6b151757e40d2',
            'x64' => 'e0d02381d951a0f745c3e1e77e673932d504c90db757f0caa9cd22ab13a6d910',
            'tar' => 'c9c310fdf4702403f119b804907be8143366b7a9d71d0e28356fe4287a706708'
          }
        },
        '7.2.4' => {
          'core' => {
            'x32' => '4b21768c1a04eb6c46fb29b50491c0c50bfbaee0f37d8bb849131fe1264d2140',
            'x64' => 'b7428584ea394855686a5e5fdb7bc1f636dd2ad133c8a4de39ba6b06c77edd34',
            'tar' => 'c5927ef75eec40b61e59b0fe4139ef0a2e38765d611cd8458c7b478060eeef52'
          },
          'software' => {
            'x32' => '785052efba8d410fba9d694e94e453879a56643ecd7bdbc299e813a8160f2555',
            'x64' => '4221c95932f4fa14394526a2ae03e4424f8a0e86979b7c92a8e8c4a020801521',
            'tar' => '0a57714dc5cf8d136a5ecf9156c6875f5547ce6c2b7aac9acc94695ea2d4b529'
          }
        },
        # 7.2.5 Cancelled
        '7.2.6' => {
          'core' => {
            'x32' => 'd3f9c7bdcc6cf0bd9c68f654b12d1d65e2d45b69e71868c219c300571adcc5ca',
            'x64' => 'e6afc6aed46b85ee799fd077bf94c2fc7e70ae5d2630580e630aaf97c4cc8d48',
            'tar' => '4136ffa64c44c84dca33032b1f0fc05b2316fa6beb54cddf0b922084378908e3'
          },
          'software' => {
            'x32' => 'b37882cdadbc98a19bdb833c68a6ee95c8de58d39cf1e14189888b034c676a08',
            'x64' => 'fb8e1a17f17676373c99bb00df717a148e69897106a66d6f4be3cabfd9af4626',
            'tar' => '9369a8ce67ff200aa098a14690fd65a023f6ea7c5dbddf300462456cd35bea84'
          }
        },
        '7.2.7' => {
          'core' => {
            'x32' => '89759f647b1bd2ebb77915e0dd52609f3adf3ce5af911ceb37fb66a0b9555956',
            'x64' => '01d8a4edf45817aeff6bee3ec750c6b365bc009dffa3df56f300558b0e433c37',
            'tar' => 'e27f2d6979beea214775e024989e6ab8de0184d47bda49be076c7b54da1b37e3'
          },
          'software' => {
            'x32' => '16faa31f87bb876bb856bdace1cca3c5d4f4e25a49cc96a9b8c5ffc5953f59a2',
            'x64' => '2564e47e924155f417706eafacdd089c69c1dfeab03a480946aeb41e8867b58e',
            'tar' => '40c675eb1f35ca8003c3dfd952d9283bc2a69591bc641f3b40f44acacd02916c'
          }
        },
        '7.3.0' => {
          'core' => {
            'x32' => '4e75caced513bf8561e9a03209de9ccf300a8a63523e4963f58b74488af2e7ba',
            'x64' => '1560cb10a2394e3bf24b3eb51b3313fbf6e97305d5dabb60da961133c168bf4a',
            'tar' => '07b47225be858eb7ad09f3b434d4865096ab10df92b0499fb234ef270500caac'
          },
          'software' => {
            'x32' => '0d5df8e9001ee5d6d7d20fa678d762de35ff22f6aaadd6f206927ed286ca5498',
            'x64' => '4e8ed1a8f480a083ad8025e0998795e6613e90cf1e67c7b1e2ab65facf327701',
            'tar' => '20231b9e3e19b9b52a69e31c9921c9b6876624309da59c9689020dfd1f305944'
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
