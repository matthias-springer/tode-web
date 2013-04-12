class GciController < ApplicationController
  include ApplicationHelper

  before_filter :update_session_id, :except => [:get_session_id, :init, :login, :set_session_id]

  def get_session_id
    render :json => GCI.gci_get_session_id
  end

  def init
    require "./lib/gci/gci.rb"
    
    params.each do |k, v|
      GCI.send "#{k}=", v if GCI.respond_to?("#{k}=")
    end
   
    begin
      GCI.init_ffi
      
      render :json => {"success" => true, "result" => nil}
    rescue Exception => e
      render :json => {"success" => false, "exception" => e.to_s}
    end
  end

  def login
    params.each do |k, v|
      GCI.send "#{k}=", v if GCI.respond_to?("#{k}=")
    end

    begin
      #GCI.gci_logout
      GCI.gci_login
      session_id = GCI.gci_get_session_id

      # TODO: support multiple sessions
      render :json => {"success" => true, "sessionId" => session_id, "result" => session_id}
    rescue Exception => e
      render :json => {"success" => false, "exception" => e.to_s}
    end
  end

  def execute_str
    begin
      log_gci "execute_str", params
      result = GCI.gci_execute_str(params[:string], Integer(params[:oop]))

      render :json => {"success" => true, "result" => result}
    rescue Exception => e
      render :json => {"success" => false, "exception" => e.to_s}
    end
  end

  def fetch_str
    begin
      log_gci "fetch_str", params

      result = GCI.gci_fetch_string(Integer(params[:oop]))
      render :json => {"success" => true, "result" => result}
    rescue Exception => e
      render :json => {"success" => false, "exception" => e.to_s}
    end
  end

  def version
    render :json => {"success" => true, "result" => GCI.gci_version}
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
