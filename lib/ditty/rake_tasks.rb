# frozen_string_literal: true

require 'rake'
require 'rake/tasklib'

module Ditty
  class Tasks < ::Rake::TaskLib
    include ::Rake::DSL if defined?(::Rake::DSL)

    def install_tasks
      namespace :ditty do
        desc 'Generate the needed tokens'
        task :generate_tokens do
          puts 'Generating the Ditty tokens'
          require 'securerandom'
          File.write('.session_secret', SecureRandom.random_bytes(40)) unless File.file?('.session_secret')
          File.write('.token_secret', SecureRandom.random_bytes(40)) unless File.file?('.token_secret')
        end

        desc 'Seed the Ditty database'
        task :seed do
          puts 'Seeding the Ditty database'
          require 'ditty/seed'
        end

        desc 'Prepare Ditty migrations'
        task :prep do
          puts 'Prepare the Ditty folders'
          Dir.mkdir 'pids' unless File.exist?('pids')

          puts 'Preparing the Ditty migrations folder'
          Dir.mkdir 'migrations' unless File.exist?('migrations')
          ::Ditty::Components.migrations.each do |path|
            FileUtils.cp_r "#{path}/.", 'migrations'
          end
          puts 'Migrations added'
          Dir.foreach('migrations').sort.each { |x| puts x if File.file?("migrations/#{x}") }
        end

        desc 'Migrate Ditty database to latest version'
        task :migrate do
          puts 'Running the Ditty migrations'
          Rake::Task['ditty:migrate:up'].invoke
        end

        namespace :migrate do
          folder = 'migrations'

          desc 'Check if the migration is current'
          task :check do
            require 'sequel'
            puts 'Running Ditty Migrations check'
            ::Sequel.extension :migration
            ::Sequel::Migrator.check_current(::DB, folder)
          end

          desc 'Migrate Ditty database to latest version'
          task :up do
            require 'sequel'
            puts 'Running Ditty Migrations up'
            ::Sequel.extension :migration
            ::Sequel::Migrator.apply(::DB, folder)
          end

          desc 'Roll back the Ditty database'
          task :down do
            require 'sequel'
            puts 'Running Ditty Migrations down'
            ::Sequel.extension :migration
            ::Sequel::Migrator.apply(::DB, folder, 0)
          end

          desc 'Reset the Ditty database'
          task :bounce do
            require 'sequel'
            puts 'Running Ditty Migrations bounce'
            ::Sequel.extension :migration
            ::Sequel::Migrator.apply(::DB, folder, 0)
            ::Sequel::Migrator.apply(::DB, folder)
          end
        end
      end
    end
  end
end

Ditty::Tasks.new.install_tasks
