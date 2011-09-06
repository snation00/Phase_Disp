#!/usr/bin/env ruby

# -*- encoding: utf-8 -*-
require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)

# $:.unshift('./lib')
$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
require 'phase_disp'

DataLoader.setup('ph_disp', false)

dir = './CML2CMOS_test/'
dir = ARGV[0] if ARGV[0]

Dir.glob(dir + '*.txt') do |file_name|
  # DataLoader::process_file(file_name)
    DataLoader::process_phase_displacement(file_name)
  # DataLoader::process_intercepts(file_name)
  # DataLoader::process_error_points(file_name)
  # DataLoader::process_ugly_error_points(file_name)
  # DataLoader::process_new_ugly_error_points(file_name)
  # DataLoader::process_daniel_intercepts(file_name)
  # DataLoader::grab_time(file_name)
  # DataLoader::new_grab_time(file_name)
end
