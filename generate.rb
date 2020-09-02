# frozen_string_literal: true

require 'fileutils'
require 'down'
require 'securerandom'
require 'yaml'

BASE_CONFIG = {
  application_name: 'production.example.com',
  certbot_active: 'no',
  certbot_email: 'example@email.com',
  certbot_mode: 'sandbox',
  domains: 'example.com,www.example.com',
  mysql_image: 'mysql:8.0',
  mysql_username: 'wordpress',
  nginx_image: 'nginx:1.15.12-alpine',
  server_directory: '/root/wordpress/',
  wordpress_image: 'wordpress:4.7-php7.1-fpm-alpine'
}.freeze

MENU_OPTIONS = {
  '1' => ['Application name', :application_name],
  '2' => ['Domains (comma separated)', :domains],
  '3' => ["Let's Encrypt email", :certbot_email],
  '4' => ["Let's Encrypt mode (sandbox/live)", :certbot_mode],
  '5' => ["Let's Encrypt is active (SSL cert has been installed -- yes/no)", :certbot_active],
  '6' => ['MySQL docker image', :mysql_image],
  '7' => ['Nginx docker image', :nginx_image],
  '8' => ['Wordpress docker image', :wordpress_image],
  '9' => ["MySQL username (don't change after initial generation)", :mysql_username],
  '10' => ['Server configuration directory', :server_directory]
}.freeze

VALID_MENU_INPUTS = MENU_OPTIONS.keys + ['w', 'q']

BASE_REPLACEMENTS = {
  '__RANDOM_PASSWORD__' => -> { SecureRandom.hex(16) }
}.freeze

def replacements(config)
  BASE_REPLACEMENTS.merge(
    '__CERTBOT_DOMAINS__' => -> { config[:domains].split(/,\s*/).map { |d| "-d #{d}" }.join(' ') },
    '__CERTBOT_EMAIL__' => -> { config[:certbot_email] },
    '__CERTBOT_MODE__' => -> { config[:certbot_mode] == 'live' ? '--force-renewal' : '--staging' },
    '__GENERATOR_DIRECTORY__' => -> { __dir__ },
    '__GENERATOR_FILE__' => -> { __FILE__ },
    '__MYSQL_IMAGE__' => -> { config[:mysql_image] },
    '__MYSQL_USER__' => -> { config[:mysql_username] },
    '__NGINX_BASIC_AUTH__' => lambda {
      if File.exist?(File.join(project_directory(config), 'nginx-auth', '.htpasswd'))
        ["        auth_basic \“#{config[:application_name]}\”;",
         "        auth_basic_user_file /etc/nginx/auth/.htpasswd;"].join("\n")
      else
        ''
      end
    },
    '__NGINX_DOMAINS__' => -> { config[:domains].split(/,\s*/).join(' ') },
    '__NGINX_IMAGE__' => -> { config[:nginx_image] },
    '__NGINX_SSL_CERTS__' => lambda {
      config[:domains].split(/,\s*/).flat_map do |domain|
        ["        ssl_certificate /etc/letsencrypt/live/#{domain}/fullchain.pem;",
         "        ssl_certificate_key /etc/letsencrypt/live/#{domain}/privkey.pem;"]
      end.join("\n")
    },
    '__PROJECT_DIRECTORY__' => -> { project_directory(config) },
    '__SERVER_DIRECTORY__' => -> { config[:server_directory] },
    '__WORDPRESS_IMAGE__' => -> { config[:wordpress_image] }
  )
end

def start(initial_config = {}.merge(BASE_CONFIG))
  config = get_user_config(initial_config)
  exists = project_exists?(config)

  create_project_directory(config)
  copy_templates(config, exists)
  download_ssl_template(config)
  insert_template_values(project_directory(config), replacements(config))
  save_config(config)
  print_success_message(config)
end

def download_ssl_template(config)
  url = "https://raw.githubusercontent.com/certbot/certbot/master/certbot-nginx/certbot_nginx/_internal/tls_configs/options-ssl-nginx.conf"
  file = Down.download(url)
  target = File.join(
    project_directory(config),
    'nginx-conf',
    file.original_filename
  )

  FileUtils.copy_file(file.path, target)
end

def load_config(path)
  yaml = File.read(path)
  YAML.load(yaml)
end

def save_config(config)
  project_dir = project_directory(config)
  yaml = YAML.dump(config)
  output_file = File.join(project_dir, 'generator-settings.yml')
  File.write(output_file, yaml)

  puts
  puts "Configuration written to #{output_file}."
  puts
  puts "In the future, you can run the program with `ruby #{__FILE__} #{output_file}` to preload the settings and update your application configuration."
end

def insert_template_values(directory, replacement_values)
  # **/* doesn't find /.env, but **/.* does
  file_list = Dir.glob("#{directory}/**/*") + Dir.glob("#{directory}/**/.*")

  file_list.each do |path|
    next unless File.file?(path)

    file_contents = File.read(path)

    file_contents.gsub!(/#{replacement_values.keys.join('|')}/) do |match|
      replacement_values[match].call
    end

    File.write(path, file_contents) if Regexp.last_match
  end
end

def create_project_directory(config)
  FileUtils.mkdir_p(project_directory(config))
end

def get_user_config(config)
  loop do
    display_menu(config)
    user_response = confirm_config

    return config if user_response == 'w'

    if user_response == 'q'
      puts 'Quitting without making any changes'
      exit
    end

    config = update_config(user_response, config)
  end
end

def project_directory(config)
  File.join('applications', config[:application_name].gsub(/\W/, '-'))
end

def project_exists?(config)
  project_dir = project_directory(config)

  File.exist?(File.join(project_dir, '.env'))
end

def update_config(update_option, config)
  response = nil
  config_key = MENU_OPTIONS[update_option][1]
  config_label = MENU_OPTIONS[update_option][0]

  loop do
    puts "What is the new value you would like to use for \"#{config_label}\" ?"
    response = STDIN.gets.chomp.strip

    break if response.size.positive?

    puts
    puts 'Sorry, you must provide a value'
  end

  config.merge(config_key => response)
end

def confirm_config
  response = nil

  loop do
    puts <<~MESSAGE
      Choose the item you would like to change. [#{VALID_MENU_INPUTS.join(',')}]

      Enter 'w' to write the configuration, or 'q' to quit.
    MESSAGE

    response = STDIN.gets.chomp

    return response if VALID_MENU_INPUTS.include?(response)

    puts
    puts "Sorry, '#{response}' is not a valid response"
    puts
  end
end

def display_menu(config)
  system('clear')

  puts 'The current configuration is:'
  puts

  MENU_OPTIONS.each_pair do |input_key, labels|
    config_key = MENU_OPTIONS[input_key][1]
    puts " #{input_key} - #{labels[0]}: #{config[config_key]}"
  end

  puts
end

# If the project already exists, we don't want to lose the env file. We make a
# copy of the file contents, and then write the contents back to the
# newly-copied file.
def copy_templates(config, exists)
  project_dir = project_directory(config)
  env_path = File.join(project_dir, '.env')
  env_content = File.read(env_path) if exists

  FileUtils.cp_r('templates/.', project_dir)
  File.write(env_path, env_content) if exists

  if ssl_is_live?(config)
    FileUtils.rm(File.join(project_dir, 'nginx-conf', 'nginx.conf'))
  else
    FileUtils.rm(File.join(project_dir, 'nginx-conf', 'nginx-ssl.conf'))
  end
end

def ssl_is_live?(config)
  config[:certbot_active] == 'yes'
end

def print_success_message(config)
  project_dir = project_directory(config)
  instructions_path = File.join(project_dir, 'instructions.txt')

  puts
  puts "Please review #{instructions_path}"
end

if ARGV[0]
  config = load_config(ARGV[0])
  start(config)
else
  start
end
