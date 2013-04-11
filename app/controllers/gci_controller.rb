class GciController < ApplicationController
  include ApplicationHelper

  before_filter :update_session_id, :except => [:get_session_id, :init, :login]

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
      
      render :json => {"success" => true}
    rescue Exception => e
      render :json => {"success" => false}
    end
  end

  def login
    params.each do |k, v|
      GCI.send "#{k}=", v if GCI.respond_to?("#{k}=")
    end

    begin
      GCI.gci_logout
      GCI.gci_login
      session_id = GCI.gci_get_session_id

      # TODO: support multiple sessions
      render :json => {"success" => true, "sessionId" => session_id}
    rescue Exception => e
      render :json => {"success" => false}
    end
  end

  def execute_string
    log_gci "execute_string", params
    GCI::GciExecuteStr(params[:string], params[:oop])
  end

  def version
    render :json => GCI.gci_version
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
