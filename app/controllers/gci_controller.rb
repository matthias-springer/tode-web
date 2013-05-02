class GciController < ApplicationController
  include ApplicationHelper

  #before_filter :update_session_id, :except => [:get_session_id, :init, :login, :set_session_id]

  def handler
    exception_handler do
      self.send params[:api_command]
    end
  end

  def exception_handler
    log_gci params[:api_command], params

    begin
      render json: {success: true, result: yield}
    rescue Exception => e
      render json: {success: false, exception: e.to_s}
    end
  end

  def get_session_id
    GCI.gci_get_session_id
  end

  def init
    require "./lib/gci/gci.rb"
    
    params.each do |k, v|
      GCI.send "#{k}=", v if GCI.respond_to?("#{k}=")
    end
   
    GCI.init_ffi
  end

  def login
    params.each do |k, v|
      GCI.send "#{k}=", v if GCI.respond_to?("#{k}=")
    end

    #GCI.gci_logout
    GCI.gci_login
    GCI.gci_get_session_id
  end

  def err
    GCI.gci_err
  end

  def execute_str
    env_id = params[:envId] ? Integer(params[:envId]) : nil
    GCI.gci_execute_str(params[:string], Integer(params[:oop]), env_id)
  end

  def execute_str_expecting_str
    env_id = params[:envId] ? Integer(params[:envId]) : nil
    result_oop = GCI.gci_execute_str(params[:string], Integer(params[:oop]), env_id)
    GCI.gci_fetch_string(result_oop)
  end

  def fetch_str
    GCI.gci_fetch_string(Integer(params[:oop]))
  end

  def long_to_oop
    GCI.gci_long_to_oop(Integer(params[:oop]))
  end

  def nb_execute_str
    GCI.gci_nb_execute_string(params[:string], Integer(params[:oop]), Integer(params[:envId]))
  end

  def new_string
    GCI.gci_new_string(params[:string])
  end

  def perform
    GCI.gci_perform(Integer(params[:receiver]), params[:selector], params[:args])
  end

  def poll_for_result
    GCI.poll_for_result
  end

  def version
    GCI.gci_version
  end

  private
  
  DEBUG = true

  def update_session_id
    if @logged_in and params[:"!session_id"]
      session_id = Integer(params[:"!session_id"])
      log_gci "update_session_id", session_id
      Gci.gci_set_session_id(session_id)
    end
  end

  def log_gci(action, params)
    if DEBUG
      puts "Calling GciController.#{action} with #{params}."
    end
  end 
end
